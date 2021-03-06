package GT::DateTime;

# Copyright 2000-2002 Rapha�l Hertzog, Fabien Fulhaber
# revised dec 2009 by ras -- support of pre-epoch dates
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# baseline 24 May 2005 7111 bytes
# $Id: DateTime.pm 718 2012-08-31 22:14:22Z ras2010 $

use strict;
use vars qw(@ISA @EXPORT $PERIOD_TICK $PERIOD_1MIN $PERIOD_5MIN $PERIOD_10MIN
            $PERIOD_15MIN $PERIOD_30MIN $HOUR $PERIOD_2HOUR $PERIOD_3HOUR
            $PERIOD_4HOUR $DAY $WEEK $MONTH $YEAR %NAMES
%SEC_BY_TIMEFRAME
            $PERIOD_HOUR
            $GT_SEC $GT_DATE $GT_DAY $GT_YEAR
            $GT_WEEK_EXT $GT_MONTH_EXT $GT_WEEK_INT $GT_MONTH_INT
            $GT_TICK $GT_MIN $GT_10MIN $GT_15MIN $GT_30MIN $GT_1MIN $GT_5MIN
            $GT_HOUR $GT_1HOUR $GT_2HOUR $GT_3HOUR $GT_4HOUR
           );


require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw($PERIOD_TICK $PERIOD_1MIN $PERIOD_5MIN $PERIOD_10MIN
             $PERIOD_15MIN $PERIOD_30MIN $HOUR $PERIOD_2HOUR $PERIOD_3HOUR
             $PERIOD_4HOUR $DAY $WEEK $MONTH $YEAR
%SEC_BY_TIMEFRAME
             $PERIOD_HOUR
             $GT_SEC $GT_DATE $GT_DAY $GT_YEAR
             $GT_WEEK_EXT $GT_MONTH_EXT $GT_WEEK_INT $GT_MONTH_INT
             $GT_TICK $GT_MIN $GT_10MIN $GT_15MIN $GT_30MIN $GT_1MIN $GT_5MIN
             $GT_HOUR $GT_1HOUR $GT_2HOUR $GT_3HOUR $GT_4HOUR
            );

use Date::Manip;
use Time::Local;
use Date::Calc qw(Week_of_Year Monday_of_Week);



###l4p  use Log::Log4perl qw(:easy);

$PERIOD_TICK  = 1;
$PERIOD_1MIN  = 10;
$PERIOD_5MIN  = 30;
$PERIOD_10MIN = 40;
$PERIOD_15MIN = 45;
$PERIOD_30MIN = 50;
$HOUR         = 60;
$PERIOD_HOUR  = 60;
$PERIOD_2HOUR = 62;
$PERIOD_3HOUR = 64;
$PERIOD_4HOUR = 66;
$DAY          = 70;
$WEEK         = 80;
$MONTH        = 90;
$YEAR         = 100;

# seconds per time period
# note that in some cases these are approximate
# (e.g. leap years, months)
#
%SEC_BY_TIMEFRAME = (
    '10'   => 60,                 # PERIOD_1MIN
    '30'   => 60 *  5,            # PERIOD_5MIN
    '40'   => 60 * 10,            # PERIOD_10MIN
    '45'   => 60 * 15,            # PERIOD_15MIN
    '50'   => 60 * 30,            # PERIOD_30MIN
    '60'   => 60 * 60,            # $HOUR
    '62'   => 60 * 60 * 2,        # $PERIOD_2HOUR
    '64'   => 60 * 60 * 3,        # $PERIOD_3HOUR
    '66'   => 60 * 60 * 4,        # $PERIOD_4HOUR
    '70'   => 60 * 60 * 24,       # $DAY
    '80'   => 60 * 60 * 24 *   7, # $WEEK -=- this is a calendar week
    '90'   => 60 * 60 * 24 *  30, # $MONTH
   '100'   => 60 * 60 * 24 * 365, # $YEAR
);

