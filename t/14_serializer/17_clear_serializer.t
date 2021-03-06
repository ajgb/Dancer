use Dancer ':tests';
use Dancer::Test;
use Test::More tests => 4;
use Dancer::ModuleLoader;
use LWP::UserAgent;

plan skip_all => 'Test::TCP is needed to run this test'
    unless Dancer::ModuleLoader->load('Test::TCP');

plan skip_all => 'JSON is needed to run this test'
    unless Dancer::ModuleLoader->load('JSON');

set serializer => 'JSON';

my $data = { foo => 'bar' };

Test::TCP::test_tcp(
    client => sub {
        my $port    = shift;
        my $ua      = LWP::UserAgent->new;
        my $request = HTTP::Request->new( GET => "http://127.0.0.1:$port/" );
        my $res;

        $res = $ua->request($request);
        ok( $res->is_success, 'Successful response from server' );
        like(
            $res->content,
            qr/"foo" \s \: \s "bar"/x,
            'Correct content',
        );

        # new request, no serializer
        $res = $ua->request($request);
        ok( $res->is_success, 'Successful response from server' );
        is_deeply(
            $res->content,
            "$data",
            'Serializer undef, getting our object back',
        );
    },

    server => sub {
        my $port = shift;
        use Dancer ':tests';

        setting apphandler   => 'Standalone';
        setting port         => $port;
        setting show_errors  => 1;
        setting startup_info => 0;

        get '/' => sub { $data };

        after sub { set serializer => undef };

        Dancer->dance();
    },
);

