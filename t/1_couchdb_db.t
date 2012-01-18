#!/usr/bin/env perl

#pragmas
use strict;
use warnings;
use feature qw(say);

#modules
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/../lib";
use CouchDB::Interface;


my $uri = 'http://hartmut:vodacom@hartmut.iriscouch.com';	#left out ending / on pupose for testing
my $couch = new_ok('CouchDB::Interface' => [uri => $uri, name => 'testing']);
is($couch->uri, $uri.'/','Absence of / handled OK');

subtest 'Connection to invalid URI' => sub {
	dies_ok { CouchDB::Interface->new(uri => 'http://rub.i.sh/', name => 'bogus') }, "Connection to invalid URI handled OK" ;	
};

lives_ok { $couch->del_db } "Database deletion OK" if $couch->has_db;	 

my $db = $couch->all_dbs;
ok( grep(/testing/, @{$db} ), "all_dbs works ( @{$db} )"  );
subtest 'Database creation' => sub {
	my $data;
	$data = $couch->create_db;
	is(defined $data->{ok} && $data->{ok} == 1, 1, 'Database creation OK');
		
};

my $data = $couch->del_db;
is(defined $data->{ok} && $data->{ok} == 1, 1, 'Database deletion OK');
is($couch->has_db('docs_testing'), 1, "has_db test OK");

done_testing();