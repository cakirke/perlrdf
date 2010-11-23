# RDF::Query::Functions
# -----------------------------------------------------------------------------

=head1 NAME

RDF::Query::Functions - Standard Extension Functions

=head1 VERSION

This document describes RDF::Query::Functions version 2.904.

=head1 DESCRIPTION

This stub module simply loads all other modules named
C<< RDF::Query::Functions::* >>. Each of those modules
has an C<install> method that simply adds coderefs
to C<< %RDF::Query::functions >>.

=cut

package RDF::Query::Functions;

use strict;
use warnings;
no warnings 'redefine';

our $BLOOM_FILTER_LOADED;

use Log::Log4perl;

use Module::Pluggable
	search_path => [ __PACKAGE__ ],
	require     => 1,
	inner       => 1,
	sub_name    => 'function_sets',
	;

######################################################################

our ($VERSION, $l);
BEGIN {
	$l			= Log::Log4perl->get_logger("rdf.query.functions");
	$VERSION	= '2.904';
}

######################################################################

foreach my $function_set (__PACKAGE__->function_sets) {
	$function_set->install;
}

1;

__END__

=head1 SEE ALSO

L<RDF::Query::Functions::SPARQL>,
L<RDF::Query::Functions::Xpath>,
L<RDF::Query::Functions::Jena>,
L<RDF::Query::Functions::Geo>,
L<RDF::Query::Functions::Kasei>.

=head1 AUTHOR

 Gregory Williams <gwilliams@cpan.org>,
 Toby Inkster <tobyink@cpan.org>.

=cut
