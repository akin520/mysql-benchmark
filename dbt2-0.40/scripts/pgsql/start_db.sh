#!/bin/sh

#
# This file is released under the terms of the Artistic License.
# Please see the file LICENSE, included in this package, for details.
#
# Copyright (C) 2002 Rod Taylor & Open Source Development Lab, Inc.
#

FLAG=${1}

DIR=`dirname ${0}`
. ${DIR}/pgsql_profile || exit 1

LOGFILE="log"
OUTDIR="."
while getopts "fo:p:" OPT; do
	case ${OPT} in
	f)
		rm -f ${PGDATA}/postmaster.pid
		;;
	o)
		OUTDIR=${OPTARG}
		;;
	p)
		PARAMETERS=$OPTARG
		;;
	esac
done

if [ -f ${PGDATA}/postmaster.pid ]; then
	echo "Database is already started."
	exit 0
fi

sleep 1

if [ "${PARAMETERS}" = "" ]; then
	${PG_CTL} -D ${PGDATA} -l ${OUTDIR}/${LOGFILE} start
else
	${PG_CTL} -D ${PGDATA} -o "${PARAMETERS}" -l ${OUTDIR}/${LOGFILE} start
fi

sleep 10

if [ ! -f ${PGDATA}/postmaster.pid ]; then
	echo "database did not start correctly, check database log"
	exit 1
fi

exit 0
