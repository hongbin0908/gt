package GT::DB::Text;

# Copyright 2000-2002 Rapha�l Hertzog, Fabien Fulhaber
# Copyright 2009 Josef Strobel, ras
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# this version joao costa circa nov 07
# $Id: Text.pm 712 2012-02-20 21:27:22Z ras2010 $

use strict;
our @ISA = qw(GT::DB);

use GT::DB;
use GT::Prices;
use GT::Conf;
use GT::DateTime;

=head1 DB::Text access module

=head2 Overview

This database access module enable you to work with a full directory of
text files.

=head2 Configuration

Most configuration items have default values, to alter these defaults
you must indicate the configuration item and its value in your
$HOME/.gt/options file.

NB: do not quote the key values in your $HOME/.gt/options file
unless the quote is wanted as part of the value.

=over

=item DB::module	Text

Informs gt you are using the Text.pm module. This
configuration item is always required in your $HOME/.gt/options file.

=item DB::text::directory	path

where files are stored. This
configuration item is always required in your $HOME/.gt/options file.

=item DB::text::marker	string

where string delimits fields in each row of the data file.
In most instances string is a single character such as a comma,
a colon, a vertical bar or as in 'character separated values'.
In nearly all cases you will not want to quote this string in any way.
The only exception is when the quotes are actually part of the
separator string.
The marker defaults to the tab character '\t'.

=item DB::text::order	0 | 1 (default is 0)

 0 - file is ordered by date ascending, the default gt standard.
 1 - file is ordered by descending date.

This feature allows the user flexibility to use files with either
date order.

=item DB::text::header_lines	number

The number of header lines in your data file
that are to be skipped during processing. Lines with the either the
comment symbol '#' or the less than symbol '<' as the first character
do not need to be included in this value.. The header_lines default value is 0.

=item DB::text::file_extension	string

To be appended to the code file name when 
searching the data file.  For instance, if the data file is called EURUSD.csv
this variable would have the value '.csv' (without the quotes).

The default file_extension is '.txt'.

if you have data in different timeframes, for instance, EURUSD_hour.csv and
EURUSD_day.csv, use the following value for this directive:

=item DB::text::file_extension	_\$timeframe.csv

 notes: @ the leading backslash on perl variable $timeframe is needed,
          but is not part of the actual filename. in this example the
          filenames would look like:
             IBM_10min.csv
             IBM_day.csv
             IBM_week.csv
        @ you can use a null string (empty string) for the
          file_extension by defining the key like so:
             DB::text::file_extension	''
          or
             DB::text::file_extension	""

=item DB::text::format		0|1|2|3 (default is 3)

The format of the date/time string. Valid values are: 

 0 - yyyy-mm-dd hh:nn:ss (the time string is optional)
 1 - US Format (month day year, any format understood
     by Date::Calc)
 2 - European Format (day month year, any format understood
     by Date::Calc)
 3 - Any format understood by Date::Manip

=item DB::text::fields::datetime	number

Column index where to find the period datetime
field. Indexes are 0 based.  For the particular case of datetime, can contain
multiple indexes, useful when date and time are separate columns in the data
file.  The date time format is anything that can be understood by Date::Manip.
A typical example would be YYYY-MM-DD HH:NN:SS. The default datetime index is 5.

=item DB::text::fields::open	number

Column index where to find the period open field.
Indexes are 0 based. The default open index is 0.

=item DB::text::fields::low	number

Column index where to find the period low field.
Indexes are 0 based. The default low index is 2. 

=item DB::text::fields::high	number

Column index where to find the period high field.
Indexes are 0 based. The default high index is 1.

=item DB::text::fields::close	number

Column index where to find the period close field.
Indexes are 0 based. The default close index is 3.

=item DB::text::fields::volume	number

Column index where to find the period volume field.
Indexes are 0 based. The default volume index is 4.

=item DB::text::fields::cache	0 | 1 

boolean indicating whether to cache the prices database.
The default is 0, do not use cache.