%NAMES = (
    $PERIOD_TICK  => "tick",
    $PERIOD_1MIN  => "1min",
    $PERIOD_5MIN  => "5min",
    $PERIOD_10MIN => "10min",
    $PERIOD_15MIN => "15min",
    $PERIOD_30MIN => "30min",
    $HOUR         => "hour",
    $PERIOD_HOUR  => "hour",
    $PERIOD_2HOUR => "2hour",
    $PERIOD_3HOUR => "3hour",
    $PERIOD_4HOUR => "4hour",
    $DAY          => "day",
    $WEEK         => "week",
    $MONTH        => "month",
    $YEAR         => "year"
);

$GT_SEC   = "%s";
$GT_DATE  = "%Y-%m-%d %T";
$GT_DAY   = "%Y-%m-%d";
#$GT_DAY   = "%Y-%m-%d %T";
     #$GT_WEEK  = "%L-%W"; # wrong for 1969-12-31
     #$GT_WEEK  = "%Y-%W"; # wrong for 1969-12-31
     #$GT_WEEK  = "%G-%U"; # wrong for 1969-12-31
     #$GT_WEEK  = "%L-%U"; # correct for 1969-12-31
$GT_WEEK_EXT  = "%G-%W"; # correct for 1969-12-31
$GT_WEEK_INT  = "%G-w%W"; # correct for 1969-12-31
$GT_MONTH_EXT = "%Y/%m";
$GT_MONTH_INT = "%Y-%m";
$GT_YEAR  = "%Y";
$GT_TICK  = "%Y-%m-%d %H:%M:%S";
$GT_MIN   = "%Y-%m-%d %H:%M:00";

$GT_5MIN  = $GT_10MIN = $GT_15MIN = $GT_30MIN = $GT_1MIN = $GT_MIN;

$GT_HOUR  = "%Y-%m-%d %H:00:00";
$GT_1HOUR = $GT_2HOUR = $GT_3HOUR = $GT_4HOUR = $GT_HOUR;



sub parse_datestring {
    my ($date, $tf, $ext) = @_;
    $ext = 0 unless defined $ext;

    $tf == $PERIOD_TICK  && return UnixDate( $date, $GT_TICK );

    $tf == $PERIOD_1MIN  && return _date_adj( $date, 1, 60 );
    $tf == $PERIOD_5MIN  && return _date_adj( $date, 5, 60 );
    $tf == $PERIOD_10MIN && return _date_adj( $date, 10, 60 );
    $tf == $PERIOD_15MIN && return _date_adj( $date, 15, 60 );
    $tf == $PERIOD_30MIN && return _date_adj( $date, 30, 60 );

    $tf == $HOUR         && return _date_adj( $date, 1, 24 );
    $tf == $PERIOD_2HOUR && return _date_adj( $date, 2, 24 );
    $tf == $PERIOD_3HOUR && return _date_adj( $date, 3, 24 );
    $tf == $PERIOD_4HOUR && return _date_adj( $date, 4, 24 );

    $tf == $DAY          && return UnixDate( $date, $GT_DAY );

#     $tf == $WEEK         && do {
#                              print STDERR "wk: \"$date\"\n";
#                              ( $ext )
#                               ? return UnixDate( $date, $GT_WEEK_EXT )
#                               : return UnixDate( $date, $GT_WEEK_INT );
#                             };

    $tf == $WEEK         && do { ( $ext )
                              ? return UnixDate( $date, $GT_WEEK_EXT )
                              : return UnixDate( $date, $GT_WEEK_INT )
                            };

    $tf == $MONTH        && do { ( $ext )
                              ? return UnixDate( $date, $GT_MONTH_EXT )
                              : return UnixDate( $date, $GT_MONTH_INT )
                            };

    $tf == $YEAR         && return UnixDate( $date, $GT_YEAR );

    # unmatched timeframe name
    my $msg = join "", "$::prog_name: map_date2time: ",
     "timeframe \"$tf\" not recognized ...",
     "\n";
    warn "$msg";

    return undef;
}


=head1 NAME

GT::DateTime - Manage TimeFrames and provides date/time helper functions

