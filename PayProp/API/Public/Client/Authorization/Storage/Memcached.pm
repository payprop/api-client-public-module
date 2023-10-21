package PayProp::API::Public::Client::Authorization::Storage::Memcached;

use strict;
use warnings;

use Mouse;
with qw/ PayProp::API::Public::Client::Role::Storage /;

use Mojo::Promise;
use Cache::Memcached;

=head1 NAME

	PayProp::API::Public::Client::Authorization::Storage::Memcached - Memcached storage solution.

=head1 SYNOPSIS

	my $MemcachedStorage = PayProp::API::Public::Client::Authorization::Storage::Memcached->new(
		servers => [ '127.0.0.1:11211' ], # Required: List of memcached servers.
	);

=head1 DESCRIPTION

Memcached storage solution to be provided for C<PayProp::API::Public::Client::Authorization::*>.

=cut

has servers => (
	is => 'ro',
	isa => 'ArrayRef[Str]',
	required => 1,
);

has Memcached => (
	is => 'ro',
	isa => 'Cache::Memcached',
	lazy => 1,
	default => sub { Cache::Memcached->new( servers => shift->servers ) },
);

sub _ping_p {
	my ( $self ) = @_;

	my ( $ping_key, $ping_value ) = ( __PACKAGE__ . '::ping', 'pong' );

	return Mojo::Promise->new(
		sub {
			my( $resolve, $reject ) = @_;

			my $value;
			eval {
				$value = $self->_get( $ping_key );
				$self->_set( $ping_key, $ping_value );
			};

			return ( $value // '' ) eq $ping_value
				? $resolve->( $ping_value )
				: $reject->('ping failed')
			;
		}
	);
}

sub _set_p {
	my ( $self, $key, $value ) = @_;

	return $self
		->_ping_p
		->then( sub { $self->_set( $key, $value ) } )
	;
}

sub _get_p {
	my ( $self, $key ) = @_;

	return $self
		->_ping_p
		->then( sub { $self->_get( $key ) } )
	;
}

sub _delete_p {
	my ( $self, $key ) = @_;

	return $self
		->_ping_p
		->then( sub { $self->_delete( $key ) } )
	;
}

sub _set {
	my ( $self, $key, $value ) = @_;

	$self->Memcached->set(
		$self->cache_prefix . $key,
		$value,
		$self->cache_ttl_in_seconds
	);

	return 1;
}

sub _get {
	my ( $self, $key ) = @_;

	my $value;
	$value = $self->Memcached->get( $self->cache_prefix . $key );

	return $value;
}

sub _delete {
	my ( $self, $key ) = @_;

	$self->Memcached->delete( $self->cache_prefix . $key );

	return 1;
}

__PACKAGE__->meta->make_immutable;
