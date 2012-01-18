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

unless ($ARGV[0]) {
    plan skip_all => "All tests skipped: URI for CouchDB server not provided";
}

my $uri = $ARGV[0];
my $debug = $ARGV[1] // 0;
my $couch = new_ok('CouchDB::Interface' => [uri => $uri, name => 'testing_db', debug => $debug]);

subtest 'Connection to invalid URI' => sub {
	dies_ok { CouchDB::Interface->new(uri => 'http://rub.i.sh/', name => 'bogus') }, "Connection to invalid URI handled OK" ;	
};

subtest 'Database deletion' => sub {
	SKIP: {
		skip 'database not available for deletion', 1 unless $couch->has_db;
		my $data = $couch->del_db;
		is(defined $data->{ok} && $data->{ok} == 1, 1, 'Database deletion OK');
	}
};	 

my $db = $couch->all_dbs;
ok( grep(/testing/, @{$db} ), "all_dbs works ( @{$db} )"  );
subtest 'Database creation' => sub {
	my $data = $couch->create_db;
	is(defined $data->{ok} && $data->{ok} == 1, 1, 'Database creation OK');
		
};

subtest 'Database deletion' => sub {
	SKIP: {
		skip 'database not available for deletion', 1 unless $couch->has_db;
		my $data = $couch->del_db;
		is(defined $data->{ok} && $data->{ok} == 1, 1, 'Database deletion OK');
	}
};
is($couch->has_db('testing_db'), 0, "has_db test OK");

done_testing();