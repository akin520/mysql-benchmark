#!/bin/bash
#
#
USER=kysd
PASSWD=kysd_cn

mysqlconn(){
   mysqladmin -h $1 -P$2 -u$USER -p$PASSWD variables|awk -F'|' 'NR>3{print $2,$3}'|awk '{print $1"\t"$2}' >/tmp/$3.log
}

difffile(){
echo >/tmp/var.log
cat /tmp/1.log |while read i j
do
  cat /tmp/2.log|while read h k
    do
      if [[ $i == $h ]];then
         TMP=$(printf "|%-35s|%40s|%40s|" "$i" "$j" "$k")
         echo "$TMP" >>/tmp/var.log
      fi
    done
done
}

show(){
  cat <<EOF
  Usage: $0 [OPTION]...
  Example:
    $0 192.168.100.65:3306 192.168.100.65:3307
    or
    $0 192.168.100.65:3306 192.168.100.65:3307 version
EOF
}

if [[ $# -lt 2 ]];then
  show
elif [[ $# -eq 2 ]];then
  ip=$(echo $1|cut -d ":" -f 1)
  port=$(echo $1|cut -d ":" -f 2)
  nip=$(echo $2|cut -d ":" -f 1)
  nport=$(echo $2|cut -d ":" -f 2)
  mysqlconn $ip $port 1
  mysqlconn $nip $nport 2
  difffile
  printf "|%-35s|%40s|%40s|" "Variable_name" "$ip" "$nip"
  cat /tmp/var.log
elif [[ $# -eq 3 ]];then
  ip=$(echo $1|cut -d ":" -f 1)
  port=$(echo $1|cut -d ":" -f 2)
  nip=$(echo $2|cut -d ":" -f 1)
  nport=$(echo $2|cut -d ":" -f 2)
  mysqlconn $ip $port 1
  mysqlconn $nip $nport 2
  difffile
  printf "|%-35s|%40s|%40s|\n" "Variable_name" "$ip" "$nip"
  grep "$3" /tmp/var.log
else
  show
fi

