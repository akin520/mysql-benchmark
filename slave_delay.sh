#!/bin/bash
#
#
MYSQLPATH=/usr/local/mysql/bin

get_master(){
  $MYSQLPATH/mysql -h$1 -P$2 -u$3 -p$4 -e "show slave status\G;" 2>/dev/null|egrep "(Master_Host|Master_Port)"|awk -F: '{print $2}'|sed 's/^[[:space:]]*//g'|sed 'N;s/\n/:/'
}

get_status(){
  $MYSQLPATH/mysql -h$1 -P$2 -u$3 -p$4 -e "show slave status\G;" 2>/dev/null|egrep "(Slave_IO_Running:|Slave_SQL_Running:)"|awk -F: '{print $2}'|sed 's/^[[:space:]]*//g'|sed 'N;s/\n//'
}

run_master(){
  $MYSQLPATH/mysql -h$1 -P$2 -u$3 -p$4 -e "CREATE TABLE IF NOT EXISTS test.heartbeat ( id int NOT NULL PRIMARY KEY, ts datetime NOT NULL );" 2>/dev/null
  pt-heartbeat -D test --update -h$1 -P $2 -u$3 -p$4 --daemonize
}

run_check(){
  pt-heartbeat -D test --check -h$1 -u$3 -p$4 -P $2
}

clear(){
  kill $(ps -ef|grep pt-heartbea[t]|awk '{print $2}') 2>/dev/null
}

check_toolkit(){
  rpm -qa|grep percona-toolkit 2>1 >/dev/null
  if [[ $? != 0 ]]; then
    echo "Please download percona-toolkit,web:http://www.percona.com/doc/percona-toolkit/2.1/index.html"
    exit 0
  fi
}

show(){
  cat <<EOF
Usage: $0 [OPTION]...
Example:
  $0 192.168.100.65:3307

EOF

}

if [[ $# -lt 1 ]];then
  show
elif [[ $# -eq 1 ]];then
  check_toolkit
  clear
  ip=$(echo $1|cut -d ":" -f 1)
  port=$(echo $1|cut -d ":" -f 2)
  read -p "Enter User:" user
  read -p "Enter Password:" passwd
  master=$(get_master $ip $port $user $passwd)
  if [[ ! -z $master ]];then
    mip=$(echo $master|cut -d ":" -f 1)
    mport=$(echo $master|cut -d ":" -f 2)
    run_master $mip $mport $user $passwd
    echo $?
    printf "%-25s|%-5s|%-25s|\n" "Master" "Times" "Slave"
    while :
    do
      status=$(get_status $ip $port $user $passwd)
      if [[ $status == "YesYes" ]];then
        times=$(run_check $ip $port $user $passwd)
        printf "%-25s|\e[32m%-5s\e[0m|%-25s|\n" $master $times $1
      else
         echo -e "\e[31m[$1]\e[0m Slave is \e[31mSTOP\e[0m!"
      fi
      sleep 1
    done
  else
    echo -e "\e[31m[$1]\e[0m not is Slave!"
  fi
else
  show
fi

