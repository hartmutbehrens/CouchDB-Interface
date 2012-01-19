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
	return undef;
}

sub has_db {
	my $self = shift;
	my $name = shift // $self->name;
	return (grep { $_ eq $name } @{$self->all_dbs()}) ? 1 : 0;
}

sub create_db {
	my $self = shift;
	my $name = shift // $self->name;
	my $uri = $self->uri.$name.'/';
	my $request = CouchDB::Interface::Request->new(uri => $uri, debug => $self->debug, method => 'put');
	return $self->_get_response($request,201);
}

sub del_db {
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
	$self->insert($docs);
}

sub insert {
	my ($self,$docs) = @_;
	confess 'An arrray reference is expected' unless ref $docs eq 'ARRAY';
	$self->_get_rev($docs);
	my $request = CouchDB::Interface::Request->new(uri => $self->db_uri.'_bulk_docs', content => {'docs' => $docs}, debug => $self->debug, method => 'post');
	return $self->_get_response($request,201);
}

sub par_to_string {
	my ($self,$params) = @_;
	my $string = defined $params ? '&'.join( '&' ,map($_.'="'.$params->{$_}.'"' ,keys %$params)) : '';
	return $string;
}

#get revision, if one is available
sub _get_rev {
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
	return undef;
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
	return undef;
}

1;

=pod

=head1 SYNOPSIS
	
	use CouchDB::Interface;
	my $couch = CouchDB::Interface->new({uri => 'http://localhost:5984', name => $db});
	
	#if authentication credentials are required
	my $couch = CouchDB::Interface->new({uri => 'http://user:password@localhost:5984', name => $db});
	
	#get a list of all databases on the CouchDB server
	my @databases = $couch->all_dbs;
	
	#check whether a database exists on the CouchDB server
	my $exists_other = $couch->has_db($other_db);
	
	#create a database
	my $status = $couch->create_db($other_db);
	
	#delete a database
	my $status = $couch->del_db($other_db); 
	
	#check whether a document exists
	$couch->exists_doc( { id => $doc_id } );
	
	#save a document, assign id yourself
	my $content = { 'foo' => 'bar', 'bar' => 'foo' };
	my $status = $couch->save_doc( { id => $doc_id, content => $content } );
	
	#save a document, let CouchDB assign a unique id
	my $content = { 'foo' => 'bar', 'bar' => 'foo' };
	my $status = $couch->save_doc( { content => $content } );
	
	#retrieve a document
	my $doc = $couch->get_doc( { id => $doc_id } );
	
	#delete a document
	my $status = $couch->delete_doc( { id => $doc_id } );
	
	

=attr name 
The name of the database on the CouchDB server.

=attr debug 
Enable verbose debugging

=method new

Create a new CouchDB::Interface object.

	my $couch = CouchDB::Interface->new({uri => 'http://localhost:5984', name => $db});

=method all_dbs
List Get a list of databases on the CouchDB server.

=method has_db
Check whether a database exists on the CouchDB server. Returns 1 if the database is present and 0 otherwise.

	#check whether a database exists on the CouchDB server
	my $exists = $couch->has_db($db_name);
	
If no database name is provided, then the presence of the database specified in the 'name' attribute is checked.

	my $couch = CouchDB::Interface->new({uri => 'http://localhost:5984', name => $db});
	#check whether $db exists on the CouchDB server
	my $exists = $couch->has_db;  

=cut
__END__
