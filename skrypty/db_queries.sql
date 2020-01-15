-- utworzenie tabeli z informacją o liczbie sąsiadów danego adresu w odległości maksymalnie 500m
create unlogged table neighbours as 
    SELECT 
      a.lokalnyid, 
      count(*)-1 no_of_neighbours
      -- odejmujemy jeden ponieważ łączymy tabelę samą do siebie
      -- więc każdy punkt będzie miał przynajmniej jednego sąsiada: siebie
    FROM dedup a
    JOIN dedup b ON ST_DWithin(a.gml, b.gml, 500)
    GROUP BY a.lokalnyid
;
alter table neighbours add primary key (lokalnyid);
alter table neighbours set logged ;


-- utworzenie tabeli z informcją o powierzchni budynku dla każdego adresu
-- szukamy najbliższego budynku w odległości maksymalnie 50m
create unlogged table areas as 
    select lokalnyid, st_area(geom) building_area
    from (
        -- znajdź dla każdego punktu adresowego budynki oddalone maks o 50m
        -- następnie je ponumeruj od najbliższych do najdalszych
        select
            a.lokalnyid,
            b.geom,
            row_number() over(partition by a.lokalnyid order by ST_Distance(a.gml, b.geom)) rn
        from dedup a
        join lod1_buildings_all b on ST_DWithin(a.gml, b.geom, 50)
    ) a
    where rn = 1
;
alter table areas add primary key (lokalnyid);
alter table areas set logged ;


-- utworzenie tabeli pomocnicznej z ponumerowanymi wierszami co zostanie wykorzystane
-- przy dzieleniu procesu sprawadzania ukształtowania terenu na mniejsze kawałki
create unlogged table dedup2 as 
    select row_number() over(order by gml) rn, *
    from dedup
    order by 1
;
alter table dedup2 add primary key (rn);
cluster dedup2 using dedup2_pkey;


-- utworzenie tabeli na informacje o ukształtowaniu terenu dla adresu
-- zapełnia skrypt terrain_prepare.py
create table terrain (
    lokalnyid uuid primary key,
    min_z double precision,
    max_z double precision,
    median_z double precision
);



vacuum analyze;


-- przygotowanie tabeli przejściowej z dotychczas zebranymi informacjami
create table geowynik as
select
    lokalnyid,
    teryt_simc,
    teryt_ulic,
    nr,
    st_transform(gml, 4326) geom,
    no_of_neighbours,
    building_area,
    max_z-min_z delta_z,
    median_z
from dedup d
join terrain t using(lokalnyid)
left join neighbours n using(lokalnyid)
left join areas a using(lokalnyid)
;

-- utworzenie tabeli na węzły
create table nodes (
  municipality_code_value text,
  city_code_value text,
  city_name text,
  street_code_value text,
  street_name text,
  house_no text,
  latitude numeric,
  longitude numeric,
  fiber smallint,
  copper smallint,
  xdsl smallint,
  radio smallint
);

-- utworzenie tabeli na zasięgi
create table endpoints (
  municipality_code_value text,
  city_code_value text,
  city_name text,
  street_code_value text,
  street_name text,
  house_no text,
  latitude numeric,
  longitude numeric,
  medium text,
  stationary_bandwidth_name numeric
);



-- utworzenie tabeli z węzłami po uzupełnieniu danych lokalizacyjnych na podstawie danych z PRG
drop table if exists geonodes ;
create unlogged table geonodes as
with a as (
    select 
        teryt_simc
        , coalesce(teryt_ulic, '99999') teryt_ulic
        ,nr
        ,x ,y
    from wynik
),
b as (
    select a.x, a.y, n.fiber, n.copper, n.xdsl, n.radio
    from nodes n
    join a 
        on a.teryt_simc = n.city_code_value and a.teryt_ulic = coalesce(n.street_code_value, '99999') and a.nr = n.house_no
    where latitude is null
),
c as (
    select n.longitude x, n.latitude y, n.fiber, n.copper, n.xdsl, n.radio
    from nodes n
    where latitude is not null
),
z as (
    select * from b
    union all
    select * from c
)
select 
    ST_SetSRID(ST_MakePoint(x, y),4326)::geography as geom,
    max(fiber) fiber, 
    max(copper) copper, 
    max(xdsl) xdsl, 
    max(radio) radio
