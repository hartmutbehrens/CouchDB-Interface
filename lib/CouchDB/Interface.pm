package CouchDB::Interface;
# ABSTRACT: CouchDB::Interface - use CouchDB's RESTful API

#pragmas
use strict;
use warnings;
use feature qw(say);

#modules
use Carp qw(confess);
use CouchDB::Interface::Request;
use Moo;

extends 'CouchDB::Interface::Connector';

has name => (is => 'rw', required => 1);
has debug => (is => 'rw', default => sub { return 0} );

sub all_dbs {
	my $self = shift;
	my $request = CouchDB::Interface::Request->new(uri => $self->uri.'_all_dbs', debug => $self->debug, method => 'get');
	my $dbs = $self->_get_response($request,200);
	if ($dbs) {
		return wantarray ? @{$dbs} : $dbs;
	}
	return;
}

sub has_db {
	my $self = shift;
	my $name = shift // $self->name;
	return ( grep { $_ eq $name } $self->all_dbs() ) ? 1 : 0;
}

sub create_db {
	my $self = shift;
	my $name = shift // $self->name;
	my $uri = $self->uri.$name.'/';
	my $request = CouchDB::Interface::Request->new(uri => $uri, debug => $self->debug, method => 'put');
	return $self->_get_response($request,201);
}

sub delete_db {
	my $self = shift;
	my $name = shift // $self->name;
	my $uri = $self->uri.$name.'/';
	my $request = CouchDB::Interface::Request->new(uri => $uri, debug => $self->debug, method => 'delete');
	return $self->_get_response($request,200);
}

sub db_uri {
	my $self = shift;
	return $self->uri.$self->name.'/'; 
}

sub doc_uri {
	my ($self,$par) = @_;
	my $uri = $self->db_uri.$par->{id};
	$uri .= '?rev='.$par->{rev} if defined $par->{rev};
	return $uri; 
}

sub _fetch {
	my ($self,$ids,$path) = @_; 
	confess "An arrray reference is expected" unless ref $ids eq 'ARRAY';
	my $request = CouchDB::Interface::Request->new(uri => $self->db_uri.$path, content => {'keys' => $ids}, debug => $self->debug, method => 'post');
	return $self->_get_response($request,200);
}

sub get_multiple {
	my ($self,$ids,$params) = @_;
	return $self->_fetch($ids,'_all_docs'.$self->par_to_string($params));
}

sub get_multiple_with_doc {
	my ($self,$ids,$params) = @_;
	return $self->_fetch($ids,'_all_docs?include_docs=true'.$self->par_to_string($params));
}

sub update {
	my ($self,$docs) = @_;
	return $self->insert($docs);
}

sub insert {
	my ($self,$docs) = @_;
	confess 'An arrray reference is expected' unless ref $docs eq 'ARRAY';
	$docs = $self->_add_rev($docs);
	my $request = CouchDB::Interface::Request->new(uri => $self->db_uri.'_bulk_docs', content => {'docs' => $docs}, debug => $self->debug, method => 'post');
	return $self->_get_response($request,201);
}

sub par_to_string {
	my ($self,$params) = @_;
	my $string = defined $params ? '&'.join( '&' ,map { $_.'="'.$params->{$_}.'"' } keys %$params ) : '';
	return $string;
}

#get revision, if one is available
sub _add_rev {
	my ($self,$docs) = @_;
	my %index;
	for my $i (0..$#$docs) {
		$index{$docs->[$i]->{_id}} = $i if defined $docs->[$i]->{_id};	#some docs may not have _id defined (POST request to Couch will assign _id)
	}
	my $ids = $self->get_multiple( [keys %index] );
	for my $id (@{$ids->{rows}}) {
		next unless defined $id->{value};
		$docs->[$index{$id->{id}}]->{_rev} = $id->{value}->{rev};	
	}
	return $docs;
}

sub exists_doc {
	my ($self,$params) = @_;
	return 1 if $self->get_doc($params);
	return 0;
}

sub get_doc {
	my ($self,$params) = @_;
	my $request = CouchDB::Interface::Request->new(uri => $self->doc_uri($params), debug => $self->debug, method => 'get');
	return $self->_get_response($request,200); 
}

sub _get_response {
	my ($self,$request,$expected) = @_;
	my $response = $request->execute;
	my $rv = $self->_is_response($response,$expected);
	return defined $rv ? $rv->json : undef; 
}

sub _is_response {
	my ($self,$response,$expected) = @_;
	if ($response) {
		return $response if defined $response->code && $response->code == $expected;
	}
	return;
}

sub save_doc {
	my ($self,$params) = @_;
	if ($params->{id}) {
		return $self->_put_doc($params);
	}
	else {
		return $self->_post_doc($params);
	}
}

