package GT::BackTest;

# Copyright 2000-2002 Rapha�l Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# incorporate derek shinaberry fixes

use strict;
use vars qw(@EXPORT @ISA);

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(backtest_single backtest_all backtest_multi);

use GT::Portfolio;
use GT::Prices;
use GT::Eval;
use GT::Conf;
use GT::DateTime;
###l4p  use Log::Log4perl qw(:easy);
use GT::Indicators::MaxDrawDown;

=head1 NAME

GT::BackTest - Backtest trading systems in different conditions

=head1 OPTIONS

=over 4

=item Analysis::ReferenceTimeFrame

You can set this configuration item to day, week, month or year. There
will be a standardized performance result based on that timeframe. By
default the value is "year".

=back

=head1 DESCRIPTION

=over

=item C<< backtest_single($pf_man, $sys_man, $broker, $calc, $first, $last, $initial_value) >>

Backtest the a system using the given portfolio manager (ie set of money
management rules) on the data contained by $calc during the period $first
to $last (indices used by the calculator).

=cut

sub backtest_single {
    my ($pf_manager, $sys_manager, $broker, $calc, $first, $last, $initial_value) = @_;
    my $systemname = $sys_manager->get_name;
    my $broker_object;

    if ( $::debug ) {
        print STDERR "\$first=$first, \$last=$last, \$initial_value=$initial_value\n";
    }
    # Create an empty portfolio object and make the manager use it
    my $p = GT::Portfolio->new;
    $pf_manager->set_portfolio($p);
    if ( defined $initial_value ) {
        $p->set_initial_value( $initial_value );
    } else {
        $p->set_initial_value( 10000 );
    }

    # Set up the broker used for cost calculation
    if (defined($broker) && $broker) {
        $broker_object = create_standard_object(
            split (/\s+/, "Brokers::$broker"));
    } else {
        my $broker_module = GT::Conf::get("Brokers::module");
        if (defined($broker_module) && $broker_module) {
            $broker_object = create_standard_object("Brokers::$broker_module");
        }
    }
    if (defined($broker_object) && $broker_object) {
        $p->set_broker($broker_object);
    }

    # Calculate the indicators
    $sys_manager->precalculate_interval($calc, $first, $last);
    # Run the system
    for(my $i = $first; $i <= $last; $i++)
    {

        # Apply the orders available
        $p->apply_pending_orders($calc, $i, $systemname, $pf_manager);

        # Manage the open positions
        foreach my $position ($p->list_open_positions($systemname))
        {
            $p->apply_pending_orders_on_position($position, $calc, $i);
            if ($position->is_open)
            {

                if ( $::debug ) {
                    if ( $position->list_pending_orders() ) {
                        print STDERR "date: ", $calc->prices->at($i)->[$DATE] , " ";
                        print STDERR "tpi: $i: position->list_pending_orders:\n";
                        use Data::Dumper;
                        print STDERR Dumper $position->list_pending_orders();
                        print STDERR "\n";

                    } else {
                        print STDERR "date: ", $calc->prices->at($i)->[$DATE] , " ";
                        print STDERR "tpi: $i: position->list_detailed_orders:\n";
                        use Data::Dumper;
                        print STDERR Dumper $position->list_detailed_orders();
                        print STDERR "\n";
                    }
                }

                $sys_manager->manage_position(
                    $calc, $i, $position, $pf_manager);
            }
        }

        # Store the portfolio evaluation
        $p->store_evaluation($calc->prices->at($i)->[$DATE]);

        # Detect new opportunities
        $sys_manager->apply_system($calc, $i, $pf_manager);

    }

    # Close the open positions
    foreach my $position ($p->list_open_positions($systemname))
    {
        my $close = GT::Portfolio::Order->new;
        if ($position->is_long)
        {
            $close->set_sell_order;
        } else {
            $close->set_buy_order;
        }
        $close->set_quantity($position->quantity);
        $close->set_type_limited;
        $close->set_price($calc->prices->at($last)->[$LAST]);

        $position->add_order($close);
        $p->apply_pending_orders_on_position($position, $calc, $last);
        $p->store_evaluation($calc->prices->at($last)->[$DATE]);
    }

    # Buy & hold
    my $buyhold = 0;
    $buyhold = $calc->prices->at($last)->[$LAST] /
    $calc->prices->at($first)->[$LAST] - 1 if ( $calc->prices->at($first)->[$LAST] != 0);

    # Launch the analysis
    my $re = $p->real_global_analysis();
    $re->{'buyandhold'} = $buyhold;

    # Standardized performance
    GT::Conf::default("Analysis::ReferenceTimeFrame", "year");
    my $tf_name = GT::Conf::get("Analysis::ReferenceTimeFrame");
    my $ref_tf = GT::DateTime::name_to_timeframe($tf_name);
    my $exp = GT::DateTime::timeframe_ratio($ref_tf, $calc->current_timeframe)
    / ($last - $first + 1);

    $re->{'std_buyandhold'} = (($buyhold + 1) ** $exp) - 1;
    $re->{'std_performance'} =  (($re->{'performance'} + 1) ** $exp) - 1;
    $re->{'std_timeframe'} = $tf_name;

    # Complete analysis with some data (first_date and last_date)
    $re->{'first_date'} = $calc->prices->at($first)->[$DATE];
    $re->{'last_date'} = $calc->prices->at($last)->[$DATE];

    my $timeframe = $DAY;
    if (defined($calc->prices->timeframe)) {
        $timeframe = $calc->prices->timeframe;
    }
    $re->{'duration'}
    = ( GT::DateTime::map_date_to_time( $timeframe, $re->{'last_date'} )
        -   GT::DateTime::map_date_to_time( $timeframe, $re->{'first_date'} ) )
    / 31557600;    # in years (specifically in 365 day chunks)


#print STDERR "\$re->{'duration'} == $re->{'duration'}\n";
#print STDERR "\$re->{'last_date'} == $re->{'last_date'}\n";
#print STDERR "\$re->{'first_date'} == $re->{'first_date'}\n";
#use GT::DateTimeNG;
#my = $re_duration = GT::DateTimeNG( duration( $re->{'last_date'}, $re->{'first_date'}, 'year' );
#print STDERR "duration( $l, f, 'year' ) == $re_duration"\n";


    # Calculate Buy & Hold Max Draw Down with our MaxDrawDown Indicator
    my $indicator_maxdd = GT::Indicators::MaxDrawDown->new();
    $indicator_maxdd->calculate($calc, $last);
    my $buyandhold_maxdd = $calc->indicators->get(
        $indicator_maxdd->get_name, $last);
    if (defined($buyandhold_maxdd)) {
        $re->{'buyandhold_max_draw_down'} = $buyandhold_maxdd;
    }

    # Hack to remove code reference in portfolio
    delete $p->{'date2int'};

    my $analysis = {
        "real" => $re,
        "portfolio" => $p,
    };
    return $analysis;
}


