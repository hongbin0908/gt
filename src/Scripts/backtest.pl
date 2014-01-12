#!/usr/bin/env perl
#
#!/bin/sh -- # perl, to stop looping
# the following must be on two lines
eval 'exec perl -S $0 ${1+"$@"}'
 if 0;

#!/usr/bin/perl -w

# Copyright 2000-2002 Rapha�l Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use lib '..';

use strict;
use vars qw($db);

use GT::Prices;
use GT::Portfolio;
use GT::PortfolioManager;
use GT::Calculator;
use GT::Report;
use GT::BackTest;
use GT::Eval;
use GT::Conf;
use GT::DateTime;
use GT::Tools qw(:conf :timeframe);
use GT::Graphics::DataSource;
use GT::Graphics::Driver;
use GT::Graphics::Object;
use GT::Graphics::Graphic;
use GT::Graphics::Tools qw(:axis :color);

# perl prerequisites
use GD;
use Pod::Usage;
use Getopt::Long;

use Data::Dumper;

=head1 ./backtest.pl [ options ] <code>

=head1 ./backtest.pl [ options ] <system_alias> <code>

=head1 ./backtest.pl [ options ] "<full_system_name>" <code>

=head2 Description

Backtest will run a backtest of a system on the indicated code.

You can either describe the system using options, give a full system
name, or you can give a system alias. An alias is defined in the 
configuration file with entries of the form 
 Aliases::Global::<alias_name> <full_system_name>. 

The full system name consists of a set of properties, such as trade 
filters, close strategy, etc., together with their parameters, 
separated by vertical bars ("|"). Multiple properties of the same 
type can be defined, e.g., there could be a set of close strategies.
For example,
  System:ADX 30 | TradeFilters:Trend 2 5 | MoneyManagement:Normal 
defines a system based on the "ADX" system, using a trend following trade
filter "Trend", and the "Normal" money management.

The following abbreviations are supported:
Systems = SY
CloseStrategy = CS
TradeFilters = TF
MoneyManagement = MM
OrderFactory = OF
Signals = S
Indicators = I
Generic = G

Another example of a full system name is 
  SY:TFS|CS:SY:TFS|CS:Stop:Fixed 4|MM:VAR.

=head2 Options

Backtest provide a set of options, so that you can use a combination
of MoneyManagement, TradeFilters, OrderFactory an CloseStrategy modules.

=over 4

=item --full, --start=<date>, --end=<date>, --nb-item=<nr>

Determines the time interval over which to perform the backtest. In detail:

=over

=item --start=2001-1-10, --end=2002-11-17

The start and end dates over which to perform the backtest.
The date needs to be in the
format configured in ~/.gt/options and must match the timeframe selected. 

=item --nb-items=100

The number of periods to use in the analysis.

=item --full

Consider all available periods.

=back

The periods considered are relative to the selected time frame (i.e., if timeframe
is "day", these indicate a date; if timeframe is "week", these indicate a week;
etc.). In GT format, use "YYYY-MM-DD" or "YYYY-MM-DD hh:mm:ss" for days (the
latter giving intraday data), "YYYY-WW" for weeks, "YYYY/MM" for months, and 
"YYYY" for years.

The interval of periods examined is determined as follows:

=over

=item 1 if present, use --start and --end (otherwise default to last price)

=item 1 use --nb-item (from first or last, whichever has been determined), 
if present

=item 1 if --full is present, use first or last price, whichever has not yet been determined

=item 1 otherwise, consider a two year interval.

=back

The first period determined following this procedure is chosen. If additional
options are given, these are ignored (e.g., if --start, --end, --full are given,
--full is ignored).

=item --timeframe=1min|5min|10min|15min|30min|hour|3hour|day|week|month|year

The timeframe can be any of the available modules in GT/DateTime.  

=item --max-loaded-items

