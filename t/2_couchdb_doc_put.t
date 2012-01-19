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

subtest 'Document PUT' => sub {
	my $content = {'name' => 'foo','surname' => 'bar'};
	$couch->delete_doc({id => 'first_doc'});	#delete doc, if it exists
	
	my $data = $couch->save_doc({id => 'first_doc', content => $content});	#id specified, will run a PUT request
	is(defined $data->{ok} && $data->{ok} == 1, 1, 'Document PUT OK');
	my $fetched = $couch->get_doc({id => 'first_doc'});
	is($fetched->{name},$content->{name}, 'Document content OK');
	
	$content->{name} = 'foodoo';
	$data = $couch->save_doc({id => 'first_doc', content => $content});
	is(defined $data->{ok} && $data->{ok} == 1, 1, 'Document PUT with updated content OK');
	$fetched = $couch->get_doc({id => 'first_doc'});
	is($fetched->{name},$content->{name}, 'Document content update OK');
	
	$content->{address} = 'foovilldale';
	$data = $couch->save_doc({id => 'first_doc', content => $content});
	is(defined $data->{ok} && $data->{ok} == 1, 1, 'Document PUT with new content OK');
	$fetched = $couch->get_doc({id => 'first_doc'});
	is($fetched->{address},$content->{address}, 'Document new content update OK');
	
	$couch->delete_doc({id => 'first_doc'});	#delete doc, if it exists
};

done_testing();