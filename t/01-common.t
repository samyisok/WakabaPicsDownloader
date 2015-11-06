use strict;
use warnings;

use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use_ok q{My::WakabaDownloader};
use Carp;

my @subs =
  qw(go_to_sleep get_tmp_urls get_url_pics do_download_pics write_to_error_log);

can_ok q{My::WakabaDownloader}, @subs;

$My::WakabaDownloader::verbose = 0;

sub make_content {
    my ($name_file) = @_;
    open( my $fh, '<', $name_file ) or croak "can't open mockfile";
    my $file_content;
    while ( readline($fh) ) {
        $file_content .= $_;
    }
    close $fh;
    return $file_content;

}

sub clean_log {
    my ($name_file) = @_;
    unlink $name_file if ( -e $name_file );
}

sub check_size_file {
    my ( $orig_file, $new_file ) = @_;
    return 1 if make_content($orig_file) eq make_content($new_file);
}

our @filename_pics =
  qw (1446408245375.jpg 1446407731740.png 1446408209795.gif 1446408294142.jpg );

sub test_webserver {
    use POE;
    use POE::Component::Server::HTTP;
    use HTTP::Status qw/RC_OK/;
    POE::Component::Server::HTTP->new(
        Port           => 32080,
        ContentHandler => {
            "/b/"                      => \&index_b,
            "/b/1.html"                => \&index_404,
            "/b/res/3742158.html"      => \&res_thread1,
            "/b/src/$filename_pics[0]" => \&src_pic1,
            "/b/src/$filename_pics[1]" => \&src_pic2,
            "/b/src/$filename_pics[2]" => \&src_pic3,
            "/b/src/$filename_pics[3]" => \&src_pic4
        },
        Headers => { Server => 'Simple Perl POE web-server', },
    );

    sub index_b {
        my ( $request, $response ) = @_;

        $response->code(RC_OK);
        $response->push_header("application/x-www-form-urlencoded");
        $response->content( make_content('test_files/mockhttp_tmpurls') );
        return RC_OK;
    }

    sub index_404 {
        my ( $request, $response ) = @_;

        $response->code(404);
        $response->push_header("application/x-www-form-urlencoded");
        $response->content( make_content('test_files/mockhttp_tmpurls') );
        return RC_OK;
    }

    sub res_thread1 {
        my ( $request, $response ) = @_;

        $response->code(RC_OK);
        $response->push_header("application/x-www-form-urlencoded");
        $response->content( make_content('test_files/mockhttp_thread') );

        return RC_OK;
    }

    sub src_pic1 {
        my ( $request, $response ) = @_;

        $response->code(RC_OK);
        $response->push_header("application/x-www-form-urlencoded");
        $response->content( make_content("test_files/$filename_pics[0]") );

        return RC_OK;
    }

    sub src_pic2 {
        my ( $request, $response ) = @_;

        $response->code(RC_OK);
        $response->push_header("application/x-www-form-urlencoded");
        $response->content( make_content("test_files/$filename_pics[1]") );

        return RC_OK;
    }

    sub src_pic3 {
        my ( $request, $response ) = @_;

        $response->code(RC_OK);
        $response->push_header("application/x-www-form-urlencoded");
        $response->content( make_content("test_files/$filename_pics[2]") );

        return RC_OK;
    }

    sub src_pic4 {
        my ( $request, $response ) = @_;

        $response->code(RC_OK);
        $response->push_header("application/x-www-form-urlencoded");
        $response->content( make_content("test_files/$filename_pics[3]") );

        return RC_OK;
    }

    $poe_kernel->run();
}

subtest 'check logfile' => sub {
    my $name_file = 'logfile.txt';
    unlink $name_file if ( -e $name_file );
    use My::WakabaDownloader qw(:all);
    write_to_error_log('message1');
    write_to_error_log('message2');
    my $test_file = 1 if ( -e $name_file );
    ok $test_file, "File Succesful created";
    open( my $fh, '<', $name_file );
    my @array_lines;

    while ( readline($fh) ) {
        push @array_lines, $_;
    }
    ok( grep ( /message1/, @array_lines ), "message 1 found" );
    ok( grep ( /message2/, @array_lines ), "message 2 found" );
    clean_log($name_file);
};