=head2 new()

Create a new DB object used to retrieve quotes from a directory
full of text files containing prices.

=cut
sub new {
    my $type = shift;
    my $class = ref($type) || $type;

    my $self = { "directory" => GT::Conf::get("DB::Text::directory") };

    GT::Conf::default('DB::Text::header_lines',     '0');
    GT::Conf::default('DB::Text::marker',           "\t");
    GT::Conf::default('DB::Text::file_extension',   '.txt');
    GT::Conf::default('DB::Text::format',           '3');
    GT::Conf::default('DB::Text::fields::open',     '0');
    GT::Conf::default('DB::Text::fields::high',     '1');
    GT::Conf::default('DB::Text::fields::low',      '2');
    GT::Conf::default('DB::Text::fields::close',    '3');
    GT::Conf::default('DB::Text::fields::volume',   '4');
    GT::Conf::default('DB::Text::fields::datetime', '5');

    # clk patch 17apr09
    GT::Conf::default('DB::Text::cache',            '0');

    # js patch 23nov09
    GT::Conf::default('DB::Text::order',            '0');

    $self->{'header_lines'} = GT::Conf::get('DB::Text::header_lines');
    $self->{'mark'} = GT::Conf::get('DB::Text::marker');
    $self->{'date_format'} = GT::Conf::get('DB::Text::format');
    $self->{'extension'} = GT::Conf::get('DB::Text::file_extension');
    $self->{'datetime'} = GT::Conf::get('DB::Text::fields::datetime');
    $self->{'open'} = GT::Conf::get('DB::Text::fields::open');
    $self->{'low'} = GT::Conf::get('DB::Text::fields::low');
    $self->{'high'} = GT::Conf::get('DB::Text::fields::high');
    $self->{'close'} = GT::Conf::get('DB::Text::fields::close');
    $self->{'volume'} = GT::Conf::get('DB::Text::fields::volume');

    # clk patch 17apr09
    $self->{'use_cache'} = GT::Conf::get('DB::Text::cache');

    # js patch 23nov09
    $self->{'order'} = GT::Conf::get('DB::Text::order');

    return bless $self, $class;
}

=head2 $db->disconnect

Disconnects from the database.

=cut

sub disconnect {
    my $self = shift;
}

=head2 $db->set_directory("/new/directory")

Indicate the directory containing all the text files.

=cut

sub set_directory {
    my ($self, $dir) = @_;
    ( $self->{'directory'} = $dir ) =~ s@/$@@;
#    $self->{'directory'} = $dir;
}

=head2 $db->get_prices($code, $timeframe)

Returns a GT::Prices object containing all known prices for the symbol $code.

=cut

