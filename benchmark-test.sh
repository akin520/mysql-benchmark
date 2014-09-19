#!/bin/bash
SYSBENCHDIR=sysbench/sysbench/
TPCCDIR=tpcc-mysql/

cpu(){
echo -e  "\033[30;31mCPU benchmak\033[0m" 
read -p "Primer numbers limit[default:2000]:" primer
if [[ $primer == "" ]];then
    primer=2000
fi
echo "=============================CPU Test===================================="
$SYSBENCHDIR/sysbench --test=cpu --cpu-max-prime=2000 run
echo "========================================================================="
}

threads(){
echo -e  "\033[30;31mthreads benchmak\033[0m"
read -p "Number of threads[default:500]:" threads
if [[ $threads == "" ]];then
    threads=500
fi
read -p "Thread yields[default:1000]:" yields
if [[ $yields == "" ]];then
    yields=1000
fi
read -p "Thread locks[default:8]:" locks
if [[ $locks == "" ]];then
    locks=8
fi
echo "=============================Threads Test================================"
$SYSBENCHDIR/sysbench  --test=threads --num-threads=$threads --thread-yields=$yields --thread-locks=$locks run
echo "========================================================================="
}

io(){
echo -e  "\033[30;31mIO benchmak\033[0m"
read -p "Number of threads[default:10]:" threads
if [[ $threads == "" ]];then
    threads=10
fi
read -p "File total size[default:2G]:" size
if [[ $size == "" ]];then
    size=2G
fi
read -p "File test mod[default:rndrw]{seqwr|seqrewr|seqrd|rndrd|rndwr|rndrw}:" mode
if [[ $mode == "" ]];then
    mode=rndrw
fi
echo "=============================IO Test================================"
echo "Create file wait......"
$SYSBENCHDIR/sysbench --test=fileio --num-threads=$threads --file-total-size=$size --file-test-mode=$mode prepare >/dev/null 2>&1
$SYSBENCHDIR/sysbench --test=fileio --num-threads=$threads --file-total-size=$size --file-test-mode=$mode run
$SYSBENCHDIR/sysbench --test=fileio --num-threads=$threads --file-total-size=$size --file-test-mode=$mode cleanup 
echo "========================================================================="
}

memory(){
echo -e  "\033[30;31mMemory benchmak\033[0m"
read -p "Memory block size[default:8k]:" block
if [[ $block == "" ]];then
    block=8k
fi
read -p "Memory total size[default:1G]:" size
if [[ $size == "" ]];then
    size=1G
fi
echo "=============================Memory Test================================"
$SYSBENCHDIR/sysbench --test=memory --memory-block-size=$block --memory-total-size=$size run
echo "========================================================================="

}

oltp(){
echo -e  "\033[30;31mOLTP benchmak\033[0m"
read -p "Mysql host[default:localhost]:" local
if [[ $local == "" ]];then
    local=localhost
fi
read -p "Mysql user[default:root]:" user
if [[ $user == "" ]];then
    user=root
fi
read -p "Mysql Password[default:google123]:" password
if [[ $password == "" ]];then
    password=google123
fi
read -p "Mysql Port[default:3306]:" port
if [[ $port == "" ]];then
    port=3306
fi
read -p "Mysql engine[default:innodb]:" engine
if [[ $size == "" ]];then
    engine=innodb
fi
read -p "OLTP table size[default:100]:" size
if [[ $size == "" ]];then
    size=100
fi
read -p "OLTP table count[default:32]:" count
if [[ $count == "" ]];then
    count=32
fi
read -p "OLTP table threads[default:20]:" threads
if [[ $threads == "" ]];then
    threads=20
fi

echo "=============================OLTP Test================================"
echo "Create DATABASE wait......"
mysqladmin -h $local -u$user -p$password drop sbtest
mysqladmin -h $local -u$user -p$password create sbtest
$SYSBENCHDIR/sysbench --test=$SYSBENCHDIR/tests/db/parallel_prepare.lua --max-time=100 --oltp-dist-type=uniform --max-requests=0 --mysql-user=$user --mysql-password=$password --mysql-table-engine=$engine --oltp-table-size=$size --oltp-tables-count=$count --oltp-range-size=90 --oltp-point-selects=1 --oltp-simple-ranges=1 --oltp-sum-ranges=1 --oltp-order-ranges=1 --oltp-distinct-ranges=1 --oltp-non-index-updates=10 --num-threads=$threads --mysql-host=$local --mysql-port=$port prepare  >/dev/null 2>&1

$SYSBENCHDIR/sysbench --test=$SYSBENCHDIR/tests/db/oltp.lua --max-time=100 --oltp-dist-type=uniform --max-requests=0 --mysql-user=$user --mysql-password=$password --mysql-table-engine=$engine --oltp-table-size=$size --oltp-tables-count=$count --oltp-range-size=90 --oltp-point-selects=1 --oltp-simple-ranges=1 --oltp-sum-ranges=1 --oltp-order-ranges=1 --oltp-distinct-ranges=1 --oltp-non-index-updates=10 --num-threads=$threads --mysql-host=$local --mysql-port=$port run


echo "========================================================================="

}

tpcc-mysql(){
echo -e  "\033[30;31mTPCC-MySQL benchmak\033[0m"
read -p "Mysql host[default:localhost]:" local
if [[ $local == "" ]];then
    local=localhost
fi
read -p "Mysql user[default:root]:" user
if [[ $user == "" ]];then
    user=root
fi
read -p "Mysql Password[default:google123]:" password
if [[ $password == "" ]];then
    password=google123
fi
read -p "Mysql Port[default:3306]:" port
if [[ $port == "" ]];then
    port=3306
fi
read -p "Warehouse number[default:1]:" warehouse
if [[ $warehouse == "" ]];then
    warehouse=1
fi
read -p "Connections number[default:20]:" connections
if [[ $connections == "" ]];then
    connections=20
fi
read -p "running times[default:50]:" running_time
if [[ $running_time == "" ]];then
    running_time=50
fi

echo "=============================TPCC-MySQL Test================================"
echo "Create DATABASE wait......"
mysqladmin -h $local -u$user -p$password drop tpcc
mysqladmin -h $local -u$user -p$password create tpcc
mysql -h $local -u$user -p$password tpcc < $TPCCDIR/create_table.sql
mysql -h $local -u$user -p$password tpcc < $TPCCDIR/add_fkey_idx.sql

$TPCCDIR/tpcc_load $local tpcc $user $password $warehouse >/dev/null 2>&1
$TPCCDIR/tpcc_start -h $local -d tpcc -u $user -p $password -P $port -w $warehouse -c $connections -r 1 -l $running_time

echo "========================================================================="

}


a=$#
if [[ $a -eq 0 ]]; then
clear
cat << "EOF"

This script is mysql benchmark v0.0.1:

#benchmark-test.sh [opt]
  cpu		cpu benchmark
  threads 	threads benchmark
  io 		io benchmark
  memory	memory benchmark
  oltp		mysql oltp benchmark

examples:
#benchmark-test.sh cpu threads io memory oltp


Press Ctrl-C now if you want to exit

EOF
else
  $1
  $2
  $3
  $4
  $5
fi

