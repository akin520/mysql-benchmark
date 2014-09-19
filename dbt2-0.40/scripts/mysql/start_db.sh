#!/bin/bash

#
# This file is released under the terms of the Artistic License.
# Please see the file LICENSE, included in this package, for details.
#
# Copyright (C) 2006 Mark Wong & Open Source Development Labs, Inc.
#

LOGFILE="log"
OUTDIR="."
while getopts "fo:" OPT; do
	case ${OPT} in
	f)
		if [ -f "yes/var/localhost.pid" ]; then
			rm yes/var/localhost.pid
		fi
		;;
	o)
		OUTDIR=$OPTARG
		;;
	esac
done

if [ -f "yes/var/localhost.pid" ]; then
	echo "MySQL pid file 'yes/var/localhost.pid' already exists."
	exit 1
fi
nohup /usr/local/mysql/bin/mysqld_safe --log-error=${OUTDIR}/${LOGFILE} > /dev/null 2>&1 &
sleep 10

exit 0
