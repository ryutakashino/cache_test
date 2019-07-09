#!/bin/sh
FLAG=${1:-run} # 引数なし or run で実行する．それ以外の引数を与えると，グラフの生成のみを行う．

MAX=25;
pwdir="$(command dirname -- "${0}")"
tmp="tmp" #一時ファイル
main="time" #実行時間を記録するファイル名
declare -a events=(L1-dcache-stores LLC-store-misses LLC-stores dTLB-store-misses dTLB-stores node-store-misses node-stores mem-stores) #perf listで見つけたstoreが関係するイベント群

# 実行関数
execute () {
    x_value=$1          # 第一引数はx軸の値
    event_list=${@:2}   # 第二引数以降はイベント名 
    script="srun -p comq -N 1 -w ppx00 -- perf stat -o $tmp "
    for e in ${event_list[@]};do 
        script+="-e $e "
    done 
    script+="$pwdir/cache $x_value"
    eval $script >> ${main%.*}.dat
}

# perfで得られた値をgrepにより抽出するための関数
grep_events () {
    x_value=$1          # 第一引数はx軸の値
    event_list=${@:2}   # 第二引数以降はイベント名 
    for e in ${event_list[@]};do 
        value=`cat $tmp | grep $e | awk '{print $1}' | sed -e 's/,//'`
        echo $x_value $value >> ${e%.*}.dat
    done 
}

execute_wrapper() {
# 初期化
    : > ${main%.*}.dat
    for e in ${events[@]}; do
        : > ${e%.*}.dat
    done

    for ((i=0; i<$MAX; i+=1)); do
        execute $((1 << i)) ${events[@]}
        grep_events $((1 << i)) ${events[@]}
        echo $((1 << i)) "= 2 << " $i
    done
}


# 外部ファイルgenplot.shを用いて，グラフを生成する．
# genplot.shは引数を整えてgnuplotを呼び出すだけのプログラム
generate_graph () {
    list=$@

# stat構文でファイル中の最大値を求めている．最大値は変数STAT_maxに格納される．
# L1,L2,LLCの位置に黒の補助線を挿入している．
    for e in ${list[@]}; do
        CALCULATE="\$2" \
        OUTPUT="${e}.eps" \
        OPT="set terminal postscript enhanced color font 'Arial,20';
        set format y '%2.2t{/Symbol \264}10^{%T}';
        set format x '%2.0t{/Symbol \264}10^{%T}';
        stats '${e%.*}.dat' using 2;
        CMIN=1e-1;
        CMAX=STATS_max*1.0;
        C=32; set arrow 1 from C,CMIN to C,CMAX nohead;
        C=256;set arrow 2 from C,CMIN to C,CMAX nohead;
        C=35840; set arrow 3 from C,CMIN to C,CMAX nohead;
        set logscale y;
        set logscale x; " \
        XLABEL="Datasize[KB]" \
        YLABEL="${e}" \
        ./genplot.sh \
        ${e%.*}.dat ${e}
    done
}

# Main処理
gcc -O3 -o cache $pwdir/cache.c -lrt
[ $FLAG == "run" ]  && execute_wrapper
set -x
generate_graph $main ${events[@]}

