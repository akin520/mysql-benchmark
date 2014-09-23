#!/bin/bash

hits(){
mysql -uroot -e "SHOW GLOBAL status like 'Innodb_buffer_pool_read_requests';SHOW GLOBAL status like 'Innodb_buffer_pool_reads'" |egrep "(Innodb_buffer_pool_read_requests|Innodb_buffer_pool_reads)"|awk '{print $2}'|sed 'N;s/\n/ /'|awk '{print $1"\t"$2"\t"(($1-$2)/$1)*100"%"}'
}

read -p "Mysql user[default:root]:" user
if [[ $user == "" ]];then
    user=root
fi
read -p "Mysql Password[default:google123]:" password
if [[ $password == "" ]];then
    password=google123
fi

read -p "Refresh times[default:5]:" refresh
if [[ $refresh == "" ]];then
    refresh=5
fi

cat >~/.my.cnf<<EOF
[client]
user=$root
password=$password
EOF

echo -e "requests\treads\thits"

while :
do
  hits
  sleep $refresh
done

