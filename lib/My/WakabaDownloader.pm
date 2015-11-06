package My::WakabaDownloader;

use strict;
use warnings;
use Carp;
use List::MoreUtils qw(uniq);
use Exporter qw(import);
our @EXPORT_OK =
  qw( create_save_dir go_to_sleep get_tmp_urls get_url_pics do_download_pics write_to_error_log);
our %EXPORT_TAGS = (
    all => [
        qw(create_save_dir go_to_sleep get_tmp_urls get_url_pics do_download_pics write_to_error_log)
    ]
);
our $VERSION = 0.01;
our $verbose //= undef;

sub create_save_dir{
    my ($dir_to_save) = @_;
    mkdir $dir_to_save unless ( -d $dir_to_save );
}

sub go_to_sleep {
    sleep 1;
}

sub write_to_error_log {
    my $err_log_file = "logfile.txt";
    my ($message)    = @_;
    my $time         = time();
    open( my $errlog_handler, ">>", $err_log_file )
      or croak "can't write to error log $!";
    print $errlog_handler "$time: $message \n";
    print "$time: $message \n" if $My::WakabaDownloader::verbose; 
    close $errlog_handler;
}

sub get_tmp_urls {
    my ($my_ua)       = shift;
    my ($my_host_url) = shift;
    my ($my_board)    = shift;
    my $main_url      = $my_host_url . "/" . $my_board . "/";
    my @my_tmp_tread_url;
    my $page = 0;
    while (1) {
        my $my_tmp_page = $page != 0 ? "$page.html" : "";
        my $response = $my_ua->get( $main_url . $my_tmp_page );
        write_to_error_log("TRY: $main_url$my_tmp_page");
        if ( $response->is_success ) {
            my $content     = $response->decoded_content;
            my @my_tmp_urls = $content =~ /\/$my_board\/res\/\d+.html/g;
            @my_tmp_urls = uniq @my_tmp_urls;
            push @my_tmp_tread_url, @my_tmp_urls;
            $page++;
        }
        else {
            write_to_error_log($my_tmp_page);
            last;
        }
        go_to_sleep();
    }
    write_to_error_log("Total thread URL: " . scalar @my_tmp_tread_url);
    return uniq @my_tmp_tread_url;
}

sub get_url_pics {
    my ($my_ua)            = shift;
    my ($my_host_url)      = shift;
    my ($my_board)         = shift;
    my (@my_tmp_tread_url) = @_;
    my @my_url_pics;
    foreach my $url (@my_tmp_tread_url) {
        my $response = $my_ua->get( $my_host_url . $url );
        write_to_error_log("TRY: $my_host_url . $url ");
        if ( $response->is_success ) {
            my $content = $response->decoded_content;
            my @my_tmp_pics_urls =
              $content =~ /\/$my_board\/src\/\d+.(?:jpg|png|gif)/g;
            @my_tmp_pics_urls = uniq @my_tmp_pics_urls;
            push @my_url_pics, @my_tmp_pics_urls;
        }
        else {
            write_to_error_log("ERR: GET TREAD $url");
        }
        go_to_sleep();
    }
    write_to_error_log("Total urls pics:" . scalar @my_url_pics);
    return @my_url_pics;
}

sub do_download_pics {
    my ($my_ua)          = shift;
    my ($my_dir_to_save) = shift;
    my ($my_host_url)    = shift;
    my ($my_board)       = shift;
    my (@my_url_pics)    = @_;
    my @my_downloaded_pics;
    create_save_dir($my_dir_to_save);
    foreach my $url (@my_url_pics) {
        my $file_name = $url;
        $file_name =~ s/\/$my_board\/src\///;
        my $save_path = $my_dir_to_save . "/" . $file_name;
        unless ( -e $save_path ) {
            my $response = $my_ua->get( $my_host_url . $url );
            write_to_error_log "#####: get $my_host_url$url ";
            if ( $response->is_success ) {
                my $content = $response->decoded_content;
                open( my $filehandler, ">", $save_path )
                  or croak "can't open or create file $!";
                print $filehandler $content;
                close $filehandler;
                push @my_downloaded_pics, $file_name;
                sleep 1;
            }
            else {
                write_to_error_log("ERR: CAN'T get $my_host_url$url");
            }
        }
        else {
            write_to_error_log("file exist, $save_path ");
        }
    }
    write_to_error_log("Totaly downloaded pics: " . scalar @my_downloaded_pics);
    return @my_downloaded_pics;
}

1;