Determines the number of periods (back from the last period) that are loaded
for a given market from the data base. Care should be taken to ensure that
these are consistent with the performed analysis. If not enough data is
loaded to satisfy dependencies, for example, correct results cannot be obtained.
This option is effective only for certain data base modules and ignored otherwise.

=item --template="backtest.mpl"

Output is generated using the indicated HTML::Mason component.
For Example, --template="backtest.mpl"
The template directory is defined as Template::directory in the options file.
Each template can be predefined by including it into the options file
For example, Template::backtest backtest.mpl

=item --html

Output is generated in html

=item --graph="filename.png"

Generate a graph of your portfolio value over the time of the backtest and
display it in the generated html.

=item --display-trades

Display the trades with little symbols on the graph. This works well if
trades last long enough otherwise your graph will be overwhelmed with
unsignificant symbols.

=item --store="portfolio.xml"

Store the resulting portfolio in the indicated file.

=item --iv="<investment amount>" or --initial_value

set the investment amount for the backtest analysis -- default is 10000.
can also be set using the config option "Backtest::initial_value" which
will is be loaded from $HOME/.gt/options if present.

=item --broker="NoCosts"

Calculate commissions and annual account charge, if applicable, using
GT::Brokers::<broker_name> as broker.

=item --system="<system_name>"

use the GT::Systems::<system_name> as the source of buy/sell orders.  

=item --money-management="<money_management_name>" 

use the GT::MoneyManagement::<money_management_name> as money management system.

=item --trade-filter="<filter_name>"

use the GT::TradeFilters::<filter_name> as a trade filter.  

=item --order-factory="<order_factory_name>" 

use GT::OrderFactory::<order_factory_name> as an order factory.  

=item --close-strategy="<close_strategy_name>" 

use GT::CloseStrategy::<close_strategy_name> as a close strategy.

=item --set=SETNAME

Stores the backtest results in the "backtests" directory (refer to your options file for the location of this directory) using the set name SETNAME. Use the --set option of analyze_backtest.pl to differentiate between the different backtest results in your directory.

=item --output-directory=DIRNAME

Override the "backtests" directory in the options file.

=item --verbose

for a more noisy run or debug, multiples increase the verbosity level.

=item --options=<key>=<value>

A configuration option (typically given in the options file) in the
form of a key=value pair. For example,
 --option=DB::Text::format=0
sets the format used to parse markets via the DB::Text module to 0.

=back

=head2 Examples

=over 4

=item

./backtest.pl TFS 13000

=item

./backtest.pl --full TFS 13000

=item

./backtest.pl --close-strategy="Systems::TFS" --close-strategy="Stop::Fixed 6" --money-management="VAR" --money-management="OrderSizeLimit" --system="TFS" --broker="SelfTrade Int�gral" 13000

=item

./backtest.pl --broker="SelfTrade Int��gral" "SY:TFS|CS:SY:TFS|CS:Stop:Fixed 6|MM:VAR|MM:OrderSizeLimit" 13000

=back

=cut


( our $prog_name = $0 ) =~ s@^.*/@@;    # lets identify ourself

GT::Conf::load();
GT::Conf::default("BT::Graphic::Grid::Color", "[220,220,220]");
my $outputdir = GT::Conf::get("BackTest::Directory") || '';
my $set = '';

# Manage options
our $verbose = 0;
our $debug = 0;

my ($full, $html, $display_trades) =
   (0,     0,     0);
my ($template, $graph_file, $ofname, $broker, $system, $timeframe) =
   ('',        '',          '',      '',      '',      'day');
my ($start, $end, $store_file) =
   ('',     '',   '');
my (@mmname, @tfname, @csname) =
  ( (),      (),      () );

my ($nb_item, $max_loaded_items) = (0, -1);

my $initial_value = 0;    # alter using command line option --initial_value
                          # or the config option Backtest::initial_value
my @options;
my $man = 0;

