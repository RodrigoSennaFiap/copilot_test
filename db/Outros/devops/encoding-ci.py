import os
import re

print("Verificador de ENCODING de objetos")
print("Lendo objetos do arquivo: ")

# Coloque o caminho completo para o arquivo de leitura
path = "./db_files.sql"
with open(path, 'r', encoding='utf-8') as file:
    vetor_objetos = file.readlines()

print("Iniciando a verificar seus objetos: ")

def separator(text):
    print(text)

def detect_encoding(filename):
    encodings_to_try = ['utf-8', 'ascii']

    for encoding in encodings_to_try:
        try:
            with open(filename, 'rb') as f:
                first_bytes = f.read(3)
                if first_bytes != b'\xef\xbb\xbf':  # Verifica se não há BOM
                    f.seek(0)  # Volta para o início do arquivo
                    f.read().decode(encoding)
                else:
                    return None  # Retorna None se o arquivo tiver BOM
            return encoding
        except UnicodeDecodeError:
            pass
    return None

for obj in vetor_objetos:
    # Verificar se a linha é um comentário (iniciada com '--') e ignorá-la
    if re.match(r'^\s*--', obj.strip()):  # Verifica se a linha começa com '--'
        print("Ignorando comentario:", obj)
        continue
    
    print("Processando objeto:", obj.strip())
    separator("########### ARQUIVOS ###########")

    # Verificar o encoding do objeto
    encoding = detect_encoding(obj.strip())

    if encoding is None:
        separator(f"Nao foi possivel determinar o encoding do objeto: {obj.strip()}")
        print("Interrompendo a esteira CI.")
        exit(1)  # Encerra o script com código de saída 1 (indicando erro)

    print("Encoding:", encoding)

    # Verificar se o encoding não é UTF-8 nem US-ASCII
    if encoding not in ['utf-8', 'utf-16', 'latin-1']:
        separator(f"Objeto: {obj.strip()} encoding: {encoding}")
        print("Objeto com encoding indevido. Interrompendo a esteira CI.")
        exit(1)  # Encerra o script com código de saída 1 (indicando erro)

    separator("____________________________________________________________________________________________")

print("Objetos validados!")
print("Sem mais nenhum objeto para verificar")
print("Fim")
