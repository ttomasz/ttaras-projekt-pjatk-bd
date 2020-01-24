### dodatkowe skrypty używane przy projekcie

* fme_workspaces - folder z workspace'ami dla programu FME Workbench
* lod1_download - folder ze skryptem w Pythonie do pobierami plików GML z modelami budynków 3D
* db_queries.sql - plik z częścią zapytań SQL wykorzystywanych do przetwarzania danych
* prg_download.py - skrypt w Pythonie do pobierania spakowanych plików GML z danymi adresowymi ze zbioru PRG.

Skrypt wykonywany z konsoli np:

```bash
python3 prg_download.py --output_dir /home/tt/folder/
```

```
python prg_download.py --output_dir "C:\folder\"
```

* teryt_download.py - skrypt w Pythonie do pobierania danych ze słownika TERYT prowadzonego przez GUS. Skrypt pobiera spakowany plik CSV z API typu SOAP i ładuje je do bazy PostgreSQL. 

Skrypt wywoływany z konsoli np:

```bash
python3 teryt_download.py --api_env "test" --api_user "UzytkownikTestowy" --api_password "12345" --dsn "host=localhost port=5432 user=test password=test"
```

* prg_parser.py - skrypt w Pythonie do parsowania plików GML z danymi adresowymi ze zbioru PRG. 

Skrypt wywoływany z konsoli.
Parametry:

```
--input - Plik do przetworzenia. Parser potrafi przetworzyć plik także jeżeli jest spakowany do zip.
--writer - Jak zapisać dane. Do wyboru: postgresql, sqlite, csv, stdout.
--csv_directory - Ścieżka do katalogu na pliki CSV. Używane kiedy writer to csv.
--sqlite_file - Scieżka do pliku sqlite. Używane kiedy writer to sqlite.
--dsn - Ciąg znaków z danymi do połączenia się do bazy PostgreSQL. Używane kiedy writer to postgresql.
--prep_tables - Czy usunąć tabele i je dodać od nowa. Może występować samo jak i z opisem true/false.
--limit - Pozwala ograniczyć liczbę przetwarzanych rekordów w przypadku przekierowania wyjścia na StdOut. Głównie do testowania.
```

* prg_prepare - folder ze skryptami w Pythonie i SQL do czyszczenia danych adresowych ze zbioru PRG.

Skrypt wywoływany z konsoli np:

```bash
python3 prg_prepare.py --full --dsn "host=localhost port=5432 user=test password=test"
```