GetOptions(
            'full!'                 => \$full,
            'verbose+'              => \$verbose,
            'html!'                 => \$html,
            'template=s'            => \$template,
            "store=s"               => \$store_file,
            'sy|system=s'           => \$system,
            'mm|moneymanagement|money-management=s'  => \@mmname,
            'tf|tradefilter|trade-filter=s'          => \@tfname,
            'of|orderfactory|order-factory=s'        => \$ofname,
            'cs|closestrategy|close-strategy=s'      => \@csname,
            'dt|displaytrades|display-trades!'       => \$display_trades,
            'iv|initial_value|initial-value=s'       => \$initial_value,
            'broker=s'              => \$broker,
            "timeframe=s"           => \$timeframe,
            'start=s'               => \$start,
            'end=s'                 => \$end,
            'graph=s'               => \$graph_file,
            "max-loaded-items=i"    => \$max_loaded_items,
            "option=s"              => \@options,
            "help|man|?!"           => \$man,
            'od|output-directory=s' => \$outputdir,
            'set=s'                 => \$set,
            'nb-item=i'             => \$nb_item,
            # 'tight!' => \$tight,
           );

if ( $#ARGV <= -1 ) {
  usage();
  exit 0;
}

if ( $verbose >= 3 ) {
    $verbose = 0;
    ++$debug;
}


#warn "verbose is $verbose\n";
#warn "debug is $debug\n";


foreach (@options) {
    my ($key, $value) = split (/=/, $_);
    GT::Conf::set($key, $value);
}

#pod2usage( -verbose => 1 ) if $man;
pod2usage( -verbose => 2 ) if $man;

if ( $outputdir && ! -d $outputdir ) {
  die "The directory '$outputdir' doesn't exist !\n";
} else {
  print "using . for output files\n" if $verbose || $debug;
}


# Create the entire framework
my $db = create_db_object();
my $pf_manager = GT::PortfolioManager->new;
my $sys_manager = GT::SystemManager->new;
my $sysname;
if ( $initial_value == 0 ) {
    $initial_value = GT::Conf::get('Backtest::initial_value')
     ? GT::Conf::get('Backtest::initial_value')
     : 10000;
}


unless ( $system || $#ARGV == 1 ) {
    warn "You must give a system or system alias argument!\n";
    usage();
    exit 0;
}

if ( $system ) {
    $sys_manager->set_system(
     create_standard_object(split (/\s+/, "Systems::$system")));
} else {

#GT::Conf::conf_dump;

    my $alias = shift;
    if (! defined($alias)) {
        if ( $#ARGV < 0 ) {
          usage();
          exit 0;
        }
        my $msg = "You must either specify a system via the --system parameter\n"
         . " or list an alias name on the command line.\n";
        die "$msg";
    }

    if ($alias !~ /\|/) {
        $sysname = resolve_alias($alias);
        die "Alias unknown '$alias'" if (! $sysname);
        $sys_manager->set_alias_name($alias);
    } else {
        $sysname = $alias;
    }

    if (defined($sysname) && $sysname) {
        $sys_manager->setup_from_name($sysname);
        $pf_manager->setup_from_name($sysname);
    } else {
        die "You must give either a --system argument or an alias name.";
    }
}

foreach (@mmname)
{
    $pf_manager->add_money_management_rule(
	create_standard_object(split (/\s+/, "MoneyManagement::$_")));
}
my $mmbasic_added = $pf_manager->default_money_management_rule(
 create_standard_object("MoneyManagement::Basic"));
warn "$prog_name: warning: added mm::basic to system\n"
 if $mmbasic_added && ( $verbose || $debug );

$pf_manager->default_money_management_rule(
	create_standard_object("MoneyManagement::Basic"));
warn "$prog_name: warning: added mm::basic to system\n"
 if $mmbasic_added && ( $verbose || $debug );

