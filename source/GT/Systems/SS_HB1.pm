package GT::Systems::SS_HB1;

# @author hongbin0908@gmail.com
# @desc a system only use EMA

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Prices;
use GT::Systems;
use GT::Indicators::SMA;
use GT::Indicators::ADX;
use GT::Indicators::ADXR;
use GT::Indicators::MACD;

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
    if ($self->{'args'}->is_constant()) {
		my $period1 = $self->{'args'}->get_arg_constant(1);
		my $period2 = $self->{'args'}->get_arg_constant(2);
		my $period3 = $self->{'args'}->get_arg_constant(3);
		my $sma1 = GT::Indicators::SMA->new([$period1]);
		my $sma2 = GT::Indicators::SMA->new([$period2]);
		my $sma3 = GT::Indicators::SMA->new([$period3]);
		$sma1->calculate_interval($calc, $first, $last);
		$sma2->calculate_interval($calc, $first, $last);
		$sma3->calculate_interval($calc, $first, $last);
    }
    return;
}

sub long_signal {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $period1 = $self->{'args'}->get_arg_values($calc, $i, 1);
	my $period2 = $self->{'args'}->get_arg_values($calc, $i, 2);
	my $period3 = $self->{'args'}->get_arg_values($calc, $i, 3);
    my $sma1 = GT::Indicators::SMA->new([$period1]);
	my $sma2 = GT::Indicators::SMA->new([$period2]);
	my $sma3 = GT::Indicators::SMA->new([$period3]);
    my $sma1_name = $sma1->get_name;
	my $sma2_name = $sma2->get_name;
	my $sma3_name = $sma3->get_name;
	
	my $sma1_value = $calc->indicators->get($sma1_name, $i);
	my $sma1_value_b = $calc->indicators->get($sma1_name, $i - 1);
	my $sma2_value = $calc->indicators->get($sma2_name, $i);
  	my $sma2_value_b = $calc->indicators->get($sma2_name, $i - 1);
	my $sma3_value = $calc->indicators->get($sma3_name, $i);
	my $sma3_value_b = $calc->indicators->get($sma3_name, $i - 1);
	if ($sma1_value_b == undef) {
		return 0;
	}
	if ( ($sma1_value_b < $sma2_value_b) && ($sma1_value > $sma2_value)) {
		return 1;
	}
	return 0;
}

sub short_signal {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $period1 = $self->{'args'}->get_arg_values($calc, $i, 1);
	my $period2 = $self->{'args'}->get_arg_values($calc, $i, 2);
	my $period3 = $self->{'args'}->get_arg_values($calc, $i, 3);
    my $sma1 = GT::Indicators::SMA->new([$period1]);
	my $sma2 = GT::Indicators::SMA->new([$period2]);
	my $sma3 = GT::Indicators::SMA->new([$period3]);
    my $sma1_name = $sma1->get_name;
	my $sma2_name = $sma2->get_name;
	my $sma3_name = $sma3->get_name;
	
	my $sma1_value = $calc->indicators->get($sma1_name, $i);
	my $sma1_value_b = $calc->indicators->get($sma1_name, $i - 1);
	my $sma2_value = $calc->indicators->get($sma2_name, $i);
  	my $sma2_value_b = $calc->indicators->get($sma2_name, $i - 1);
	my $sma3_value = $calc->indicators->get($sma3_name, $i);
	my $sma3_value_b = $calc->indicators->get($sma3_name, $i - 1);
	
	#if ( (sma1_value_b > sma2_value_b) && (sma1_value < sma2_value)) {
	#	return 1;
	#}
	return 0;
}
