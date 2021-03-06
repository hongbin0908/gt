package GT::Report;

# Copyright 2000-2002 Rapha�l Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# ras hack based on version dated 24 Apr 2005 with 15599 bytes
# $Id: Report.pm 713 2012-02-20 22:09:44Z ras2010 $
# @change:
#     2013-12-07: add json report format 
use strict;
use JSON;

use GT::Portfolio;
use GT::CacheValues;
use GT::BackTest::Spool;
use GT::Eval;
use GT::Prices;
use GT::DateTime;

# This is not very clean ... should probably find another
# system to let the user redirect the output
*OUT = *STDOUT;

=head1 NAME

GT::Report - Generate visual report of common objects

=head1 DESCRIPTION

This modules provides various functions to dump to GT::Report::OUT
(by default STDOUT) various objects in a nice formatted text.

in the methods below variable $detailed is just a boolean. if
true (perl truth is any string or number except zero) then the
method will switch into detailed mode

=over

=item C<< GT::Report::Portfolio($portfolio, $detailed) >>

Prints the content of a portfolio in text format.

=cut

sub Portfolio {
    my ($p, $detailed) = @_;

    $detailed = 0 if (! defined($detailed));

    if ( ! @{$p->{'history'}} ) {
        print OUT "\nNo History (closed positions) in portfolio\n\n"
        if $detailed;
        print OUT "\n" if ! $detailed;
        return;
    }

    my $db = create_db_object();

    print OUT "History of the portfolio :\n";
    print OUT "--------------------------\n";
    my @gain= ();
    my @loss= ();
    foreach my $position (@{$p->{'history'}})
    {
        if ($position->is_long)
        {
            print OUT "Long position";
        } else {
            print OUT "Short position";
        }
        my $name = $db->get_name($position->code);
        if ($name) {
            print OUT " (" . $position->id .") on $name (" . $position->code . ")";
        } else {
            print OUT " (" . $position->id .") on " . $position->code;
        }
        if ($detailed and $position->source)
        {
            print OUT " coming from " . $position->source;
        }
        print OUT "\n";
        foreach my $order ($position->list_detailed_orders)
        {
            my $text = swrite('  @<<<<<<<<<  @<<< @>>>>>> at @<<<<<<<<<',
                $order->submission_date, 
                $order->is_buy_order ? "Buy" : "Sell",
                $order->quantity,
                sprintf("%.4f", $order->price));
            print OUT "$text\n";
        }
        if ($detailed)
        {
            my $pstats = $position->stats($p);
            my $diff = $pstats->{'sold'} - $pstats->{'bought'} 
            - $pstats->{'cost'};
            my $variation = 0;
            if ($position->is_long) {
                $variation = ($pstats->{'bought'} !=0) ? 
                ($diff / $pstats->{'bought'}) : 0;
            } else {
                $variation = ($pstats->{'sold'} !=0) ? 
                ($diff / $pstats->{'sold'}) : 0;
            }

            my $text = swrite('Result: @<<<<<< => @<<<<<<<',
                sprintf("%.2f%%", $variation * 100),
                sprintf("%.0f", $diff));
            print OUT "$text\n\n";
        }
    }
    $^A = "";

}

=item C<< GT::Report::PortfolioShort($portfolio) >>

	Prints the content of a portfolio in concise textual format.

=cut

sub PortfolioShort {
    my ($p) = @_;

    my $db = create_db_object();
    
    foreach my $position (@{$p->{'history'}}) {
      foreach my $order ($position->list_detailed_orders) {
       my $text = swrite('@<<<<<<<<<  @<<< @>>>>>> at @<<<<<<<<<',
                         $order->submission_date, 
                         $order->is_buy_order ? "Buy" : "Sell",
                         $order->quantity,
                         sprintf("%.4f", $order->price));
       print OUT "$text\n";
      }
    $^A = "";
    }
}

=item C<< GT::Report::PortfolioHTML($portfolio, $detailed) >>

