#!/bin/bash -eux

Ploter(){
    OUTNAME=${1} # ${1%.*}.png

    COMM+="set term png size $2, $3;"
    COMM+="set output '${OUTNAME}';"
    COMM+="set xrange [1:];"
    COMM+="set yrange [0.1:];"
    COMM+="set xlabel '$4';"
    COMM+="set ylabel '$5';"

    COMM+="set font 'Meiryo';"
    COMM+=${6:-""}
    COMM+=${7:-""}
    COMM+=${8:-""}

# 以下を実行しないと，次のエラーがでる．
# gnuplot: error while loading shared libraries: libimf.so: cannot open shared object file: No such file or directory
    set +xe
    module load intel/2018.1
    set -xe
    gnuplot -e "$COMM"
}


# デフォルト変数値の設定
#---------------------------------------------------
# 入力ファイルとタイトル以外の設定は，環境変数の形で渡す．
# 先頭にCALCULATE="something" genplot.sh 引数　のような形で指定する．
# 指定がなかった場合は次で定義される値になる．
: ${Xs:=1200}
: ${Ys:=600};
: ${OUTPUT:="result"}
: ${CALCULATE:="\$1/2**20/\$2"}
: ${XLABEL:="x"}
: ${YLABEL:="y"}
: ${OPT:=""}
: ${PLOTOPT:=""}
: ${REPLOT:=""}
#---------------------------------------------------

# 引数は <datafile.txt タイトル> の組で渡す．
# 必然的に偶数である．奇数の場合は異常終了させる．
# 空白を含む変数を引数として渡す際に"${arg}"としないとエラーになる．
(( $# & 1 )) && echo "the number of arg must be even" && exit 1


# 各データのplot構文を作る．
# 引数: データファイル名 データ値 タイトル オプション
GenPlotSyntax(){
    #[ $# -ne 4 ] && echo "$0 called but its args is invalid" && exit 1;
    SYNTAX="'$1' using 1:($2) w lp title '$3' ${4:-""}"
    echo $SYNTAX
}

# 関数GenPlotSyntaxを用いて，gnuplotにおけるplot ~文を作成する．
PLOTSYNTAX=""
for ((i=1; i<=$#; i+=2)); do
    if [ $i -eq 1 ]; then
        PLOTSYNTAX+="plot "
    else
        PLOTSYNTAX+=", "
    fi
    PLOTSYNTAX+=`GenPlotSyntax ${@:$i:1} $CALCULATE ${@:($i+1):1} "${PLOTOPT}"`
done

# 引数を与えてgnuplotを呼び出す．
Ploter "$OUTPUT" $Xs $Ys "$XLABEL" "$YLABEL" "$OPT" "$PLOTSYNTAX" "$REPLOT" 
