#!/usr/bin/env perl 
#===============================================================================
#         FILE: img_br_ddownloader.pl
#        USAGE: ./img_br_ddownloader.pl
#      CREATED: 10/19/2015 20:55:55
#      modules: sudo cpan LWP
#               sudo cpan Getopt
#     Perl-ver: 5.18
#===============================================================================

use strict;
use warnings;
use utf8;
use LWP;
use v5.18;
use HTTP::Cookies;
use List::MoreUtils qw(uniq);
use Getopt::Long qw(GetOptions);
use FindBin;
use lib "$FindBin::Bin/lib";
use My::WakabaDownloader qw(:all);

### init
my $board       = "b";
my $host_url    = "http://iichan.hk";
my $log_verbose = 0;

GetOptions(
    'board=s'   => \$board,
    'host=s'    => \$host_url,
    'verbose=s' => \$log_verbose,
  )
  or die "usage: $0 --board $board --host $host_url --verbose 1\n";

$My::WakabaDownloader::verbose = $log_verbose if $log_verbose;

my $agent =
"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10; rv:33.0) Gecko/20100101 Firefox/33.0";

my $prefix_to_save = $host_url;
$prefix_to_save =~ s/http:\/\///;
my $dir_to_save = './img_save' . "_" . $prefix_to_save . "_" . $board;
my %headers     = (
    "Accept" =>
      "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Encoding" => "gzip, deflate",
    "Accept-Language" => "ru-RU,ru;q=0.8,en-US;q=0.5,en;q=0.3",
    "Connection"      => "keep-alive",
);

our @tmp_tread_url;
my $ua = LWP::UserAgent->new;
$ua->timeout(10);
$ua->agent($agent);
$ua->cookie_jar;

foreach my $key ( keys %headers ) {
    $ua->default_header( $key => $headers{$key} );
}

mkdir $dir_to_save unless ( -d $dir_to_save );

#END init

@tmp_tread_url = get_tmp_urls( $ua, $host_url, $board );
my @url_pics = get_url_pics( $ua, $host_url, $board, @tmp_tread_url );
my @downloaded_pics =
  do_download_pics( $ua, $dir_to_save, $host_url, $board, @url_pics );

my $totaly_pics = scalar @downloaded_pics;
