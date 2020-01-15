INSERT INTO prg.pa
    SELECT
       pa.lokalnyid::uuid                                                                    lokalnyid,
       trim(ja2.nazwa)                                                                       woj,
       trim(ja3.nazwa)                                                                       pow,
       trim(ja4.nazwa)                                                                       gmi,
       case when length(ja4.idteryt) = 7 then substr(ja4.idteryt, 1, 6) else ja4.idteryt end terc6,
       trim(m.nazwa)                                                                         msc,
       case when m.idteryt ~ '^0+$' then null else m.idteryt end                             simc,
       trim(replace(replace(replace(replace(u.nazwaglownaczesc, '&quot;' , '"'), '`', '"'), '  ', ' '), 'ul. ', '')) ul,
       case when u.idteryt ~ '^0+$' then null else u.idteryt end                             ulic,
       pa.numerporzadkowy,
       ltrim(rtrim(replace(replace(upper(trim(pa.numerporzadkowy)), '\', '/'), ' ', ''), './'), '.0/') nr,
       case when pa.kodpocztowy = '00-000' then null else pa.kodpocztowy end                 pna,
       st_flipcoordinates(ST_GeomFromGML(SUBSTRING(pa.geometry, 54, length(pa.geometry) - 64))) geom
    FROM prg.punkty_adresowe pa
    LEFT JOIN prg.jednostki_administracyjne ja2 on pa.komponent_01 = ja2.gmlid
    LEFT JOIN prg.jednostki_administracyjne ja3 on pa.komponent_02 = ja3.gmlid
    LEFT JOIN prg.jednostki_administracyjne ja4 on pa.komponent_03 = ja4.gmlid
    LEFT JOIN prg.miejscowosci m on pa.komponent_04 = m.gmlid
    LEFT JOIN prg.ulice u on pa.komponent_05 = u.gmlid
    WHERE pa.status in ('istniejacy', 'wTrakcieBudowy')
        and pa.numerporzadkowy is not null
        and coalesce(pa.numerporzadkowy, '') <> coalesce(pa.ulica, '')
        and pa.numerporzadkowy !~ '^\d+([ ]+\d+)+$'
        and pa.numerporzadkowy !~ '^B\.*N\.*.*$'
        and pa.numerporzadkowy !~ '^[\.0 \-]+$'
        and trim(pa.numerporzadkowy) <> ''
        and pa.numerporzadkowy not like '%,%'
        and pa.numerporzadkowy not ilike '% do %'
        and pa.numerporzadkowy not ilike '%test%'
        and m.nazwa is not null
        and (u.nazwaglownaczesc is null or (u.nazwaglownaczesc is not null and u.nazwaglownaczesc <> '???'))
ON CONFLICT DO NOTHING
;