from z
group by ST_SetSRID(ST_MakePoint(x, y),4326)::geography
;
-- utworznie indeksu przestrzennego
create index geonodes_geom_idx on geonodes using gist (geom);

CLUSTER geonodes using geonodes_geom_idx;
alter table geonodes set logged;
analyze;


-- utworzenie tabel tymczasowych do łatwiejszego liczenia statystyk związanych z węzłami
-- obliczenia związane z węzłami dokonane w FME
drop table if exists geonodes_fiber;
drop table if exists geonodes_copper_xdsl;
drop table if exists geonodes_copper_nonxdsl;
drop table if exists geonodes_radio;

create unlogged table geonodes_fiber as select geom::geography from geonodes where fiber = 1;
create index on geonodes_fiber using gist (geom);

create unlogged table geonodes_copper_xdsl as select geom::geography from geonodes where copper = 1 and xdsl = 1;
create index on geonodes_copper_xdsl using gist (geom);

create unlogged table geonodes_copper_nonxdsl as select geom::geography from geonodes where copper = 1 and xdsl = 0;
create index on geonodes_copper_nonxdsl using gist (geom);

create unlogged table geonodes_radio as select geom::geography from geonodes where radio = 1;
create index on geonodes_radio using gist (geom);

ANALYZE;


-- utworzenie tabeli ze wszystkimi informacjami dla każdego adresu
create unlogged table lookup_addr as
SELECT *
FROM geowynik w
left JOIN temp_fiber_count using(lokalnyid)
left JOIN temp_nonxdsl_count using(lokalnyid)
left JOIN temp_radio_count using(lokalnyid)
left JOIN temp_xdsl_count using(lokalnyid)
left JOIN fiber using(lokalnyid)
left JOIN radio using(lokalnyid)
left JOIN copper_xdsl using(lokalnyid)
left JOIN copper_nonxdsl using(lokalnyid)
;
alter table lookup_addr add primary key(teryt_simc, teryt_ulic, nr);
alter table lookup_addr set LOGGED;
create index luadr_geo_idx on lookup_addr using gist(geom);
analyze;


-- utworzenie ostatecznej tabeli do wyeksportowania i dalszej obróbki w pythonie
create table dataset as 
with 
ep_adr as (
    select 
        city_code_value teryt_simc, 
        coalesce(street_code_value) teryt_ulic, 
        house_no nr, 
        max(stationary_bandwidth_name) przepustowosc
    from endpoints e
    where house_no is not null
    group by 1,2,3
),
ep_latlon as (
    select 
        st_setsrid(st_makepoint(longitude, latitude), 4326) geom,
        max(stationary_bandwidth_name) przepustowosc
    from endpoints e
    where latitude is not null and house_no is null
    group by 1
)
select 
    ea.przepustowosc,
    no_of_neighbours,
    building_area,
    delta_z,
    median_z,
    fiber_count,
    copper_nonxdsl_count,
    radio_count,
    copper_xdsl_count,
    distance_fiber,
    distance_radio,
    distance_copper_xdsl,
    distance_copper_nonxdsl
from ep_adr ea
join lookup_addr la using(teryt_simc, teryt_ulic, nr)
UNION ALL
select 
    ell.przepustowosc,
    no_of_neighbours,
    building_area,
    delta_z,
    median_z,
    fiber_count,
    copper_nonxdsl_count,
    radio_count,
    copper_xdsl_count,
    distance_fiber,
    distance_radio,
    distance_copper_xdsl,
    distance_copper_nonxdsl
from ep_latlon ell
cross join lateral (
    select *
    from lookup_addr la
    order by st_transform(la.geom, 2180) <-> st_transform(ell.geom, 2180)
    limit 1
) lgeo
;
