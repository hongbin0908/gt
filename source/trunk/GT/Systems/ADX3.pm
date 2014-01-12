package GT::Systems::ADX3;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Prices;
use GT::Systems;
use GT::Indicators::SMA;
use GT::Indicators::ADX;
use GT::Indicators::ADXR;
use GT::Indicators::MACD;

@ISA = qw(GT::Systems);
@NAMES = ("ADX3[#1]");
@DEFAULT_ARGS = (14);

=pod

=head1  Stochastic

=cut

sub initialize {
    my ($self) = @_;

    $self->{'sma1'} = GT::Indicators::SMA->new([ 4 ]);
    $self->{'sma2'} = GT::Indicators::SMA->new([ 9 ]);
    $self->{'sma3'} = GT::Indicators::SMA->new([ 18 ]);

    $self->{'allow_multiple'} = 0;

    $self->add_indicator_dependency($self->{'sma1'}, 2);
    $self->add_indicator_dependency($self->{'sma2'}, 2);
    $self->add_indicator_dependency($self->{'sma3'}, 2);
}


sub precalculate_interval {
    my ($self, $calc, $first, $last) = @_;
    if ($self->{'args'}->is_constant()) {
		my $period = $self->{'args'}->get_arg_constant(1);
		my $adx = GT::Indicators::ADX->new([$period]);
		$adx->calculate_interval($calc, $first, $last);
		my $adxr = GT::Indicators::ADXR->new([$period]);
		$adxr->calculate_interval($calc, $first, $last);
    }

	my $macd = GT::Indicators::MACD->new([12,26,9]);
	$macd->calculate_interval($calc, $first, $last);
    return;
}

sub long_signal {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $period = $self->{'args'}->get_arg_values($calc, $i, 1);
    my $adx = GT::Indicators::ADX->new([$period]);
    my $adx_name = $adx->get_name(0);
	my $positive_di_name = $adx->get_name(1);
	my $negative_di_name = $adx->get_name(2);
	my $adxr = GT::Indicators::ADXR->new([$period]);
    my $adxr_name = $adxr->get_name;
	my $macd = GT::Indicators::MACD->new([12,26,9]);
	my $macd_name = $macd->get_name(0);
	my $macd_singal_name = $macd->get_name(1);
	
    $self->remove_volatile_dependencies();
    $self->add_volatile_indicator_dependency($adx, 2);
	$self->add_volatile_indicator_dependency($adxr, 1);

	if ($calc->indicators->get($positive_di_name, $i) < $calc->indicators->get($negative_di_name, $i)) {
		return 0;
	}

	
	if ($calc->indicators->get($adx_name, $i) < $calc->indicators->get($adx_name, $i-2)) {
		return 0;
	}
	
	if ($calc->indicators->get($adxr_name, $i) < 25) {
		return 0;
	}

    return 0 if (!$self->check_dependencies($calc, $i));
    
	my $sma1=$indic->get($self->{'sma2'}->get_name, $i);
	my $sma1_b=$indic->get($self->{'sma2'}->get_name, $i-1);
	my $sma2=$indic->get($self->{'sma3'}->get_name, $i);
	my $sma2_b=$indic->get($self->{'sma3'}->get_name, $i - 1);

	my $macd_value = $indic->get($macd_name,$i);
	my $macd_value_b = $indic->get($macd_name, $i -2);
	my $macd_singal = $indic->get($macd_singal_name, $i);
	my $macd_singal_b = $indic->get($macd_singal_name, $i - 2);
	#if ( (($macd > $macd_singal) && ($macd_b < $macd_singal_b))  ||
    #     (($sma1> $sma2)  && ($sma1_b < $sma2_b))
	#	) {
	#	return 1;
	#} 
	if (($sma1> $sma2)  && ($sma1_b < $sma2_b)) {
    	return 1;
	}
    #if ( ( $indic->get($self->{'sma1'}->get_name, $i - 1) <
  	#   $indic->get($self->{'sma2'}->get_name, $i - 1)) &&
 	# ( $indic->get($self->{'sma1'}->get_name, $i) >
	#   $indic->get($self->{'sma2'}->get_name, $i) )
    #   )
    #{
	#return 1;
    #}
    return 0;
}

sub short_signal {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    
    return 0;
}
