#!/bin/bash

# build_db.sh

TOPDIR="/root/src/dbt2-0.40"
source ${TOPDIR}/scripts/dbt2_profile || exit 1

usage() {

  if [ "$1" != "" ]; then
    echo ''
    echo "error: $1"
  fi

  echo ''
  echo 'usage: build_db.sh [options]'
  echo 'options:'
  echo '       -d <database name>'
  echo '       -f <path to dataset files>'
  echo '       -g (generate data files)'
  echo '       -m <database scheme [OPTIMIZED|ORIG] (default OPTIMIZED)>'
  echo '       -s <database socket>'
  echo '       -h <database host>'
  echo '       -u <database user>'
  echo '       -p <database password>'
  echo '       -e <storage engine: [MYISAM|INNODB|BDB]. (default INNODB)>'
  echo '       -l <to use LOCAL keyword while loading dataset>'
  echo '       -v <verbose>'  
  echo '       -w <scale factor>'  
  echo ''
  echo 'Example: bash build_db.sh -d dbt2 -f /tmp/dbt2-w3 -s /tmp/mysql.sock'
  echo ''
}

command_exec()
{
  if [ -n "$VERBOSE" ]; then
    echo "Executed command: $1"
  fi

  eval "$1"

  rc=$?
  if [ $rc -ne 0 ]; then
   echo "ERROR: rc=$rc"
   case $rc in
     127) echo "COMMAND NOT FOUND"
	  ;;
       *) echo "SCRIPT INTERRUPTED"
	  ;;
    esac
    exit 255
  fi
}

load_tables()
{

TABLES="customer district history item new_order order_line orders stock warehouse"

for TABLE in $TABLES ; do

  echo "Loading table $TABLE"

  if [ "$TABLE" == "orders" ]; then
    FN="order"
  else
    FN="$TABLE"
  fi

  command_exec "$MYSQL $DB_NAME -e \"LOAD DATA $LOCAL INFILE \\\"$DB_PATH/$FN.data\\\" \
		INTO TABLE $TABLE FIELDS TERMINATED BY '\t'\""

done

}


create_tables()
{

if [ "$DB_SCHEME" == "OPTIMIZED" ]; then

CUSTOMER="CREATE TABLE customer (
  c_id int(11) NOT NULL default '0',
  c_d_id int(11) NOT NULL default '0',
  c_w_id int(11) NOT NULL default '0',
  c_first varchar(16) default NULL,
  c_middle char(2) default NULL,
  c_last varchar(16) default NULL,
  c_street_1 varchar(20) default NULL,
  c_street_2 varchar(20) default NULL,
  c_city varchar(20) default NULL,
  c_state char(2) default NULL,
  c_zip varchar(9) default NULL,
  c_phone varchar(16) default NULL,
  c_since timestamp NOT NULL,
  c_credit char(2) default NULL,
  c_credit_lim decimal(24,12) default NULL,
  c_discount double default NULL,
  c_balance decimal(24,12) default NULL,
  c_ytd_payment decimal(24,12) default NULL,
  c_payment_cnt double default NULL,
  c_delivery_cnt double default NULL,
  c_data text,
  PRIMARY KEY  (c_w_id,c_d_id,c_id),
  KEY c_w_id (c_w_id,c_d_id,c_last,c_first)
)"

DISTRICT="CREATE TABLE district (
  d_id int(11) NOT NULL default '0',
  d_w_id int(11) NOT NULL default '0',
  d_name varchar(10) default NULL,
  d_street_1 varchar(20) default NULL,
  d_street_2 varchar(20) default NULL,
  d_city varchar(20) default NULL,
  d_state char(2) default NULL,
  d_zip varchar(9) default NULL,
  d_tax double default NULL,
  d_ytd decimal(24,12) default NULL,
  d_next_o_id int(11) default NULL,
  PRIMARY KEY  (d_w_id,d_id)
)"

HISTORY="CREATE TABLE history (
  h_c_id int(11) default NULL,
  h_c_d_id int(11) default NULL,
  h_c_w_id int(11) default NULL,
  h_d_id int(11) default NULL,
  h_w_id int(11) default NULL,
  h_date timestamp NOT NULL,
  h_amount double default NULL,
  h_data varchar(24) default NULL
)"


ITEM="CREATE TABLE item (
  i_id int(11) NOT NULL default '0',
  i_im_id int(11) default NULL,
  i_name varchar(24) default NULL,
  i_price double default NULL,
  i_data varchar(50) default NULL,
  PRIMARY KEY  (i_id)
)"


NEW_ORDER="CREATE TABLE new_order (
  no_o_id int(11) NOT NULL default '0',
  no_d_id int(11) NOT NULL default '0',
  no_w_id int(11) NOT NULL default '0',
  PRIMARY KEY  (no_d_id,no_w_id,no_o_id)
)"

