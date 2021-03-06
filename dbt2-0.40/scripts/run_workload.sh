#!/bin/bash
#
# This file is released under the terms of the Artistic License.
# Please see the file LICENSE, included in this package, for details.
#
# Copyright (C) 2002-2006 Mark Wong & Open Source Development Labs, Inc.
#

abs_top_srcdir=/root/src/dbt2-0.40
DBDIR=mysql

DIR=`dirname $0`
source ${DIR}/dbt2_profile || exit 1

trap 'echo "Test was interrupted by Control-C."; \
	killall client; killall driver; killall sar; killall sadc; killall vmstat; killall iostat; ${DB_COMMAND} ${abs_top_srcdir}/scripts/${DBDIR}/stop_db.sh' INT
trap 'echo "Test was interrupted. Got TERM signal."; \
	killall client; killall driver;  killall sar; killall sadc; killall vmstat; killall iostat; ${DB_COMMAND} ${abs_top_srcdir}/scripts/${DBDIR}/stop_db.sh' TERM

do_sleep()
{
	echo "Sleeping $1 seconds"
	sleep $1
}

make_directories()
{
	COMMAND=""
	HOST=${1}
	if [ -n "${HOST}" ]; then
		COMMAND="ssh ${HOST}"
	fi
	${COMMAND} mkdir -p ${OUTPUT_DIR}
	${COMMAND} mkdir -p ${CLIENT_OUTPUT_DIR}
	${COMMAND} mkdir -p ${DRIVER_OUTPUT_DIR}
	${COMMAND} mkdir -p ${DB_OUTPUT_DIR}
}

oprofile_annotate()
{
	COMMAND=""
	DIR=${1}
	HOST=${2}
	if [ -n "${HOST}" ]; then
		COMMAND="ssh ${HOST}"
	else
		HOST=`hostname`
	fi
	echo "oprofile is annotating source: ${HOST}"
	${COMMAND} mkdir -p ${DIR}/oprofile/
	${COMMAND} mkdir -p ${DIR}/oprofile/annotate
	if [ -n "${COMMAND}" ]; then
		${COMMAND} "sudo opannotate --source --assembly > ${DIR}/oprofile/assembly.txt 2>&1"
	else
		sudo opannotate --source --assembly > ${DIR}/oprofile/assembly.txt 2>&1
	fi
	${COMMAND} sudo opannotate --source --output-dir=${DIR}/oprofile/annotate
}

oprofile_collect()
{
	COMMAND=""
	DIR=${1}
	HOST=${2}
	if [ -n "${HOST}" ]; then
		COMMAND="ssh ${HOST}"
	else
		HOST=`hostname`
	fi
	#
	# I don't think we need any output dumped to the terminal.
	#
	echo "oprofile is dumping data: ${HOST}"
	${COMMAND} sudo opcontrol --dump
	if [ -n "${COMMAND}" ]; then
		${COMMAND} "sudo opreport -l -p /lib/modules/`${COMMAND} uname -r` -o ${DIR}/oprofile.txt > /dev/null 2>&1"
		${COMMAND} "sudo opreport -l -c -p /lib/modules/`${COMMAND} uname -r` -o ${DIR}/callgraph.txt > /dev/null 2>&1"
	else
		sudo opreport -l -p /lib/modules/`uname -r` \
				-o ${DIR}/oprofile.txt > /dev/null 2>&1
		sudo opreport -l -c -p /lib/modules/`uname -r` \
				-o ${DIR}/callgraph.txt > /dev/null 2>&1
	fi
	${COMMAND} sudo opcontrol --stop
}

oprofile_init()
{
	COMMAND=""
	HOST=${1}
	if [ -n "${HOST}" ]; then
		COMMAND="ssh ${HOST}"
	else
		HOST=`hostname`
	fi
	echo "starting oprofile: ${HOST}"
	${COMMAND} sudo opcontrol \
			--vmlinux=/usr/src/linux-`${COMMAND} uname -r`/vmlinux -c 100
	sleep 1
	START_ARGS=""
	MACHINE=`${COMMAND} uname -m`
	if [ "${MACHINE}" == "ppc64" ]; then
		#
		# Oprofile fails to work on ppc64 because the defaults settings
		# are invalid on this platform.  Why isn't it smart enough to
		# have valid default setting depending on arch?
		#
		START_ARGS="-e CYCLES:150000:0:1:1"
	fi
	${COMMAND} sudo opcontrol --start-daemon ${START_ARGS}
	sleep 1
	${COMMAND} sudo opcontrol --start
}