=head1 DESCRIPTION

This version does not suffer from the unix date epoch problem.
It performs all date/time conversions within this module
(e.g. the timeperiod submodules in DateTime directory are no longer used).

This module exports all the variable describing the available "periods"
commonly used for trading : $PERIOD_TICK $PERIOD_1MIN, $PERIOD_5MIN,
$PERIOD_10MIN, $PERIOD_15MIN, $PERIOD_30MIN, $HOUR, $PERIOD_2HOUR, 
$PERIOD_3HOUR, $PERIOD_4HOUR, $DAY, $WEEK, $MONTH, $YEAR.

The timeframes are represented by those variables which are only numbers.
You can compare those numbers to know which timeframe is smaller or which
one is bigger.

It also provides several functions to manipulate dates and periods. Those
functions use modules GT::DateTime::* to do the actual work depending on
the selected timeframe.

=head2 Functions provided by submodules

map_date_to_time($date) is a function returning a time (ie a number of
seconds since 1970) representing that date in the history. It is usually
corresponding to the first second of the given period.

map_time_to_date($time) is the complementary function. It will return a
date describing the period that includes the given time.

=head2 Functions

=over

=item C<< GT::DateTime::map_date_to_time($timeframe, $date) >>

=item C<< GT::DateTime::map_time_to_date($timeframe, $time) >>

=item C<< GT::DateTime::parse_datestring( $date, $timeframe ) >>

FIXME -- add pod for this method

Those are the generic functions used to convert a date into a time and vice
versa.

$timeframe is timeframe value (e.g output from name_to_timeframe("day"))
or the timeframe variables $DAY, $WEEK, etc, but not the timeframe names
like 'day', 'week', etc

$time is unix epoch seconds

$date is gt date string (YYYY-MM-DD) -- and that is a potential problem
because format checking isn't performed here or in the subsequent methods.
the issues are formats for week (YYYY-MM) and month (YYYY/MM) and year (YYYY).

to avoid this issue use GT::DateTime::convert_date for date string conversions.

=cut