Prints the content of a portfolio in HTML format.

=cut

sub PortfolioHTML {
    my ($p, $detailed) = @_;

    $detailed = 0 if (! defined($detailed));
    
    my $db = create_db_object();
    
    print OUT "<h2>History of the portfolio</h2>\n";
    print OUT "<table border='1' cellpadding='5' cellspacing='0'>\n";
    print OUT "<tr><th>Trade #</th><th>Code</th><th>Type</th>";
    if ($detailed) {
    	print OUT "<th>Source</th>";
    }
    print OUT "<th>Shares</th><th>Entry Date</th><th>Entry Price</th><th>Exit Date</th><th>Exit Price</th><th>Return</th><th>Duration</th></tr>\n";
    foreach my $position (@{$p->{'history'}})
    {
	my $pstats = $position->stats($p);
	my $diff = $pstats->{'sold'} - $pstats->{'bought'} 
	    	- $pstats->{'cost'};
	my $variation = 0;
	if ($position->is_long) {
	    $variation = ($pstats->{'bought'} !=0) ? 
                    ($diff / $pstats->{'bought'}) : 0;
	} else {
	    $variation = ($pstats->{'sold'} !=0) ? 
	    	($diff / $pstats->{'sold'}) : 0;
	}
	my $bg = ($variation > 0 ) ? "bgcolor='#55FF55'" : "bgcolor='#FF5555'";
	print OUT "<tr><td $bg>" . $position->id . "</td>";
	my $name = $db->get_name($position->code);
	if ($name) {
	    print OUT "<td $bg>" . $name . " - " . $position->code . "</td>";
	} else {
	    print OUT "<td $bg>" . $position->code . "</td>";
	}
	if ($position->is_long)
	{
	    print OUT "<td $bg>Long</td>";
	} else {
	    print OUT "<td $bg>Short</td>";
	}
	if ($detailed)
	{
	    print OUT "<td $bg>" . $position->source . "</td>";
	}
	my $n = 0;
	my ($start_date, $start_price, $end_date, $end_price);
	foreach my $order ($position->list_detailed_orders)
	{
	   if ($n == 0)
	   {
		print OUT "<td $bg>" . $order->quantity . "</td>";
		$start_date = $order->submission_date;
		$start_price = $order->price;
	   }
	   else
	   {
		$end_date = $order->submission_date;
		$end_price = $order->price;
	   }
	   $n++;
	}
	my $timeframe = $DAY;
	if (defined($position->timeframe)) {
	    $timeframe = $position->timeframe;
	}
#	my $duration = ( GT::DateTime::map_date_to_time($timeframe, $end_date)
#         - GT::DateTime::map_date_to_time($timeframe, $start_date) ) / 86400;
        my $duration;
        if ( $timeframe < $DAY ) {
            $duration = ( GT::DateTime::map_date_to_time($timeframe, $end_date)
             - GT::DateTime::map_date_to_time($timeframe, $start_date) )
             / GT::DateTime::secs_in_timeframe($timeframe);
        }
        else {
            $duration = ( GT::DateTime::map_date_to_time($timeframe, $end_date)
             - GT::DateTime::map_date_to_time($timeframe, $start_date) ) / 86400;
        }
        $duration = safe_sprintf( "%.4f", $duration );

#print STDERR "-->> we know results are seconds so to get seconds from timeframe\n",
#print STDERR "demominator ", GT::DateTime::secs_in_timeframe($timeframe), "\n";
#print STDERR $duration / GT::DateTime::secs_in_timeframe($timeframe), "\n";

#print STDERR "\$duration == $duration\n";
#print STDERR "\$end_date == $end_date\n";
#print STDERR "\$start_date == $start_date\n";
#use GT::DateTimeNG;
#my = $durationng = GT::DateTimeNG( duration( $end_date, $start_date, 'day' );
#print STDERR "duration( $e, $s, 'year' ) == $durationng"\n";

	
        printf OUT ("<td $bg>%s</td><td $bg>%.4f</td>", $start_date, $start_price);
        printf OUT ("<td $bg>%s</td><td $bg>%.4f</td>", $end_date, $end_price);
	printf OUT ("<td $bg>%.2f%%</td>", $variation * 100);
	printf OUT ("<td $bg>%s</td>", $duration);
	print OUT "</tr>\n";
    }
    print OUT "</table>\n";
}

