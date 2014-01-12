#!/usr/bin/perl -w
# hongbin0908@gmail.com
# test the Signal mode

use lib '..';

use strict;
use vars qw($db);

use GT::Prices;
use GT::Calculator;
use GT::Conf;
use GT::Eval;
use Getopt::Long;
use GT::Tools qw(:timeframe);
use Pod::Usage;

use GT::Signals::Generic::CrossOverUp;
GT::Conf::load();
my $signal = GT::Signals::Generic::CrossOverUp->new(['{I:EMA 9}','{I:EMA 18}']);
my $signal_name = $signal->get_name;
print '$signal_name = ' . "$signal_name" . "\n";