sub map_date_to_time {
    my ($timeframe, $date) = @_;
    my ($y, $m, $d, $w);

#print STDERR "\$date=\"$date\"\n";

    unless ( $date =~ m@\d\d\d\d|/|-@io ) {
      my ( $package, $filename, $line ) = caller;
      my $msg = join "", "date to timeframe:",
       "\ncalled from \"$filename\" line $line\n",
       "\tdate format is questionable: tf=$timeframe, d=\'$date\'\n",
       "\n";
      print STDERR "$msg"; 
    }
# if ( $debug ) {
#   my ( $package, $filename, $line ) = caller;
#  my $msg = join "", "dt:md2t:",
#    "\ncalled from \"$filename\" line $line\n",
#   "\ttf=$timeframe, d=$date\n",
#   "\n";
#  print STDERR "$msg";
#   open( LOG, "+>>", "/tmp/gt:dt:h.log" )
#    or warn "cannot create LOG, /tmp/gt:dt:h.log";
#   print LOG "$msg";
# }

    $timeframe == $YEAR
     && return timegm(0, 0, 0, 1, 0, $date);

    $timeframe == $MONTH && do {
        ($y, $m) = split /\//, $date;
        return timegm(0, 0, 0, 1, $m - 1, $y);
    };

    $timeframe == $WEEK && do {
        ($y, $w) = split /-/, $date;
        (my $yw, my $mw, $d) = Monday_of_Week($w, $y);
        return timegm(0, 0, 0, $d, $mw - 1, $yw)
    };

    my ($ymd, $hms) = ( '', '' );
    ($ymd, $hms) = split / /, $date;

#print STDERR "dt: \$ymd=\"$ymd\", \$hms=\"$hms\"\n";

    $ymd =~ s/^\s*|\s*$//;    # remove leading/trailing whitespace
    $hms = "00:00:00" unless defined $hms;
    my ($h, $n, $s) = split /:/, $hms;
    ($y, $m, $d) = split /-/, $ymd;

#print STDERR "dt: \$date=\"$date\", \$d=\"$d\"\n";

    $timeframe == $DAY && do {
        ($d) = split / /, $d if $d =~ m/\s+/;
        return timegm(0, 0, 0, $d, $m - 1, $y);
    };

    $timeframe == $PERIOD_TICK
     && return timegm($s, $n, $h, $d, $m - 1, $y);

    $timeframe == $PERIOD_30MIN
      && do {
         _date_adj( $s, $n, $h, $d, $m, $y, 30, 60 );
         return timegm(0, $n, $h, $d, $m - 1, $y);
    };
    $timeframe == $PERIOD_10MIN
      && do {
         _date_adj( $s, $n, $h, $d, $m, $y, 10, 60 );
         return timegm(0, $n, $h, $d, $m - 1, $y);
    };
    $timeframe == $PERIOD_15MIN
      && do {
         _date_adj( $s, $n, $h, $d, $m, $y, 15, 60 );
         return timegm(0, $n, $h, $d, $m - 1, $y);
    };
    $timeframe == $PERIOD_5MIN
      && do {
         _date_adj( $s, $n, $h, $d, $m, $y, 5, 60 );
         return timegm(0, $n, $h, $d, $m - 1, $y);
    };
    $timeframe == $PERIOD_1MIN
      && return timegm(0, $n, $h, $d, $m - 1, $y);

    $timeframe == $HOUR
       && return timegm(0, 0, $h, $d, $m - 1, $y);
    $timeframe == $PERIOD_2HOUR
      && do {
         _date_adj( $s, $n, $h, $d, $m, $y, 2, 24 );
         return timegm(0, 0, $h, $d, $m - 1, $y);
    };
    $timeframe == $PERIOD_3HOUR
      && do {
         _date_adj( $s, $n, $h, $d, $m, $y, 3, 24 );
         return timegm(0, 0, $h, $d, $m - 1, $y);
    };
    $timeframe == $PERIOD_4HOUR
      && do {
         _date_adj( $s, $n, $h, $d, $m, $y, 4, 24 );
         return timegm(0, 0, $h, $d, $m - 1, $y);
    };
}


