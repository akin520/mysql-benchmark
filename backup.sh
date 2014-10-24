#!/bin/bash
#
#-------------config---------------
MYDUMPER=/usr/local/bin/mydumper
INNOBACKUPEX=/usr/bin/innobackupex
BACKUPDIR=/backup
HOST=127.0.0.1
USER=root
PASSWD=google123
PORT=3306
WEEK=$(date +%U)
DAY=$(date +%w)
#-------------functions---------------
logic_backup(){
  mkdir -p $BACKUPDIR/$WEEK/$DAY
  $MYDUMPER -o  $BACKUPDIR/$WEEK/$DAY -D --snapshot-interval=30 -h $HOST -u $USER -p $PASSWD -P $PORT
}
phy_backup(){
  mkdir -p $BACKUPDIR/$WEEK/
  $INNOBACKUPEX --defaults-file=/etc/my.cnf --host=$HOST --no-timestamp --user=$USER --password=$PASSWD $BACKUPDIR/$WEEK/$1
}
phy_inc_backup(){
  mkdir -p $BACKUPDIR/$WEEK/
  $INNOBACKUPEX --defaults-file=/etc/my.cnf --host=$HOST --no-timestamp --user=$USER --password=$PASSWD --incremental --incremental-basedir=$BACKUPDIR/$WEEK/$1 $BACKUPDIR/$WEEK/$DAY
}
#-------------backup crontab---------------
if [[ $DAY == 0 ]];then
  logic_backup
elif [[ $DAY == 1 ]];then
  phy_backup $DAY
elif [[ $DAY == 2 ]];then
  if [[ ! -d $BACKUPDIR/$WEEK/1 ]];then
    phy_backup 1
  else
    phy_inc_backup 1
  fi
elif [[ $DAY == 3 ]]; then
  if [[ ! -d $BACKUPDIR/$WEEK/1 ]];then
    phy_backup 1
  else
    phy_inc_backup 1
  fi
elif [[ $DAY == 4 ]]; then
  phy_backup $DAY
elif [[ $DAY == 5 ]]; then
  if [[ ! -d $BACKUPDIR/$WEEK/4 ]];then
    phy_backup 4
  else
    phy_inc_backup 4
  fi
else
  if [[ ! -d $BACKUPDIR/$WEEK/4 ]];then
    phy_backup 4
  else
    phy_inc_backup 4
  fi
fi
#-------------rsync backup---------------
/usr/bin/rsync -az $BACKUPDIR/$WEEK 192.168.100.65::server1/