=item C<< GT::Report::OpenPositions($portfolio, $detailed) >>

Display the list of open positions.

=cut

sub OpenPositions {
    my ($p, $detailed) = @_;
    my $db = create_db_object();
    foreach my $position ($p->list_open_positions) {
	if ($position->is_long)
	{
	    print OUT "Long position";
	} else {
	    print OUT "Short position";
	}
	my $name = $db->get_name($position->code);
	if ($name) {
	    print OUT " (" . $position->id .") on $name (" . $position->code . ")";
	} else {
	    print OUT " (" . $position->id .") on " . $position->code;
	}
	if ($detailed and $position->source)
	{
	    print OUT " coming from " . $position->source;
	}
	print OUT "\n";
	foreach my $order ($position->list_detailed_orders)
	{
	    my $text = swrite('  @<<<<<<<<<  @<<< @>>>>>> at @<<<<<<<<<',
			$order->submission_date, 
			$order->is_buy_order ? "Buy" : "Sell",
			$order->quantity,
			sprintf("%.4f", $order->price));
	    print OUT "$text\n";
	}
	my $pstats = $position->stats($p);
	my $sstats = { %{$pstats} };
	my $prices;
	if (! $db->has_code($position->code)) {
	    print "Code not available in database. No calculations done.\n\n";
	    next;
	}
	eval {
	    $prices = $db->get_last_prices($position->code, 1);
	};
	if ($@) {
	    print "Error while retrieving prices. No calculations done.\n\n";
	    next;
	}
	my $order = GT::Portfolio::Order->new();
	$order->set_quantity($position->quantity);
	$order->set_type_limited();
	$order->set_price($prices->at($prices->count() - 1)->[$CLOSE]);
	if ($position->is_long) {
	    $order->set_sell_order;
	    $pstats->{'sold'} += $position->quantity * $order->price;
	    $sstats->{'sold'} += $position->quantity * $position->stop if defined($position->stop);
	} else {
	    $order->set_buy_order;
	    $pstats->{'bought'} += $position->quantity * $order->price;
	    $sstats->{'bought'} += $position->quantity * $position->stop if defined($position->stop);
	}
	$pstats->{'costs'} += $p->get_order_cost($order);
	$sstats->{'costs'} = $pstats->{'costs'};
	my $diff = $pstats->{'sold'} - $pstats->{'bought'} - $pstats->{'cost'};
	my $diff2 = $sstats->{'sold'} - $sstats->{'bought'} - $sstats->{'cost'};
	my $variation = 0;
	my $variation2 = 0;
	if ($position->is_long) {
	    $variation = ($pstats->{'bought'} !=0) ? ($diff / $pstats->{'bought'}) : 0;
	    $variation2 = ($sstats->{'bought'} !=0) ? ($diff2 / $sstats->{'bought'}) : 0;
	} else {
	    $variation = ($pstats->{'sold'} !=0) ? ($diff / $pstats->{'sold'}) : 0;
	    $variation2 = ($sstats->{'sold'} !=0) ? ($diff2 / $sstats->{'sold'}) : 0;
	}

	my $text;
	$text = swrite('Current: @<<<<<< (@<<<<<< => @<<<<<<<)',
			    sprintf("%.2f", $order->price),
			    sprintf("%.2f%%", $variation * 100),
			    sprintf("%.0f", $diff));
	if (defined($position->stop)) { 
	    $text .= swrite('  Stop: @<<<<<< (@<<<<<< => @<<<<<<<)',
			    sprintf("%.2f", $position->stop),
			    sprintf("%.2f%%", $variation2 * 100),
			    sprintf("%.0f", $diff2));
	} else {
	    $text .= '  Stop: none';
	}
	print OUT "$text\n\n";
    }
    $^A = "";
}

