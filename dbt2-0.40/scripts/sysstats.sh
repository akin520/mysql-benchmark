#!/bin/bash

#
# This file is released under the terms of the Artistic License.
# Please see the file LICENSE, included in this package, for details.
#
# Copyright (C) 2002-2006 Mark Wong & Open Source Development Labs, Inc.
#

if [ $# -lt 1 ]; then
    echo "usage: sysstats.sh --outdir <output_dir> --iter <iterations> -sample <sample_length>"
    echo "	<output_dir> will be created if it doesn't exist"
    exit
fi

COUNTER=0

while :
do
	case $# in
	0)
		break
		;;
	esac

	option=$1
	shift

	orig_option=$option
	case $option in
	--*)
		;;
	-*)
		option=-$option
		;;
	esac

	case $option in
	--*=*)
		optarg=`echo $option | sed -e 's/^[^=]*=//'`
		arguments="$arguments $option"
		;;
	--db | --dbname | --outdir | --iter | --sample)
		optarg=$1
		shift
		arguments="$arguments $option=$optarg"
		;;
	esac

	case $option in
	--db)
		DBTYPE=$optarg
		;;
	--dbname)
		DBTYPE_NAME=$optarg
		;;
	--outdir)
		OUTPUT_DIR=$optarg
		;;
	--iter)
		ITERATIONS=$optarg
		;;
	--sample)
		SAMPLE_LENGTH=$optarg
		;;
	esac
done

if [ -z $OUTPUT_DIR ]; then
	echo "use --outdir"
	exit
fi

if [ -z $ITERATIONS ]; then
	echo "use --iter"
	exit
fi

if [ -z $SAMPLE_LENGTH ]; then
	echo "use --sample"
	exit
fi

# create the output directory in case it doesn't exist
mkdir -p $OUTPUT_DIR

echo "starting system statistics data collection"

# collect all sar data in binary form
/usr/bin/sar -o $OUTPUT_DIR/sar_raw.out $SAMPLE_LENGTH $ITERATIONS &

# collect i/o data per physical device
/usr/bin/iostat -d $SAMPLE_LENGTH $ITERATIONS >> $OUTPUT_DIR/iostat.out &
/usr/bin/iostat -d -x $SAMPLE_LENGTH $ITERATIONS >> $OUTPUT_DIR/iostatx.out &

# collect vmstat data
VMSTAT_OUTPUT=$OUTPUT_DIR/vmstat.out
OS=`uname`
if [ ${OS} == "SunOS" ]; then
	/usr/bin/vmstat $SAMPLE_LENGTH $ITERATIONS >> $VMSTAT_OUTPUT &
else
	/usr/bin/vmstat -n $SAMPLE_LENGTH $ITERATIONS >> $VMSTAT_OUTPUT &
fi

exit 0
