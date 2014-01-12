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
use GT::Indicators::ADX2;
use GT::Indicators::DMI;


GT::Conf::load();

my $db = create_db_object();
my $id_adx14 = GT::Indicators::ADX2->new([14]);
my $tr = GT::Indicators::TR->new();
my $trname = "{I:TR " . "{I:Prices HIGH}" . " " .
      "{I:Prices LOW}" . " " .
	"{I:Prices CLOSE}" . "}";
    
my $tr14 = GT::Indicators::Generic::Sum->new([14, $trname]);
my $dm =      GT::Indicators::DMI->new([14]);

my ($calc, $first, $last) = find_calculator($db, "QQQ2", $DAY, 0, "2010-07-09", 0, 0, 0);
$id_adx14->calculate_interval($calc, $first, $last);
for (my $i = $first; $i <= $last; $i++) {
	print $calc->prices->at($i)->[$DATE] . " ";
	print $calc->prices->at($i)->[$HIGH] . " ";
	print $calc->prices->at($i)->[$LOW] . " " ;
	print $calc->prices->at($i)->[$CLOSE] . " ";
    my $value = $calc->indicators->get($tr->get_name(), $i); 
	if (defined($value)) {printf("TR:%.3f ", $value);}
    my $dmp=$calc->prices->at($i)->[$HIGH] - $calc->prices->at($i-1)->[$HIGH];
    if ($dmp < 0) {$dmp=0;}
    if ($i != $first) {printf("+DM:%.2f", $dmp);}
    my $dmn=$calc->prices->at($i-1)->[$LOW] - $calc->prices->at($i)->[$LOW];
    if ($dmn < 0) {$dmn=0;}
    if ($i != $first) {printf("-DM:%.2f", $dmn);}
    $value =  $calc->indicators->get($tr14->get_name() ,$i);
	if (defined($value)) {printf("TR14:%.2f ", $value);}
    $value =  $calc->indicators->get($id_adx14->get_name(1), $i);
	if (defined($value)) {printf("+DMI:%.2f ", $value);}
    $value =  $calc->indicators->get($id_adx14->get_name(2),$i);
	if (defined($value)) { printf("-DMI:%.2f ",$value);}
    $value = $calc->indicators->get($id_adx14->get_name(3), $i);
    if (defined($value)) {printf ("DA:%.2f ", $value);}
    $value = $calc->indicators->get($id_adx14->get_name(0), $i);
	if (defined($value)) {printf("ADX:%.2f",$value);}
    printf("\n");
}