=item C<< GT::Report::safe_sprintf($format, $value) >>

Checks value is not a NaN, then calls sprintf.

=cut

sub safe_sprintf {
	my ($format, $value) = @_;

        $value = 'NaN' if ( ! defined($value) );
	if ($value =~ /^NaN$/i || $value =~ /^NaNQ$/i) {
		sprintf("%s", $value);
	} else {
		sprintf($format, $value);
	}
}

=item C<< GT::Report::PortfolioAnalysis($analysis, $detailed) >>

Pretty prints the results of the analysis of the portfolio.

nb -- first argument is $analysis, not a $portfolio. for an
example in code see sub backtest_single in ../GT/BackTest.pm,
sub real_global_analysis, sub real_analysis_by_code and
sub new_analysis all in ../GT/Portfolio.pm.

=cut

sub PortfolioAnalysis {
    my ($a, $detailed) = @_;

    $detailed = 0 if (! defined($detailed));

    if ( ! $a->{'first_date'} ) {
       $a->{'first_date'} = "1984-01-01";
       print OUT "no 'first_date' found, set to $a->{'first_date'}\n"
        if ( $detailed );
    }
    if ( ! $a->{'last_date'} ) {
       my ($sec, $min, $hour, $d, $m, $y, $wd, $yd) = localtime();
       $a->{'last_date'} = sprintf("%04d-%02d-%02d", $y+1900, $m+1, $d);
       print OUT "no 'last_date' found, set to $a->{'last_date'}\n"
        if ( $detailed );
    }
    print OUT "Analysis of the portfolio (" .
    $a->{'first_date'} . " / " . $a->{'last_date'} . ")\n";
    print OUT "-----------------------------------------------------\n";
    my $format =
'Performance : @>>>>> (@>>>>>)	  Buy & Hold : @>>>>> (@>>>>>) () => by @<<<<<<<
MaxDrawDown :      @>>>>>  B&H MaxDrawDown :   @>>>>>
Best performance : @>>>>>  Worst performance : @>>>>>
Net gain : @>>>>>>>>>>>>>  Gross gain :@>>>>>>>>>>>>>

Trades statistics
Number of trades : @>>>>>  Trades/Year : @>>>>>>>>>>>
Number of gains : @>>>>>>  Number of losses : @>>>>>>  Win. ratio : @>>>>>>
Max consec. win : @>>>>>>  Max consec. loss : @>>>>>>  Expectancy : @>>>>>>
Average gain : @>>>>>>>>>  Average loss : @>>>>>>>>>>  Avg. perf  : @>>>>>>
Biggest gain : @>>>>>>>>>  Biggest loss : @>>>>>>>>>>  Profit fac : @>>>>>>
Sum of gains : @>>>>>>>>>  Sum of losses : @>>>>>>>>>  Risk of ruin : @>>>>
';
    my $text = swrite($format, 
                ($a->{'performance'} > 10)
                 ? safe_sprintf("%.0f%%", $a->{'performance'} * 100)
                 : safe_sprintf("%.1f%%", $a->{'performance'} * 100),
                safe_sprintf("%.1f%%", $a->{'std_performance'} * 100),
                safe_sprintf("%.1f%%", $a->{'buyandhold'} * 100),
                safe_sprintf("%.1f%%", $a->{'std_buyandhold'} * 100),
                 $a->{'std_timeframe'},
                safe_sprintf("%.1f%%", $a->{'max_draw_down'} * 100),
                safe_sprintf("%.1f%%", $a->{'buyandhold_max_draw_down'}),
                 ($a->{'max_performance'} > 10)
                  ? safe_sprintf("%.0f%%", $a->{'max_performance'} * 100)
                  : safe_sprintf("%.1f%%", $a->{'max_performance'} * 100),
                safe_sprintf("%.1f%%", $a->{'min_performance'} * 100),
                safe_sprintf("%.2f", $a->{'global_gain'}),
                safe_sprintf("%.2f", $a->{'gross_gain'}),
                $a->{'nb_gain'} + $a->{'nb_loss'},
                ($a->{'duration'} != 0)
                 ? safe_sprintf("%.2f", ($a->{'nb_gain'} + $a->{'nb_loss'})
                  / $a->{'duration'})
                 : safe_sprintf("%.2f", ($a->{'nb_gain'} + $a->{'nb_loss'})),
                $a->{'nb_gain'},
                $a->{'nb_loss'},
                safe_sprintf("%.1f%%", $a->{'win_loss_ratio'} * 100),
                $a->{'max_consecutive_winner'},
                $a->{'max_consecutive_loser'},
                safe_sprintf("%.2f", $a->{'expectancy'}),
                safe_sprintf("%.2f%%", $a->{'average_gain'} * 100),
                safe_sprintf("%.2f%%", $a->{'average_loss'} * 100),
                safe_sprintf("%.2f%%", $a->{'average_performance'} * 100),
                safe_sprintf("%.2f%%", $a->{'biggest_gain'} * 100),
                safe_sprintf("%.2f%%", $a->{'biggest_loss'} * 100),
                safe_sprintf("%.2f", $a->{'profit_factor'}),
                safe_sprintf("%.2f", $a->{'sum_of_gain'}),
                safe_sprintf("%.2f", $a->{'sum_of_loss'}),
                safe_sprintf("%.1f%%", $a->{'risk_of_ruin'} * 100)
               );

    print OUT $text;

    if ($detailed) {
        $format =
'
Corresponding dates
MaxDrawDown  : @<<<<<<<<<  Best perf    : @<<<<<<<<<  Worst perf : @<<<<<<<<<
Biggest gain : @<<<<<<<<<  Biggest loss : @<<<<<<<<<
Max consec. win : @<<<<<<<<<  Max consec. loss : @<<<<<<<<<
';
        $text = swrite($format,
                 $a->{'max_draw_down_date'},
                 $a->{'max_performance_date'},
                 $a->{'min_performance_date'},
                 $a->{'biggest_gain_date'},
                 $a->{'biggest_loss_date'},
                 $a->{'max_consecutive_winner_date'},
                 $a->{'max_consecutive_loser_date'},
                );
        print OUT $text;
    }
    $^A = "";
}

