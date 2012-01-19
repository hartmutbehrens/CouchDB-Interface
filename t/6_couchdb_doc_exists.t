#!/usr/bin/env perl

use strict;
use warnings;
use feature qw(say);

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
my $content = {'name' => 'foofoo','surname' => 'barbar'};
$couch->delete_doc({id => 'first_doc'});
$couch->save_doc({id => 'first_doc', content => $content});	#id specified, will run a PUT request

subtest 'Document EXISTS' => sub {
	is($couch->exists_doc({id => 'first_doc'}), 1, 'Document check OK');
};

done_testing();