oprofile_reset()
{
	COMMAND=""
	HOST=${1}
	if [ -n "${HOST}" ]; then
		COMMAND="ssh ${HOST}"
	else
		HOST=`hostname`
	fi
	echo "reseting oprofile counters: ${HOST}"
	${COMMAND} sudo opcontrol --reset
}

oprofile_stop()
{
	COMMAND=""
	HOST=${1}
	if [ -n "${HOST}" ]; then
		COMMAND="ssh ${HOST}"
	else
		HOST=`hostname`
	fi
	echo "stopping oprofile daemon: ${HOST}"
	${COMMAND} sudo opcontrol --shutdown
}

post_process_sar()
{
	FILE=${1}
	if [ -f ${FILE} ]; then
		/usr/bin/sar -f ${FILE} -A > `dirname ${FILE}`/sar.out
	fi
}

readprofile_collect()
{
	COMMAND=""
	DIR=${1}
	HOST=${2}
	if [ -n "${HOST}" ]; then
		COMMAND="ssh ${HOST}"
	else
		HOST=`hostname`
	fi
	echo "collecting readprofile data: ${HOST}"
	PROFILE=${DIR}/readprofile.txt
	if [ -n "${COMMAND}" ]; then
		${COMMAND} "/usr/sbin/readprofile -n -m /boot/System.map-`${COMMAND} uname -r` > ${PROFILE}"
		${COMMAND} "cat ${PROFILE} | sort -n -r -k1 > ${DIR}/readprofile_ticks.txt"
		${COMMAND} "cat ${PROFILE} | sort -n -r -k3 > ${DIR}/readprofile_load.txt"
	else
		/usr/sbin/readprofile -n -m /boot/System.map-`uname -r` > ${PROFILE}
		cat ${PROFILE} | sort -n -r -k1 > ${DIR}/readprofile_ticks.txt
		cat ${PROFILE} | sort -n -r -k3 > ${DIR}/readprofile_load.txt
	fi
}

readprofile_clear()
{
	COMMAND=""
	HOST=${1}
	if [ -n "${HOST}" ]; then
		COMMAND="ssh ${HOST}"
	else
		HOST=`hostname`
	fi
	echo "clearing readprofile data: ${HOST}"
	${COMMAND} sudo /usr/sbin/readprofile -r
}

usage()
{
	if [ "$1" != "" ]; then
		echo
		echo "error: $1"
	fi
	echo ''
	echo 'usage: run_workload.sh -c <number of database connections> -d <duration of test> -w <number of warehouses>'
	echo 'other options:'
	echo '       -d <database name. (default dbt2)>'
	echo '       -h <database host name. (default localhost)>'
	echo '       -l <database port number>'
	echo '       -o <enable oprofile data collection>'
	echo '       -s <delay of starting of new threads in milliseconds>'
	echo '       -n <no thinking or keying time (default no)>'
	if [ "$DBDIR" == "mysql" ]; then
	echo '       -u <database user>'
	echo '       -x <database password>'
	fi
	echo '       -z <comments for the test>'
	echo ''
	echo 'Example: sh run_workload.sh -c 20 -d 100 -w 1'
	echo 'Test will be run for 120 seconds with 20 database connections and scale factor (num of warehouses) 1'
	echo ''
}

validate_parameter()
{
	if [ "$2" != "$3" ]; then
		usage "wrong argument '$2' for parameter '-$1'"
		exit 1
	fi
}

DB_HOSTNAME="localhost"
DB_PASSWORD=""
DB_PARAMS=""
CLIENT_HOSTNAME="localhost"

#
# Set the default DB_PORT depending on which database is used.
#
if [ ${DBDIR} == "pgsql" ]; then
	DB_PORT=5432
