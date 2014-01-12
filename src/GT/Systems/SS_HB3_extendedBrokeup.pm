package GT::Systems::SS_HB3_extendedBrokeup;

# @author hongbin0908@gmail.com
# @desc a system only use EMA

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Prices;
use GT::Systems;
use GT::Indicators::ADX2;
use GT::OrderFactory::StopPrice;

@ISA = qw(GT::Systems);
@NAMES = ("SS_HB1[#1,#2,#3]");
@DEFAULT_ARGS = (4,9,18);

=pod

=head1  Stochastic

=cut

sub initialize {
    my ($self) = @_;
}


sub precalculate_interval {
    my ($self, $calc, $first, $last) = @_;
    my $adx = GT::Indicators::ADX2->new([14]);
    $adx->calculate_interval($calc, $first, $last);
    return;
}

sub long_signal {
    my ($self, $calc, $i) = @_;
    my $close = $calc->prices->at($i)->[$CLOSE];
    my $high = $calc->prices->at($i)->[$HIGH];
    my $low = $calc->prices->at($i)->[$LOW];

    if ($close < 30){ return 0;}
    for (my $j = $i - 30; $j < $i ; $j++) {
        if ($calc->prices->at($j)->[$HIGH] > $close) {
            return 0;
        }
    }

    for (my $j = $i - 9; $j < $i; $j++) {
        if ($calc->prices->at($j)->[$HIGH] - $calc->prices->at($j)->[$LOW] > $high - $low) {
            return 0;
        }
    }

    my $adx = GT::Indicators::ADX2->new([14]);
    my $adxname = $adx->get_name(0);

    ##if ($calc->indicators->get($adxname, $i) < 30) {
    ##    return 0;
    ##}
    
    return 1;
}

sub short_signal {
	return 0;
}

sub default_order_factory {
    return GT::OrderFactory::StopPrice->new;
}
