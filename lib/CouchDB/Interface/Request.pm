package CouchDB::Interface::Request;
# ABSTRACT: CouchDB::Interface::Request - wrap CouchDB::Interface method calls in an HTTP request and provide the HTTP response

#pragmas
use strict;
use warnings;
use feature qw(say);

#modules
use Moo;
use Mojo::JSON;
use Mojo::UserAgent;

has uri => ( is => 'rw', required => 1 );
has method => ( is => 'rw', required => 1 );
has content => ( is => 'rw' );
has debug => (is => 'rw', default => sub { return 0} );
has ua => ( is => 'rw', default => sub { return Mojo::UserAgent->new->detect_proxy->connect_timeout( 5 ) } );
has headers => (is => 'rw', default => sub { return { 'Cache-Control' => 'no-cache' } } );
has json => ( is => 'rw', default => sub { return Mojo::JSON->new } );
has max_retry => ( is => 'rw', default => sub { return 2 } );


sub execute {
	my $self = shift;
	
	my $content = $self->content; 
	if (ref $content) {	
        $content = $self->json->encode($content);
        $self->headers({ 'Cache-Control' => 'no-cache', 'Content-Type' => 'application/json' });
    }
    
	my ($count,$response,$method) = (0,undef,$self->method);
	while ( $response = $self->ua->$method($self->uri => $self->headers => $content )->res ) {
		$count++;
		say "Request repeat $count" if $count > 1 && $self->debug;
		last if (defined $response->code) || ($count > $self->max_retry);
	}
	$self->_describe($response) if $self->debug;
	return $response;
}

sub _describe {
	my ($self,$response) = @_;
	say "\tRequest:  ", uc($self->method),' ',$self->uri;
	say "\tSent Content:  ", $self->json->encode($self->content);
	say "\tResponse code was: \"",$response->code,'\ (',$response->message,')' if defined $response->code;
	say "\tError was: \"",$response->error,"\"." if defined $response->error;
	say '';
}
1;

=pod
=cut
__END__