elif [ ${DBDIR} == "mysql" ]; then
	DB_PORT=""
fi
DB_USER=${DBUSER}
SLEEPY=1000 # milliseconds
USE_OPROFILE=0
THREADS_PER_WAREHOUSE=10

while getopts "c:d:H:hl:nop:s:t:u:w:x:z:" opt; do
	case $opt in
	c)
		# Check for numeric value
		DBCON=`echo $OPTARG | egrep "^[0-9]+$"`
		validate_parameter $opt $OPTARG $DBCON
		;;
	d)
		DURATION=`echo $OPTARG | egrep "^[0-9]+$"`
		validate_parameter $opt $OPTARG $DURATION
		;;
	H)
		DB_HOSTNAME=${OPTARG}
		;;
	h)
		usage
		exit 1
		;;
	l)
		DB_PORT=`echo $OPTARG | egrep "^[0-9]+$"`
		validate_parameter $opt $OPTARG $DB_PORT
		;;
	n)
		NO_THINK="-ktd 0 -ktn 0 -kto 0 -ktp 0 -kts 0 -ttd 0 -ttn 0 -tto 0 -ttp 0 -tts 0"
		;;
	o)
		USE_OPROFILE=1
		;;
	p)
		DB_PARAMS=$OPTARG
		;;
	s)
		SLEEPY=`echo $OPTARG | egrep "^[0-9]+$"`
		validate_parameter $opt $OPTARG $SLEEPY
		;;
	t)
		THREADS_PER_WAREHOUSE=`echo $OPTARG | egrep "^[0-9]+$"`
		validate_parameter $opt $OPTARG $THREADS_PER_WAREHOUSE
		;;
	u)      
		DB_USER=${OPTARG}
		;;

	w)
		WAREHOUSES=`echo $OPTARG | egrep "^[0-9]+$"`
		validate_parameter $opt $OPTARG $WAREHOUSES
		;;
	x)      
		DB_PASSWORD=${OPTARG}
		;;

	z)
		COMMENT=$OPTARG
		;;
	esac
done

# Check parameters.

if [ "$DBCON" == "" ]; then
	echo "specify the number of database connections using -c #"
	exit 1
fi

if [ "$DURATION" == "" ]; then
	echo "specify the duration of the test in seconds using -d #"
	exit 1
fi

if [ "$WAREHOUSES" == "" ]; then
	echo "specify the number of warehouses using -w #"
	exit 1
fi

if [ $(( $THREADS_PER_WAREHOUSE*1 )) -lt 1 -o $(( $THREADS_PER_WAREHOUSE*1 )) -gt 1000 ]; then
	usage "-t value should be in range [1..1000]. Please specify correct value"
	exit 1
fi

ULIMIT_N=`ulimit -n`
ESTIMATED_ULIMIT=$(( 2*${WAREHOUSES}*${THREADS_PER_WAREHOUSE}+${DBCON} ))
if [ ${ULIMIT_N} -lt $(( $ESTIMATED_ULIMIT )) ]; then
  usage "you're open files ulimit is too small, must be at least ${ESTIMATED_ULIMIT}"
  exit 1
fi

# Determine the output directory for storing data.
RUN_NUMBER=-1
RUN_FILE="${abs_top_srcdir}/scripts/run_number"
if test -f ${RUN_FILE}; then
  read RUN_NUMBER < ${RUN_FILE}
fi
if [ $RUN_NUMBER -eq -1 ]; then
	RUN_NUMBER=0
fi
OUTPUT_DIR=${abs_top_srcdir}/scripts/output/${RUN_NUMBER}
CLIENT_OUTPUT_DIR=$OUTPUT_DIR/client
DRIVER_OUTPUT_DIR=$OUTPUT_DIR/driver
DB_OUTPUT_DIR=$OUTPUT_DIR/db

#
# Create the directories we will need.
#
make_directories
if [ -n ${DB_HOSTNAME} -a ! "${DB_HOSTNAME}" == "localhost" ]; then
	#
	# Create direcotires on the database server if specified.
	#
	make_directories ${DB_HOSTNAME}
	#
	# We want to sync everything with the system executing this script so
	# use rsync to delete any files that may be on the database system but
	# only in the database output directory.
	#
	/usr/bin/rsync -a -e "ssh" --delete ${DB_OUTPUT_DIR}/ \
			${DB_HOSTNAME}:${DB_OUTPUT_DIR}/