sub backtest_multi {
    my ($pf_manager, $sys_manager_ref, $broker_ref, $calc_ref, $long_first, $long_last, $long_code, $init) = @_;
    my @sysmanager = @{$sys_manager_ref};
    my @brokers = @{$broker_ref};
    my @calc = @{$calc_ref};
    $init = 10000 unless ( defined($init) );

    # Create an empty portfolio object and make the manager use it
    my $p = GT::Portfolio->new;
    $pf_manager->set_portfolio($p);
    $p->set_initial_value( $init );

    # Set up the Brokers:
    my @broker_object = ();
    my $cnt = 0;    foreach my $broker ( @brokers ) {
      if (defined($broker) && $broker) {
        $broker_object[$cnt] = create_standard_object(
         split (/\s+/, "Brokers::$broker"));
      } else {
        my $broker_module = GT::Conf::get("Brokers::module");
        if (defined($broker_module) && $broker_module) {
          $broker_object[$cnt] = create_standard_object(
           "Brokers::$broker_module");
        }
      }
      $cnt++;
    }

    # Insert the calc_ojects in the portfolio..
    foreach my $calc ( @calc ) {
      $p->{objects}->{calc}->{$calc->code()} = $calc;
    }

    # Run the system
    for(my $i = $long_first; $i <= $long_last; $i++)  {

      my $date = $calc[$long_code]->prices->at($i)->[$DATE];

      $pf_manager->submit_parked_orders();

      foreach my $j ( 0..$#sysmanager ) {
        my $systemname = $sysmanager[$j]->get_name;

        # Set the right broker
        if (defined($broker_object[$j]) && $broker_object[$j]) {
          $p->set_broker($broker_object[$j]);
        }
        foreach my $calc ( @calc ) {
          next if (!$calc->prices->has_date($date));
          my $ii = $calc->prices->date($date);

          # Apply the orders available
          $p->apply_pending_orders($calc, $ii, $systemname, $pf_manager);

          # Manage the open positions
          foreach my $position ($p->list_open_positions($systemname)) {
            $p->apply_pending_orders_on_position($position, $calc, $ii);
            if ($position->is_open) {
              $sysmanager[$j]->manage_position(
               $calc, $ii, $position, $pf_manager);
            }
          }
          # Store the portfolio evaluation
          $p->store_evaluation($calc->prices->at($ii)->[$DATE]);
        }
      }

      foreach my $j ( 0..$#sysmanager ) {
        my $systemname = $sysmanager[$j]->get_name;
        my $sys_manager = $sysmanager[$j];

        # Try out the signals for all codes
        foreach my $calc ( @calc ) {

          next if (!$calc->prices->has_date($date));
          my $ii = $calc->prices->date($date);

          # Detect new opportunities
          $sys_manager->apply_system_parked($calc, $ii, $pf_manager);

        }
      }

    }


    # Close the open positions
    foreach my $j ( 0..$#sysmanager ) {
      my $systemname = $sysmanager[$j]->get_name;

      foreach my $position ($p->list_open_positions($systemname)) {

        foreach my $calc ( @calc ) {

          next if ($position->code() ne $calc->code());

          my $close = GT::Portfolio::Order->new;
          if ($position->is_long) {
            $close->set_sell_order;
          } else {
            $close->set_buy_order;
          }
          $close->set_quantity($position->quantity);
          $close->set_type_limited;

          my $last_date = $calc->prices->find_nearest_date(
           $calc[$long_code]->prices->at($long_last)->[$DATE] );
          my $last = $calc->prices->date( $last_date );
          $close->set_price($calc->prices->at($last)->[$LAST]);
          $position->add_order($close);
          $p->apply_pending_orders_on_position($position, $calc, $last);
          $p->store_evaluation($calc->prices->at($last)->[$DATE]);

          last;
        }
      }

    }

    # Delete the parked orders
    $pf_manager->delete_parked_orders();

    # Buy & hold
    my $buyhold = 0; #$calc->prices->at($last)->[$LAST] /
                  #$calc->prices->at($first)->[$LAST] - 1;

    # Launch the analysis
    my $re = $p->real_global_analysis();
    my $th = {}; #$p->theoretical_analysis_by_code($calc->code);
    $th->{performance} = 0 if not defined($th->{performance});
    $re->{'buyandhold'} = $buyhold;
    $th->{'buyandhold'} = $buyhold;

#    # Standardized performance
    GT::Conf::default("Analysis::ReferenceTimeFrame", "year");
    my $tf_name = GT::Conf::get("Analysis::ReferenceTimeFrame");
    my $ref_tf = GT::DateTime::name_to_timeframe($tf_name);
    my $exp = GT::DateTime::timeframe_ratio($ref_tf, $calc[0]->current_timeframe)
              / ($long_last - $long_first + 1);

    $re->{'std_buyandhold'} = (($buyhold + 1) ** $exp) - 1;
    $th->{'std_buyandhold'} = (($buyhold + 1) ** $exp) - 1;

    $re->{'std_performance'} =  (($re->{'performance'} + 1) ** $exp) - 1;
    $th->{'std_performance'} =  (($th->{'performance'} + 1) ** $exp) - 1;

    $re->{'std_timeframe'} = $tf_name;
    $th->{'std_timeframe'} = $tf_name;

#    # Complete analysis with some data (first_date and last_date)
    $re->{'first_date'} = $calc[$long_code]->prices->at($long_first)->[$DATE];
    $th->{'first_date'} = $calc[$long_code]->prices->at($long_first)->[$DATE];
    $re->{'last_date'} = $calc[$long_code]->prices->at($long_last)->[$DATE];
    $th->{'last_date'} = $calc[$long_code]->prices->at($long_last)->[$DATE];

# ras hack analysis {'duration'} was missing?
    my $timeframe = $calc[$long_code]->prices->timeframe;
    $re->{'duration'}
     = ( GT::DateTime::map_date_to_time( $timeframe, $re->{'last_date'} )
       - GT::DateTime::map_date_to_time( $timeframe, $re->{'first_date'} ))
       / 31557600;    # in years (specifically in 365 day chunks)

    $th->{'duration'}
     = ( GT::DateTime::map_date_to_time( $timeframe, $th->{'last_date'} )
       - GT::DateTime::map_date_to_time( $timeframe, $th->{'first_date'} ))
       / 31557600;    # in years (specifically in 365 day chunks)


#print STDERR "\$re->{'duration'} == $re->{'duration'}\n";
#print STDERR "\$re->{'last_date'} == $re->{'last_date'}\n";
#print STDERR "\$re->{'first_date'} == $re->{'first_date'}\n";
#use GT::DateTimeNG;
#my = $re_duration = GT::DateTimeNG( duration( $re->{'last_date'}, $re->{'first_date'}, 'year' );
#print STDERR "duration( $l, f, 'year' ) == $re_duration"\n";
#print STDERR "\$th->{'duration'} == $th->{'duration'}\n";
#print STDERR "\$th->{'last_date'} == $th->{'last_date'}\n";
#print STDERR "\$th->{'first_date'} == $th->{'first_date'}\n";
#use GT::DateTimeNG;
#my = $th_duration = GT::DateTimeNG( duration( $th->{'last_date'}, $th->{'first_date'}, 'year' );
#print STDERR "duration( $l, $f, 'year' ) == $th_duration"\n";


    # Calculate Buy & Hold Max Draw Down with our MaxDrawDown Indicator
#    my $indicator_maxdd = GT::Indicators::MaxDrawDown->new();
#    $indicator_maxdd->calculate($calc, $last);
#    my $buyandhold_maxdd = $calc->indicators->get(
#     $indicator_maxdd->get_name, $last);
#    if (defined($buyandhold_maxdd)) {
#       $re->{'buyandhold_max_draw_down'} = $buyandhold_maxdd;
#       $th->{'buyandhold_max_draw_down'} = $buyandhold_maxdd;
#    }
    ### NOTE: Need to assign something to these to avoid undef value in output
    $re->{'buyandhold_max_draw_down'} = 0;
    $th->{'buyandhold_max_draw_down'} = 0;

    # Hack to remove code reference in portfolio
    delete $p->{'date2int'};

    my $analysis = {
        "theoretical" => $th,
        "real" => $re,
        "portfolio" => $p,
    };

    return $analysis;
}


=item C<< GT::BackTest::combinate_system_and_manager(\@systems, \@managers) >>

Returns a hash that can be used by backtest_combinations

=cut
sub combinate_system_and_manager {
    my ($self, $systems, $managers) = @_;

    my $combi = {};
    foreach (@{$systems})
    {
        $combi->{$_->get_name}{"system"} = $_;
        $combi->{$_->get_name}{"managers"} = $managers;
    }
    return $combi;
}

=item C<< GT::BackTest::create_managers_with_filters(\@filters) >>

Create all possible managers with all the possible combinations
of filters.

=cut

sub create_managers_with_filters {

    my $managers = {};

    return $managers;
}

1;
