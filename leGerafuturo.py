import json
import sys

tmpfile1 = sys.argv[1]

dados = open(tmpfile1)
x = json.load(dados)

for x in x:
    dia = x["Data"]
    cota = x["Cota"]
    print dia[0:4]+dia[5:7]+dia[8:10]+' '+str(cota)
