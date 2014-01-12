#!/usr/bin/perl -w
# hongbin0908@gmail.com
# test the Calculator mode

use lib '..';

use strict;
use vars qw($db);

use GT::DateTime;
use GT::Eval;
use GT::Calculator;
use GT::Tools qw(:timeframe);

GT::Conf::load();

my $db = create_db_object();

my ($prices, $calc) = get_timeframe_data("WDC", $DAY, $db, -1);

print "@{$prices->at_date('2013-11-08')}" . "\n";

my ($calc, $first, $last) = find_calculator($db, "WDC", $DAY, 0, 0, 0, 0, 0);

print '$first = ' . "$first\n";
print '$last = ' . "$last\n";



