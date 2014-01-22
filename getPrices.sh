#!/bin/bash

FIM="`date +"%d/%m/%Y"`"
HOJE="`date "+%Y%m%d"`"
INICIO="`date -v-3m +"%d/%m/%Y"`"
BASE="/Users/dclobato/Documents/Bancos/Cotacoes/Snapshots/"
DIRETORIO="$BASE$HOJE/"

ELINKS=`which elinks`
ELINKSPAR='-dump 1 -dump-width 500'
SED=`which sed`
WGET=`which wget`
AWK=`which awk`
TR=`which tr`
CUT=`which cut`
SORT=`which sort`
READ=`which read`
XLS2CSV=`which xls2csv`
TAIL=`which tail`
WC=`which wc`

WGETOPT="--no-check-certificate -q --user-agent=\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/537.13+ (KHTML, like Gecko) Version/5.1.7 Safari/534.57.2\""

## BBURL="http://www21.bb.com.br/portalbb/cotaFundos/GFI9,2,null,null,006.bbx?tipo=5\&fundo="
BBURL="http://www37.bb.com.br/portalbb/cotaFundos/GFI9,2,001.bbx?tipo=5\&fundo="
GFURL="https://online.gerafuturo.com.br/onlineGeracao/PortalManager?show=produtos.resultado_historico_cotas\&busca=s\&dataInicio=$INICIO\&dataFim=$FIM\&id_fundo_clube="
#BCURL="http://www4.bcb.gov.br/pec/taxas/port/PtaxRPesq.asp"
BCURL="https://www3.bcb.gov.br/ptax_internet/consultaBoletim.do?method=gerarCSVFechamentoMoedaNoPeriodo&ChkMoeda="
BVURL="http://www.infomoney.com.br/Pages/Download/Download.aspx?dtIni=null\&dtFinish=null\&Semana=null\&Per=3\&type=1\&StockType=1\&Stock="
BVURL2="\&Ativo="
TDURL="https://www.tesouro.fazenda.gov.br/images/arquivos/artigos/"

#### Remove linhas em branco
BASEPARSER="$AWK '/./' | $SED -e 's/^ *//'"

#### Organizacao final
ENDPARSER="$SORT -rn"

#### Parsers para cada um dos bancos
BBPARSE="$SED '1,3d' | $SED -e :a -e '\$d;N;2,3ba' -e 'P;D' | $TR -s ' ' ';' | $TR -s '.' '/' | $TR -s ',' '.' | $AWK -F '[/|;]' '{ printf \"%s%s%s %s\n\", \$3, \$2, \$1, \$4 ; }'"
GFPARSE="$TR -s ' ' ';' | $TR -s ',' '.' | $AWK -F '[/|;]' '{ printf \"%s%s%s %s\n\", \$3, \$2, \$1, \$4 ; }'"
BCPARSE="$CUT -s -f 1,6 -d ';' | $AWK -F ';' '{ printf \"%s %f\\n\", \$1, \$2 ; }' | $TR ',' '.' | $AWK -F '\\0' '{ print substr(\$0, 5, 4) substr(\$0, 3, 2) substr(\$0, 1, 2), substr(\$0, 10)}'"
BVPARSE="$SED -E -e 's/^ *//;1d;s/ +/ /g;s/\.//g' | $CUT -s -f 1,2,6,8,9 -d ' ' | $TR -s ' ' ';' | $TR -s ',' '.' | $AWK -F '[/|;]' '{ printf \"%s%s%s %s %s %s %s\\n\", \$3, \$2, \$1, \$4, \$5, \$6, \$7}'"
TDPARSE="$SED '1,2d' | $CUT -f 1,5 -d ';' | $SED -E -e 's/,//g' | awk -F '[/|;]' '{printf \"%s%s%s %s\\n\", \$3, \$2, \$1, \$4}'"

