# Przewidywanie dostępności stacjonarnego internetu szerokopasmowego na podstawie lokalizacji

autor: Tomasz Taraś

## Wstęp

Celem pracy jest przygotowanie modelu, który determinował będzie dostępność internetu na podstawie lokalizacji przestrzennej.

Publicznie dostępne są dane na temat tego na jakie (prędkość, technologia) połączenie do internetu możemy liczyć w danej lokalizacji. Dane te zbierane są corocznie w pierwszym kwartale roku według stanu na 31 grudnia roku poprzedniego. Zbiera je Urząd Komunikacji Elektronicznej od przedsiębiorców telekomunikacyjnych. Dane te jednak zbierane są "do adresu" czyli jako lokalizacja jest adres lub jego współrzędne, a rejestry adresowe w Polsce są średniej jakości z różnych względów. Przedsiębiorca nie ma możliwości podawania zasięgu swojej sieci w postaci np. poligonów określających przestrzennie skrawek terenu gdzie dany operator może świadczyć usługi. Dodatkowo rozporządzenie określające jakiego rodzaju dane przedsiębiorcy mają podawać w sprawozdaniu do Urzędu jest dość skomplikowane i budzi sporo wątpliwości wśród sprawozdających się.

Te dwa czynniki powodują, że jakość danych nie jest idealna. Model stworzony w ramach tej pracy mogłby służyć jako imputer uzupełniający brakujące dane przy innych analizach lub do wykrywania anomalii, czyli obszarów, które dane wskazują jako pozbawione dostępu do szybkiego internetu, które według modelu powinny być w zasięgu sieci lub odwrotnie.

Praca skupi się głównie na zebraniu i przygotowaniu danych co jest tutaj głównym wyzwaniem. Część danych, które mogłyby być przydatne do tego zadania jest niedostępna lub płatna i trzeba kreatywnie wykorzystać te zbiory, które są dostępne. Dodatkowym wyzwaniem, będzie rozmiar wykorzystywanych danych jako, że model powinien móc objąć działaniem całą Polskę, która ma ponad 7,4 mln adresów, ponad 14 mln budynków i ponad 311 tys. km2 powierzchni.

## Zbiory danych wykorzystane w pracy

W pracy wykorzystano następujące zbiory danych:

