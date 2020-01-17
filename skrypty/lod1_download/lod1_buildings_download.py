import urllib.request
import shutil
from os.path import join, dirname, abspath

base_path_for_files = r'C:/podyplomowka/lod1/'

with open(join(dirname(abspath(__file__)),'lista_powiatow.txt'), 'r') as f:
    powiaty = [str(x).strip() for x in f]

for pow in powiaty:
    print(pow)
    file_name = join(base_path_for_files, pow+'.zip')
    url = f'https://integracja.gugik.gov.pl/Budynki3D/pobierz.php?d=2&plik=powiaty/lod1/{pow}_gml.zip'
    try:
        with urllib.request.urlopen(url) as response, open(file_name, 'wb') as out_file:
            shutil.copyfileobj(response, out_file)
    except Exception as e:
        print('There was a problem with:', pow, '- exception:', e)