=item C<< GT::Report::PortfolioJson($analysis, $detailed) >>

Json prints the results of the analysis of the portfolio.

=cut

sub PortfolioJson {
    my ($a, $detailed, $outfile) = @_;
	print "outfile:" . $outfile;
    $detailed = 0 if (! defined($detailed));

    if ( ! $a->{'first_date'} ) {
       $a->{'first_date'} = "1984-01-01";
       print OUT "no 'first_date' found, set to $a->{'first_date'}\n"
        if ( $detailed );
    }
    if ( ! $a->{'last_date'} ) {
       my ($sec, $min, $hour, $d, $m, $y, $wd, $yd) = localtime();
       $a->{'last_date'} = sprintf("%04d-%02d-%02d", $y+1900, $m+1, $d);
       print OUT "no 'last_date' found, set to $a->{'last_date'}\n"
        if ( $detailed );
    }
    print OUT "Analysis of the portfolio (" .
    $a->{'first_date'} . " / " . $a->{'last_date'} . ")\n";
    print OUT "-----------------------------------------------------\n";
	my $jout=();
	$jout->{"performance"} = $a->{'performance'};           #performance
	$jout->{"std_performance"} = $a->{'std_performance'};   #performance by year
	$jout->{"buyandhold"} = $a->{'buyandhold'};             #Buy & Hold
	$jout->{"std_buyandhold"} = $a->{'std_buyandhold'};     #Buy & Hold by year
	$jout->{"max_draw_down"} = $a->{'max_draw_down'};       # Max draw Down
	$jout->{"buyandhold_max_draw_down"} = $a->{'buyandhold_max_draw_down'}; # B&H Max Draw Down
	$jout->{'max_performance'} = $a->{'max_performance'};   # Best performance
    $jout->{'min_performance'} = $a->{'min_performance'};   # Worst performance
    $jout->{'global_gain'} = $a->{'global_gain'};           # Net Gain
    $jout->{'gross_gain'} = $a->{'gross_gain'};             # Gross Gain
    $jout->{'number_of_trades'} = $a->{'nb_gain'} + $a->{'nb_loss'};          # Number of trades
	$jout->{'number_per_year'} =  ($a->{'duration'} != 0)
                 ? (($a->{'nb_gain'} + $a->{'nb_loss'})
                  / $a->{'duration'})
                 : ($a->{'nb_gain'} + $a->{'nb_loss'});                                                                                 #Trades/Year
	$jout->{'nb_gain'} = $a->{'nb_gain'};                  # num of gains
    $jout->{'nb_loss'} = $a->{'nb_loss'};                  # num of losses
	$jout->{'win_loss_ratio'} = $a->{'win_loss_ratio'};    #Win. ratio
    $jout->{'max_consecutive_winner'} = $a->{'max_consecutive_winner'}; # Max consec. win
	$jout->{'max_consecutive_loser'} = $a->{'max_consecutive_loser'};   # Max consec. loss
	$jout->{'expectancy'} = $a->{'expectancy'};            # Ecpectancy
    $jout->{'average_gain'} = $a->{'average_gain'};        # Average gain
    $jout->{'average_loss'} = $a->{'average_loss'};        # Average loss
    $jout->{'average_performance'} =  $a->{'average_performance'};      # Avg. perf
    $jout->{'biggest_gain'} =  $a->{'biggest_gain'};       # Biggest gain
    $jout->{'biggest_loss'} = $a->{'biggest_loss'};        # Biggest loss
	$jout->{'profit_factor'} = $a->{'profit_factor'};
    $jout->{'sum_of_gain'} = $a->{'sum_of_gain'};
    $jout->{'sum_of_loss'} = $a->{'sum_of_loss'};
    $jout->{'risk_of_ruin'} = $a->{'risk_of_ruin'};
    $^A = "";
	return  encode_json($jout);
}

