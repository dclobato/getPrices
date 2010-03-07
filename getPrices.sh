#!/bin/bash

FIM="`date +"%d/%m/%Y"`"
INICIO="`date -v-2m +"%d/%m/%Y"`"
DIRETORIO="/Users/dclobato/Documents/Bancos/Cotacoes/Snapshots/"

ELINKS=`which elinks`
ELINKSPAR='-dump 1 -dump-width 500'
SED=`which sed`
AWK=`which awk`
TR=`which tr`
CUT=`which cut`
SORT=`which sort`

BBURL="http://www21.bb.com.br/portalbb/cotaFundos/GFI9,2,null,null,006.bbx?tipo=5\&fundo="
GFURL="https://online.gerafuturo.com.br/onlineGeracao/PortalManager?show=produtos.resultado_historico_cotas\&busca=s\&dataInicio=$INICIO\&dataFim=$FIM\&id_fundo_clube="
BCURL="http://www4.bcb.gov.br/pec/taxas/port/PtaxRPesq.asp"

#### Remove linhas em branco
BASEPARSER="$AWK '/./' | $SED -e 's/^ *//'"

#### Organizacao final
ENDPARSER="$SORT -rn"

#### Parsers para cada um dos bancos
BBPARSE="$SED '1,3d' | $SED -e :a -e '\$d;N;2,3ba' -e 'P;D' | $TR -s ' ' ';' | $TR -s '.' '/' | $TR -s ',' '.' | $AWK -F '[/|;]' '{ printf \"%s%s%s %s\n\", \$3, \$2, \$1, \$4 ; }'"
GFPARSE="$TR -s ' ' ';' | $TR -s ',' '.' | $AWK -F '[/|;]' '{ printf \"%s%s%s %s\n\", \$3, \$2, \$1, \$4 ; }'"
BCPARSE="$CUT -s -f 1,6 -d ';' | $AWK -F ';' '{ printf \"%s %f\\n\", \$1, \$2 ; }' | $TR ',' '.' | $AWK -F '\\0' '{ print substr(\$0, 5, 4) substr(\$0, 3, 2) substr(\$0, 1, 2), substr(\$0, 10)}'"

processLine(){
  line="$@" # get all args

  TIPO=$(echo $line | awk '{ print $1 }')
  SAIDA=$(echo $line | awk '{ print $2 }')
  BANCO=$(echo $line | awk '{ print $3 }')
  CODFU=$(echo $line | awk '{ print $4 }')

  tmpFile1="$DIRETORIO$SAIDA.1.tmp"
  tmpFile2="$DIRETORIO$SAIDA.2.tmp"
  finalFile="$DIRETORIO$SAIDA.mdSnapshots"
  touch $tmpFile1
  touch $tmpFile2

  echo "Obtendo cotacoes de $SAIDA ($CODFU) a partir do banco $BANCO -- tipo: $TIPO"
  if [ "$BANCO" == "BB" ]; then
     eval "$ELINKS $ELINKSPAR $BBURL$CODFU > $tmpFile1"
     cat $tmpFile1 | eval "$BASEPARSER | $BBPARSE > $tmpFile2"
     eval "$ENDPARSER < $tmpFile2 >$finalFile"
  fi
  if [ "$BANCO" == "GF" ]; then
     eval "$ELINKS $ELINKSPAR $GFURL$CODFU > $tmpFile1"
     cat $tmpFile1 | eval "$BASEPARSER | $GFPARSE > $tmpFile2"
     eval "$ENDPARSER < $tmpFile2 >$finalFile"
  fi
  if [ "$BANCO" == "BC" ]; then
     MOEDA=$(echo $line | awk '{ print $5 }')
     BCPAR="?RadOpcao=1\&DATAINI=$INICIO\&DATAFIM=$FIM\&ChkMoeda=$CODFU\&OPCAO=1\&MOEDA=$CODFU\&DESCMOEDA=$MOEDA\&BOLETIM=\&TxtOpcao5=$MOEDA\&TxtOpcao4=$CODFU"
     eval "$ELINKS $ELINKSPAR $BCURL$BCPAR > $tmpFile1"
     TOGET=`cat $tmpFile1 | grep "download/cotacoes/BC" | cut -f 3 -d " " | uniq`
     wget $TOGET -q -O $tmpFile2
     cat $tmpFile2 | eval "$BASEPARSER | $BCPARSE" > $tmpFile1
     eval "$ENDPARSER < $tmpFile1 >$finalFile"
  fi
  rm $tmpFile2 $tmpFile1
}

# Store file name
ARQFUNDOS=""

# Make sure we get file name as command line argument
# Else read it from standard input device
if [ "$1" == "" ]; then
   ARQFUNDOS="/dev/stdin"
else
   ARQFUNDOS="$1"
   # make sure file exist and readable
   if [ ! -f $ARQFUNDOS ]; then
  	echo "$ARQFUNDOS nao existe"
  	exit 1
   elif [ ! -r $ARQFUNDOS ]; then
  	echo "$ARQFUNDOS nao pode ser lido"
  	exit 2
   fi
fi
# read $FILE using the file descriptors

# Set loop separator to end of line
BAKIFS=$IFS
IFS=$(echo -en "\n\b")
exec 3<&0
exec 0<"$ARQFUNDOS"
while read -r line
do
	processLine $line
done
exec 0<&3

# restore $IFS which was used to determine what the field separators are
IFS=$BAKIFS
exit 0
