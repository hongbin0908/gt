#!/usr/bin/perl -w
# hongbin0908@gmail.com
# test the Calculator mode

use lib '..';

use strict;
use vars qw($db);

use GT::DateTime;
use GT::Prices;
use GT::Eval;
use GT::Calculator;
use GT::Tools qw(:timeframe);
use GT::Indicators::ADX;

GT::Conf::load();

my $db = create_db_object();

my $id_sma4 = GT::Indicators::SMA->new([4]);
my ($calc, $first, $last) = find_calculator($db, "WDC", $DAY, 0, 0, 0, 0, 0);
$id_sma4->calculate_interval($calc, $first, $last);
print '$id_sma4->get_nb_values = ' . $id_sma4->get_nb_values . "\n";
my $name = $id_sma4->get_name(0);
for (my $i = $first; $i <= $last; $i++) {
	print $calc->prices->at($i)->[$DATE] . " ". $calc->indicators->get($name, $i) . "\n";
}