if ($ofname)
{
    $sys_manager->set_order_factory(
	create_standard_object(split (/\s+/, "OrderFactory::$ofname")));
} else {
    my $of = $sys_manager->set_order_factory();
    if ( ! defined $of && ( $verbose || $debug ) ) {
    my $msg = join "", "$prog_name: notice: ",
     "without explicit orderfactory the implicit default is\n",
     "OF::MarketPrice. ",
     "this equates to market open price day after the order.",
     "\n";
    warn "$msg";
    }
}

foreach (@tfname)
{
    $sys_manager->add_trade_filter(
	create_standard_object(split (/\s+/, "TradeFilters::$_")));
}
foreach (@csname)
{
    $sys_manager->add_position_manager(
	create_standard_object(split (/\s+/, "CloseStrategy::$_")));
}

# Prepare data
my $code = shift;
if (! $code) {
    die "You must give a symbol for the simulation.\n";
}

if ( $timeframe ) {
    $timeframe = GT::DateTime::name_to_timeframe($timeframe);
}

# Verify dates and adjust to timeframe, comment out if not desired
check_dates($timeframe, $start, $end);

my ($calc, $first, $last) = find_calculator($db, $code, $timeframe, $full, $start, $end, $nb_item, $max_loaded_items);

$pf_manager->finalize;
$sys_manager->finalize;


# The real work happens here
my $analysis = backtest_single(
 $pf_manager, $sys_manager, $broker, $calc, $first, $last, $initial_value);

if ($store_file) {
    $analysis->{'portfolio'}->store($store_file);
} else {
    $analysis->{'portfolio'}->store("./bt_portfolio.xml");
}


if ($graph_file) {
    # create graph for backtested portfolio
    my $graph_ds = GT::Graphics::DataSource::PortfolioEvaluation->new($calc, $analysis->{'portfolio'});
    $graph_ds->set_selected_range($first, $last);

    # create graph for buy and hold portfolio
    my $pf_manager2 = GT::PortfolioManager->new;
    my $sys_manager2 = GT::SystemManager->new;
    $pf_manager2->setup_from_name("SY:AlwaysInTheMarket | TF:LongOnly | TF:OneTrade | CS:NeverClose");
    $sys_manager2->setup_from_name("SY:AlwaysInTheMarket | TF:LongOnly | TF:OneTrade | CS:NeverClose");
    my $def_rule = create_standard_object("MoneyManagement::Basic");
    $pf_manager2->default_money_management_rule($def_rule);
    $pf_manager2->finalize;
    $sys_manager2->finalize;
    my $analysis2 = backtest_single(
     $pf_manager2, $sys_manager2, $broker, $calc, $first, $last, $initial_value);
    my $graph_ds2 = GT::Graphics::DataSource::PortfolioEvaluation->new($calc, $analysis2->{'portfolio'});
    $graph_ds2->set_selected_range($first, $last);

    # set up graphic objects
    my $zone = GT::Graphics::Zone->new(700, 300, 80, 40, 0, 40);
    my $scale = GT::Graphics::Scale->new();
    $scale->set_horizontal_linear_mapping($first, $last + 1, 0, $zone->width);
    $scale->set_vertical_linear_mapping(union_range($graph_ds->get_value_range, $graph_ds2->get_value_range), 0, $zone->height);
    $zone->set_default_scale($scale);
    my $axis_h = GT::Graphics::Axis->new($scale);
    my $axis_v = GT::Graphics::Axis->new($scale);
    $axis_h->set_custom_big_ticks(build_axis_for_interval(union_range($graph_ds->get_value_range, $graph_ds2->get_value_range), 0, 1));
    $axis_v->set_custom_big_ticks(build_axis_for_timeframe($calc->prices(), $YEAR, 1, 1), 1);
    $zone->set_axis_left($axis_h);
    $zone->set_axis_bottom($axis_v);
    my $graphic = GT::Graphics::Graphic->new($zone);
    my $graph = GT::Graphics::Object::Curve->new($graph_ds, $zone);
    $graph->set_foreground_color([0, 190, 0]);
    $graph->set_antialiased(0);
    my $graph2 = GT::Graphics::Object::Curve->new($graph_ds2, $zone);
    $graph2->set_foreground_color([190, 0, 0]);
    $graph2->set_antialiased(0);
    $graphic->add_object($graph2);
    $graphic->add_object($graph);
    if ($display_trades) {
	my $trades = GT::Graphics::Object::Trades->new($calc, $zone,
							$analysis->{'portfolio'},
							$first, $last);
	$graphic->add_object($trades);
    }

    my $driver = create_standard_object("Graphics::Driver::GD");
    my $picture = $driver->create_picture($zone);
    $graphic->display($driver, $picture);
    $driver->save_to($picture, $graph_file);
}

