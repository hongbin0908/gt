#!/usr/bin/perl -w
# hongbin0908@gmail.com
# test the Calculator mode

use lib '..';

use strict;
use JSYNC;
use vars qw($db);

use GT::DateTime;
use GT::Prices;
use GT::Eval;
use GT::Calculator;
use GT::Tools qw(:timeframe);
use GT::Indicators::TR;

GT::Conf::load();

my $db = create_db_object();
my $id_tr = GT::Indicators::TR->new();
my ($calc, $first, $last) = find_calculator($db, "WDC", $DAY, 0, 0, 0, 0, 0);
$id_tr->calculate_interval($calc, $first, $last);
for (my $i = $first; $i <= $last; $i++) {
	for (my $j = 0; $j < $id_tr->get_nb_values; $j++) {
		my $name = $id_tr->get_name($j);
		print $calc->prices->at($i)->[$DATE] . " " . $name . " " . $calc->indicators->get($name, $i). "(" . $calc->prices->at($i-1)->[$CLOSE] . ",".$calc->prices->at($i)->[$HIGH]."," .$calc->prices->at($i)->[$LOW] .")\n";
	}
}
