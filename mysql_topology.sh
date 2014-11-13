#!/bin/bash
#
#create select user
USER=kysd
PASSWORD=kysd_cn
MYSQLPATH=/usr/local/mysql/bin
get_slave(){
  $MYSQLPATH/mysql -h$1 -P$2 -u$USER -p$PASSWORD -e "show slave hosts\G;" 2>/dev/null|egrep "(Host|Port)"|awk -F: '{print $2}'|sed 's/^[[:space:]]*//g'|sed 'N;s/\n/:/'
}

get_master(){
  $MYSQLPATH/mysql -h$1 -P$2 -u$USER -p$PASSWORD -e "show slave status\G;" 2>/dev/null|egrep "(Master_Host|Master_Port)"|awk -F: '{print $2}'|sed 's/^[[:space:]]*//g'|sed 'N;s/\n/:/'
}

show(){
  cat <<EOF
Usage: $0 [OPTION]...
Example:
  $0 192.168.100.65:3307

EOF

}

menu(){
  printf "%-25s|%-5s|%-25s|%-30s\n" "Master" "Rel" "Slave" "Other"
}

if [[ $# -lt 1 ]];then
  show
elif [[ $# -eq 1 ]];then
  ip=$(echo $1|cut -d ":" -f 1)
  port=$(echo $1|cut -d ":" -f 2)
  slave=$(get_slave $ip $port)
  master=$(get_master $ip $port)
  #echo slave:$slave
  #echo master:$master
  if [[ -z $slave && ! -z $master ]];then
    menu
    printf "%-25s|\e[32m%-5s\e[0m|%-25s|%-30s\n" $master "<----" $1 ""
  elif [[ ! -z $slave && -z $master ]];then
    menu
    printf "%-25s|\e[32m%-5s\e[0m|%-25s|%-30s\n" $1 "<----" $slave ""
  elif [[ ! -z $slave && ! -z $master ]];then
    if [[ $slave == $master ]];then
      menu
      printf "%-25s|\e[32m%-5s\e[0m|%-25s|%-30s\n" $1 "<--->" $slave ""
    else
      echo topology
    fi
  else
    echo -e "\e[31m[$1]\e[0m not find any topology!"
  fi
else
  show
fi



