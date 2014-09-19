#!/usr/bin/perl -w

#
# This file is released under the terms of the Artistic License.
# Please see the file LICENSE, included in this package, for details.
#
# Copyright (C) 2003 Mark Wong & Open Source Development Lab, Inc.
#

use strict;
use Getopt::Long;

my $stats_dir;

GetOptions(
	"dir=s" => \$stats_dir
);

unless ( $stats_dir ) {
	print "usage: analyze_stats.pl --dir <directory>\n";
	exit 1;
}

my @index_names = ("i_customer", "i_orders", "pk_customer", "pk_district",
		"pk_item", "pk_new_order", "pk_order_line", "pk_orders", "pk_stock",
		"pk_warehouse" );

my @table_names = ("customer", "district", "history", "item", "new_order",
		"order_line", "orders", "stock", "warehouse");

my @input_file;

sub process {
	my ( $filename, $column, $ylabel, @names ) = @_;

	# Read it all the data files and process the data.
	my @index_data;
	$filename = ( split /\//, $filename )[ -1 ];
	foreach my $index ( @names ) {
		my @data;
		my $previous_value = 0;

		# The first data point must be a zero.
		push @data, 0;
		open( FILE, "$stats_dir/$filename" );
		while ( <FILE> ) {
			/\s$index\s/ and do {
				my $current_value = ( split, $_ )[ $column ];
				push @data, $current_value - $previous_value;
				$previous_value = $current_value;
			}
		}
		close( FILE );
		@{ $index_data[ $#index_data + 1] } = @data;
	}

	# Output the a graphable data file.
	# The last data point seems kind of screwy, always drop it.
	$filename =~ s/out$/data/;
	open( FILE, ">$stats_dir/$filename" );
	for ( my $i = 0; $i < ( scalar @{ $index_data[ 0 ] } ) - 1; $i++ ) {
		print FILE "$i";
		for ( my $j = 0; $j < scalar @index_data; $j++ ) {
			print FILE " $index_data[ $j ][ $i ]";
		}
		print FILE "\n";
	}
	close( FILE );

	# Create a gnuplot input file.
	my $input_filename = $filename;
	$input_filename =~ s/data$/input/;
	push @input_file, $input_filename;
	my $png_filename = $filename;
	$png_filename =~ s/data$/png/;
	open( FILE, ">$stats_dir/$input_filename" );
	print FILE "plot \"$filename\" using 1:2 title \"$names[ 0 ]\" with lines, \\\n";
	my $i;
	for ( $i = 1; $i < (scalar @names) - 1; $i++ ) {
		print FILE "\"$filename\" using 1:" . ($i + 2) .
			" title \"$names[ $i ]\" with lines, \\\n";
	}
	print FILE "\"$filename\" using 1:" . ($i + 2) .
		" title \"$names[ $i ]\" with lines\n";
	print FILE "set grid xtics ytics\n";
	print FILE "set xlabel \"Elapsed Time (Minutes)\"\n";
	print FILE "set ylabel \"$ylabel\"\n";
	print FILE "set term png small\n";
	print FILE "set output \"$png_filename\"\n";
	print FILE "set yrange [0:]\n";
	print FILE "replot\n";
	close( FILE );
}

foreach my $filename ( <$stats_dir/*indexes_scan.out> ) {
	process( $filename, 10, "Index Scans", @index_names );
}
foreach my $filename ( <$stats_dir/*index_info.out> ) {
	process( $filename, 8, "Blocks Read", @index_names );
}
foreach my $filename ( <$stats_dir/*table_info.out> ) {
	process( $filename, 4, "Blocks Read", @table_names );
}

# Plot each gnuplot input file.
chdir $stats_dir;
foreach my $filename ( @input_file ) {
	system "gnuplot $filename";
}