ORDER_LINE="CREATE TABLE order_line (
  ol_o_id int(11) NOT NULL default '0',
  ol_d_id int(11) NOT NULL default '0',
  ol_w_id int(11) NOT NULL default '0',
  ol_number int(11) NOT NULL default '0',
  ol_i_id int(11) default NULL,
  ol_supply_w_id int(11) default NULL,
  ol_delivery_d timestamp NOT NULL,
  ol_quantity double default NULL,
  ol_amount double default NULL,
  ol_dist_info varchar(24) default NULL,
  PRIMARY KEY  (ol_w_id,ol_d_id,ol_o_id,ol_number)
)"

ORDERS="CREATE TABLE orders (
  o_id int(11) NOT NULL default '0',
  o_d_id int(11) NOT NULL default '0',
  o_w_id int(11) NOT NULL default '0',
  o_c_id int(11) default NULL,
  o_entry_d timestamp NOT NULL,
  o_carrier_id int(11) default NULL,
  o_ol_cnt int(11) default NULL,
  o_all_local double default NULL,
  PRIMARY KEY  (o_w_id,o_d_id,o_id),
  KEY o_w_id (o_w_id,o_d_id,o_c_id,o_id)
)"


STOCK="CREATE TABLE stock (
  s_i_id int(11) NOT NULL default '0',
  s_w_id int(11) NOT NULL default '0',
  s_quantity double NOT NULL default '0',
  s_dist_01 varchar(24) default NULL,
  s_dist_02 varchar(24) default NULL,
  s_dist_03 varchar(24) default NULL,
  s_dist_04 varchar(24) default NULL,
  s_dist_05 varchar(24) default NULL,
  s_dist_06 varchar(24) default NULL,
  s_dist_07 varchar(24) default NULL,
  s_dist_08 varchar(24) default NULL,
  s_dist_09 varchar(24) default NULL,
  s_dist_10 varchar(24) default NULL,
  s_ytd decimal(16,8) default NULL,
  s_order_cnt double default NULL,
  s_remote_cnt double default NULL,
  s_data varchar(50) default NULL,
  PRIMARY KEY  (s_w_id,s_i_id)
)"

WAREHOUSE="CREATE TABLE warehouse (
  w_id int(11) NOT NULL default '0',
  w_name varchar(10) default NULL,
  w_street_1 varchar(20) default NULL,
  w_street_2 varchar(20) default NULL,
  w_city varchar(20) default NULL,
  w_state char(2) default NULL,
  w_zip varchar(9) default NULL,
  w_tax double default NULL,
  w_ytd decimal(24,12) default NULL,
  PRIMARY KEY  (w_id)
)"

else

WAREHOUSE="create table warehouse ( w_id int not null, 
  w_name varchar(10), 
  w_street_1 varchar(20), 
  w_street_2 varchar(20), 
  w_city varchar(20), 
  w_state char(2), 
  w_zip char(9), 
  w_tax real, 
  w_ytd numeric(24, 12), 
  constraint pk_warehouse primary key (w_id) 
)"


DISTRICT="create table district ( d_id int not null,
  d_w_id int not null,
  d_name varchar(10),
  d_street_1 varchar(20),
  d_street_2 varchar(20),
  d_city varchar(20),
  d_state char(2),
  d_zip char(9),
  d_tax real,
  d_ytd numeric(24, 12),
  d_next_o_id int,
  constraint pk_district primary key (d_w_id, d_id)
)"

CUSTOMER="create table customer ( c_id int not null, 
  c_d_id int not null, 
  c_w_id int not null, 
  c_first varchar(16), 
  c_middle char(2), 
  c_last varchar(16),   
  c_street_1 varchar(20),	       
  c_street_2 varchar(20), 
  c_city varchar(20), 
  c_state char(2),  
  c_zip char(9), 
  c_phone char(16), 
  c_since timestamp, 
  c_credit char(2), 
  c_credit_lim numeric(24, 12), 
  c_discount real, 
  c_balance numeric(24, 12), 
  c_ytd_payment numeric(24, 12), 
  c_payment_cnt real, 
  c_delivery_cnt real, 
  c_data text, 
  constraint pk_customer primary key (c_w_id, c_d_id, c_id)
)"

HISTORY="create table history ( h_c_id int, 
  h_c_d_id int, 
  h_c_w_id int, 
  h_d_id int, 
  h_w_id int, 
  h_date timestamp, 
  h_amount real, 
  h_data varchar(24)
)"

NEW_ORDER="create table new_order ( no_o_id int not null, 
  no_d_id int not null, 
  no_w_id int not null, 
  constraint pk_new_order primary key (no_o_id, no_d_id, no_w_id) 
)"

ORDERS="create table orders ( o_id int not null, 
  o_d_id int not null, 
  o_w_id int not null, 
  o_c_id int,
  o_entry_d timestamp,
  o_carrier_id int,
  o_ol_cnt int,
  o_all_local real,
  constraint pk_orders primary key (o_w_id, o_d_id, o_id)
)"

ORDER_LINE="create table order_line ( ol_o_id int not null,
  ol_d_id int not null,
  ol_w_id int not null,
  ol_number int not null,
  ol_i_id int,
  ol_supply_w_id int,
  ol_delivery_d timestamp,
  ol_quantity real,
  ol_amount real, 
  ol_dist_info varchar(24),
  constraint pk_order_line primary key (ol_w_id, ol_d_id, ol_o_id, ol_number)
)"

