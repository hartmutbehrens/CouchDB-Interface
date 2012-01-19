#!/usr/bin/env perl

use strict;
use warnings;
use feature qw(say);

use Data::Dumper;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/../lib";
use CouchDB::Interface;

unless ($ENV{COUCHDB_URI}) {
    plan skip_all => "All tests skipped: Environmental variable COUCHDB_URI specifying a CouchDB server address is not set";
}
my $uri = $ENV{COUCHDB_URI};
my $debug = $ARGV[0] // 0;
my $couch = new_ok('CouchDB::Interface' => [uri => $uri, name => 'testing_db', debug => $debug]);
$couch->create_db;	#create db, if it does not exist

subtest 'Document POST' => sub {
	my $content = {'name' => 'foobar','surname' => 'barfoo'};
	
	my $data = $couch->save_doc({content => $content});		#no id specified generates a POST request
	is(defined $data->{ok} && $data->{ok} == 1, 1, 'Document POST OK');
	is(defined $data->{id}, 1, 'Document POST assigned id OK');
};

done_testing();