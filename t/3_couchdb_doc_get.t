#!/usr/bin/env perl

use strict;
use warnings;
use feature qw(say);

use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/../lib";
use CouchDB::Interface;

unless ($ARGV[0]) {
    plan skip_all => "All tests skipped: URI for CouchDB server not provided";
}

my $uri = $ARGV[0];
my $debug = $ARGV[1] || 0;
my $couch = new_ok('CouchDB::Interface' => [uri => $uri, name => 'testing_db', debug => $debug]);

$couch->create_db;	#create db, if it does not exist
my $content = {'name' => 'foofoofoo','surname' => 'barbarbar'};
$couch->save_doc({id => 'first_doc', content => $content});	#id specified, will run a PUT request

subtest 'Document GET' => sub {
	SKIP: {
		skip 'first_doc not available for testing', 1 unless $couch->exists_doc({id => 'first_doc'});
		my $data = $couch->get_doc({id => 'first_doc'});
		is(defined $data->{_rev}, 1, 'Document retrieval OK');
		is($data->{name},$content->{name}, 'Document content OK');
	}
	
	my $data = $couch->get_doc({id => 'bogus'});
	is($data, undef, 'Non-existent document retrieval handled OK');
};

done_testing();