sub _put_doc {
	my ($self,$params) = @_;
	
	my $doc = $self->get_doc($params);
	$params->{content}->{_rev} = $doc->{_rev} if $doc;	#if doc already exists, then fill in revision number unless it was provided
	my $request = CouchDB::Interface::Request->new(uri => $self->doc_uri($params), debug => $self->debug, method => 'put', content => $params->{content});
	return $self->_get_response($request,201);
}

sub _post_doc {
	my ($self,$params) = @_;
	my $request = CouchDB::Interface::Request->new(uri => $self->db_uri, debug => $self->debug, method => 'post', content => $params->{content});
	return $self->_get_response($request,201);
}

sub delete_doc {
	my ($self,$params) = @_;
	my $doc = $self->get_doc($params);
	if ($doc) {
		$params->{rev} = $doc->{_rev};
		my $request = CouchDB::Interface::Request->new(uri => $self->doc_uri($params), debug => $self->debug, method => 'delete');
		return $self->_get_response($request,200);
	}
	return;
}

1;

=pod

=head1 SYNOPSIS
	
	use CouchDB::Interface;
	my $couch = CouchDB::Interface->new({uri => 'http://localhost:5984', name => 'db_name'});
	
	#if authentication credentials are required
	my $couch = CouchDB::Interface->new({uri => 'http://user:password@localhost:5984', name => 'db_name'});
	
	#get a list of all databases on the CouchDB server
	my @databases = $couch->all_dbs;
	
	#check whether a database exists on the CouchDB server
	my $exists_other = $couch->has_db('name');
	
	#create a database
	my $status = $couch->create_db('name');
	
	#delete a database
	my $status = $couch->del_db('name'); 
	
	#check whether a document exists
	$couch->exists_doc( { id => 'some_doc_id' } );
	
	#save a document to the database, assign id yourself
	my $content = { 'foo' => 'bar', 'bar' => 'foo' };
	my $status = $couch->save_doc( { id => 'some_doc_id', content => $content } );
	
	#save a document to the database, let CouchDB assign a unique id
	my $content = { 'foo' => 'bar', 'bar' => 'foo' };
	my $status = $couch->save_doc( { content => $content } );
	
	#retrieve a document
	my $doc = $couch->get_doc( { id => 'some_doc_id' } );
	
	#delete a document
	my $status = $couch->delete_doc( { id => 'some_doc_id' } );
	
	

=attr name 
The name of the database on the CouchDB server.

=attr debug 
Enable verbose debugging

=method new

Create a new CouchDB::Interface object.

	my $couch = CouchDB::Interface->new({uri => 'http://localhost:5984', name => 'db_name'});

=method all_dbs
List Get a list of databases on the CouchDB server.

=method has_db('db_name')
Check whether the database exists on the CouchDB server. Returns 1 if the database is present and 0 otherwise.

	#check whether a database exists on the CouchDB server
	my $exists = $couch->has_db('db_name');
	
If a database name is not provided, then the presence of the database specified in the 'name' attribute is checked.

	my $couch = CouchDB::Interface->new({uri => 'http://localhost:5984', name => 'another_db'});
	my $exists = $couch->has_db; #check if 'another_db' exists on the CouchDB server
	
=method create_db('db_name')
Create a database on the CouchDB server.

	my $status = $couch->create_db('db_name'); # $status->{ok} == 1 if successful
	
If the request was succesful, then the hashref C<$status> will contain the decoded JSON response of the CouchDB server. 
For unsuccesful requests undef will be returned.

=method delete_db('db_name')
Delete a database on the CouchDB Server. 

	my $status = $couch->delete_db('db_name'); # $status->{ok} == 1 if successful
	
The return value is the same as for method C<create_db>

=method exists_doc('doc_id')
Check whether the named document exists on the CouchDB server. Returns 1 if the document is present and 0 otherwise.

	#check whether a database exists on the CouchDB server
	my $exists = $couch->exists_doc('doc_id');
	
=method get_doc('doc_id')
Retrieve the named document from CouchDB server.

	my $doc= $couch->get_doc('doc_id');
	
If the document exists, then the hashref C<$doc> will contain the decoded JSON response of the CouchDB server.
C<undef> will be returned if the document does not exist.

=method save_doc( { id => 'doc_id', content => $content } )
Save a document to the CouchDB server.

	my $content = { 'foo' => 'bar', 'bar' => 'foo' };
	my $status = $couch->save_doc( { id => 'some_doc_id', content => $content } ); # $status = {"ok" => 1} if successful

If the request was succesful, then the hashref C<$status> will contain the decoded JSON response of the CouchDB server. 
For unsuccesful requests undef will be returned.

The C<id> attribute may be omitted, in which case the CouchDB server will assign a unique UUID to the stored document.
The unique id will be available in the C<$status> hashref.

	my $status = $couch->save_doc( { content => $content } ); # $status->{ok} == 1 if successful
	say "The CouchDB assigned id of the document is: ", $status->{id};


=cut
__END__
