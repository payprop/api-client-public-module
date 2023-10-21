package PayProp::API::Public::Client::Role::JSON;

use strict;
use warnings;

use Mouse::Role;

=head1 NAME

	PayProp::API::Public::Client::Role::JSON - Role to convert model to JSON structure.

=head1 SYNOPSIS

	package Module::Requiring::JSON;
	with qw/ PayProp::API::Public::Client::Role::JSON /;

	...;

	__PACKAGE__->meta->make_immutable;

	my $Module = Module::Requiring::JSON->new;
	my $structure_ref = $Module->TO_JSON;

=head1 DESCRIPTION

Role to convert C<Mouse> object to hashref structure via C<TO_JSON> method.
This role should only be consumed by parent models e.g. C<PayProp::API::Public::Client::Response::Export::*>.

*IMPORTANT*
The purpose of this role is to help with debugging API object response structures. It is not advised to
rely on the results returned from the C<TO_JSON> method. The results from this method can change without
prior warning.

=cut

sub TO_JSON {
	my ( $self, $value, $structure ) = @_;

	$value //= $self unless $structure;
	$structure //= {};

	my $ref_type = ref $value;

	if ( ! $ref_type || $ref_type =~ m/Bool/ ) {
		return $value;
	}
	elsif ( $ref_type eq 'ARRAY' ) {
		my @items;
		foreach my $item ( $value->@* ) {
			push @items, $self->TO_JSON( $item, $structure );
		}
		return \@items;
	}
	elsif ( $ref_type eq 'HASH' ) {
		foreach my $key ( keys $value->%* ) {
			$structure->{ $key } = $self->TO_JSON( $value->{ $key }, $structure );
		}
		return $structure;
	}
	elsif ( $ref_type =~ m/PayProp::API::Public::Client::Response/ ) {
		foreach my $Attribute (
			( map { $value->meta->get_attribute( $_ ) } $value->meta->get_attribute_list )
		) {
			my $key = $Attribute->name;

			my $reader = $Attribute->get_read_method;
			my $item = $value->$reader;

			$structure->{ $key } //= {};
			$structure->{ $key } = $self->TO_JSON( $item, $structure->{ $key } );
		}
	}
	else {
		die "Unhandled ref_type: $ref_type";
	}

	return $structure;
}

1;