fi

# Update log.html
echo "<a href='$RUN_NUMBER/report/'>$RUN_NUMBER</a>: $COMMENT<br />" >> ${abs_top_srcdir}/scripts/output/log.html

# Update the run number for the next test.
RUN_NUMBER=`expr $RUN_NUMBER + 1`
echo $RUN_NUMBER > ${RUN_FILE}

# Create a readme file in the output directory and date it.
date >> $OUTPUT_DIR/readme.txt
echo "$COMMENT" >> $OUTPUT_DIR/readme.txt
uname -a >> $OUTPUT_DIR/readme.txt
echo "Command line: $0 $@" >> $OUTPUT_DIR/readme.txt

# Get any OS specific information.
OS_DIR=`uname`
$abs_top_srcdir/scripts/$OS_DIR/get_os_info.sh -o $OUTPUT_DIR

# Output run information into the readme.txt.
echo "Database Scale Factor: $WAREHOUSES warehouses" >> $OUTPUT_DIR/readme.txt
echo "Test Duration: $DURATION seconds" >> $OUTPUT_DIR/readme.txt
echo "Database Connections: $DBCON" >> $OUTPUT_DIR/readme.txt

if [ -n ${DB_HOSTNAME} -a ! "${DB_HOSTNAME}" == "localhost" ]; then
	DB_COMMAND="ssh ${DB_HOSTNAME}"
fi

${DB_COMMAND} ${abs_top_srcdir}/scripts/${DBDIR}/stop_db.sh
if [ -n "${DB_COMMAND}" ]; then
	${DB_COMMAND} "${abs_top_srcdir}/scripts/${DBDIR}/start_db.sh ${START_DB_ARGS} -p \"${DB_PARAMS}\"" || exit 1
else
	${abs_top_srcdir}/scripts/${DBDIR}/start_db.sh ${START_DB_ARGS} \
			-p "${DB_PARAMS}" || exit 1
fi

#
# Redisplay the test parameters.
#
echo "************************************************************************"
echo "*              DBT-2 test for ${DBDIR} started"
echo "*                                                                      *"
echo "*	    Results can be found in output/$(( $RUN_NUMBER-1 )) directory"
echo "************************************************************************"
echo "*                                                                      *"
echo "*  Test consists of 3 stages:                                          *"
echo "*                                                                      *"
echo "*  1. Start of client to create pool of databases connections          *"
echo "*  2. Start of driver to emulate terminals and transactions generation *"
echo "*  3. Processing of results                                            *"
echo "*                                                                      *"
echo "************************************************************************"

#
# Build up the client command line arguments.
#

echo ""
echo "DATABASE SYSTEM: ${DB_HOSTNAME}"
echo "DATABASE NAME: ${DBNAME}"

if [ -n "${DB_USER}" ]; then
  echo "DATABASE USER: ${DB_USER}"
  CLIENT_COMMAND_ARGS="${CLIENT_COMMAND_ARGS} -u ${DB_USER}"
fi 

if [ -n "${DB_PASSWORD}" ]; then 
  echo "DATABASE PASSWORD: *******" 
  CLIENT_COMMAND_ARGS="${CLIENT_COMMAND_ARGS} -a ${DB_PASSWORD}"
fi 

if [ -n "${DB_SOCKET}" ]; then 
  echo "DATABASE SOCKET: ${DB_SOCKET}"
  CLIENT_COMMAND_ARGS="${CLIENT_COMMAND_ARGS} -t ${DB_SOCKET}"
fi 

if [ -n "${DB_PORT}" ]; then 
  echo "DATABASE PORT: ${DB_PORT}"
  CLIENT_COMMAND_ARGS="${CLIENT_COMMAND_ARGS} -l ${DB_PORT}"
fi 

