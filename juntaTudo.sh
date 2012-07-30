#!/bin/bash

BASE="/Users/dclobato/Documents/Bancos/Cotacoes/Snapshots"
DIRETORIO="$BASE/Historico"
COTACOES=`find $BASE -type d -print | sed -e "1d"`
TMPFILE="$DIRETORIO/temp.hist"

ELINKS=`which elinks`
ELINKSPAR='-dump 1 -dump-width 500'
SED=`which sed`
WGET=`which wget`
AWK=`which awk`
TR=`which tr`
CUT=`which cut`
SORT=`which sort`
READ=`which read`

#### Remove linhas em branco
BASEPARSER="$AWK '/./' | $SED -e 's/^ *//'"

#### Organizacao final
ENDPARSER="$SORT -n | uniq -"

processLine(){
  line="$@" # get all args

  TIPO=$(echo $line | awk '{ print $1 }')
  SAIDA=$(echo $line | awk '{ print $2 }')
  BANCO=$(echo $line | awk '{ print $3 }')
  CODFU=$(echo $line | awk '{ print $4 }')

  for x in $COTACOES ; {
    if [ -f $x/$SAIDA.mdSnapshots ] ; then
      cat $x/$SAIDA.mdSnapshots >> $TMPFILE
    fi 
  }
  
  cat $TMPFILE | eval "$BASEPARSER | $ENDPARSER > $DIRETORIO/$SAIDA.hist"
  rm $TMPFILE
}

CRIA=1
if [ -d $DIRETORIO ]; then
 echo ""
 echo "Historico ja existe."
 read -p "Vamos atualizar? (s/n)" RESP
 if [ "$RESP" = n ] ; then
  echo "Para obte-lo novamente, apague o diretorio $DIRETORIO"
  echo ""
  exit 1
 fi
 CRIA=0
fi

if [ "$CRIA" = "1" ] ; then
 echo "Criando diretorio para as cotacoes historicas."
 mkdir $DIRETORIO
 echo "Feito!"
fi

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

echo "Feito!"
echo ""
exit 0