# Display the results
$template = GT::Conf::get('Template::backtest') if ($template eq '');
if (defined($template) && $template ne '') {
  my $output;

  my $use = 'use HTML::Mason;use File::Spec;use Cwd;';
  eval $use;
  die($@) if($@);

  my $root = GT::Conf::get('Template::directory');
  $root = File::Spec->rel2abs( cwd() ) if (!defined($root));
  my $interp = HTML::Mason::Interp->new( comp_root => $root,
					 out_method => \$output
				       );
  $template='/' . $template unless ($template =~ /\\|\//);
  $interp->exec($template, analysis => $analysis, 
	  sys_manager => $sys_manager, pf_manager => $pf_manager, 
	  verbose => $verbose);
  print $output;
}
elsif ($html)
{
    print "Analysis of " . $sys_manager->get_name . "|" .
	$pf_manager->get_name;
    if ($graph_file) {
        print "<h2>Value of portfolio (green) vs. buy and hold (red)</h2>\n";
    	print "<img src=\"$graph_file\" alt=\"Portfolio evaluation\" \\>\n";
    }
    print "<table border='1' bgcolor='#EEEEEE'><tr><td>";
    print "<pre>";
    print "## Global analysis (full portfolio always invested)\n";
    GT::Report::PortfolioAnalysis($analysis->{'real'}, $verbose);
    print "</pre></td></tr></table>";
    GT::Report::PortfolioHTML($analysis->{'portfolio'}, $verbose);
}
else
{
    print "## Analysis of " . $sys_manager->get_name . "|" .
		$pf_manager->get_name . "\n";
    GT::Report::Portfolio($analysis->{'portfolio'}, $verbose);
    print "## Global analysis (full portfolio always invested)\n";
    GT::Report::PortfolioAnalysis($analysis->{'real'}, $verbose);
	GT::Report::PortfolioJson($analysis->{'real'}, $verbose, "/home/abin/workplace/gt/source/trunk/Scripts/backtest.out");
    print "\n";
}

$db->disconnect;

if ( $set ) {
  # Store intermediate result
  my $bkt_spool = GT::BackTest::Spool->new($outputdir);
  my $stats = [ $analysis->{'real'}{'std_performance'},
		$analysis->{'real'}{'performance'},
		$analysis->{'real'}{'max_draw_down'},
		$analysis->{'real'}{'std_buyandhold'},
		$analysis->{'real'}{'buyandhold'}
	      ];

  $bkt_spool->update_index();
  $bkt_spool->add_alias_name($sys_manager->get_name, $sys_manager->alias_name);
  $bkt_spool->add_results($sys_manager->get_name, $code, $stats,
			  $analysis->{'portfolio'}, $set);
  $bkt_spool->sync();
}


sub usage {
print <<"eof";
./backtest.pl [ options ] <code>
./backtest.pl [ options ] <system_alias> <code>
./backtest.pl [ options ] "<full_system_name>" <code>
  options: -full -verbose -html -dt
  opt w arg: -te fn, -mm s, -tf s, -of s, -cs s, -b s, -sy s, -sto fn, -gr fn,
             -mli n, -od dn, -set s, -iv n
  typical opts: -start date, -end date, -timeframe tfname
eof

}
