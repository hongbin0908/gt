#!/usr/bin/env perl
#
#!/bin/sh -- # perl, to stop looping
# the following must be on two lines
eval 'exec perl -S $0 ${1+"$@"}'
 if 0;

#!/usr/bin/perl -w

use lib '..';

use File::Basename;
use Cwd 'abs_path';
use Test::Simple tests => 1;
use POSIX qw(strftime);
use GT::Systems::SS_HB3_extendedBrokeup;

use vars qw($db);
use GT::Prices;
use GT::Portfolio;
use GT::PortfolioManager;
use GT::Calculator;
use GT::Report;
use GT::BackTest;
use GT::Eval;
use GT::Conf;
use GT::DateTime;
use GT::Tools qw(:conf :timeframe);

my $local_path = dirname(abs_path($0));
 


sub prepare_data() {
    $codefile = $local_path . "/../../data/UNKOWN.txt";
    printf "%s\n", $codefile;
    open(FILE, ">" . $codefile);
    for (my $i = 0 ; $i < 29; $i++) {
        my $datestr = strftime "%F", localtime(time() + $i * 3600 * 24);
        syswrite(FILE, "1\t1\t1\t1\t1000\t" . $datestr . "\n");
    }
    my $datestr = strftime "%F", localtime(time() + 29 * 3600 * 24);
    syswrite(FILE, "2\t2\t2\t2\t1000\t" . $datestr . "\n");
    close(FILE);
}
my $db = create_db_object();

prepare_data();

my ($calc, $first, $last) = find_calculator($db, 'UNKOWN', GT::DataTime::name_to_timeframe("day"), 0, '', '', 0, -1);



ok( 1 ne 2, '1 is equal to 2');