sub map_time_to_date {
    my ($timeframe, $time) = @_;

##print STDERR "\$timeframe=$timeframe, \$time=$time\n";

# if ( $debug ) {
#   my ( $package, $filename, $line ) = caller;
#  my $msg = join "", "dt:mt2d:",
#    "\ncalled from \"$filename\" line $line\n",
#   "\ttf=$timeframe, t=$time\n",
#   "\n";
#  print STDERR "$msg";
#   open( LOG, "+>>", "/tmp/gt:dt:h.log" )
#    or warn "cannot create LOG, /tmp/gt:dt:h.log";
#   print LOG "$msg";
# }
    my ($s, $n, $h, $d, $m, $y, $wd, $yd) = gmtime($time);

    $timeframe == $DAY
      && return sprintf("%04d-%02d-%02d", $y + 1900, $m + 1, $d);
    $timeframe == $WEEK
      && do {
         my ($week, $year) = Week_of_Year($y + 1900, $m + 1, $d);
         return sprintf("%04d-%02d", $year, $week);
    };
    $timeframe == $MONTH
      && return sprintf("%04d/%02d", $y + 1900, $m + 1);
    $timeframe == $YEAR
      && return sprintf("%04d", $y + 1900);

    $timeframe == $HOUR
      && do {
         _date_adj( $s, $n, $h, $d, $m, $y, 1, 24 );
         return sprintf("%04d-%02d-%02d %02d:00:00", $y + 1900, $m + 1, $d, $h);
    };
    $timeframe == $PERIOD_2HOUR
      && do {
         _date_adj( $s, $n, $h, $d, $m, $y, 2, 24 );
         return sprintf("%04d-%02d-%02d %02d:00:00", $y + 1900, $m + 1, $d, $h);
    };
    $timeframe == $PERIOD_3HOUR
      && do {
         _date_adj( $s, $n, $h, $d, $m, $y, 3, 24 );
         return sprintf("%04d-%02d-%02d %02d:00:00", $y + 1900, $m + 1, $d, $h);
    };
    $timeframe == $PERIOD_4HOUR
      && do {
         _date_adj( $s, $n, $h, $d, $m, $y, 4, 24 );
         return sprintf("%04d-%02d-%02d %02d:00:00", $y + 1900, $m + 1, $d, $h);
    };

    $timeframe == $PERIOD_30MIN
      && do {
         _date_adj( $s, $n, $h, $d, $m, $y, 30, 60 );
         return sprintf("%04d-%02d-%02d %02d:%02d:00", $y + 1900, $m + 1, $d, $h, $n);
    };
    $timeframe == $PERIOD_15MIN
      && do {
         _date_adj( $s, $n, $h, $d, $m, $y, 15, 60 );
         return sprintf("%04d-%02d-%02d %02d:%02d:00", $y + 1900, $m + 1, $d, $h, $n);
    };
    $timeframe == $PERIOD_10MIN
      && do {
         _date_adj( $s, $n, $h, $d, $m, $y, 10, 60 );
         return sprintf("%04d-%02d-%02d %02d:%02d:00", $y + 1900, $m + 1, $d, $h, $n);
    };
    $timeframe == $PERIOD_5MIN
      && do {
         _date_adj( $s, $n, $h, $d, $m, $y, 5, 60 );
         return sprintf("%04d-%02d-%02d %02d:%02d:00", $y + 1900, $m + 1, $d, $h, $n);
    };
    $timeframe == $PERIOD_1MIN
      && do {
         _date_adj( $s, $n, $h, $d, $m, $y, 1, 60 );
         return sprintf("%04d-%02d-%02d %02d:%02d:00", $y + 1900, $m + 1, $d, $h, $n);
    };

    $timeframe == $PERIOD_TICK
      && return sprintf("%04d-%02d-%02d %02d:%02d:%02d", $y + 1900, $m + 1, $d, $h, $n, $s);
}


# _date_adj adjusts the time value passed in
# and returns the adjusted time iaw the parameters
# or undef if something went wrong
sub _date_adj {
    my ( $ss, $mn, $hh, $d, $m, $y, $ts, $com) = @_;
    # ts -- time span in minutes
    # $com -- the time component (year, month, week, day, hr, min)
    my $a_time = "bad date";
    my $factor = $com / $ts;

    unless ( $com == 24 || $com == 60 ) {
        my $msg = join "", "gt::datetime::_date_adj: error:",
         " invalid time component value got $com.",
         "\nvalues supported are 60 (hour) and 24 (day)",
         "\n";
        die "$msg";
    }

    $_[0] = "00";
    $_[1] = sprintf( "%02s", ( ( $mn / $ts ) % $factor ) * $ts ) if ( $com == 60 );
    
    $_[2] = sprintf( "%02s", ( ( $hh / $ts ) % $factor ) * $ts ) if ( $com == 24 );

} # end _date_adj

=item C<< GT::DateTime::convert_date($date, $orig_timeframe, $dest_timeframe) >>

This function does convert the given date from the $orig_timeframe in a
date of the $dest_timeframe. Take care that the destination timeframe must be
bigger than the original timeframe.

where

  $date is date string 'YYYY-MM-DD'
  timeframes the internal variables (e.g. $PERIOD_xxx, $DAY, $WEEK, $MONTH, etc)

for example:

  my $weekly_date = GT::DateTime::convert_date("2008-06-23", $DAY, $WEEK);

=cut

sub convert_date {
    my ($date, $orig, $dest) = @_;
    ###l4p  WARN  "the destination time frame must be bigger" if ( $orig <= $dest);

# if ( $debug ) {
#   my ( $package, $filename, $line ) = caller;
#   my $msg = join "", "dt:cd:",
#    "\ncalled from \"$filename\" line $line\n",
#    "\td=$date, orig_tf=$orig, dest_tf=$dest\n",
#    "\n";
#   open( LOG, "+>>", "/tmp/gt:dt:h.log" )
#    or warn "cannot create LOG, /tmp/gt:dt:h.log";
#   print LOG "$msg";
# }

    return map_time_to_date($dest, map_date_to_time($orig, $date));
}

