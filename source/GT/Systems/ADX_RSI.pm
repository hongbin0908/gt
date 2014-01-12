package GT::Systems::ADX_RSI;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Prices;
use GT::Systems;
use GT::Indicators::ADX;
use GT::Indicators::RSI;
@ISA = qw(GT::Systems);
@NAMES = ("ADX");
@DEFAULT_ARGS = (14);

=pod

=head1 Trend following system

=cut

sub initialize {
    my ($self) = @_;

    $self->{'allow_multiple'} = 0;
}

sub precalculate_interval {
    my ($self, $calc, $first, $last) = @_;
    if ($self->{'args'}->is_constant()) {
    my $period = $self->{'args'}->get_arg_constant(1);
    my $adx = GT::Indicators::ADX->new([$period]);
    $adx->calculate($calc, $last);
    }
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
    my $period = $self->{'args'}->get_arg_values($calc, $i, 1);
    my $adx = GT::Indicators::ADX->new([$period]);
    my $rsi = GT::Indicators::RSI->new([$period]);
    my $adxname = $adx->get_name;
    my $rsiname = $rsi->get_name;
    $self->remove_volatile_dependencies();
    $self->add_volatile_indicator_dependency($adx, 2);
    $self->add_volatile_indicator_dependency($rsi, 3);

    return 0 if (!$self->check_dependencies($calc, $i));

    if (($calc->indicators->get($adxname, $i) < 60)
    )
    {
    if(($calc->indicators->get($rsiname, $i) > 60)) {
    return 1;
    }
    }
    return 0;
}

sub short_signal {
    my ($self, $calc, $i) = @_;

    return 0;
}