THREADS=$(( ${WAREHOUSES}*${THREADS_PER_WAREHOUSE} ))
echo "DATABASE CONNECTIONS: ${DBCON}"
echo "TERMINAL THREADS: ${THREADS}"
echo "TERMINALS PER WAREHOUSE: ${THREADS_PER_WAREHOUSE}"
echo "SCALE FACTOR(WAREHOUSES): ${WAREHOUSES}"
echo "DURATION OF TEST (in sec): ${DURATION}"
echo "1 client stared every ${SLEEPY} millisecond(s)"
echo ""

#
# Start the client.
#
echo "Stage 1. Starting up client..."
if [ ${DBDIR} == "pgsql" ]; then
	if [ ${USE_PGPOOL} -eq 1 ]; then
		echo "Starting pgpool..."
		 -f ${DIR}/pgsql/pgpool.conf
		TMP_DB_HOSTNAME="localhost"
	else
		TMP_DB_HOSTNAME=${DB_HOSTNAME}
	fi
	CLIENT_COMMAND_ARGS="${CLIENT_COMMAND_ARGS} -d ${TMP_DB_HOSTNAME}"
elif [ ${DBDIR} == "mysql" ]; then
	CLIENT_COMMAND_ARGS="${CLIENT_COMMAND_ARGS} -d ${DBNAME} -t /tmp/mysql.sock"
fi
CLIENT_COMMAND_ARGS="${CLIENT_COMMAND_ARGS} -f -c ${DBCON} -s ${SLEEPY} -o ${CLIENT_OUTPUT_DIR}"
${abs_top_srcdir}/src/client ${CLIENT_COMMAND_ARGS} > \
		${OUTPUT_DIR}/client.out 2>&1 || exit 1 &

# Sleep long enough for all the client database connections to be established.
SLEEPYTIME=$(( (1+$DBCON)*$SLEEPY/1000 ))
do_sleep $SLEEPYTIME

# Start collecting data before we start the test.
SLEEP_RAMPUP=$(( (($WAREHOUSES+1)*10*$SLEEPY/1000) ))
SLEEPYTIME=$(( $SLEEP_RAMPUP+$DURATION ))
SAMPLE_LENGTH=60
ITERATIONS=$(( ($SLEEPYTIME/$SAMPLE_LENGTH)+1 ))
${abs_top_srcdir}/scripts/sysstats.sh \
		--iter ${ITERATIONS} \
		--sample ${SAMPLE_LENGTH} \
		--outdir ${OUTPUT_DIR} > ${OUTPUT_DIR}/stats.out 2>&1 &
if [ -n ${DB_HOSTNAME} -a ! "${DB_HOSTNAME}" == "localhost" ]; then
	${DB_COMMAND} "${abs_top_srcdir}/scripts/sysstats.sh --iter ${ITERATIONS} --sample ${SAMPLE_LENGTH} --outdir ${DB_OUTPUT_DIR} > ${DB_OUTPUT_DIR}/stats.out 2>&1" &
fi
${DB_COMMAND} ${abs_top_srcdir}/scripts/${DBDIR}/db_stat.sh -o $DB_OUTPUT_DIR \
		-i $ITERATIONS -s $SAMPLE_LENGTH > $OUTPUT_DIR/dbstats.out 2>&1 &

# Initialize oprofile before we start the driver.
if [ ${USE_OPROFILE} -eq 1 ]; then
	oprofile_init
	if [ -n ${DB_HOSTNAME} -a ! "${DB_HOSTNAME}" == "localhost" ]; then
		oprofile_init ${DB_HOSTNAME}
	fi
fi

# Start the driver.
echo ''
echo "Stage 2. Starting up driver..."
echo "${SLEEPY} threads started per millisecond"

DRIVERS=$(( $THREADS_PER_WAREHOUSE*$WAREHOUSES ))
DRIVER_COMMAND_ARGS="-d ${CLIENT_HOSTNAME} -l ${DURATION} -wmin 1 -wmax ${WAREHOUSES} -w ${WAREHOUSES} -sleep ${SLEEPY} -outdir ${DRIVER_OUTPUT_DIR} -tpw ${THREADS_PER_WAREHOUSE} ${NO_THINK}"
${abs_top_srcdir}/src/driver ${DRIVER_COMMAND_ARGS} > \
		${OUTPUT_DIR}/driver.out 2>&1 || exit 1&

