#!/usr/bin/perl -w
# hongbin0908@gmail.com
# test the Calculator mode

use lib '..';

use strict;
use vars qw($db);

use GT::DateTime;
use GT::Eval;

GT::Conf::load();

my $db = create_db_object();
my $prices = $db->get_prices("WDC", $DAY);
print @{$prices->at_date('2013-11-08 00:00:00')} . "\n";