#### Dane o infrastrukturze szerokopasmowej i zasięgach (SIIS)
__podmiot__: Urząd Komunikacji Elektronicznej  
__link__: [dane.gov.pl](https://dane.gov.pl/dataset/588,system-informacyjny-o-infrastrukturze-szerokopasmowej-api?page=1&per_page=50&sort=-title)  
__rozmiar__: spakowane ok. 1GB, rozpakowane pliki CSV ok. 8GB  
__opis__: Zbiór zawiera dane o infrastrukturze szerokopasmowej oraz o "zasięgach", czyli dostępności usługi dostępu do internetu. Dane przekazywane przez przedsiębiorców telekomunikacyjnych w ramach corocznej inwentaryzacji.

#### Dane o adresach z Państwowego Rejestru Granic (PRG)
__podmiot__: Główny Urząd Geodezji i Kartografii  
__link__: [gugik.gov.pl](http://www.gugik.gov.pl/pzgik/dane-bez-oplat/dane-z-panstwowego-rejestru-granic-i-powierzchni-jednostek-podzialow-terytorialnych-kraju-prg)  
__rozmiar__: spakowane ok. 1GB, rozpakowane pliki XML ok. 18GB  
__opis__: Zbiór zawiera listę adresów dla całęgo kraju zgodnie z tym co przekazane zostało do urzędu przez samorządy (gminy).

#### Modele 3D budynków (LOD1)
__podmiot__: Główny Urząd Geodezji i Kartografii  
__link__: [linki w geoportalu krajowym](https://mapy.geoportal.gov.pl/imap/Imgp_2.html?locale=pl&gui=new&sessionID=4857706), [opis](https://integracja.gugik.gov.pl/Budynki3D/budynki3d_opis.pdf)  
__rozmiar__: spakowane ok. GB  
__opis__: Zbiór zawiera modele 3D budynków o dokładności LOD1 dla całego kraju. Modele te zostały wykorzystane do utworzenia warstwy obrysów budynków 2D. To pozwoliło policzyć przybliżoną powierzchnię budynku dla adresu.  
Informacje wymagane do podania zgodnie z licenją:  
* Źródło: www.geoportal.gov.pl
* Dysponent: Główny Geodeta Kraju
* Data pobrania zbioru: 2019-11-10
* Zakres przetworzenia: Geometria budynków została spłaszczona do 2D oraz wyekstrahowana została część poligonowa wykorzystana dalej jako obrys budynku.
* Informacja: Modele 3D budynków nie stanowią rejestru publicznego ani elementu treści takiego rejestru. W konsekwencji czego mają wartość jedynie poglądową. Niezgodność Modeli 3D budynków ze stanem faktycznym lub prawnym, tak w postaci nieprzetworzonej jak i po ich ewentualnym przetworzeniu w procesie ponownego wykorzystania, nie może stanowić podstawy odpowiedzialności Głównego Geodety Kraju z jakiegokolwiek tytułu wobec jakiegokolwiek podmiotu.
* Licencja: https://integracja.gugik.gov.pl/Budynki3D/GUGiK_Licencja_na_Budynki3D.pdf

#### Numeryczny Model Terenu (NMT)
__podmiot__: Główny Urząd Geodezji i Kartografii  
__link__: [gugik.gov.pl](http://www.gugik.gov.pl/pzgik/dane-bez-oplat/dane-dotyczace-numerycznego-modelu-terenu-o-interwale-siatki-co-najmniej-100-m-nmt_100)  
__rozmiar__: spakowane ok. MB, rozpakowane pliki txt ok. MB  
__opis__: Zbiór zawiera punkty pomiarowe (co 100m) wysokości terenu nad poziomem morza. Zostanie wykorzystany do określenia ukształtowania terenu dla punktu.

#### Dane o nazwach urzędowych jednostek administracyjnych, miejscowości i ulic (rejestr TERYT)
__podmiot__: Główny Urząd Statystyczny  
__link__: [eteryt.stat.gov.pl](http://eteryt.stat.gov.pl/eTeryt/rejestr_teryt/udostepnianie_danych/baza_teryt/uzytkownicy_indywidualni/pobieranie/pliki_pelne.aspx)  
__rozmiar__: spakowane ok. 7MB, rozpakowane pliki CSV ok. 20MB  
__opis__: Zbiór zawiera oficjalną listę nazw jednostek administracyjnych, miejscowości i ulic kompilowaną przez GUS na podstawie rozporządzeń (jednostki, miejscowości) oraz uchwał samorządowych (ulice). Zbiór wykorzystany do walidacj danych adresowych PRG.

Wszystkie zbiory należą do danych publicznych udostępnianych przez urzędy na podstawie odpowiednich przepisów.

## Przygotowanie danych o infrastrukturze szerokopasmowej

Po pobraniu archiwum z najnowszymi dostępnymi danymi ze strony: i rozpakowaniu go, ładujemy biblioteki i ścieżki do plików z danymi, żeby móc wstępnie przetowrzyć dane w Pythonie.

Archiwum zawiera kilka plików CSV:
* networkendpoint_view.csv - plik zawiera tzw. "zakończenia sieci" w praktyce oznacza to "zasięg" sieci w postaci listy adresów lub współrzędnych z informacją w jakiej technologii i o jakiej maksymalnej prędkości dostawca internetu może świadczyć usługę w danym budynku;
* users_entity_view.csv - plik zawiera listę przedsiębiorców telekomunikacyjnych z id, służy głównie jako lookup table dla pozostałych plików, jeżeli interesuje nas który przedsiębiorca świadczy usługę lub posiada dany kawałek infrastruktury
* infrastructure_node_view.csv - plik zawiera informacje o węzłach telekomunikacyjnych, są to adresy lub współrzędne miejsc, gdzie jest infrastruktura telekomunikacyjna taka jak routery, switche itp;
* infrastructure_nodeinterface_view.csv - plik zawiera informacje o interfejsach w węzłach, czyli sprzęt jakich technologii znajduje się w węźle
* infrastructure_noderangeradio_view.csv - plik zawiera informacje o zasięgach anten radiowych, na cele tej analizy nie będzie to nam potrzebne


```python
import os
import pandas as pd
import numpy as np

folder = r'C:\Users\ttaras\jupyter\2018'
path_nodes = os.path.join(folder, 'infrastructure_node_view.csv')
path_node_interfaces = os.path.join(folder, 'infrastructure_nodeinterface_view.csv')
path_node_range_radio = os.path.join(folder, 'infrastructure_noderangeradio_view.csv')
path_companies = os.path.join(folder, 'users_entity_view.csv')
path_endpoints = os.path.join(folder, 'networkendpoint_view.csv')

```

Dalej przygotujemy oddzielnie dane dla zasięgów oraz dane dla węzłów.

### Zasięgi

Ładujemy dane o zasięgach z pliku CSV. Pomijamy od razu część kolumn i nadajemy odpowiednie typy.


```python
endpoints_df = pd.read_csv(
    path_endpoints, 
    usecols=[
        'municipality_code_value',
        'city_code_value',
        'city_name',
        'street_code_value',
        'street_name',
        'house_no',
        'latitude',
        'longitude',
        'medium',
        'stationary_bandwidth_name'
    ],
    dtype={
        'municipality_code_value': 'category',
        'city_code_value': 'category',
        'city_name': str,
        'street_code_value': 'category',
        'street_name': str,
        'house_no': str,
        'latitude': np.float64,
        'longitude': np.float64,
        'medium': 'category',
        'stationary_bandwidth_name': np.float32
    }
)
```

Tak wygląda DataFrame po załadowaniu


```python
endpoints_df.head()
```




<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>municipality_code_value</th>
      <th>city_code_value</th>
      <th>city_name</th>
      <th>street_code_value</th>
      <th>street_name</th>
      <th>house_no</th>
      <th>latitude</th>
      <th>longitude</th>
      <th>medium</th>
      <th>stationary_bandwidth_name</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td>1418044</td>
      <td>0921438</td>
      <td>Piaseczno</td>
      <td>09340</td>
      <td>ul. Kordeckiego</td>
      <td>4</td>
      <td>52.057000</td>
      <td>21.002062</td>
      <td>radiowe</td>
      <td>0.0</td>
    </tr>
    <tr>
      <th>1</th>
      <td>1418044</td>
      <td>0921438</td>
      <td>Piaseczno</td>
      <td>10036</td>
      <td>ul. Krupówki</td>
      <td>7</td>
      <td>52.068033</td>
      <td>21.033234</td>
      <td>radiowe</td>
      <td>0.0</td>
    </tr>
    <tr>
      <th>2</th>
      <td>1418044</td>
      <td>0921438</td>
      <td>Piaseczno</td>
      <td>11205</td>
      <td>ul. 11 Listopada</td>
      <td>83</td>
      <td>52.050284</td>
      <td>20.990206</td>
      <td>radiowe</td>
      <td>0.0</td>
    </tr>
    <tr>
      <th>3</th>
      <td>1418044</td>
      <td>0921438</td>
      <td>Piaseczno</td>
      <td>14907</td>
      <td>ul. Okrężna</td>
      <td>18</td>
      <td>52.062186</td>
      <td>20.982096</td>
      <td>radiowe</td>
      <td>0.0</td>
    </tr>
    <tr>
      <th>4</th>
      <td>1418044</td>
      <td>0921438</td>
      <td>Piaseczno</td>
      <td>15129</td>
      <td>ul. Orężna</td>
      <td>7</td>
      <td>52.070958</td>
      <td>21.007444</td>
      <td>radiowe</td>
      <td>0.0</td>
    </tr>
  </tbody>
</table>
</div>



Plik zawiera informacje o zasięgach stacjonarnych oraz mobilnych (LTE etc.). Zostawimy sobie tylko interesujące nas zasięgi stacjonarne.


```python
total_row_count = len(endpoints_df.index)
endpoints_df = endpoints_df[endpoints_df['stationary_bandwidth_name'] > 0]
filtered_row_count = len(endpoints_df.index)

print('Ogólna liczba wierszy w pliku CSV:', total_row_count)
print('Liczba wierszy po odfiltrowaniu zasięgów mobilnych:', filtered_row_count)
```

    Ogólna liczba wierszy w pliku CSV: 44123969
    Liczba wierszy po odfiltrowaniu zasięgów mobilnych: 11011310
    

Większość rekordów jest zestandaryzowana i zawiera kody gmin, miejscowości i ulic zgodne z urzędowym rejestrem TERYT, ale część np. ulic z różnych powodów nie ma tych kodów podanych, a zamiast tego jest kod stanowiący placeholder: '99998'. Sprawdźmy najpierw ile takich rekordów jest w naszych danych:


```python
len(endpoints_df[endpoints_df['street_code_value'] == '99998'].index)
```




    17582



Niewiele, ale prawdopodobnie niewielkim kosztem będziemy w stanie część z nich uzupełnić, więc spróbujemy.

Innym kodem stanowiącym placeholder jest kod ulic: '99999', który oznacza brak nazwy ulicy. W miastach się to zdarza ale mniejsze miejscowości i wsie dość często nie nadają nazw ulicom/drogom i adres to po prostu miejscowość i numer porządkowy np. Stara Wieś 3.

Przeprowadzimy teraz drobne czyszczenie i standaryzację danych.

Najpierw przeprowadzimy operację trim/strip usuwającą zbędne znaki białe z początku i końca wartości tekstowych, a następnie wszystkie litery występujące w numerach porządkowych zamienimy na wielkie, a nazwy ulic na małe. Dodatkowo z nazw ulic usuniemy przedrostek 'ul. '. Te operacje pozwolą nam porównać ten zbiór danych z innymi.


```python
endpoints_df['house_no'] = endpoints_df['house_no'].str.strip().str.upper()
endpoints_df['city_name'] = endpoints_df['city_name'].str.strip().str.lower()
endpoints_df['street_name'] = endpoints_df['street_name'].str.strip().str.lower()
endpoints_df['street_name'] = endpoints_df['street_name'].str.replace('ul. ', '')
```

Następnie dla zasięgów radiowych wszystkie wartości ponad 50 mbit/s sprowadzimy do wartości 50 mbit/s. Technicznie mało prawdopodobne, żeby dostęp radiowy pozwalał na szybsze prędkości o ile nie jest to LTE ze świetnym zasięgiem lub dedykowana radiolinia i większość z tych przypadków to najprawdopoboniej błędy w danych lub błędne interpretacje jakie dane powinny być wysłane do urzędu w ramach sprawozdania.


```python
endpoints_df.loc[
    (endpoints_df['medium'] == 'radiowe') & (endpoints_df['stationary_bandwidth_name'] > 50), 
    'stationary_bandwidth_name'
] = 50
```

Teraz spróbujemy uzupełnić część brakujących kodów ulic posiłkujac się istniejącymi w innych rekordach nazwami ulic i ich kodami. Następnie odrzucamy te rekordy których nie udało nam się dopasować.


```python
# backslashes allow splitting lines for better formatting
lookup = endpoints_df[~endpoints_df['street_code_value'].isin({'99999', '99998'})][['city_code_value', 'street_code_value', 'street_name']].drop_duplicates().dropna()

lookup.set_index(['city_code_value', 'street_name'], inplace=True)

temp = endpoints_df[endpoints_df['street_code_value'] == '99998'][['city_code_value', 'street_name']].join(lookup, on=['city_code_value', 'street_name'], rsuffix='_joined')

endpoints_df = endpoints_df.join(temp, rsuffix='_joined')

endpoints_df['street_code_value'] = endpoints_df[['street_code_value', 'street_code_value_joined']].apply(lambda x: x[0] if x[0] != '99998' else x[1], axis=1)

endpoints_df.drop(
    columns=['city_code_value_joined', 'street_code_value_joined', 'street_name_joined'], 
    inplace=True
)

endpoints_df.dropna(
    subset=['street_code_value', 'street_name'], 
    how='all', 
    axis=0, 
    inplace=True
)

endpoints_df = endpoints_df[endpoints_df['street_code_value'] != '99998']
```

Sprawdzamy ile rekordów nam zostało:


```python
len(endpoints_df.index)
```




    10947485



Usuwamy współrzędne z rekordów gdzie są podane liczby całkowite. Astronomicznie mało prawdopodobne żeby współrzędne jakiegoś obiektu to było dokładnie 20, 50 zamiast 20.000034, 50.000011. Są to błędy w sprawozdawczości przedsiębiorców.

Współrzędne tutaj będziemy traktować drugorzędnie. Jako podstawowe źródło posłuży nam zbiór PRG z urzędowymi adresami.


```python
endpoints_df.loc[(endpoints_df['latitude'] == round(endpoints_df['latitude'])) & (endpoints_df['longitude'] == round(endpoints_df['longitude'])), ['latitude', 'longitude']] = np.nan
```

Tak wygląda nasz DataFrame przed eksportem:


```python
endpoints_df.head()
```




<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>municipality_code_value</th>
      <th>city_code_value</th>
      <th>city_name</th>
      <th>street_code_value</th>
      <th>street_name</th>
      <th>house_no</th>
      <th>latitude</th>
      <th>longitude</th>
      <th>medium</th>
      <th>stationary_bandwidth_name</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>626</th>
      <td>1432064</td>
      <td>0921415</td>
      <td>ożarów mazowiecki</td>
      <td>17394</td>
      <td>poznańska</td>
      <td>167</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>kablowe współosiowe miedziane</td>
      <td>250.0</td>
    </tr>
    <tr>
      <th>627</th>
      <td>1432064</td>
      <td>0921415</td>
      <td>ożarów mazowiecki</td>
      <td>12740</td>
      <td>adama mickiewicza</td>
      <td>7</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>światłowodowe</td>
      <td>1000.0</td>
    </tr>
    <tr>
      <th>628</th>
      <td>1432064</td>
      <td>0921415</td>
      <td>ożarów mazowiecki</td>
      <td>12740</td>
      <td>adama mickiewicza</td>
      <td>5A</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>światłowodowe</td>
      <td>1000.0</td>
    </tr>
    <tr>
      <th>1259</th>
      <td>1201011</td>
      <td>0981682</td>
      <td>bochnia</td>
      <td>24983</td>
      <td>wygoda</td>
      <td>64</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>radiowe</td>
      <td>50.0</td>
    </tr>
    <tr>
      <th>1385</th>
      <td>0603011</td>
      <td>0930176</td>
      <td>rejowiec fabryczny</td>
      <td>10562</td>
      <td>kwiatowa</td>
      <td>72</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>światłowodowe</td>
      <td>1000.0</td>
    </tr>
  </tbody>
</table>
</div>



Eksport danych o zasięgach do pliku CSV.


```python
endpoints_df.to_csv(r'C:\Users\ttaras\jupyter\zasiegi.csv', sep=';', index=False)
```

### Węzły i interfejsy

Ładujemy dane o węzłach i interfejsach z plików CSV. Pomijamy od razu część kolumn i nadajemy odpowiednie typy.


```python
nodes_df = pd.read_csv(
    path_nodes, 
    usecols=[
        'municipality_code_value',
        'city_code_value',
        'city_name',
        'street_code_value',
        'street_name',
        'house_no',
        'latitude',
        'longitude',
    ],
    dtype={
        'municipality_code_value': str,
        'city_code_value': str,
        'city_name': str,
        'street_code_value': str,
        'street_name': str,
        'house_no': str,
        'latitude': np.float64,
        'longitude': np.float64,
    }
)
int_df = pd.read_csv(
    path_node_interfaces, 
    usecols=[
        'node_id', 
        'transmission_medium', 
        'technology_twisted_pair_copper'
    ]
)
```

Tak wyglądają nasze DataFrame po załadowaniu:

Węzły:


```python
nodes_df.head()
```




<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>municipality_code_value</th>
      <th>city_code_value</th>
      <th>city_name</th>
      <th>street_code_value</th>
      <th>street_name</th>
      <th>house_no</th>
      <th>latitude</th>
      <th>longitude</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td>3001022</td>
      <td>0524542</td>
      <td>Wyszyny</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>52.8923</td>
      <td>16.8586</td>
    </tr>
    <tr>
      <th>1</th>
      <td>0662011</td>
      <td>0929902</td>
      <td>Chełm</td>
      <td>21787</td>
      <td>ul. Szarych Szeregów</td>
      <td>9B</td>
      <td>51.1421</td>
      <td>23.4300</td>
    </tr>
    <tr>
      <th>2</th>
      <td>1425062</td>
      <td>0625668</td>
      <td>Słupica</td>
      <td>99999</td>
      <td>NaN</td>
      <td>168</td>
      <td>51.4124</td>
      <td>21.4048</td>
    </tr>
    <tr>
      <th>3</th>
      <td>0662011</td>
      <td>0929902</td>
      <td>Chełm</td>
      <td>11205</td>
      <td>ul. 11 Listopada</td>
      <td>2</td>
      <td>51.8325</td>
      <td>23.2944</td>
    </tr>
    <tr>
      <th>4</th>
      <td>0603114</td>
      <td>0107821</td>
      <td>Siedliszcze</td>
      <td>22073</td>
      <td>ul. Szpitalna</td>
      <td>15A</td>
      <td>51.1963</td>
      <td>23.1603</td>
    </tr>
  </tbody>
</table>
</div>



Interfejsy:


```python
int_df.head()
```




<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>node_id</th>
      <th>transmission_medium</th>
      <th>technology_twisted_pair_copper</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td>15837612</td>
      <td>światłowodowe</td>
      <td>NaN</td>
    </tr>
    <tr>
      <th>1</th>
      <td>12144737</td>
      <td>kablowe parowe miedziane</td>
      <td>1 Gigabit Ethernet</td>
    </tr>
    <tr>
      <th>2</th>
      <td>14365015</td>
      <td>kablowe parowe miedziane</td>
      <td>1 Gigabit Ethernet</td>
    </tr>
    <tr>
      <th>3</th>
      <td>14822051</td>
      <td>radiowe</td>
      <td>NaN</td>
    </tr>
    <tr>
      <th>4</th>
      <td>2917895</td>
      <td>światłowodowe</td>
      <td>NaN</td>
    </tr>
  </tbody>
</table>
</div>



Podobnie jak w przypadku zasięgów zestandaryzujemy adresy węzłów.


```python
nodes_df['house_no'] = nodes_df['house_no'].str.strip().str.upper()
nodes_df['city_name'] = nodes_df['city_name'].str.strip().str.lower()
nodes_df['street_name'] = nodes_df['street_name'].str.strip().str.lower()
nodes_df['street_name'] = nodes_df['street_name'].str.replace('ul. ', '')
```

Następnie dla interfejsów rozpiszemy wartości z kolumny 'medium transymisyjne' (oraz 'technology_twisted_pair_copper') metodą one-hot encoding, czyli stworzymy 4 kolumny, które będą przybierać wartośc 0 lub 1 zależnie od tego czy dane medium np. światłowodowe odpowiada temu rekordowi czy nie. Pogrupujemy interfejsy po id węzła dzięki czemu uzyskamy informacje per węzeł na temat technologii jakie są dla niego dostępne.
Dla medium kablowego parowego robimy wyjątek i dzielimy je na kable telefoniczne i nie-telefoniczne co odpowiada odpwiednio 1 i 0 w kolumnie 'xDSL'. Dla prostszego przetwarzania zostawiona zostanie kolumna 'copper' dla wszystkich kabli miedzianych.


```python
int_df['fiber'] = int_df['transmission_medium'].apply(lambda x: 1 if x == 'światłowodowe' else 0)

int_df['xdsl'] = int_df['technology_twisted_pair_copper'].apply(lambda x: 1 if x in ('ADSL2+', 'POTS/ISDN', 'VDSL2', 'ADSL2', 'ADSL', 'VDSL') else 0)

int_df['copper'] = int_df['transmission_medium'].apply(lambda x: 1 if x in ('kablowe parowe miedziane', 'kablowe współosiowe miedziane') else 0)

int_df['radio'] = int_df['transmission_medium'].apply(lambda x: 1 if x == 'radiowe' else 0)

int_df.drop(
    columns=['transmission_medium', 'technology_twisted_pair_copper'], 
    inplace=True
)

int_df = int_df.groupby(by='node_id', as_index=True)[['fiber', 'copper', 'xdsl', 'radio']].max()
```

Dla węzłów też spróbujemy uzupełnić brakujące kody ulic.


```python
temp = nodes_df[nodes_df['street_code_value'] == '99998'][['city_code_value', 'street_name']].join(lookup, on=['city_code_value', 'street_name'], rsuffix='_joined')

nodes_df = nodes_df.join(temp, rsuffix='_joined')

nodes_df['street_code_value'] = nodes_df[['street_code_value', 'street_code_value_joined']].apply(lambda x: x[0] if x[0] != '99998' else x[1], axis=1)

nodes_df.drop(
    columns=['city_code_value_joined', 'street_code_value_joined', 'street_name_joined'], 
    inplace=True
)
```

Usuwamy współrzędne tam gdzie są całkowite.


```python
nodes_df.loc[(nodes_df['latitude'] == round(nodes_df['latitude'])) & (nodes_df['longitude'] == round(nodes_df['longitude'])), ['latitude', 'longitude']] = np.nan
```

Dołączamy do węzłów informacje o technologiach z interfejsów.


```python
nodes_df = nodes_df.join(int_df)
```

Ile węzłów mamy w naszym DataFrame:


```python
len(nodes_df.index)
```




    348670



Ostatecznie uzupełniamy jeszcze brakujące wartości dla kolumn oznaczających technologie. Brak wartości jest równoznaczny 0 zgodnie z naszym kodowaniem.


```python
nodes_df['fiber'].fillna(0, inplace=True)
nodes_df['copper'].fillna(0, inplace=True)
nodes_df['xdsl'].fillna(0, inplace=True)
nodes_df['radio'].fillna(0, inplace=True)
```

Tak wygląda nasz DataFrame przed eksportem:


```python
nodes_df.head()
```




<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>municipality_code_value</th>
      <th>city_code_value</th>
      <th>city_name</th>
      <th>street_code_value</th>
      <th>street_name</th>
      <th>house_no</th>
      <th>latitude</th>
      <th>longitude</th>
      <th>fiber</th>
      <th>copper</th>
      <th>xdsl</th>
      <th>radio</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td>3001022</td>
      <td>0524542</td>
      <td>wyszyny</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>NaN</td>
      <td>52.8923</td>
      <td>16.8586</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
    </tr>
    <tr>
      <th>1</th>
      <td>0662011</td>
      <td>0929902</td>
      <td>chełm</td>
      <td>21787</td>
      <td>szarych szeregów</td>
      <td>9B</td>
      <td>51.1421</td>
      <td>23.4300</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
    </tr>
    <tr>
      <th>2</th>
      <td>1425062</td>
      <td>0625668</td>
      <td>słupica</td>
      <td>99999</td>
      <td>NaN</td>
      <td>168</td>
      <td>51.4124</td>
      <td>21.4048</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
    </tr>
    <tr>
      <th>3</th>
      <td>0662011</td>
      <td>0929902</td>
      <td>chełm</td>
      <td>11205</td>
      <td>11 listopada</td>
      <td>2</td>
      <td>51.8325</td>
      <td>23.2944</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
    </tr>
    <tr>
      <th>4</th>
      <td>0603114</td>
      <td>0107821</td>
      <td>siedliszcze</td>
      <td>22073</td>
      <td>szpitalna</td>
      <td>15A</td>
      <td>51.1963</td>
      <td>23.1603</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
      <td>0.0</td>
    </tr>
  </tbody>
</table>
</div>



Eksport danych o węzłach do pliku CSV.


```python
nodes_df.to_csv(r'C:\Users\ttaras\jupyter\wezly.csv', sep=';', index=False)
```

## Przygotowanie danych adresowych wraz z potrzebnymi dla modelu informacjami o charakterystyce przestrzennej danego punktu

### Parsowanie i czyszczenie danych adresowych z Państwowego Rejestru Granic (PRG)



### Przygotowanie obrysów budynków na podstawie modeli 3D (LOD1)



### Przygotowanie danych z Numerycznego Modelu Terenu




### Połączenie danych w spójny słownik adresów wraz z dodatkowymi informacjami




## Przygotowanie kompletnego zbioru do uczenia modelu


