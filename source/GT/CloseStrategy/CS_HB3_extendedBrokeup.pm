package GT::CloseStrategy::CS_HB3_extendedBrokeup;

#author hongbin0908@gmail.com

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Prices;
use GT::CloseStrategy;
use GT::Eval;
use GT::Tools qw(:generic);

@ISA = qw(GT::CloseStrategy);
@NAMES = ("CSHB3");
@DEFAULT_ARGS = ();

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
    return;
}


sub long_position_opened {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;
    my $indice_opened = $calc->prices->date($position->open_date);
    $position->set_stop($calc->prices->at($indice_opened-1)->[$CLOSE] - 1.0);
}


sub manage_long_position {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;
    my $initial_period = $calc->prices->date($position->{'open_date'});
    if ($calc->prices->at($i+1)->[$HIGH] > $calc->prices->at($initial_period-1)->[$HIGH] + 5) {
        my $order = $pf_manager->sell_limited_price($calc, $sys_manager->get_name, $calc->prices->at($initial_period-1)->[$HIGH] + 5 );
        $pf_manager->submit_order_in_position($position, $order, $i, $calc);
    } elsif ( $calc->prices->at($i+1)->[$CLOSE] < $calc->prices->at($initial_period-1)->[$CLOSE]) {
        my $order = $pf_manager->virtual_sell_at_close($calc, $sys_manager->get_name );
        $pf_manager->submit_order_in_position($position, $order, $i, $calc);
    }
    return;
    
}

sub manage_short_position {
}

1;