=item C<< GT::DateTime::list_of_timeframe() >>

Returns the list of timeframes that are managed by the DateTime framework.

=cut

sub list_of_timeframe {
    return (
            $PERIOD_TICK, $PERIOD_1MIN, $PERIOD_5MIN, $PERIOD_10MIN,
            $PERIOD_15MIN, $PERIOD_30MIN, $HOUR, $PERIOD_2HOUR, $PERIOD_3HOUR,
            $PERIOD_4HOUR, $DAY, $WEEK, $MONTH, $YEAR
           );
}

=item C<< GT::DateTime::name_of_timeframe($tf) >>

Return the official name of the corresponding timeframe.

=cut

sub name_of_timeframe {
    my ($tf) = @_;
    return $NAMES{$tf};
}

# just an alias
sub timeframe_to_name {
    return name_of_timeframe( @_ );
}

=item C<< GT::DateTime::name_to_timeframe($name) >>

Returns the timeframe associated to the given name.

=cut

sub name_to_timeframe {
    my ($name) = @_;
    foreach (keys %NAMES)
    {
        return $_ if $NAMES{$_} eq $name;
#       if ($NAMES{$_} eq $name)
#       {
#           return $_;
#       }
    }
    return undef;
}


=item C<< GT::DateTime::secs_in_timeframe( $timeframe ) >>

Returns the number of seconds in timeframe. Note $timeframe is
the timeframe constant value not the timeframe name,

=cut

sub secs_in_timeframe {
    my ($tf) = @_;
    exists $SEC_BY_TIMEFRAME{$tf}
     ? return $SEC_BY_TIMEFRAME{$tf}
     : return undef;
}


=item C<< GT::DateTime::timeframe_ratio($first, $second) >>

Returns how many times the second timeframe fits in the first one.

=cut

sub timeframe_ratio {
    my ($first, $second) = @_;

    $first == $second && return 1;
    $first < $second && return (1 / timeframe_ratio($second, $first));

    $first == $PERIOD_TICK
      && die("Cannot set timeframe ratio for tick data");

    $first == $PERIOD_1MIN
      && return timeframe_ratio($HOUR, $second) / 60;
    $first == $PERIOD_5MIN
      && return timeframe_ratio($HOUR, $second) / 12;
    $first == $PERIOD_10MIN
      && return timeframe_ratio($HOUR, $second) / 6;
    $first == $PERIOD_15MIN
      && return timeframe_ratio($HOUR, $second) / 4;
    $first == $PERIOD_30MIN
      && return timeframe_ratio($HOUR, $second) / 2;

    $first == $HOUR
      && do { $second == $PERIOD_1MIN  && return 60;
              $second == $PERIOD_5MIN  && return 12;
              $second == $PERIOD_10MIN && return 6;
              $second == $PERIOD_30MIN && return 2;
              $second == $HOUR         && return 1;
    };

    $first == $PERIOD_2HOUR
      && return timeframe_ratio($HOUR, $second) * 2;
    $first == $PERIOD_3HOUR
      && return timeframe_ratio($HOUR, $second) * 3;
    $first == $PERIOD_4HOUR
      && return timeframe_ratio($HOUR, $second) * 4;

    $first == $DAY
      && do { $second == $PERIOD_1MIN  && return 8 * 60;
              $second == $PERIOD_5MIN  && return 8 * 12;
              $second == $PERIOD_10MIN && return 8 * 6;
              $second == $PERIOD_30MIN && return 8 * 2;
              $second == $HOUR         && return 8;
    };

    $first == $WEEK
      && do { $second == $DAY  && return 5;
               return timeframe_ratio($DAY, $second) * 5;
    };

    $first == $MONTH
      && do { $second == $DAY  && return 52 * 5 / 12;
              $second == $WEEK && return 52 / 12;
              return timeframe_ratio($DAY, $second) * 52 * 5 / 12;
    };

    $first == $YEAR
      && do { $second == $MONTH && return 12;
              $second == $WEEK  && return 52;
              $second == $DAY   && return 260;    # based on 52 wks/yr and 5 days/wk
              return timeframe_ratio($DAY, $second) * 260;
    };

    # unmatched timeframe name
    my $msg = join "", "$::prog_name: timeframe_ratio: warning:",
     "timeframe \"$first\" not recognized.\n",
     "timeframes are ... ",
     " -- FIX ME -- ::: list timeframe names or ???",
     "\n";
    warn "$msg";

    return 1;
}


