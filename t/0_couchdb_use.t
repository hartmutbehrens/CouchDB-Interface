use strict;
use warnings;
use feature qw(say);

#modules
use Test::More tests => 1;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/../lib";
use CouchDB::Interface;

my $debug = $ARGV[0] // 0;

#we can't be sure that a CouchDB server is available, so can only test failure reliably
subtest 'Connection to invalid URI' => sub {
	dies_ok { CouchDB::Interface->new(uri => 'http://rub.i.sh/', name => 'bogus', debug => $debug ) }, "Connection to invalid URI handled OK" ;	
};

done_testing();