echo -n "estimated rampup time: "
do_sleep $SLEEP_RAMPUP
echo "estimated rampup time has elapsed"

# Clear the readprofile data after the driver ramps up.
if [ -f /proc/profile ]; then
	readprofile_clear()
	if [ -n ${DB_HOSTNAME} -a ! "${DB_HOSTNAME}" == "localhost" ]; then
		readprofile_clear ${DB_HOSTNAME}
	fi
fi

# Reset the oprofile counters after the driver ramps up.
if [ ${USE_OPROFILE} -eq 1 ]; then
	oprofile_reset
	if [ -n ${DB_HOSTNAME} -a ! "${DB_HOSTNAME}" == "localhost" ]; then
		oprofile_reset ${DB_HOSTNAME}
	fi
fi

# Sleep for the duration of the run.
echo -n "estimated steady state time: "
do_sleep $DURATION

# Collect readprofile data.
if [ -f /proc/profile ]; then
	readprofile_collect ${OUTPUT_DIR}
	if [ -n ${DB_HOSTNAME} -a ! "${DB_HOSTNAME}" == "localhost" ]; then
		readprofile_collect ${DB_OUTPUT_DIR} ${DB_HOSTNAME}
	fi
fi

# Collect oprofile data.
if [ ${USE_OPROFILE} -eq 1 ]; then
	oprofile_collect ${OUTPUT_DIR}
	if [ -n ${DB_HOSTNAME} -a ! "${DB_HOSTNAME}" == "localhost" ]; then
		oprofile_collect ${DB_OUTPUT_DIR} ${DB_HOSTNAME}
	fi
fi

echo ''
echo "Stage 3. Processing of results..."

# Client doesn't go away by itself like the driver does, so kill it.
echo "Killing client..."
killall client driver 2> /dev/null

${DB_COMMAND} ${abs_top_srcdir}/scripts/${DBDIR}/stop_db.sh
if [ ${USE_PGPOOL} -eq 1 ]; then
	 -f ${DIR}/pgsql/pgpool.conf stop
fi

# Run some post processing analysese.
${abs_top_srcdir}/scripts/post-process \
		--dir ${OUTPUT_DIR} --xml > ${DRIVER_OUTPUT_DIR}/results.out

if [ ${USE_OPROFILE} -eq 1 ]; then
	oprofile_annotate ${OUTPUT_DIR} &
	if [ -n ${DB_HOSTNAME} -a ! "${DB_HOSTNAME}" == "localhost" ]; then
		oprofile_annotate ${DB_OUTPUT_DIR} ${DB_HOSTNAME} &
	fi
	wait
fi

if [ ${USE_OPROFILE} -eq 1 ]; then
	oprofile_stop
	if [ -n ${DB_HOSTNAME} -a ! "${DB_HOSTNAME}" == "localhost" ]; then
		oprofile_stop ${DB_HOSTNAME}
	fi
fi

if [ -n ${DB_HOSTNAME} -a ! "${DB_HOSTNAME}" == "localhost" ]; then
	#
	# If a database system is specified, rsync all the logs back to here.
	#
	/usr/bin/rsync -a -e "ssh" --delete ${DB_HOSTNAME}:${DB_OUTPUT_DIR}/ \
			${DB_OUTPUT_DIR}/
fi

# Change the permissions on the database log, not readable by other users by
# default.  (No, not the transaction log.)
chmod 644 ${DB_OUTPUT_DIR}/log

# Postprocessing of Database Statistics
post_process_sar ${OUTPUT_DIR}/sar_raw.out
post_process_sar ${DB_OUTPUT_DIR}/sar_raw.out
if [ -f "${abs_top_srcdir}/scripts/${DBDIR}/analyze_stats.pl" ]; then
	${abs_top_srcdir}/scripts/${DBDIR}/analyze_stats.pl --dir ${DB_OUTPUT_DIR}
fi


echo "Test completed."
echo "Results are in: $OUTPUT_DIR"
echo

cat $DRIVER_OUTPUT_DIR/results.out