=item C<< GT::DateTime::duration( date1, date2, [ units ] ) >>

computes the time duration from date1 to date2 and adjust the results
in terms of calendar units. units is optional, if not provided it
defaults to 1 calendar year (365 days). the values of units should be
given in terms of standard calendar units counted in days.

meaning for one year specify 365, for a quarter 90, a month 30, a
week 7. the words 'year', 'quarter', 'month', 'week' and 'day' can also
be used.

note that this yields 'approximate' and decimal based results. for
example from '1962-01-07' to '1962-01-13' counts only 4.00 days
not 5 days. similarly '1962-01-01' .. '1962-02-01' is 1.00 months,
but '1962-01-01' .. '1962-01-31' yields only 0.99 months.

GT::Tools::round() can be used to good effect to get integer values.

=cut

sub duration {
    my ($d1, $d2, $units ) = @_;
    my $err;

    $units = 365 unless $units;
    if    ( $units =~ m/day*/oi ) {
        $units = 1;
    }
    elsif ( $units =~ m/week*/oi ) {
        $units = 7;
    }
    elsif ( $units =~ m/month*/oi ) {
        $units = 30;
    }
    elsif ( $units =~ m/quarter*/oi ) {
        $units = 90;
    }
    elsif ( $units =~ m/year*/oi ) {
        $units = 365;
    }
    else {
        $units = 365;
        my $msg = join "", "gt::datetime: error: duration units \$units\"",
         "not recognized\nuse 'year', 'quarter', 'month', 'week' and 'day'",
         " or their calendar counterpart numerical values. defaulting to",
         " year ($units days).",
         "\n";
         warn $msg;
    }

    my $deltaduration = DateCalc( $d1, $d2, \$err, 1 ); # appoximate mode
    if ( $err ) {
        my $msg = join "", "gt::datetime: error: duration error $err\n",
         "send entire command line, your options file to developers list",
         " along with this message: d1=\"$d1\", d2=\"$d2\"",
         "\n";
         warn $msg;
    }

#print STDERR "delta duration=$deltaduration\n";

    my $duration;
    # convert the delta in terms of units
    my $dec = 2;          # result to 2 decimal places
    my $mode = 'approx';  # use approximate calculations
    SWX: {
      if    ( $units == 1 ) {
           $duration = Delta_Format($deltaduration, $mode, $dec, "%dt");
      }
      elsif ( $units == 7 ) {
           $duration = Delta_Format($deltaduration, $mode, $dec, "%wt");
      }
      elsif ( $units == 30 ) {
           $duration = Delta_Format($deltaduration, $mode, $dec, "%Mt");
      }
      elsif ( $units == 90 ) {
           $duration = Delta_Format($deltaduration, $mode, $dec, "%Mt")
           / $units;
      }
      elsif ( $units == 365 ) {
           $duration = Delta_Format($deltaduration, $mode, $dec, "%yt");
      }

    } # end SWX

    ( $err ) ? return 'NaN' : return $duration;
}


=item C<< GT::DateTime::_date_adj( date_string, time_span, ts_component ) >>

computes the relationship between the specified time span and the
time span component and applies the factor to the time element of the
date string.

the return value is the adjusted date string as a standard gt time
string, YYYY-MM-DD hh:mm:ss.

this is an internal function, it is used to convert a date/time to
another time factor.

=cut


1;
