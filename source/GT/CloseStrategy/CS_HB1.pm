package GT::CloseStrategy::CS_HB1;

#author hongbin0908@gmail.com

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Prices;
use GT::CloseStrategy;
use GT::Eval;
use GT::Tools qw(:generic);
use GT::Indicators::ADX;
use GT::Indicators::RSI;


@ISA = qw(GT::CloseStrategy);
@NAMES = ("CSHB1[#1,#2,#3]");
@DEFAULT_ARGS = (4,9,18);

=head1 NAME

CloseStrategy::CS_HB1

=head1 DESCRIPTION 

this is a close strategy writen by Bin Hong


=back

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

sub manage_long_position {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;
    return 0 if (! $self->check_dependencies($calc, $i));
    

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
	
	if ( ($sma1_value_b > $sma2_value_b) && ($sma1_value < $sma2_value)) {
		my $order = $pf_manager->sell_market_price($calc, 
                                                   $sys_manager->get_name);
        $pf_manager->submit_order_in_position($position, $order, $i, $calc);
	}
	
    return;
}

sub manage_short_position {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;
   
    return;
}

1;