processLine(){
  line="$@" # get all args

  TIPO=$(echo $line | awk '{ print $1 }')    # Tipo de ativo
  SAIDA=$(echo $line | awk '{ print $2 }')   # Nome arquivo de saida (= Security ID/Ticker Symbol)
  BANCO=$(echo $line | awk '{ print $3 }')   # Fonte dos dados
  CODFU=$(echo $line | awk '{ print $4 }')   # Codigo do ativo
  FILTD=$(echo $line | awk '{ print $5 }')   # Nome do arquivo cotacoes (apenas para TIPO="TD")
  VENTD=$(echo $line | awk '{ print $6 }')   # Vencimento do titulo publico (apenas para TIPO="TD")
  PRETD=$(echo $line | awk '{ print $7 }')    # Prefixo na planilha (apenas para TIPO="TD")
  

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
     #https://www3.bcb.gov.br/ptax_internet/consultaBoletim.do?method=gerarCSVFechamentoMoedaNoPeriodo&ChkMoeda=222&DATAINI=19/11/2013&DATAFIM=21/12/2013
     MOEDA=$(echo $line | awk '{ print $5 }')
     INICIOBC=`echo $INICIO | $SED 's/\//\%2F/g'`
     FIMBC=`echo $FIM | $SED 's/\//\%2F/g'`
     BCPAR="$CODFU&DATAINI=$INICIO&DATAFIM=$FIM"
     echo "$BCURL$BCPAR"
     $WGET -q "$BCURL$BCPAR" -O $tmpFile1
     #eval "$ELINKS $ELINKSPAR $tmpFile1 > $tmpFile2"
     #TOGET=`cat $tmpFile2 | grep "download/cotacoes/BC" | cut -f 3 -d " " | uniq`
     #$WGET $TOGET -q -O $tmpFile2
     cat $tmpFile1 | eval "$BASEPARSER | $BCPARSE" > $tmpFile2
     eval "$ENDPARSER < $tmpFile2 >$finalFile"
  fi
  if [ "$BANCO" == "BV" ]; then
     eval "$ELINKS $ELINKSPAR $BVURL$CODFU$BVURL2$CODFU > $tmpFile1"
     cat $tmpFile1 | eval "$BASEPARSER | $BVPARSE > $tmpFile2"
     eval "$ENDPARSER < $tmpFile2 >$finalFile"
  fi
  if [ "$BANCO" == "TD" ]; then
     eval "$WGET $WGETOPT $TDURL$FILTD.xls"
     if [ "$PRETD" = "NTN-B-P" ]; then
        PRETD="NTN-B Principal"
     fi
     eval "$XLS2CSV -q -x $FILTD.xls -w \"$PRETD $VENTD\" -c $tmpFile1"
     cat $tmpFile1 | eval "$BASEPARSER | $TDPARSE | $TAIL -n 120 > $tmpFile2"
     eval "$ENDPARSER < $tmpFile2 >$finalFile"
     rm $FILTD.xls
  fi

  echo -n "  Total de cotacoes >>> "
  echo "`$WC -l $finalFile`"
  echo -n "  Cotacao mais atual >> "
  echo "`head -n 1 $finalFile`"
  echo ""
  #rm $tmpFile2 $tmpFile1
}

CRIA=1
if [ -d $DIRETORIO ]; then
 echo ""
 echo "Cotacoes para hoje ja foram obtidas."
 read -p "Vamos obter novamente? (s/n)" RESP
 if [ "$RESP" = n ] ; then
  echo "Para obte-las novamente, apague o diretorio $DIRETORIO"
  echo ""
  exit 1
 fi
 CRIA=0
fi

if [ "$CRIA" = "1" ] ; then
 echo "Criando diretorio para as cotacoes atuais."
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

if [ -h $BASE/ultimo ]; then
 echo "Atualizando o link para o diretorio com as cotacoes atuais..."
 rm $BASE/ultimo
else
 echo "Criando o link para o diretorio com as cotacoes atuais..."
fi
ln -s $DIRETORIO $BASE/ultimo
echo "Feito!"
echo ""
exit 0