ITEM="create table item ( i_id int not null,
  i_im_id int,
  i_name varchar(24), 
  i_price real, 
  i_data varchar(50), 
  constraint pk_item primary key (i_id) 
)"

STOCK="create table stock ( s_i_id int not null, 
  s_w_id int not null, 
  s_quantity real, 
  s_dist_01 varchar(24), 
  s_dist_02 varchar(24), 
  s_dist_03 varchar(24), 
  s_dist_04 varchar(24), 
  s_dist_05 varchar(24), 
  s_dist_06 varchar(24), 
  s_dist_07 varchar(24), 
  s_dist_08 varchar(24), 
  s_dist_09 varchar(24), 
  s_dist_10 varchar(24), 
  s_ytd numeric(16, 8), 
  s_order_cnt real, 
  s_remote_cnt real, 
  s_data varchar(50), 
  constraint pk_stock primary key (s_w_id, s_i_id, s_quantity) 
)"
fi

TABLES="STOCK ITEM ORDER_LINE ORDERS NEW_ORDER HISTORY CUSTOMER DISTRICT WAREHOUSE"

for TABLE in $TABLES ; do

  echo "Creating table $TABLE"
  command_exec "$MYSQL $DB_NAME -e \"\$$TABLE ENGINE=$DB_ENGINE\""

done

}

#DEFAULTs

DIR=`dirname ${0}`

LOCAL=""
VERBOSE=""
DB_PASSWORD=""
DB_PATH=""
DB_NAME=""

MYSQL="/usr/local/mysql/bin/mysql"
DB_HOST="localhost"
DB_NAME=${DBNAME}
DB_PATH=${DBDATA}
DB_SOCKET="/tmp/mysql.sock"
DB_USER=${DBUSER}
DB_ENGINE="INNODB"
DB_SCHEME="OPTIMIZED"
GENERATE_DATAFILE=0
WAREHOUSES=1

while getopts "d:h:f:gs:e:m:u:p:vw:" opt; do
	case $opt in
	d)
		DB_NAME=${OPTARG}
		;;
	f)
		DB_PATH=$OPTARG
		;;
	g)
		GENERATE_DATAFILE=1
		;;

	s)
		DB_SOCKET=$OPTARG
		;;
	l)
		LOCAL="LOCAL"
		;;
	h)
		DB_HOST=$OPTARG
		;;
	u)
		DB_USER=$OPTARG
		;;
	p)
		DB_PASSWORD=$OPTARG
		;;	
	e)
		DB_ENGINE=$OPTARG
		;;
	m)
		DB_SCHEME=$OPTARG
		;;
	v)
		VERBOSE=1
		;;
	w)
		WAREHOUSES=${OPTARG}
		;;
	?)
		usage
		exit 1
		;;
	esac
done

# Check parameters.
if [ "$DB_PATH" == "" ]; then
  usage "specify path where dataset txt files are located - using -f <absolute path>"
  exit 1
fi

if [ ! -d "$DB_PATH" ]; then
  usage "Directory '$DB_PATH' not exists. Please specify
       correct path to data files using -f <absolute path>"
  exit 1
fi

if [ "$DB_NAME" == "" ]; then
  usage "specify database name using -d #"
  exit 1
fi

if [ "$DB_ENGINE" != "INNODB" -a "$DB_ENGINE" != "MYISAM" -a "$DB_ENGINE" != "BDB" ]; then
  usage "$DB_ENGINE. Please specifey correct storage engine [MYISAM|INNODB|BDB]"
  exit 1
fi

if [ "$DB_SCHEME" != "OPTIMIZED" -a "$DB_SCHEME" != "ORIG" ]; then
  usage "$DB_SCHEME. Please specifey correct database scheme [OPTIMIZED|ORIG]"
  exit 1
fi

if [ "${DB_PASSWORD}" != "" ]; then
  MYSQL_ARGS="--password=${DB_PASSWORD}"
fi

if [ ! -f "yes/var/localhost.pid" ]; then
	${DIR}/start_db.sh || exit 1
fi

if [ ${GENERATE_DATAFILE} -eq 1 ]; then
	#
	# Generate data files.
	#
	${TOPDIR}/src/datagen -d ${DBDATA} -w ${WAREHOUSES} --mysql || exit 1
fi

MYSQL_ARGS="$MYSQL_ARGS -h $DB_HOST -u $DB_USER --socket=$DB_SOCKET"
MYSQL="$MYSQL $MYSQL_ARGS"

echo ""
echo "Loading of DBT2 dataset located in $DB_PATH to database $DB_NAME."
echo ""
echo "DB_ENGINE:      $DB_ENGINE"
echo "DB_SCHEME:      $DB_SCHEME"
echo "DB_HOST:        $DB_HOST"
echo "DB_USER:        $DB_USER"
echo "DB_SOCKET:      $DB_SOCKET"

command_exec "$MYSQL -e \"drop database if exists $DB_NAME\" "
command_exec "$MYSQL -e \"create database $DB_NAME\" "

# Create tables
echo ""
create_tables

# Load tables
echo ""
load_tables


