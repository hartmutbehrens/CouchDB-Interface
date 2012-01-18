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

unless ($ARGV[0]) {
    plan skip_all => "All tests skipped: URI for CouchDB server not provided";
}

my $uri = $ARGV[0];
my $debug = $ARGV[1] || 0;
my $couch = new_ok('CouchDB::Interface' => [uri => $uri, name => 'testing_db', debug => $debug]);
$couch->create_db;	#create db, if it does not exist

my $content1 = {'name' => 'foo','surname' => 'bar'};
$couch->save_doc({id => 'first_doc', content => $content1});
my $content2 = {'name' => 'foodoo','surname' => 'barzar'};
$couch->save_doc({id => 'second_doc', content => $content2});

subtest 'Multiple Document FETCH' => sub {
	my $data;
	my @want = qw(first_doc second_doc);
	lives_ok { $data = $couch->get_multiple(\@want) } 'Multiple doc id and rev fetch OK';
	my @ids = map( $_->{id} , @{$data->{rows}} );
	is_deeply(\@ids,\@want,'Retrieved ids from fetch are OK');
	
	lives_ok { $data = $couch->get_multiple_with_doc(['first_doc','second_doc']) } 'Multiple doc fetch OK';
	@ids = map( $_->{id} , @{$data->{rows}} );
	is_deeply(\@ids,\@want,'Retrieved ids from fetch_with_doc are OK');
	
	lives_ok { $data = $couch->get_multiple(['bogus_id']) } 'Doc fetch with bogus id handled OK';
	is( defined $data->{rows}->[0]->{error}, 1, 'Unknown doc id generates error OK' );
	
	push @want, 'another_bogus_id';
	lives_ok { $data = $couch->get_multiple(\@want) } 'Multiple doc fetch with bogus id handled OK';
	is( defined $data->{rows}->[2]->{error}, 1, 'Unknown doc id generates error OK' );
	
	lives_ok { $data = $couch->get_multiple_with_doc(\@want) } 'Multiple doc fetch with bogus id handled OK';
	is( defined $data->{rows}->[2]->{error}, 1, 'Unknown doc id generates error OK' );
	
	lives_ok { $data = $couch->get_multiple(['']) } 'Doc fetch with no id handled OK';
	is( defined $data->{rows}->[0]->{error}, 1, 'No doc id generates error OK' );
	
};

done_testing();