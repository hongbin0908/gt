package GT::OrderFactory::StopPrice;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::OrderFactory;
use GT::Prices;

@ISA = qw(GT::OrderFactory);
@NAMES = ("MarketPrice");
@DEFAULT_ARGS = ();

=head1 NAME

GT::OrderFactory::StopPrice

=head1 DESCRIPTION

Create an order at stoped price.

=cut
sub create_buy_order {
    my ($self, $calc, $i, $sys_manager, $pf_manager) = @_;
    if ($i < 1) {return;}
    
    return $pf_manager->buy_conditional($calc, $sys_manager->get_name, $calc->prices->at($i)->[$HIGH] + 0.02, $calc->prices->at($i)->[$HIGH] + 0.02);
}

sub create_sell_order {
    my ($self, $calc, $i, $sys_manager, $pf_manager) = @_;

    if ($i < 1) {return;}

    my $low_last = $calc->prices->at($i-1)->[$LOW];

    return $pf_manager->sell_conditional($calc, $sys_manager->get_name, $low_last - 0.2);
}

1;