=item C<< GT::Report::AnalysisList >>

Display the results of the backtest. Results per code and per system.

=cut

#=============================================
# previously sub _get_name was defined inside sub AnalysisList
sub _get_name {
    my ($spool, $name) = @_;
    my $res = $spool->get_alias_name($name);
    return $res if (defined($res) && $res);
    return $name;
}
#=============================================

sub AnalysisList {
    my ($spool, $set) = @_;

    my $l = $spool->list_available_data($set);
    my $s = $spool;
    
    # Find all codes
    my %codes;
    foreach (keys %{$l})
    {
	foreach my $code (@{$l->{$_}})
	{
	    $codes{$code} = 1;
	}
    }
    
    # $spool->get_stats($sysname, $code) returns an array
    # [0] std_perf
    # [1] perf
    # [2] max draw down
    # [3] std_buyandhold
    # [4] buyandhold
   
    my $db = create_db_object();
    my ($nb_gain, $nb_loss, $mean, $buyhold);
    # Analysis by code
    foreach my $code (sort keys %codes)
    {
	$nb_gain = $nb_loss = 0; $mean = 1; $buyhold = 0;
	my @systems = sort { 
		    ($s->get_stats($b,$code)->[0] <=>
		     $s->get_stats($a,$code)->[0]) ||
		    ($s->get_stats($b,$code)->[1] <=>
		     $s->get_stats($a,$code)->[1])
		    }
		    grep { 
			defined($s->get_stats($_,$code))
		    } keys %{$l};
	next if (! scalar @systems);
	my $name = $db->get_name($code);
	if ($name ne $code) {
	    print OUT "Results of systems for $name ($code) :\n";
	} else {
	    print OUT "Results of systems for $code :\n";
	}
	foreach (@systems)
	{
	    my $ana = $s->get_stats($_, $code);

	    $buyhold = $ana->[3];
	    if ($ana->[0] > 0) { $nb_gain++ } else { $nb_loss++ };
	    $mean *= (1 + $ana->[0]);
	    my $text = swrite("@>>>>> @>>>>> [@>>>>>]",
		sprintf("%.1f%%", $ana->[0] * 100),
		sprintf("%.1f%%", $ana->[1] * 100),
		sprintf("%.1f%%", $ana->[2] * 100)
	    );
	    print OUT "$text " . _get_name($s, $_) . "\n";
	}
	next if ($nb_loss + $nb_gain == 0);
	$mean = $mean ** (1 / ($nb_loss + $nb_gain));
	printf OUT "Global results : %d gain(s) and %d loss(es), average " .
		   "%.1f%%", $nb_gain, $nb_loss, ($mean - 1) * 100;
	printf OUT ", buy&hold %.1f%%\n\n", $buyhold * 100;
    }

    # Analysis by system
    foreach my $sys (sort keys %{$l})
    {
	$nb_gain = $nb_loss = 0; $mean = 1; $buyhold = 1;
	my @codes = sort { ($s->get_stats($sys,$b)->[0] <=> 
			    $s->get_stats($sys,$a)->[0]) || 
			   ($s->get_stats($sys,$b)->[1] <=> 
			    $s->get_stats($sys,$a)->[1])
		      }
		 grep { defined($s->get_stats($sys,$_))
		      } 
		 @{$l->{$sys}};
	next if (! scalar @codes);
	print OUT "Results for system ";
	print OUT _get_name($s, $sys) . " :\n";
	foreach (@codes)
	{
	    my $ana = $s->get_stats($sys, $_);
	    if ($ana->[0] > 0) { $nb_gain++ } else { $nb_loss++ };
	    $mean *= (1 + $ana->[0]);
	    $buyhold *= (1 + $ana->[3]);
	    my $text = swrite("@>>>>> @>>>>> [@>>>>>]",
		sprintf("%.1f%%", $ana->[0] * 100),
		sprintf("%.1f%%", $ana->[1] * 100),
		sprintf("%.1f%%", $ana->[2] * 100)
	    );
	    my $name = $db->get_name($_);
	    if ($name ne $_) {
		print OUT "$text $name ($_)\n";
	    } else {
		print OUT "$text $_\n";
	    }
	}
	next if ($nb_loss + $nb_gain == 0);
	$mean = $mean ** (1 / ($nb_loss + $nb_gain));
	$buyhold = $buyhold ** (1 / ($nb_loss + $nb_gain));
	printf OUT "Global results : %d gain(s) and %d loss(es), average " .
		   "%.1f%%", $nb_gain, $nb_loss, ($mean - 1) * 100;
	printf OUT ", avg. buy&hold %.1f%%\n\n", ($buyhold - 1) * 100;
    }
    $^A = "";
}

=item C<< GT::Report::SimplePortfolioAnalysis >>

Pretty prints only the main results of the analysis.

=cut

sub SimplePortfolioAnalysis {
    my ($a) = shift;

    my $format = 'Performance : @>>>>>  MaxDrawDown : @>>>>>';

    my $text = swrite($format,
		    sprintf("%.1f%%", $a->{'performance'} * 100),
		    sprintf("%.1f%%", $a->{'max_draw_down'} * 100) );

    print OUT $text;
    $^A = "";
}

=item C<< GT::Report::CacheValues >>

Prints a summary of the content of the cache.

=back

=cut

sub CacheValues {
    my ($cache) = @_;

    # Print statistics of available computed data for each
    # "name"
}

sub swrite {
    my $format = shift;
    $^A = "";
    formline($format,@_);
    return $^A;
}

1;