sub get_prices {
    my ($self, $code, $timeframe) = @_;
    $timeframe = $DAY unless ($timeframe);

    my $prices = GT::Prices->new;
    # WARNING: Can only load data that is in daily format or smaller
    # Trying to load weekly or monthly data will fail.
    return $prices if ($timeframe > $DAY);

    $prices->set_timeframe($timeframe);

    my %fields = ( 'open'   => $self->{'open'},
                   'high'   => $self->{'high'},
                   'low'    => $self->{'low'},
                   'close'  => $self->{'close'},
                   'volume' => $self->{'volume'},
                   'date'   => $self->{'datetime'},
                  );
    $self->{'fields'} = \%fields;

    my $extension = $self->{'extension'};

    my $tfname = GT::DateTime::name_of_timeframe($timeframe);
    $extension =~ s/\$timeframe/$tfname/g;

#    my $file;
# #   if ( $extension =~ m/['"]['"]/o ) {
# #   if ( $extension =~ m/^['"]['"]$/o ) {
# #   if ( $extension =~ m/^(''|"")$/o ) {
# #   if ( $extension =~ m/^""$/ ) {
# #   if ( $extension =~ m/""/ ) {
# #   if ( $extension =~ m/""|''/ ) {
#    if ( $extension =~ m/^(""|'')$/ ) {
#        $file = join "", $self->{'directory'}, "/$code";
# print STDERR "db::text code only \$file \"$file\"\n";
#    }
#    else {
#        $file = join "", $self->{'directory'}, "/$code", $extension;
# print STDERR "db::text code and ext \$file \"$file\"\n";
#    }
# #   my $file = ( $extension =~ m/['"]['"]/o )
   my $file = ( $extension =~ m/^(""|'')$/o )
    ? join "", $self->{'directory'}, "/$code"
    : join "", $self->{'directory'}, "/$code", $extension;

# print STDERR "db::text \$file \"$file\"\n";

# clk patch 17apr09
#     if ($self->{'use_cache'}) {
#         require Storable;
#         if ( -f $file.".cache"
#          && (stat($file.".cache"))[9] > (stat($file))[9] ) {
#             return Storable::retrieve( $file.".cache" );
#         }
#     }

    $prices->loadtxt( $file,
                      $self->{'mark'},
                      $self->{'date_format'},
                      $self->{'header_lines'},
                      %fields,
                    );

# clk patch 17apr09
#     if ($self->{'use_cache'}) {
#         $prices->timestamp($_) for 0..$prices->count-1;
#         Storable::nstore($prices, $file.".cache");
#     }

    # js patch 23nov09
    if ( $self->{'order'} eq 1 ) {    # reverse the price list
        $prices->reverse();
    }

    return $prices;
}

=pod

=head2 $db->get_last_prices($code, $limit, $timeframe)

Returns a GT::Prices object containing the $limit last known prices for
the symbol $code.

=cut

sub get_last_prices {
    my ($self, $code, $limit, $timeframe) = @_;

    ### warn "$limit parameter ignored in DB::Text::get_last_prices. loading entire dataset." if ($limit > -1);
    return get_prices($self, $code, $timeframe, -1);
}

=head2 $db->has_code($code, [ $timeframe ] )

checks to see if the prices database has an entry for $code.
by default $timeframe is $DAY, and is optional, but if you are
using a file based db and have $timeframe based files then you
must also set $timeframe appropriately.

=cut

sub has_code {
    my ($self, $code, $timeframe) = @_;
    $timeframe = $DAY unless $timeframe;

    my $extension = $self->{'extension'};

#print STDERR "\$extension is \"$extension\"\n";

    my $tfname = GT::DateTime::name_of_timeframe($timeframe);
    $extension =~ s/\$timeframe/$tfname/g;
    #$extension =~ s/\$timeframe/\.\*/g;

#print STDERR "post s/// \$extension is \"$extension\"\n";

    my $file_exists = 0;
    my $file_pattern = "";

    $extension =~ tr/"'//d;

#print STDERR "post tr, ext:$extension: length \$extension is ",length $extension,"\n";

    unless ( length $extension > 0 ) {
        $file_pattern = join "", $self->{'directory'}, "/$code";
    }
    else {
        $file_pattern = join "", $self->{'directory'}, "/$code", $extension;
    }

    #my $file_pattern = ( $extension =~ m//o )
    # ? join "", $self->{'directory'}, "/$code"
    # : join "", $self->{'directory'}, "/$code", $extension;
    #my $file_pattern = $self->{'directory'} . "/$code$extension";
    #my $file_pattern = "$code$extension";

#print STDERR "post file pattern \$extension is \"$extension\"\n";
#print STDERR "\$file_pattern is \"$file_pattern\"\n";

    if ($extension =~ /\*/) {
        eval "use File::Find;";
        find ( sub { $file_exists = 1 if ($_ =~ /$file_pattern/); },
               $self->{'directory'}
             );

#print STDERR "if ext\$file_exists=\"$file_exists\"\n";

    } else {
        $file_exists = 1 if (-e $file_pattern);

#print STDERR "else ext\$file_exists=\"$file_exists\"\n";

    }

    return $file_exists;
}

1;
