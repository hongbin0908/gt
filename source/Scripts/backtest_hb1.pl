#!/usr/bin/env perl
#
#!/bin/sh -- # perl, to stop looping
# the following must be on two lines
eval 'exec perl -S $0 ${1+"$@"}'
 if 0;

#!/usr/bin/perl -w
use lib '..';
use strict;
use String::Util 'trim';
use Time::Local;
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


use Getopt::Long;

# @author hongbin0908@gmail.com
my ($system , $csname,$index) = ("", "","dow30");

GetOptions(
    'sy=s'  => \$system,
    'cs=s'  => \$csname,
    'id=s'  => \$index,
    );


my $db = create_db_object();
my $pf_manager = GT::PortfolioManager->new;
$pf_manager->add_money_management_rule(create_standard_object("MoneyManagement::Basic"));
my $sys_manager = GT::SystemManager->new;
$sys_manager->set_system(create_standard_object(split(/\s+/,"Systems::$system")));
my $of = $sys_manager->set_order_factory();
$sys_manager->add_position_manager(create_standard_object(split(/\s+/, "CloseStrategy::$csname")));
my $initial_value = 10000;
my $timeframe = GT::DateTime::name_to_timeframe("day");
my $start = ''; my $end = '';
check_dates($timeframe, $start, $end);

my $full = 0;
my $nb_item = 0;
my $max_loaded_items = -1;
my $broker='';


print "system = " . $system . "\n";
print "close strategy = " . $csname . "\n";

sub get_sp500() {#{{{
    open(my $fin, "<", "/home/abin/geniustrader/data/sp500.in") || die "can not open file";
    my @array;
    while (<$fin>) {
        if (trim($_) == "") {
            push(@array, trim($_));
        }   
    }
    return @array;
}#}}}

sub get_dow30() {#{{{
    open(my $fin, "<", "/home/abin/geniustrader/data/dow30.in") || die "can not open file";
    my @array;
    while(<$fin>) {
        if (trim($_) == "") {
            push(@array, trim($_));
        }
    }
    return @array;
}#}}}


my @syms;
if ($index == 'dow30') {
    @syms = get_dow30();
} else {
    @syms= get_sp500();
}
my $performance=0.0;
my $buyandhold=0.0;


sub get_days {
    my ($date) = @_;
    $date =~ m/(\d+)-(\d+)-(\d+) (\d+):(\d+):(\d+)/;
    return timelocal($6, $5, $4, $3, $2-1, $1)*1.0/24/3600;
}
my $tit = 0.0;
foreach my $code (@syms)
{
    my ($calc, $first, $last) =find_calculator($db, $code, $timeframe, $full, $start, $end, $nb_item, $max_loaded_items);
    
    $pf_manager->finalize;
    $sys_manager->finalize;
    
    
    my $analysis = backtest_single($pf_manager, $sys_manager, $broker, $calc, $first, $last, $initial_value);
    
    foreach my $position (@{$analysis->{'portfolio'}->{'history'}}) {
        my $stats = $position->stats($analysis->{'portfolio'});
        my $it = $stats->{"ugain"} * 10000.0/$position->{"open_price"};
        $tit += $it;
        printf  "%s%s\tgain:%.2f\tacc_gain:%.2f\n", $position->{"code"}, $stats->{"vobose"}, $it,  $tit;
    }
}