subtest 'check geturls' => sub {
    my @expected_urls =
      qw(/b/res/3740854.html /b/res/3740987.html /b/res/3741112.html /b/res/3737372.html /b/res/3740953.html /b/res/3741080.html /b/res/3689885.html /b/res/3583268.html /b/res/3729342.html /b/res/3727761.html /b/res/3740970.html);

    use threads;
    use LWP;
    use HTTP::Cookies;
    my %headers = (
        "Accept" =>
          "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Encoding" => "gzip, deflate",
        "Accept-Language" => "ru-RU,ru;q=0.8,en-US;q=0.5,en;q=0.3",
        "Connection"      => "keep-alive",
    );

    our @tmp_tread_url;

    my $agent =
"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10; rv:33.0) Gecko/20100101 Firefox/33.0";

    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    $ua->agent($agent);
    $ua->cookie_jar;

    foreach my $key ( keys %headers ) {
        $ua->default_header( $key => $headers{$key} );
    }
    my $webserver =
      threads->create( sub { test_webserver(); } );

    sleep(1);

    my $host_url       = 'http://localhost:32080';
    my $board          = 'b';
    my $prefix_to_save = $host_url;
    $prefix_to_save =~ s/http:\/\///;
    my $dir_to_save = './img_save' . "_" . $prefix_to_save . "_" . $board;

    my @output_array = get_tmp_urls( $ua, $host_url, $board );
    my $tmp = join " ", @output_array;
    is_deeply( \@output_array, \@expected_urls, "Get URL treads is correct" );

    my @expected_pics = (
        "/b/src/$filename_pics[1]", "/b/src/$filename_pics[2]",
        "/b/src/$filename_pics[0]", "/b/src/$filename_pics[3]"
    );
    my @output_pics_array =
      get_url_pics( $ua, $host_url, $board, qw(/b/res/3742158.html) );
    is_deeply( \@output_pics_array, \@expected_pics,
        "Get URL Pics is correct" );

    my $save_dir = 'save_dir';

    sub clean_save_dir {
        use File::Path 'remove_tree';
        my ($my_save_dir) = @_;
        remove_tree($my_save_dir) if -e $my_save_dir;
    }
    clean_save_dir($save_dir);

    my @expected_downloaded_pics = (
        $filename_pics[1], $filename_pics[2],
        $filename_pics[0], $filename_pics[3]
    );
    my @output_downloaded_pics =
      do_download_pics( $ua, $save_dir, $host_url, $board, @output_pics_array );
    is_deeply( \@output_downloaded_pics, \@expected_downloaded_pics,
        "downloaded pics correct" );
    sleep 1;
    $webserver->detach;

    sub check_pic {
        my ($file) = @_;
        return 1 if -e $file;
    }
    ok( check_pic("$save_dir/$filename_pics[0]"), "file1 ok" );
    ok( check_pic("$save_dir/$filename_pics[1]"), "file2 ok" );
    ok( check_pic("$save_dir/$filename_pics[2]"), "file3 ok" );
    ok( check_pic("$save_dir/$filename_pics[3]"), "file4 ok" );
    ok( check_size_file( "test_files/$filename_pics[0]", "$save_dir/$filename_pics[0]" ),
        "file1 size ok" );
    ok( check_size_file( "test_files/$filename_pics[1]", "$save_dir/$filename_pics[1]" ),
        "file2 size ok" );
    ok( check_size_file( "test_files/$filename_pics[2]", "$save_dir/$filename_pics[2]" ),
        "file3 size ok" );
    ok( check_size_file( "test_files/$filename_pics[3]", "$save_dir/$filename_pics[3]" ),
        "file4 size ok" );
    clean_save_dir($save_dir);
    clean_log('logfile.txt');
};

done_testing();
