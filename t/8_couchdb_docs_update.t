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
use Mojo::JSON;

unless ($ARGV[0]) {
    plan skip_all => "All tests skipped: URI for CouchDB server not provided";
}

my $uri = $ARGV[0];
my $debug = $ARGV[1] || 0;
my $couch = new_ok('CouchDB::Interface' => [uri => $uri, name => 'testing_db', debug => $debug]);
$couch->create_db;	#create db, if it does not exist

subtest 'Multiple Document INSERT/UPDATE' => sub {
	my $data = [{ '_id' => 'first_doc', 'name' => 'julius', 'surname' => 'ceasar'},
				{ '_id' => 'second_doc', 'name' => 'king', 'surname' => 'george'},
				{ '_id' => 'third_doc', 'name' => 'captain', 'surname' => 'kirk'}];
	
	my $response; 
	lives_ok { $response = $couch->insert($data) } 'Multiple doc insert/update OK';
	is(defined $response->[0]->{rev}, 1, 'First entry insert/update OK');
	is(defined $response->[1]->{rev}, 1, 'Second entry insert/update OK');
	is(defined $response->[2]->{rev}, 1, 'Second entry insert/update OK');
	
	$data = [{ '_id' => 'first_doc', 'name' => 'julius', 'surname' => 'foobar'},
				{ '_id' => 'second_doc', 'name' => 'king', 'surname' => 'tut'},
				{ '_id' => 'third_doc', '_deleted' => Mojo::JSON->true }];
				
	lives_ok { $response = $couch->insert($data) } 'Multiple doc insert/update with delete OK';
	is(defined $response->[0]->{rev}, 1, 'First entry insert/update with delete OK');
	is(defined $response->[1]->{rev}, 1, 'Second entry insert/update with delete OK');
	is(defined $response->[2]->{rev}, 1, 'Second entry insert/update with delete OK');
};

done_testing();