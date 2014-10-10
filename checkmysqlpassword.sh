#!/bin/bash
#check mysql password

MYSQL=/usr/local/mysql/bin/
USER=root
PASSWORD=google123
if [[ ! -s password.txt ]];then
  echo "not fine password.txt file"
  exit 0
fi

#dump mysql user
$MYSQL/mysql -u$USER -p$PASSWORD -e "select user from mysql.user where password != '';"|awk 'NR>1{print $0}' >/tmp/mysql-user

#make password
cat /tmp/mysql-user >/tmp/pass.txt
cat password.txt >>/tmp/pass.txt
cat password.txt|while read i
do 
  cat /tmp/mysql-user|while read j
    do
      echo $j$i >>/tmp/pass.txt
      echo $j.$i >>/tmp/pass.txt
      echo $j\_$i >>/tmp/pass.txt
    done
done

#create diff table
$MYSQL/mysql -u$USER -p$PASSWORD -e "CREATE TABLE IF NOT EXISTS test.pass(decrypt VARCHAR(50), encrypt VARCHAR(50)) ENGINE=innodb; truncate table test.pass ; load data infile '/tmp/pass.txt' into table test.pass(decrypt); UPDATE test.pass SET encrypt=password(decrypt);"

#not password user
clear
echo "Default value is null password:"
$MYSQL/mysql -u$USER -p$PASSWORD -e "select concat(host,'@',user) as user,password from mysql.user where password = '';"
echo ""
echo ""
echo "use weaker passwords:"
$MYSQL/mysql -u$USER -p$PASSWORD -e "select concat(host,'@',user) as user,password,decrypt from mysql.user as a,test.pass as b where a.password=b.encrypt;"

