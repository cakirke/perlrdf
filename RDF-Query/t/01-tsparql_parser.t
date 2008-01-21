#!/usr/bin/perl
use strict;
use warnings;
use utf8;

use Test::More tests => 108;

use YAML;
use Scalar::Util qw(reftype);

use_ok( 'RDF::Query::Parser::tSPARQL' );
my $parser	= new RDF::Query::Parser::tSPARQL ();
isa_ok( $parser, 'RDF::Query::Parser::tSPARQL' );



my (@data)	= YAML::Load(do { local($/) = undef; <DATA> });
foreach (@data) {
	next unless (reftype($_) eq 'ARRAY');
	my ($name, $sparql, $correct)	= @$_;
	my $parsed	= $parser->parse( $sparql );
	my $r	= is_deeply( $parsed, $correct, $name );
	unless ($r) {
		warn 'PARSE ERROR: ' . $parser->error;
		my $dump	= YAML::Dump($parsed);
		$dump		=~ s/\n/\n  /g;
		warn $dump;
		exit;
	}
}


sub _____ERRORS______ {}

##### ERRORS

{
	my $sparql	= <<"END";
		PREFIX	rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
		SELECT ?node
		WHERE {
			?node rdf:type <http://kasei.us/e/ns/mt/blog> .
		}
		extra stuff
END
	my $parsed	= $parser->parse( $sparql );
	is( $parsed, undef, 'extra input after query' );
	like( $parser->error, qr/Remaining input/, 'got expected error' );
}


__END__
---
- single triple; no prefix
- |
  SELECT ?node
  WHERE {
    ?node a <http://kasei.us/e/ns/mt/blog> .
  }
- method: SELECT
  namespaces: {}
  sources: []
  triples:
    - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
      - !!perl/array:RDF::Query::Algebra::Triple
        -
          - node
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://www.w3.org/1999/02/22-rdf-syntax-ns#type
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://kasei.us/e/ns/mt/blog
  variables:
    -
      - node
---
- simple DESCRIBE
- |
  DESCRIBE ?node
  WHERE { ?node a <http://kasei.us/e/ns/mt/blog> }
- method: DESCRIBE
  namespaces: {}
  sources: []
  triples:
    - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
      - !!perl/array:RDF::Query::Algebra::Triple
        -
          - node
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://www.w3.org/1999/02/22-rdf-syntax-ns#type
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://kasei.us/e/ns/mt/blog
  variables:
    -
      - node
---
- SELECT, WHERE, USING
- |
  PREFIX	rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
  PREFIX	foaf: <http://xmlns.com/foaf/0.1/>
  PREFIX	dcterms: <http://purl.org/dc/terms/>
  PREFIX	geo: <http://www.w3.org/2003/01/geo/wgs84_pos#>
  SELECT	?page
  WHERE	{
  			?person foaf:name "Gregory Todd Williams" .
  			?person foaf:homepage ?page .
  		}
- method: SELECT
  namespaces:
    dcterms: http://purl.org/dc/terms/
    foaf: http://xmlns.com/foaf/0.1/
    geo: http://www.w3.org/2003/01/geo/wgs84_pos#
    rdf: http://www.w3.org/1999/02/22-rdf-syntax-ns#
  sources: []
  triples:
    - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
      - !!perl/array:RDF::Query::Algebra::Triple
        -
          - person
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://xmlns.com/foaf/0.1/name
        - !!perl/array:RDF::Query::Node::Literal
          - LITERAL
          - Gregory Todd Williams
      - !!perl/array:RDF::Query::Algebra::Triple
        -
          - person
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://xmlns.com/foaf/0.1/homepage
        -
          - page
  variables:
    -
      - page
---
- SELECT, WHERE, USING; variables with "$"
- |
  PREFIX	rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
  PREFIX	foaf: <http://xmlns.com/foaf/0.1/>
  PREFIX	dcterms: <http://purl.org/dc/terms/>
  PREFIX	geo: <http://www.w3.org/2003/01/geo/wgs84_pos#>
  SELECT	$page
  WHERE	{
  			$person foaf:name "Gregory Todd Williams" .
  			$person foaf:homepage $page .
  		}
- method: SELECT
  namespaces:
    dcterms: http://purl.org/dc/terms/
    foaf: http://xmlns.com/foaf/0.1/
    geo: http://www.w3.org/2003/01/geo/wgs84_pos#
    rdf: http://www.w3.org/1999/02/22-rdf-syntax-ns#
  sources: []
  triples:
    - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
      - !!perl/array:RDF::Query::Algebra::Triple
        -
          - person
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://xmlns.com/foaf/0.1/name
        - !!perl/array:RDF::Query::Node::Literal
          - LITERAL
          - Gregory Todd Williams
      - !!perl/array:RDF::Query::Algebra::Triple
        -
          - person
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://xmlns.com/foaf/0.1/homepage
        -
          - page
  variables:
    -
      - page
---
- VarUri EQ OR constraint, numeric comparison constraint
- |
  PREFIX	rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
  PREFIX	foaf: <http://xmlns.com/foaf/0.1/>
  PREFIX	dcterms: <http://purl.org/dc/terms/>
  PREFIX	geo: <http://www.w3.org/2003/01/geo/wgs84_pos#>
  SELECT	?image ?point ?lat
  WHERE	{
  			?point geo:lat ?lat .
  			?image ?pred ?point .
  			FILTER(
  				(?pred = <http://purl.org/dc/terms/spatial> || ?pred = <http://xmlns.com/foaf/0.1/based_near>)
  				&&		?lat > 52.988674
  				&&		?lat < 53.036526
  			) .
  }
- method: SELECT
  namespaces:
    dcterms: http://purl.org/dc/terms/
    foaf: http://xmlns.com/foaf/0.1/
    geo: http://www.w3.org/2003/01/geo/wgs84_pos#
    rdf: http://www.w3.org/1999/02/22-rdf-syntax-ns#
  sources: []
  triples:
    - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
      - !!perl/array:RDF::Query::Algebra::Triple
        -
          - point
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://www.w3.org/2003/01/geo/wgs84_pos#lat
        -
          - lat
      - !!perl/array:RDF::Query::Algebra::Triple
        -
          - image
        -
          - pred
        -
          - point
    -
      - OLDFILTER
      -
        - '&&'
        -
          - '||'
          -
            - ==
            -
              - pred
            - !!perl/array:RDF::Query::Node::Resource
              - URI
              - http://purl.org/dc/terms/spatial
          -
            - ==
            -
              - pred
            - !!perl/array:RDF::Query::Node::Resource
              - URI
              - http://xmlns.com/foaf/0.1/based_near
        -
          - '>'
          -
            - lat
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - 52.988674
            - ~
            - http://www.w3.org/2001/XMLSchema#decimal
        -
          - <
          -
            - lat
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - 53.036526
            - ~
            - http://www.w3.org/2001/XMLSchema#decimal
  variables:
    -
      - image
    -
      - point
    -
      - lat
---
- regex constraint; no trailing '.'
- |
  PREFIX	rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
  PREFIX	foaf: <http://xmlns.com/foaf/0.1/>
  PREFIX	dcterms: <http://purl.org/dc/terms/>
  PREFIX	geo: <http://www.w3.org/2003/01/geo/wgs84_pos#>
  SELECT	?person ?homepage
  WHERE	{
  			?person foaf:name "Gregory Todd Williams" .
  			?person foaf:homepage ?homepage .
  			FILTER	REGEX(?homepage, "kasei")
  		}
- method: SELECT
  namespaces:
    dcterms: http://purl.org/dc/terms/
    foaf: http://xmlns.com/foaf/0.1/
    geo: http://www.w3.org/2003/01/geo/wgs84_pos#
    rdf: http://www.w3.org/1999/02/22-rdf-syntax-ns#
  sources: []
  triples:
    - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
      - !!perl/array:RDF::Query::Algebra::Triple
        -
          - person
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://xmlns.com/foaf/0.1/name
        - !!perl/array:RDF::Query::Node::Literal
          - LITERAL
          - Gregory Todd Williams
      - !!perl/array:RDF::Query::Algebra::Triple
        -
          - person
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://xmlns.com/foaf/0.1/homepage
        -
          - homepage
    -
      - OLDFILTER
      -
        - '~~'
        -
          - homepage
        - !!perl/array:RDF::Query::Node::Literal
          - LITERAL
          - kasei
  variables:
    -
      - person
    -
      - homepage
---
- filter with variable/function-call equality
- |
  PREFIX	rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
  PREFIX	foaf: <http://xmlns.com/foaf/0.1/>
  PREFIX	dcterms: <http://purl.org/dc/terms/>
  PREFIX	geo: <http://www.w3.org/2003/01/geo/wgs84_pos#>
  PREFIX	func: <http://example.com/>
  SELECT	?person ?homepage
  WHERE	{
  			?person foaf:name "Gregory Todd Williams" .
  			?person ?pred ?homepage .
  			FILTER( ?pred = func:homepagepred() ) .
  		}
- method: SELECT
  namespaces:
    dcterms: http://purl.org/dc/terms/
    foaf: http://xmlns.com/foaf/0.1/
    geo: http://www.w3.org/2003/01/geo/wgs84_pos#
    rdf: http://www.w3.org/1999/02/22-rdf-syntax-ns#
    func: http://example.com/
  sources: []
  triples:
    - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
      - !!perl/array:RDF::Query::Algebra::Triple
        -
          - person
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://xmlns.com/foaf/0.1/name
        - !!perl/array:RDF::Query::Node::Literal
          - LITERAL
          - Gregory Todd Williams
      - !!perl/array:RDF::Query::Algebra::Triple
        -
          - person
        -
          - pred
        -
          - homepage
    -
      - OLDFILTER
      -
        - ==
        -
          - pred
        - !!perl/array:RDF::Query::Algebra::Function
          - FUNCTION
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://example.com/homepagepred
  variables:
    -
      - person
    -
      - homepage
---
- filter with variable/function-call equality
- |
  		PREFIX	rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
  		PREFIX	foaf: <http://xmlns.com/foaf/0.1/>
  		PREFIX	dcterms: <http://purl.org/dc/terms/>
  		PREFIX	geo: <http://www.w3.org/2003/01/geo/wgs84_pos#>
  		SELECT	?person ?homepage
  		WHERE	{
  					?person foaf:name "Gregory Todd Williams" .
  					?person ?pred ?homepage .
  					FILTER( ?pred = <func:homepagepred>() ) .
  				}
- method: SELECT
  namespaces:
    dcterms: http://purl.org/dc/terms/
    foaf: http://xmlns.com/foaf/0.1/
    geo: http://www.w3.org/2003/01/geo/wgs84_pos#
    rdf: http://www.w3.org/1999/02/22-rdf-syntax-ns#
  sources: []
  triples:
    - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
      - !!perl/array:RDF::Query::Algebra::Triple
        -
          - person
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://xmlns.com/foaf/0.1/name
        - !!perl/array:RDF::Query::Node::Literal
          - LITERAL
          - Gregory Todd Williams
      - !!perl/array:RDF::Query::Algebra::Triple
        -
          - person
        -
          - pred
        -
          - homepage
    -
      - OLDFILTER
      -
        - ==
        -
          - pred
        - !!perl/array:RDF::Query::Algebra::Function
          - FUNCTION
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - func:homepagepred
  variables:
    -
      - person
    -
      - homepage
---
- filter with LANG(?var)/literal equality
- |
  PREFIX	rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
  PREFIX	foaf: <http://xmlns.com/foaf/0.1/>
  PREFIX	dcterms: <http://purl.org/dc/terms/>
  PREFIX	geo: <http://www.w3.org/2003/01/geo/wgs84_pos#>
  SELECT	?person ?homepage
  WHERE	{
  			?person foaf:name ?name .
  			FILTER( LANG(?name) = 'en' ) .
  		}
- method: SELECT
  namespaces:
    dcterms: http://purl.org/dc/terms/
    foaf: http://xmlns.com/foaf/0.1/
    geo: http://www.w3.org/2003/01/geo/wgs84_pos#
    rdf: http://www.w3.org/1999/02/22-rdf-syntax-ns#
  sources: []
  triples:
    - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
      - !!perl/array:RDF::Query::Algebra::Triple
        -
          - person
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://xmlns.com/foaf/0.1/name
        -
          - name
    -
      - OLDFILTER
      -
        - ==
        - !!perl/array:RDF::Query::Algebra::Function
          - FUNCTION
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - sparql:lang
          -
            - name
        - !!perl/array:RDF::Query::Node::Literal
          - LITERAL
          - en
  variables:
    -
      - person
    -
      - homepage
---
- filter with LANGMATCHES(?var, 'literal')
- |
  PREFIX	rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
  PREFIX	foaf: <http://xmlns.com/foaf/0.1/>
  PREFIX	dcterms: <http://purl.org/dc/terms/>
  PREFIX	geo: <http://www.w3.org/2003/01/geo/wgs84_pos#>
  SELECT	?person ?homepage
  WHERE	{
  			?person foaf:name ?name .
  			FILTER( LANGMATCHES(?name, "foo"@en ) ).
  		}
- method: SELECT
  namespaces:
    dcterms: http://purl.org/dc/terms/
    foaf: http://xmlns.com/foaf/0.1/
    geo: http://www.w3.org/2003/01/geo/wgs84_pos#
    rdf: http://www.w3.org/1999/02/22-rdf-syntax-ns#
  sources: []
  triples:
    - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
      - !!perl/array:RDF::Query::Algebra::Triple
        -
          - person
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://xmlns.com/foaf/0.1/name
        -
          - name
    -
      - OLDFILTER
      - !!perl/array:RDF::Query::Algebra::Function
        - FUNCTION
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - sparql:langmatches
        -
          - name
        - !!perl/array:RDF::Query::Node::Literal
          - LITERAL
          - foo
          - en
          - ~
  variables:
    -
      - person
    -
      - homepage
---
- filter with isLITERAL(?var)
- |
  PREFIX	rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
  PREFIX	foaf: <http://xmlns.com/foaf/0.1/>
  PREFIX	dcterms: <http://purl.org/dc/terms/>
  PREFIX	geo: <http://www.w3.org/2003/01/geo/wgs84_pos#>
  SELECT	?person ?homepage
  WHERE	{
  			?person foaf:name ?name .
  			FILTER( isLITERAL(?name) ).
  		}
- method: SELECT
  namespaces:
    dcterms: http://purl.org/dc/terms/
    foaf: http://xmlns.com/foaf/0.1/
    geo: http://www.w3.org/2003/01/geo/wgs84_pos#
    rdf: http://www.w3.org/1999/02/22-rdf-syntax-ns#
  sources: []
  triples:
    - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
      - !!perl/array:RDF::Query::Algebra::Triple
        -
          - person
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://xmlns.com/foaf/0.1/name
        -
          - name
    -
      - OLDFILTER
      - !!perl/array:RDF::Query::Algebra::Function
        - FUNCTION
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - sop:isLiteral
        -
          - name
  variables:
    -
      - person
    -
      - homepage
---
- filter with DATATYPE(?var)/URI equality
- |
  PREFIX	rdfs: <http://www.w3.org/2000/01/rdf-schema#>
  PREFIX	rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
  PREFIX	foaf: <http://xmlns.com/foaf/0.1/>
  PREFIX	dcterms: <http://purl.org/dc/terms/>
  PREFIX	geo: <http://www.w3.org/2003/01/geo/wgs84_pos#>
  SELECT	?person ?homepage
  WHERE	{
  			?person foaf:name ?name .
  			FILTER( DATATYPE(?name) = rdfs:Literal ) .
  		}
- method: SELECT
  namespaces:
    dcterms: http://purl.org/dc/terms/
    foaf: http://xmlns.com/foaf/0.1/
    geo: http://www.w3.org/2003/01/geo/wgs84_pos#
    rdf: http://www.w3.org/1999/02/22-rdf-syntax-ns#
    rdfs: http://www.w3.org/2000/01/rdf-schema#
  sources: []
  triples:
    - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
      - !!perl/array:RDF::Query::Algebra::Triple
        -
          - person
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://xmlns.com/foaf/0.1/name
        -
          - name
    -
      - OLDFILTER
      -
        - ==
        - !!perl/array:RDF::Query::Algebra::Function
          - FUNCTION
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - sparql:datatype
          -
            - name
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://www.w3.org/2000/01/rdf-schema#Literal
  variables:
    -
      - person
    -
      - homepage
---
- multiple attributes using ';'
- |
  PREFIX	foaf: <http://xmlns.com/foaf/0.1/>
  SELECT	?person ?homepage
  WHERE	{
  			?person foaf:name "Gregory Todd Williams" ; foaf:homepage ?homepage .
  		}
- method: SELECT
  namespaces:
    foaf: http://xmlns.com/foaf/0.1/
  sources: []
  triples:
    - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
      - !!perl/array:RDF::Query::Algebra::Triple
        - &1
          - person
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://xmlns.com/foaf/0.1/name
        - !!perl/array:RDF::Query::Node::Literal
          - LITERAL
          - Gregory Todd Williams
      - !!perl/array:RDF::Query::Algebra::Triple
        - *1
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://xmlns.com/foaf/0.1/homepage
        -
          - homepage
  variables:
    -
      - person
    -
      - homepage
---
- predicate with full qURI
- |
  PREFIX	foaf: <http://xmlns.com/foaf/0.1/>
  SELECT	?person
  WHERE	{
  			?person foaf:name "Gregory Todd Williams", "Greg Williams" .
  		}
- method: SELECT
  namespaces:
    foaf: http://xmlns.com/foaf/0.1/
  sources: []
  triples:
    - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
      - !!perl/array:RDF::Query::Algebra::Triple
        - &1
          - person
        - &2 !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://xmlns.com/foaf/0.1/name
        - !!perl/array:RDF::Query::Node::Literal
          - LITERAL
          - Gregory Todd Williams
      - !!perl/array:RDF::Query::Algebra::Triple
        - *1
        - *2
        - !!perl/array:RDF::Query::Node::Literal
          - LITERAL
          - Greg Williams
  variables:
    -
      - person
---
- "'a' rdf:type"
- |
  PREFIX	foaf: <http://xmlns.com/foaf/0.1/>
  SELECT	?person
  WHERE	{
  			?person <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> foaf:Person
  		}
- method: SELECT
  namespaces:
    foaf: http://xmlns.com/foaf/0.1/
  sources: []
  triples:
    - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
      - !!perl/array:RDF::Query::Algebra::Triple
        -
          - person
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://www.w3.org/1999/02/22-rdf-syntax-ns#type
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://xmlns.com/foaf/0.1/Person
  variables:
    -
      - person
---
- "'a' rdf:type; multiple attributes using ';'"
- |
  PREFIX	foaf: <http://xmlns.com/foaf/0.1/>
  SELECT	?name
  WHERE	{
  			?person a foaf:Person ; foaf:name ?name .
  		}
- method: SELECT
  namespaces:
    foaf: http://xmlns.com/foaf/0.1/
  sources: []
  triples:
    - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
      - !!perl/array:RDF::Query::Algebra::Triple
        - &1
          - person
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://www.w3.org/1999/02/22-rdf-syntax-ns#type
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://xmlns.com/foaf/0.1/Person
      - !!perl/array:RDF::Query::Algebra::Triple
        - *1
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://xmlns.com/foaf/0.1/name
        -
          - name
  variables:
    -
      - name
---
- "blank node subject; multiple attributes using ';'"
- |
  PREFIX	foaf: <http://xmlns.com/foaf/0.1/>
  SELECT	?nick
  WHERE	{
  			[ foaf:name "Gregory Todd Williams" ; foaf:nick ?nick ] .
  		}
- method: SELECT
  namespaces:
    foaf: http://xmlns.com/foaf/0.1/
  sources: []
  triples:
    - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
      - !!perl/array:RDF::Query::Algebra::Triple
        - &1 !!perl/array:RDF::Query::Node::Blank
          - BLANK
          - a1
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://xmlns.com/foaf/0.1/name
        - !!perl/array:RDF::Query::Node::Literal
          - LITERAL
          - Gregory Todd Williams
      - !!perl/array:RDF::Query::Algebra::Triple
        - *1
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://xmlns.com/foaf/0.1/nick
        -
          - nick
  variables:
    -
      - nick
---
- "blank node subject; using brackets '[...]'; 'a' rdf:type"
- |
  PREFIX	foaf: <http://xmlns.com/foaf/0.1/>
  SELECT	?name
  WHERE	{
  			[ a foaf:Person ] foaf:name ?name .
  		}
- method: SELECT
  namespaces:
    foaf: http://xmlns.com/foaf/0.1/
  sources: []
  triples:
    - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
      - !!perl/array:RDF::Query::Algebra::Triple
        - &1 !!perl/array:RDF::Query::Node::Blank
          - BLANK
          - a1
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://www.w3.org/1999/02/22-rdf-syntax-ns#type
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://xmlns.com/foaf/0.1/Person
      - !!perl/array:RDF::Query::Algebra::Triple
        - *1
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://xmlns.com/foaf/0.1/name
        -
          - name
  variables:
    -
      - name
---
- "blank node subject; empty brackets '[]'"
- |
  PREFIX	foaf: <http://xmlns.com/foaf/0.1/>
  SELECT	?name
  WHERE	{
  			[] foaf:name ?name .
  		}
- method: SELECT
  namespaces:
    foaf: http://xmlns.com/foaf/0.1/
  sources: []
  triples:
    - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
      - !!perl/array:RDF::Query::Algebra::Triple
        - !!perl/array:RDF::Query::Node::Blank
          - BLANK
          - a1
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://xmlns.com/foaf/0.1/name
        -
          - name
  variables:
    -
      - name
---
- blank node object
- |
  PREFIX dao: <http://kasei.us/ns/dao#>
  PREFIX dc: <http://purl.org/dc/elements/1.1/>
  PREFIX beer: <http://www.csd.abdn.ac.uk/research/AgentCities/ontologies/beer#>
  
  SELECT ?name
  WHERE {
  	?me dao:consumed [ a beer:Ale ; beer:name ?name ] .
  }
- method: SELECT
  namespaces:
    beer: http://www.csd.abdn.ac.uk/research/AgentCities/ontologies/beer#
    dao: http://kasei.us/ns/dao#
    dc: http://purl.org/dc/elements/1.1/
  sources: []
  triples:
    - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
      - !!perl/array:RDF::Query::Algebra::Triple
        -
          - me
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://kasei.us/ns/dao#consumed
        - &1 !!perl/array:RDF::Query::Node::Blank
          - BLANK
          - a1
      - !!perl/array:RDF::Query::Algebra::Triple
        - *1
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://www.w3.org/1999/02/22-rdf-syntax-ns#type
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://www.csd.abdn.ac.uk/research/AgentCities/ontologies/beer#Ale
      - !!perl/array:RDF::Query::Algebra::Triple
        - *1
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://www.csd.abdn.ac.uk/research/AgentCities/ontologies/beer#name
        -
          - name
  variables:
    -
      - name
---
- blank node; using qName _:abc
- |
  PREFIX	foaf: <http://xmlns.com/foaf/0.1/>
  SELECT	?name
  WHERE	{
  			_:abc foaf:name ?name .
  		}
- method: SELECT
  namespaces:
    foaf: http://xmlns.com/foaf/0.1/
  sources: []
  triples:
    - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
      - !!perl/array:RDF::Query::Algebra::Triple
        - !!perl/array:RDF::Query::Node::Blank
          - BLANK
          - abc
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://xmlns.com/foaf/0.1/name
        -
          - name
  variables:
    -
      - name
---
- select with ORDER BY
- |
  PREFIX	foaf: <http://xmlns.com/foaf/0.1/>
  SELECT	?name
  WHERE	{
  			?person a foaf:Person; foaf:name ?name
  		}
  ORDER BY ?name
- method: SELECT
  namespaces:
    foaf: http://xmlns.com/foaf/0.1/
  options:
    orderby:
      -
        - ASC
        -
          - name
  sources: []
  triples:
    - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
      - !!perl/array:RDF::Query::Algebra::Triple
        - &1
          - person
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://www.w3.org/1999/02/22-rdf-syntax-ns#type
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://xmlns.com/foaf/0.1/Person
      - !!perl/array:RDF::Query::Algebra::Triple
        - *1
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://xmlns.com/foaf/0.1/name
        -
          - name
  variables:
    -
      - name
---
- select with DISTINCT
- |
  PREFIX	foaf: <http://xmlns.com/foaf/0.1/>
  SELECT	DISTINCT ?name
  WHERE	{
  			?person a foaf:Person; foaf:name ?name
  		}
- method: SELECT
  namespaces:
    foaf: http://xmlns.com/foaf/0.1/
  options:
    distinct: 1
  sources: []
  triples:
    - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
      - !!perl/array:RDF::Query::Algebra::Triple
        - &1
          - person
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://www.w3.org/1999/02/22-rdf-syntax-ns#type
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://xmlns.com/foaf/0.1/Person
      - !!perl/array:RDF::Query::Algebra::Triple
        - *1
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://xmlns.com/foaf/0.1/name
        -
          - name
  variables:
    -
      - name
---
- select with ORDER BY; asc()
- |
  PREFIX	foaf: <http://xmlns.com/foaf/0.1/>
  SELECT	?name
  WHERE	{
  			?person a foaf:Person; foaf:name ?name
  		}
  ORDER BY asc( ?name )
- method: SELECT
  namespaces:
    foaf: http://xmlns.com/foaf/0.1/
  options:
    orderby:
      -
        - ASC
        -
          - name
  sources: []
  triples:
    - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
      - !!perl/array:RDF::Query::Algebra::Triple
        - &1
          - person
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://www.w3.org/1999/02/22-rdf-syntax-ns#type
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://xmlns.com/foaf/0.1/Person
      - !!perl/array:RDF::Query::Algebra::Triple
        - *1
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://xmlns.com/foaf/0.1/name
        -
          - name
  variables:
    -
      - name
---
- select with ORDER BY; DESC()
- |2
  		PREFIX	foaf: <http://xmlns.com/foaf/0.1/>
  		SELECT	?name
  		WHERE	{
  					?person a foaf:Person; foaf:name ?name
  				}
  		ORDER BY DESC(?name)
- method: SELECT
  namespaces:
    foaf: http://xmlns.com/foaf/0.1/
  options:
    orderby:
      -
        - DESC
        -
          - name
  sources: []
  triples:
    - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
      - !!perl/array:RDF::Query::Algebra::Triple
        - &1
          - person
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://www.w3.org/1999/02/22-rdf-syntax-ns#type
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://xmlns.com/foaf/0.1/Person
      - !!perl/array:RDF::Query::Algebra::Triple
        - *1
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://xmlns.com/foaf/0.1/name
        -
          - name
  variables:
    -
      - name
---
- select with ORDER BY; DESC(); with LIMIT
- |2
  		PREFIX	foaf: <http://xmlns.com/foaf/0.1/>
  		SELECT	?name
  		WHERE	{
  					?person a foaf:Person; foaf:name ?name
  				}
  		ORDER BY DESC(?name) LIMIT 10
- method: SELECT
  namespaces:
    foaf: http://xmlns.com/foaf/0.1/
  options:
    limit: 10
    orderby:
      -
        - DESC
        -
          - name
  sources: []
  triples:
    - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
      - !!perl/array:RDF::Query::Algebra::Triple
        - &1
          - person
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://www.w3.org/1999/02/22-rdf-syntax-ns#type
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://xmlns.com/foaf/0.1/Person
      - !!perl/array:RDF::Query::Algebra::Triple
        - *1
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://xmlns.com/foaf/0.1/name
        -
          - name
  variables:
    -
      - name
---
- select with ORDER BY; DESC(); with LIMIT; variables with "$"
- |2
  		PREFIX foaf: <http://xmlns.com/foaf/0.1/>
  		PREFIX dc: <http://purl.org/dc/elements/1.1/>
  		 select $pic $thumb $date 
  		 WHERE { $pic foaf:thumbnail $thumb .
  		 $pic dc:date $date } order by desc($date) limit 10
- method: SELECT
  namespaces:
    dc: http://purl.org/dc/elements/1.1/
    foaf: http://xmlns.com/foaf/0.1/
  options:
    limit: 10
    orderby:
      -
        - DESC
        -
          - date
  sources: []
  triples:
    - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
      - !!perl/array:RDF::Query::Algebra::Triple
        -
          - pic
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://xmlns.com/foaf/0.1/thumbnail
        -
          - thumb
      - !!perl/array:RDF::Query::Algebra::Triple
        -
          - pic
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://purl.org/dc/elements/1.1/date
        -
          - date
  variables:
    -
      - pic
    -
      - thumb
    -
      - date
---
- FILTER function call 1
- |2
  		PREFIX	rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
  		PREFIX	foaf: <http://xmlns.com/foaf/0.1/>
  		PREFIX	dcterms: <http://purl.org/dc/terms/>
  		PREFIX	geo: <http://www.w3.org/2003/01/geo/wgs84_pos#>
  		PREFIX	mygeo: <http://kasei.us/e/ns/geo#>
  		SELECT	?image ?point ?lat
  		WHERE	{
  					?point geo:lat ?lat .
  					?image ?pred ?point .
  					FILTER( mygeo:distance(?point, +41.849331, -71.392) < 10 )
  				}
- method: SELECT
  namespaces:
    dcterms: http://purl.org/dc/terms/
    foaf: http://xmlns.com/foaf/0.1/
    geo: http://www.w3.org/2003/01/geo/wgs84_pos#
    mygeo: http://kasei.us/e/ns/geo#
    rdf: http://www.w3.org/1999/02/22-rdf-syntax-ns#
  sources: []
  triples:
    - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
      - !!perl/array:RDF::Query::Algebra::Triple
        -
          - point
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://www.w3.org/2003/01/geo/wgs84_pos#lat
        -
          - lat
      - !!perl/array:RDF::Query::Algebra::Triple
        -
          - image
        -
          - pred
        -
          - point
    -
      - OLDFILTER
      -
        - <
        - !!perl/array:RDF::Query::Algebra::Function
          - FUNCTION
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://kasei.us/e/ns/geo#distance
          -
            - point
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - 41.849331
            - ~
            - http://www.w3.org/2001/XMLSchema#decimal
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - -71.392
            - ~
            - http://www.w3.org/2001/XMLSchema#decimal
        - !!perl/array:RDF::Query::Node::Literal
          - LITERAL
          - 10
          - ~
          - http://www.w3.org/2001/XMLSchema#integer
  variables:
    -
      - image
    -
      - point
    -
      - lat
---
- FILTER function call 2
- |2
  		PREFIX	rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
  		PREFIX	foaf: <http://xmlns.com/foaf/0.1/>
  		PREFIX	dcterms: <http://purl.org/dc/terms/>
  		PREFIX	geo: <http://www.w3.org/2003/01/geo/wgs84_pos#>
  		PREFIX	mygeo: <http://kasei.us/e/ns/geo#>
  		SELECT	?image ?point ?lat
  		WHERE	{
  					?point geo:lat ?lat .
  					?image ?pred ?point .
  					FILTER( mygeo:distance(?point, 41.849331, -71.392) < 5 + 5 )
  				}
- method: SELECT
  namespaces:
    dcterms: http://purl.org/dc/terms/
    foaf: http://xmlns.com/foaf/0.1/
    geo: http://www.w3.org/2003/01/geo/wgs84_pos#
    mygeo: http://kasei.us/e/ns/geo#
    rdf: http://www.w3.org/1999/02/22-rdf-syntax-ns#
  sources: []
  triples:
    - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
      - !!perl/array:RDF::Query::Algebra::Triple
        -
          - point
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://www.w3.org/2003/01/geo/wgs84_pos#lat
        -
          - lat
      - !!perl/array:RDF::Query::Algebra::Triple
        -
          - image
        -
          - pred
        -
          - point
    -
      - OLDFILTER
      -
        - <
        - !!perl/array:RDF::Query::Algebra::Function
          - FUNCTION
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://kasei.us/e/ns/geo#distance
          -
            - point
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - 41.849331
            - ~
            - http://www.w3.org/2001/XMLSchema#decimal
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - -71.392
            - ~
            - http://www.w3.org/2001/XMLSchema#decimal
        -
          - +
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - 5
            - ~
            - http://www.w3.org/2001/XMLSchema#integer
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - 5
            - ~
            - http://www.w3.org/2001/XMLSchema#integer
  variables:
    -
      - image
    -
      - point
    -
      - lat
---
- FILTER function call 3
- |2
  		PREFIX	rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
  		PREFIX	foaf: <http://xmlns.com/foaf/0.1/>
  		PREFIX	dcterms: <http://purl.org/dc/terms/>
  		PREFIX	geo: <http://www.w3.org/2003/01/geo/wgs84_pos#>
  		PREFIX	mygeo: <http://kasei.us/e/ns/geo#>
  		SELECT	?image ?point ?lat
  		WHERE	{
  					?point geo:lat ?lat .
  					?image ?pred ?point .
  					FILTER( mygeo:distance(?point, 41.849331, -71.392) < 5 * 5 )
  				}
- method: SELECT
  namespaces:
    dcterms: http://purl.org/dc/terms/
    foaf: http://xmlns.com/foaf/0.1/
    geo: http://www.w3.org/2003/01/geo/wgs84_pos#
    mygeo: http://kasei.us/e/ns/geo#
    rdf: http://www.w3.org/1999/02/22-rdf-syntax-ns#
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          -
            - point
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/2003/01/geo/wgs84_pos#lat
          -
            - lat
        - !!perl/array:RDF::Query::Algebra::Triple
          -
            - image
          -
            - pred
          -
            - point
      -
        - OLDFILTER
        -
          - <
          - !!perl/array:RDF::Query::Algebra::Function
            - FUNCTION
            - !!perl/array:RDF::Query::Node::Resource
              - URI
              - http://kasei.us/e/ns/geo#distance
            -
              - point
            - !!perl/array:RDF::Query::Node::Literal
              - LITERAL
              - 41.849331
              - ~
              - http://www.w3.org/2001/XMLSchema#decimal
            - !!perl/array:RDF::Query::Node::Literal
              - LITERAL
              - -71.392
              - ~
              - http://www.w3.org/2001/XMLSchema#decimal
          -
            - '*'
            - !!perl/array:RDF::Query::Node::Literal
              - LITERAL
              - 5
              - ~
              - http://www.w3.org/2001/XMLSchema#integer
            - !!perl/array:RDF::Query::Node::Literal
              - LITERAL
              - 5
              - ~
              - http://www.w3.org/2001/XMLSchema#integer
  variables:
    -
      - image
    -
      - point
    -
      - lat
---
- multiple FILTERs; with function call
- |2
  		PREFIX	rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
  		PREFIX	foaf: <http://xmlns.com/foaf/0.1/>
  		PREFIX	dcterms: <http://purl.org/dc/terms/>
  		PREFIX	geo: <http://www.w3.org/2003/01/geo/wgs84_pos#>
  		PREFIX	mygeo: <http://kasei.us/e/ns/geo#>
  		SELECT	?image ?point ?name
  		WHERE	{
  					?image dcterms:spatial ?point .
  					?point foaf:name ?name .
  					FILTER( mygeo:distance(?point, 41.849331, -71.392) < 10 ) .
  					FILTER REGEX(?name, "Providence, RI")
  				}
- method: SELECT
  namespaces:
    dcterms: http://purl.org/dc/terms/
    foaf: http://xmlns.com/foaf/0.1/
    geo: http://www.w3.org/2003/01/geo/wgs84_pos#
    mygeo: http://kasei.us/e/ns/geo#
    rdf: http://www.w3.org/1999/02/22-rdf-syntax-ns#
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          -
            - image
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://purl.org/dc/terms/spatial
          -
            - point
        - !!perl/array:RDF::Query::Algebra::Triple
          -
            - point
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://xmlns.com/foaf/0.1/name
          -
            - name
      -
        - OLDFILTER
        -
          - <
          - !!perl/array:RDF::Query::Algebra::Function
            - FUNCTION
            - !!perl/array:RDF::Query::Node::Resource
              - URI
              - http://kasei.us/e/ns/geo#distance
            -
              - point
            - !!perl/array:RDF::Query::Node::Literal
              - LITERAL
              - 41.849331
              - ~
              - http://www.w3.org/2001/XMLSchema#decimal
            - !!perl/array:RDF::Query::Node::Literal
              - LITERAL
              - -71.392
              - ~
              - http://www.w3.org/2001/XMLSchema#decimal
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - 10
            - ~
            - http://www.w3.org/2001/XMLSchema#integer
      -
        - OLDFILTER
        -
          - '~~'
          -
            - name
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - 'Providence, RI'
  variables:
    -
      - image
    -
      - point
    -
      - name
---
- "optional triple '{...}'"
- |2
  		PREFIX	foaf: <http://xmlns.com/foaf/0.1/>
  		SELECT	?person ?name ?mbox
  		WHERE	{
  					?person foaf:name ?name .
  					OPTIONAL { ?person foaf:mbox ?mbox }
  				}
- method: SELECT
  namespaces:
    foaf: http://xmlns.com/foaf/0.1/
  sources: []
  triples:
    - !!perl/array:RDF::Query::Algebra::Optional
      - OPTIONAL
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          - !!perl/array:RDF::Query::Node::Variable
            - person
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://xmlns.com/foaf/0.1/name
          - !!perl/array:RDF::Query::Node::Variable
            - name
      - !!perl/array:RDF::Query::Algebra::GroupGraphPattern
        - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
          - !!perl/array:RDF::Query::Algebra::Triple
            - !!perl/array:RDF::Query::Node::Variable
              - person
            - !!perl/array:RDF::Query::Node::Resource
              - URI
              - http://xmlns.com/foaf/0.1/mbox
            - !!perl/array:RDF::Query::Node::Variable
              - mbox
  variables:
    -
      - person
    -
      - name
    -
      - mbox
---
- "optional triples '{...; ...}'"
- |2
  		PREFIX	foaf: <http://xmlns.com/foaf/0.1/>
  		SELECT	?person ?name ?mbox ?nick
  		WHERE	{
  					?person foaf:name ?name .
  					OPTIONAL {
  						?person foaf:mbox ?mbox; foaf:nick ?nick
  					}
  				}
- method: SELECT
  namespaces:
    foaf: http://xmlns.com/foaf/0.1/
  sources: []
  triples:
    - !!perl/array:RDF::Query::Algebra::Optional
      - OPTIONAL
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          - !!perl/array:RDF::Query::Node::Variable
            - person
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://xmlns.com/foaf/0.1/name
          - !!perl/array:RDF::Query::Node::Variable
            - name
      - !!perl/array:RDF::Query::Algebra::GroupGraphPattern
        - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
          - !!perl/array:RDF::Query::Algebra::Triple
            - &1 !!perl/array:RDF::Query::Node::Variable
              - person
            - !!perl/array:RDF::Query::Node::Resource
              - URI
              - http://xmlns.com/foaf/0.1/mbox
            - !!perl/array:RDF::Query::Node::Variable
              - mbox
          - !!perl/array:RDF::Query::Algebra::Triple
            - *1
            - !!perl/array:RDF::Query::Node::Resource
              - URI
              - http://xmlns.com/foaf/0.1/nick
            - !!perl/array:RDF::Query::Node::Variable
              - nick
  variables:
    -
      - person
    -
      - name
    -
      - mbox
    -
      - nick
---
- union; sparql 6.2
- |2
  		PREFIX dc10:  <http://purl.org/dc/elements/1.1/>
  		PREFIX dc11:  <http://purl.org/dc/elements/1.0/>
  		SELECT	?title ?author
  		WHERE	{
  					{ ?book dc10:title ?title .  ?book dc10:creator ?author }
  					UNION
  					{ ?book dc11:title ?title .  ?book dc11:creator ?author }
  				}
- method: SELECT
  namespaces:
    dc10: http://purl.org/dc/elements/1.1/
    dc11: http://purl.org/dc/elements/1.0/
  sources: []
  triples:
    - !!perl/array:RDF::Query::Algebra::Union
      - UNION
      - !!perl/array:RDF::Query::Algebra::GroupGraphPattern
        - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
          - !!perl/array:RDF::Query::Algebra::Triple
            - !!perl/array:RDF::Query::Node::Variable
              - book
            - !!perl/array:RDF::Query::Node::Resource
              - URI
              - http://purl.org/dc/elements/1.1/title
            - !!perl/array:RDF::Query::Node::Variable
              - title
          - !!perl/array:RDF::Query::Algebra::Triple
            - !!perl/array:RDF::Query::Node::Variable
              - book
            - !!perl/array:RDF::Query::Node::Resource
              - URI
              - http://purl.org/dc/elements/1.1/creator
            - !!perl/array:RDF::Query::Node::Variable
              - author
      - !!perl/array:RDF::Query::Algebra::GroupGraphPattern
        - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
          - !!perl/array:RDF::Query::Algebra::Triple
            - !!perl/array:RDF::Query::Node::Variable
              - book
            - !!perl/array:RDF::Query::Node::Resource
              - URI
              - http://purl.org/dc/elements/1.0/title
            - !!perl/array:RDF::Query::Node::Variable
              - title
          - !!perl/array:RDF::Query::Algebra::Triple
            - !!perl/array:RDF::Query::Node::Variable
              - book
            - !!perl/array:RDF::Query::Node::Resource
              - URI
              - http://purl.org/dc/elements/1.0/creator
            - !!perl/array:RDF::Query::Node::Variable
              - author
  variables:
    -
      - title
    -
      - author
---
- literal language tag @en
- |2
  		PREFIX	foaf: <http://xmlns.com/foaf/0.1/>
  		SELECT	?person ?homepage
  		WHERE	{
  					?person foaf:name "Gary Peck"@en ; foaf:homepage ?homepage .
  				}
- method: SELECT
  namespaces:
    foaf: http://xmlns.com/foaf/0.1/
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          - &1
            - person
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://xmlns.com/foaf/0.1/name
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - Gary Peck
            - en
            - ~
        - !!perl/array:RDF::Query::Algebra::Triple
          - *1
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://xmlns.com/foaf/0.1/homepage
          -
            - homepage
  variables:
    -
      - person
    -
      - homepage
---
- typed literal ^^URI
- |2
  		PREFIX	dc: <http://purl.org/dc/elements/1.1/>
  		PREFIX	foaf: <http://xmlns.com/foaf/0.1/>
  		SELECT	?image
  		WHERE	{
  					?image dc:date "2005-04-07T18:27:56-04:00"^^<http://www.w3.org/2001/XMLSchema#dateTime>
  				}
- method: SELECT
  namespaces:
    dc: http://purl.org/dc/elements/1.1/
    foaf: http://xmlns.com/foaf/0.1/
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          -
            - image
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://purl.org/dc/elements/1.1/date
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - 2005-04-07T18:27:56-04:00
            - ~
            - http://www.w3.org/2001/XMLSchema#dateTime
  variables:
    -
      - image
---
- typed literal ^^qName
- |2
  		PREFIX	foaf: <http://xmlns.com/foaf/0.1/>
  		PREFIX	dc: <http://purl.org/dc/elements/1.1/>
  		PREFIX  xs: <http://www.w3.org/2001/XMLSchema#>
  		SELECT	?image
  		WHERE	{
  					?image dc:date "2005-04-07T18:27:56-04:00"^^xs:dateTime
  				}
- method: SELECT
  namespaces:
    foaf: http://xmlns.com/foaf/0.1/
    dc: http://purl.org/dc/elements/1.1/
    xs: http://www.w3.org/2001/XMLSchema#
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          -
            - image
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://purl.org/dc/elements/1.1/date
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - 2005-04-07T18:27:56-04:00
            - ~
            - http://www.w3.org/2001/XMLSchema#dateTime
  variables:
    -
      - image
---
- subject collection syntax
- |2
  		SELECT	?x
  		WHERE	{ (1 ?x 3) }
- method: SELECT
  namespaces: {}
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          - &1 !!perl/array:RDF::Query::Node::Blank
            - BLANK
            - a1
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#first
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - 1
            - ~
            - http://www.w3.org/2001/XMLSchema#integer
        - !!perl/array:RDF::Query::Algebra::Triple
          - *1
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#rest
          - &2 !!perl/array:RDF::Query::Node::Blank
            - BLANK
            - a2
        - !!perl/array:RDF::Query::Algebra::Triple
          - *2
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#first
          -
            - x
        - !!perl/array:RDF::Query::Algebra::Triple
          - *2
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#rest
          - &3 !!perl/array:RDF::Query::Node::Blank
            - BLANK
            - a3
        - !!perl/array:RDF::Query::Algebra::Triple
          - *3
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#first
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - 3
            - ~
            - http://www.w3.org/2001/XMLSchema#integer
        - !!perl/array:RDF::Query::Algebra::Triple
          - *3
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#rest
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#nil
  variables:
    -
      - x
---
- subject collection syntax; with pred-obj.
- |2
  		PREFIX	foaf: <http://xmlns.com/foaf/0.1/>
  		SELECT	?x
  		WHERE	{ (1 ?x 3) foaf:name "My Collection" }
- method: SELECT
  namespaces:
    foaf: http://xmlns.com/foaf/0.1/
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          - &1 !!perl/array:RDF::Query::Node::Blank
            - BLANK
            - a1
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#first
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - 1
            - ~
            - http://www.w3.org/2001/XMLSchema#integer
        - !!perl/array:RDF::Query::Algebra::Triple
          - *1
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#rest
          - &2 !!perl/array:RDF::Query::Node::Blank
            - BLANK
            - a2
        - !!perl/array:RDF::Query::Algebra::Triple
          - *2
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#first
          -
            - x
        - !!perl/array:RDF::Query::Algebra::Triple
          - *2
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#rest
          - &3 !!perl/array:RDF::Query::Node::Blank
            - BLANK
            - a3
        - !!perl/array:RDF::Query::Algebra::Triple
          - *3
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#first
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - 3
            - ~
            - http://www.w3.org/2001/XMLSchema#integer
        - !!perl/array:RDF::Query::Algebra::Triple
          - *3
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#rest
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#nil
        - !!perl/array:RDF::Query::Algebra::Triple
          - *1
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://xmlns.com/foaf/0.1/name
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - My Collection
  variables:
    -
      - x
---
- subject collection syntax; object collection syntax
- |2
  		PREFIX dc: <http://purl.org/dc/elements/1.1/>
  		SELECT	?x
  		WHERE	{ (1 ?x 3) dc:subject (1 2 3) }
- method: SELECT
  namespaces:
    dc: http://purl.org/dc/elements/1.1/
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          - &1 !!perl/array:RDF::Query::Node::Blank
            - BLANK
            - a1
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#first
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - 1
            - ~
            - http://www.w3.org/2001/XMLSchema#integer
        - !!perl/array:RDF::Query::Algebra::Triple
          - *1
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#rest
          - &2 !!perl/array:RDF::Query::Node::Blank
            - BLANK
            - a2
        - !!perl/array:RDF::Query::Algebra::Triple
          - *2
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#first
          -
            - x
        - !!perl/array:RDF::Query::Algebra::Triple
          - *2
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#rest
          - &3 !!perl/array:RDF::Query::Node::Blank
            - BLANK
            - a3
        - !!perl/array:RDF::Query::Algebra::Triple
          - *3
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#first
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - 3
            - ~
            - http://www.w3.org/2001/XMLSchema#integer
        - !!perl/array:RDF::Query::Algebra::Triple
          - *3
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#rest
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#nil
        - !!perl/array:RDF::Query::Algebra::Triple
          - &4 !!perl/array:RDF::Query::Node::Blank
            - BLANK
            - a4
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#first
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - 1
            - ~
            - http://www.w3.org/2001/XMLSchema#integer
        - !!perl/array:RDF::Query::Algebra::Triple
          - *4
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#rest
          - &5 !!perl/array:RDF::Query::Node::Blank
            - BLANK
            - a5
        - !!perl/array:RDF::Query::Algebra::Triple
          - *5
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#first
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - 2
            - ~
            - http://www.w3.org/2001/XMLSchema#integer
        - !!perl/array:RDF::Query::Algebra::Triple
          - *5
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#rest
          - &6 !!perl/array:RDF::Query::Node::Blank
            - BLANK
            - a6
        - !!perl/array:RDF::Query::Algebra::Triple
          - *6
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#first
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - 3
            - ~
            - http://www.w3.org/2001/XMLSchema#integer
        - !!perl/array:RDF::Query::Algebra::Triple
          - *6
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#rest
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#nil
        - !!perl/array:RDF::Query::Algebra::Triple
          - *1
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://purl.org/dc/elements/1.1/subject
          - *4
  variables:
    -
      - x
---
- object collection syntax
- |2
  		PREFIX test: <http://kasei.us/e/ns/test#>
  		SELECT	?x
  		WHERE	{
  					<http://kasei.us/about/foaf.xrdf#greg> test:mycollection (1 ?x 3) .
  				}
- method: SELECT
  namespaces:
    test: http://kasei.us/e/ns/test#
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://kasei.us/about/foaf.xrdf#greg
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://kasei.us/e/ns/test#mycollection
          - &1 !!perl/array:RDF::Query::Node::Blank
            - BLANK
            - a1
        - !!perl/array:RDF::Query::Algebra::Triple
          - *1
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#first
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - 1
            - ~
            - http://www.w3.org/2001/XMLSchema#integer
        - !!perl/array:RDF::Query::Algebra::Triple
          - *1
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#rest
          - &2 !!perl/array:RDF::Query::Node::Blank
            - BLANK
            - a2
        - !!perl/array:RDF::Query::Algebra::Triple
          - *2
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#first
          -
            - x
        - !!perl/array:RDF::Query::Algebra::Triple
          - *2
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#rest
          - &3 !!perl/array:RDF::Query::Node::Blank
            - BLANK
            - a3
        - !!perl/array:RDF::Query::Algebra::Triple
          - *3
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#first
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - 3
            - ~
            - http://www.w3.org/2001/XMLSchema#integer
        - !!perl/array:RDF::Query::Algebra::Triple
          - *3
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#rest
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#nil
  variables:
    -
      - x
---
- SELECT *
- |2
  		SELECT *
  		WHERE { ?a ?a ?b . }
- method: SELECT
  namespaces: {}
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          -
            - a
          -
            - a
          -
            - b
  variables:
    - !!perl/array:RDF::Query::Node::Variable
      - a
    - !!perl/array:RDF::Query::Node::Variable
      - b
---
- default prefix
- |2
  		PREFIX	: <http://xmlns.com/foaf/0.1/>
  		SELECT	?person
  		WHERE	{
  					?person :name "Gregory Todd Williams", "Greg Williams" .
  				}
- method: SELECT
  namespaces:
    __DEFAULT__: http://xmlns.com/foaf/0.1/
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          - &1
            - person
          - &2 !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://xmlns.com/foaf/0.1/name
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - Gregory Todd Williams
        - !!perl/array:RDF::Query::Algebra::Triple
          - *1
          - *2
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - Greg Williams
  variables:
    -
      - person
---
- select from named; single triple; no prefix
- |2
  			PREFIX foaf: <http://xmlns.com/foaf/0.1/>
  			SELECT ?src ?name
  			FROM NAMED <file://data/named_graphs/alice.rdf>
  			FROM NAMED <file://data/named_graphs/bob.rdf>
  			WHERE {
  				GRAPH ?src { ?x foaf:name ?name }
  			}
- method: SELECT
  namespaces:
    foaf: http://xmlns.com/foaf/0.1/
  sources:
    -
      - URI
      - file://data/named_graphs/alice.rdf
      - NAMED
    -
      - URI
      - file://data/named_graphs/bob.rdf
      - NAMED
  triples:
    - !!perl/array:RDF::Query::Algebra::NamedGraph
      - GRAPH
      - !!perl/array:RDF::Query::Node::Variable
        - src
      - !!perl/array:RDF::Query::Algebra::GroupGraphPattern
        - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
          - !!perl/array:RDF::Query::Algebra::Triple
            - !!perl/array:RDF::Query::Node::Variable
              - x
            - !!perl/array:RDF::Query::Node::Resource
              - URI
              - http://xmlns.com/foaf/0.1/name
            - !!perl/array:RDF::Query::Node::Variable
              - name
  variables:
    -
      - src
    -
      - name
---
- ASK FILTER; using <= (shouldn't parse as '<')
- |2
  				PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
  				ASK {
  					FILTER ( "1995-11-05"^^xsd:dateTime <= "1994-11-05T13:15:30Z"^^xsd:dateTime ) .
  				}
- method: ASK
  namespaces:
    xsd: http://www.w3.org/2001/XMLSchema#
  sources: []
  triples:
      -
        - OLDFILTER
        -
          - <=
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - 1995-11-05
            - ~
            - http://www.w3.org/2001/XMLSchema#dateTime
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - 1994-11-05T13:15:30Z
            - ~
            - http://www.w3.org/2001/XMLSchema#dateTime
  variables: []
---
- ORDER BY with expression
- |2
  		PREFIX	rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
  		PREFIX	foaf: <http://xmlns.com/foaf/0.1/>
  		PREFIX	dcterms: <http://purl.org/dc/terms/>
  		PREFIX	geo: <http://www.w3.org/2003/01/geo/wgs84_pos#>
  		PREFIX	xsd: <http://www.w3.org/2001/XMLSchema#>
  		SELECT	?image ?point ?lat
  		WHERE	{
  					?point geo:lat ?lat .
  					?image ?pred ?point .
  		}
  		ORDER BY ASC( xsd:decimal( ?lat ) )
- method: SELECT
  namespaces:
    dcterms: http://purl.org/dc/terms/
    foaf: http://xmlns.com/foaf/0.1/
    geo: http://www.w3.org/2003/01/geo/wgs84_pos#
    rdf: http://www.w3.org/1999/02/22-rdf-syntax-ns#
    xsd: http://www.w3.org/2001/XMLSchema#
  options:
    orderby:
      -
        - ASC
        -
          - FUNCTION
          -
            - URI
            -
              - xsd
              - decimal
          -
            - lat
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          -
            - point
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/2003/01/geo/wgs84_pos#lat
          -
            - lat
        - !!perl/array:RDF::Query::Algebra::Triple
          -
            - image
          -
            - pred
          -
            - point
  variables:
    -
      - image
    -
      - point
    -
      - lat
---
- triple pattern with trailing internal '.'
- |
  PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
  PREFIX foaf: <http://xmlns.com/foaf/0.1/>
  PREFIX cyc: <http://www.cyc.com/2004/06/04/cyc#>
  PREFIX dcterms: <http://purl.org/dc/terms/>
  PREFIX dc: <http://purl.org/dc/elements/1.1/>
  SELECT ?place ?img ?date
  WHERE {
  	?region foaf:name "Maine" .
  	?p cyc:inRegion ?region; foaf:name ?place .
  	?img dcterms:spatial ?p .
  	?img dc:date ?date;  rdf:type foaf:Image .
  }
  ORDER BY DESC(?date)
  LIMIT 10
- method: SELECT
  namespaces:
    cyc: http://www.cyc.com/2004/06/04/cyc#
    dc: http://purl.org/dc/elements/1.1/
    dcterms: http://purl.org/dc/terms/
    foaf: http://xmlns.com/foaf/0.1/
    rdf: http://www.w3.org/1999/02/22-rdf-syntax-ns#
  options:
    limit: 10
    orderby:
      -
        - DESC
        -
          - date
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          -
            - region
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://xmlns.com/foaf/0.1/name
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - Maine
        - !!perl/array:RDF::Query::Algebra::Triple
          - &1
            - p
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.cyc.com/2004/06/04/cyc#inRegion
          -
            - region
        - !!perl/array:RDF::Query::Algebra::Triple
          - *1
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://xmlns.com/foaf/0.1/name
          -
            - place
        - !!perl/array:RDF::Query::Algebra::Triple
          -
            - img
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://purl.org/dc/terms/spatial
          -
            - p
        - !!perl/array:RDF::Query::Algebra::Triple
          - &2
            - img
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://purl.org/dc/elements/1.1/date
          -
            - date
        - !!perl/array:RDF::Query::Algebra::Triple
          - *2
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#type
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://xmlns.com/foaf/0.1/Image
  variables:
    -
      - place
    -
      - img
    -
      - date
---
- "[bug] query with predicate starting with 'a' (confused with { ?subj a ?type})"
- |2
  			PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
  			PREFIX foaf: <http://xmlns.com/foaf/0.1/>
  			PREFIX cyc: <http://www.cyc.com/2004/06/04/cyc#>
  			PREFIX dcterms: <http://purl.org/dc/terms/>
  			PREFIX dc: <http://purl.org/dc/elements/1.1/>
  			PREFIX album: <http://kasei.us/e/ns/album#>
  			PREFIX p: <http://www.usefulinc.com/picdiary/>
  			SELECT ?img ?date
  			WHERE {
  				<http://kasei.us/pictures/parties/19991205-Tims_Party/> album:image ?img .
  				?img dc:date ?date ; rdf:type foaf:Image .
  			}
  			ORDER BY DESC(?date)
- method: SELECT
  namespaces:
    album: http://kasei.us/e/ns/album#
    cyc: http://www.cyc.com/2004/06/04/cyc#
    dc: http://purl.org/dc/elements/1.1/
    dcterms: http://purl.org/dc/terms/
    foaf: http://xmlns.com/foaf/0.1/
    p: http://www.usefulinc.com/picdiary/
    rdf: http://www.w3.org/1999/02/22-rdf-syntax-ns#
  options:
    orderby:
      -
        - DESC
        -
          - date
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://kasei.us/pictures/parties/19991205-Tims_Party/
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://kasei.us/e/ns/album#image
          -
            - img
        - !!perl/array:RDF::Query::Algebra::Triple
          - &1
            - img
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://purl.org/dc/elements/1.1/date
          -
            - date
        - !!perl/array:RDF::Query::Algebra::Triple
          - *1
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#type
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://xmlns.com/foaf/0.1/Image
  variables:
    -
      - img
    -
      - date
---
- dawg/simple/01
- |2
  		PREFIX : <http://example.org/data/>
  		
  		SELECT *
  		WHERE { :x ?p ?q . }
- method: SELECT
  namespaces:
    __DEFAULT__: http://example.org/data/
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://example.org/data/x
          -
            - p
          -
            - q
  variables:
    - !!perl/array:RDF::Query::Node::Variable
      - p
    - !!perl/array:RDF::Query::Node::Variable
      - q
---
- single triple with comment; dawg/data/part1
- |2
  		# Get name, and optionally the mbox, of each person
  		
  		PREFIX foaf: <http://xmlns.com/foaf/0.1/>
  		
  		SELECT ?name ?mbox
  		WHERE
  		  { ?person foaf:name ?name .
  			OPTIONAL { ?person foaf:mbox ?mbox}
  		  }
- method: SELECT
  namespaces:
    foaf: http://xmlns.com/foaf/0.1/
  sources: []
  triples:
    - !!perl/array:RDF::Query::Algebra::Optional
      - OPTIONAL
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          - !!perl/array:RDF::Query::Node::Variable
            - person
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://xmlns.com/foaf/0.1/name
          - !!perl/array:RDF::Query::Node::Variable
            - name
      - !!perl/array:RDF::Query::Algebra::GroupGraphPattern
        - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
          - !!perl/array:RDF::Query::Algebra::Triple
            - !!perl/array:RDF::Query::Node::Variable
              - person
            - !!perl/array:RDF::Query::Node::Resource
              - URI
              - http://xmlns.com/foaf/0.1/mbox
            - !!perl/array:RDF::Query::Node::Variable
              - mbox
  variables:
    -
      - name
    -
      - mbox
---
- ask query
- |
  ASK {
    ?node a <http://kasei.us/e/ns/mt/blog> .
  }
- method: ASK
  namespaces: {}
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          -
            - node
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#type
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://kasei.us/e/ns/mt/blog
  variables: []
---
- blank-pred-blank
- |
  PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
  PREFIX foaf: <http://xmlns.com/foaf/0.1/>
  SELECT ?name
  WHERE {
    [ foaf:name ?name ] foaf:maker []
  }
- method: SELECT
  namespaces:
    foaf: http://xmlns.com/foaf/0.1/
    rdf: http://www.w3.org/1999/02/22-rdf-syntax-ns#
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          - &1 !!perl/array:RDF::Query::Node::Blank
            - BLANK
            - a1
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://xmlns.com/foaf/0.1/name
          -
            - name
        - !!perl/array:RDF::Query::Algebra::Triple
          - *1
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://xmlns.com/foaf/0.1/maker
          - !!perl/array:RDF::Query::Node::Blank
            - BLANK
            - a2
  variables:
    -
      - name
---
- Filter with unary-plus
- |
  PREFIX	rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
  PREFIX	foaf: <http://xmlns.com/foaf/0.1/>
  PREFIX	dcterms: <http://purl.org/dc/terms/>
  PREFIX	geo: <http://www.w3.org/2003/01/geo/wgs84_pos#>
  SELECT	?image ?point ?lat
  WHERE	{
  			?point geo:lat ?lat .
  			?image ?pred ?point .
  			FILTER( ?lat > +52 )
  }
- method: SELECT
  namespaces:
    dcterms: http://purl.org/dc/terms/
    foaf: http://xmlns.com/foaf/0.1/
    geo: http://www.w3.org/2003/01/geo/wgs84_pos#
    rdf: http://www.w3.org/1999/02/22-rdf-syntax-ns#
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          -
            - point
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/2003/01/geo/wgs84_pos#lat
          -
            - lat
        - !!perl/array:RDF::Query::Algebra::Triple
          -
            - image
          -
            - pred
          -
            - point
      -
        - OLDFILTER
        -
          - '>'
          -
            - lat
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - 52
            - ~
            - http://www.w3.org/2001/XMLSchema#integer
  variables:
    -
      - image
    -
      - point
    -
      - lat
---
- Filter with isIRI
- |
  PREFIX	rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
  PREFIX	foaf: <http://xmlns.com/foaf/0.1/>
  PREFIX	dcterms: <http://purl.org/dc/terms/>
  PREFIX	geo: <http://www.w3.org/2003/01/geo/wgs84_pos#>
  SELECT	?image ?point ?lat
  WHERE	{
  			?point geo:lat ?lat .
  			?image ?pred ?point .
  			FILTER( isIRI(?image) )
  }
- method: SELECT
  namespaces:
    dcterms: http://purl.org/dc/terms/
    foaf: http://xmlns.com/foaf/0.1/
    geo: http://www.w3.org/2003/01/geo/wgs84_pos#
    rdf: http://www.w3.org/1999/02/22-rdf-syntax-ns#
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          -
            - point
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/2003/01/geo/wgs84_pos#lat
          -
            - lat
        - !!perl/array:RDF::Query::Algebra::Triple
          -
            - image
          -
            - pred
          -
            - point
      -
        - OLDFILTER
        - !!perl/array:RDF::Query::Algebra::Function
          - FUNCTION
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - sop:isIRI
          -
            - image
  variables:
    -
      - image
    -
      - point
    -
      - lat
---
- 'xsd:double'
- |
  PREFIX dc:  <http://purl.org/dc/elements/1.1/>
  SELECT ?node
  WHERE {
    ?node dc:identifier 1e4 .
  }
- method: SELECT
  namespaces:
    dc: http://purl.org/dc/elements/1.1/
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          -
            - node
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://purl.org/dc/elements/1.1/identifier
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - 1e4
            - ~
            - http://www.w3.org/2001/XMLSchema#double
  variables:
    -
      - node
---
- boolean literal
- |
  PREFIX dc:  <http://purl.org/dc/elements/1.1/>
  SELECT ?node
  WHERE {
    ?node dc:identifier true .
  }
- method: SELECT
  namespaces:
    dc: http://purl.org/dc/elements/1.1/
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          -
            - node
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://purl.org/dc/elements/1.1/identifier
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - true
            - ~
            - http://www.w3.org/2001/XMLSchema#boolean
  variables:
    -
      - node
---
- select with ORDER BY function call
- |
  PREFIX	foaf: <http://xmlns.com/foaf/0.1/>
  SELECT	?name
  WHERE	{
  			?person a foaf:Person; foaf:name ?name
  		}
  ORDER BY :foo(?name)
- method: SELECT
  namespaces:
    foaf: http://xmlns.com/foaf/0.1/
  options:
    orderby:
      -
        - ASC
        -
          - FUNCTION
          - 
            - URI
            -
              - __DEFAULT__
              - foo
          -
            - name
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          - &1
            - person
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#type
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://xmlns.com/foaf/0.1/Person
        - !!perl/array:RDF::Query::Algebra::Triple
          - *1
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://xmlns.com/foaf/0.1/name
          -
            - name
  variables:
    -
      - name
---
- select with bnode object as second pred-obj
- |
  PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
  PREFIX foaf: <http://xmlns.com/foaf/0.1/>
  SELECT ?name
  WHERE {
    ?r foaf:name ?name ; foaf:maker [ a foaf:Person ]
  }
- method: SELECT
  namespaces:
    foaf: http://xmlns.com/foaf/0.1/
    rdf: http://www.w3.org/1999/02/22-rdf-syntax-ns#
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          - &1
            - r
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://xmlns.com/foaf/0.1/name
          -
            - name
        - !!perl/array:RDF::Query::Algebra::Triple
          - *1
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://xmlns.com/foaf/0.1/maker
          - &2 !!perl/array:RDF::Query::Node::Blank
            - BLANK
            - a1
        - !!perl/array:RDF::Query::Algebra::Triple
          - *2
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#type
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://xmlns.com/foaf/0.1/Person
  variables:
    -
      - name
---
- select with qname with '-2' suffix
- |
  PREFIX	foaf: <http://xmlns.com/foaf/0.1/>
  PREFIX	wn: <http://xmlns.com/wordnet/1.6/>
  SELECT	?thing
  WHERE	{
  	?image a foaf:Image ;
  		foaf:depicts ?thing .
  	?thing a wn:Flower-2 .
  }
- method: SELECT
  namespaces:
    foaf: http://xmlns.com/foaf/0.1/
    wn: http://xmlns.com/wordnet/1.6/
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          - &1
            - image
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#type
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://xmlns.com/foaf/0.1/Image
        - !!perl/array:RDF::Query::Algebra::Triple
          - *1
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://xmlns.com/foaf/0.1/depicts
          -
            - thing
        - !!perl/array:RDF::Query::Algebra::Triple
          -
            - thing
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#type
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://xmlns.com/wordnet/1.6/Flower-2
  variables:
    -
      - thing
---
- select with qname with underscore
- |
  PREFIX	foaf: <http://xmlns.com/foaf/0.1/>
  SELECT	?name
  WHERE	{
  	?p a foaf:Person ;
  		foaf:mbox_sha1sum "2057969209f1dfdad832de387cf13e6ff8c93b12" ;
  		foaf:name ?name .
  }
- method: SELECT
  namespaces:
    foaf: http://xmlns.com/foaf/0.1/
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          - &1
            - p
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#type
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://xmlns.com/foaf/0.1/Person
        - !!perl/array:RDF::Query::Algebra::Triple
          - *1
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://xmlns.com/foaf/0.1/mbox_sha1sum
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - 2057969209f1dfdad832de387cf13e6ff8c93b12
        - !!perl/array:RDF::Query::Algebra::Triple
          - *1
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://xmlns.com/foaf/0.1/name
          -
            - name
  variables:
    -
      - name
---
- construct with one construct triple
- |
  PREFIX	foaf: <http://xmlns.com/foaf/0.1/>
  CONSTRUCT { ?person foaf:name ?name }
  WHERE	{ ?person foaf:firstName ?name }
- method: CONSTRUCT
  namespaces:
    foaf: http://xmlns.com/foaf/0.1/
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          -
            - person
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://xmlns.com/foaf/0.1/firstName
          -
            - name
  construct_triples:
    - !!perl/array:RDF::Query::Algebra::Triple
      -
        - person
      - !!perl/array:RDF::Query::Node::Resource
        - URI
        - http://xmlns.com/foaf/0.1/name
      -
        - name
---
- construct with two construct triples
- |
  PREFIX	foaf: <http://xmlns.com/foaf/0.1/>
  CONSTRUCT { ?person foaf:name ?name . ?person a foaf:Person }
  WHERE	{ ?person foaf:firstName ?name }
- method: CONSTRUCT
  namespaces:
    foaf: http://xmlns.com/foaf/0.1/
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          -
            - person
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://xmlns.com/foaf/0.1/firstName
          -
            - name
  construct_triples:
    - !!perl/array:RDF::Query::Algebra::Triple
      -
        - person
      - !!perl/array:RDF::Query::Node::Resource
        - URI
        - http://xmlns.com/foaf/0.1/name
      -
        - name
    - !!perl/array:RDF::Query::Algebra::Triple
      -
        - person
      - !!perl/array:RDF::Query::Node::Resource
        - URI
        - http://www.w3.org/1999/02/22-rdf-syntax-ns#type
      - !!perl/array:RDF::Query::Node::Resource
        - URI
        - http://xmlns.com/foaf/0.1/Person
---
- construct with three construct triples
- |
  PREFIX	foaf: <http://xmlns.com/foaf/0.1/>
  CONSTRUCT { ?person a foaf:Person  . ?person foaf:name ?name . ?person foaf:firstName ?name }
  WHERE	{ ?person foaf:firstName ?name }
- method: CONSTRUCT
  namespaces:
    foaf: http://xmlns.com/foaf/0.1/
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          -
            - person
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://xmlns.com/foaf/0.1/firstName
          -
            - name
  construct_triples:
    - !!perl/array:RDF::Query::Algebra::Triple
      -
        - person
      - !!perl/array:RDF::Query::Node::Resource
        - URI
        - http://www.w3.org/1999/02/22-rdf-syntax-ns#type
      - !!perl/array:RDF::Query::Node::Resource
        - URI
        - http://xmlns.com/foaf/0.1/Person
    - !!perl/array:RDF::Query::Algebra::Triple
      -
        - person
      - !!perl/array:RDF::Query::Node::Resource
        - URI
        - http://xmlns.com/foaf/0.1/name
      -
        - name
    - !!perl/array:RDF::Query::Algebra::Triple
      -
        - person
      - !!perl/array:RDF::Query::Node::Resource
        - URI
        - http://xmlns.com/foaf/0.1/firstName
      -
        - name
---
- select with triple-optional-triple
- |
  PREFIX	foaf: <http://xmlns.com/foaf/0.1/>
  SELECT	?person ?nick ?page
  WHERE	{
  	?person foaf:name "Gregory Todd Williams" .
  	OPTIONAL { ?person foaf:nick ?nick } .
  	?person foaf:homepage ?page
  }
- method: SELECT
  namespaces:
    foaf: http://xmlns.com/foaf/0.1/
  sources: []
  triples:
    - !!perl/array:RDF::Query::Algebra::Optional
      - OPTIONAL
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          - !!perl/array:RDF::Query::Node::Variable
            - person
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://xmlns.com/foaf/0.1/name
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - Gregory Todd Williams
      - !!perl/array:RDF::Query::Algebra::GroupGraphPattern
        - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
          - !!perl/array:RDF::Query::Algebra::Triple
            - !!perl/array:RDF::Query::Node::Variable
              - person
            - !!perl/array:RDF::Query::Node::Resource
              - URI
              - http://xmlns.com/foaf/0.1/nick
            - !!perl/array:RDF::Query::Node::Variable
              - nick
    - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
      - !!perl/array:RDF::Query::Algebra::Triple
        - !!perl/array:RDF::Query::Node::Variable
          - person
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://xmlns.com/foaf/0.1/homepage
        - !!perl/array:RDF::Query::Node::Variable
          - page
  variables:
    -
      - person
    -
      - nick
    -
      - page
---
- select with FROM
- |
  PREFIX	foaf: <http://xmlns.com/foaf/0.1/>
  PREFIX	geo: <http://www.w3.org/2003/01/geo/wgs84_pos#>
  SELECT	?lat ?long
  FROM	<http://homepage.mac.com/samofool/rdf-query/test-data/greenwich.rdf>
  WHERE	{
  	?point a geo:Point ;
  		geo:lat ?lat ;
  		geo:long ?long .
  }
- method: SELECT
  namespaces:
    foaf: http://xmlns.com/foaf/0.1/
    geo: http://www.w3.org/2003/01/geo/wgs84_pos#
  sources:
    -
      - URI
      - http://homepage.mac.com/samofool/rdf-query/test-data/greenwich.rdf
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          - &1
            - point
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#type
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/2003/01/geo/wgs84_pos#Point
        - !!perl/array:RDF::Query::Algebra::Triple
          - *1
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/2003/01/geo/wgs84_pos#lat
          -
            - lat
        - !!perl/array:RDF::Query::Algebra::Triple
          - *1
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/2003/01/geo/wgs84_pos#long
          -
            - long
  variables:
    -
      - lat
    -
      - long
---
- select with graph-triple-triple
- |
  # select all the email addresses ever held by the person
  # who held a given email address on 2007-01-01
  PREFIX foaf: <http://xmlns.com/foaf/0.1/>
  PREFIX t: <http://www.w3.org/2006/09/time#>
  SELECT ?mbox WHERE {
  	GRAPH ?time { ?p foaf:mbox <mailto:gtw@cs.umd.edu> } .
  	?time t:inside "2007-01-01" .
  	?p foaf:mbox ?mbox .
  }
- method: SELECT
  namespaces:
    foaf: http://xmlns.com/foaf/0.1/
    t: http://www.w3.org/2006/09/time#
  sources: []
  triples:
    - !!perl/array:RDF::Query::Algebra::NamedGraph
      - GRAPH
      - !!perl/array:RDF::Query::Node::Variable
        - time
      - !!perl/array:RDF::Query::Algebra::GroupGraphPattern
        - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
          - !!perl/array:RDF::Query::Algebra::Triple
            - !!perl/array:RDF::Query::Node::Variable
              - p
            - !!perl/array:RDF::Query::Node::Resource
              - URI
              - http://xmlns.com/foaf/0.1/mbox
            - !!perl/array:RDF::Query::Node::Resource
              - URI
              - mailto:gtw@cs.umd.edu
    - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
      - !!perl/array:RDF::Query::Algebra::Triple
        - !!perl/array:RDF::Query::Node::Variable
          - time
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://www.w3.org/2006/09/time#inside
        - !!perl/array:RDF::Query::Node::Literal
          - LITERAL
          - 2007-01-01
      - !!perl/array:RDF::Query::Algebra::Triple
        - !!perl/array:RDF::Query::Node::Variable
          - p
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://xmlns.com/foaf/0.1/mbox
        - !!perl/array:RDF::Query::Node::Variable
          - mbox
  variables:
    -
      - mbox
---
- (DAWG) syn-leading-digits-in-prefixed-names.rq
- |
  PREFIX dob: <http://placetime.com/interval/gregorian/1977-01-18T04:00:00Z/P> 
  PREFIX t: <http://www.ai.sri.com/daml/ontologies/time/Time.daml#>
  PREFIX dc: <http://purl.org/dc/elements/1.1/>
  SELECT ?desc
  WHERE  { 
    dob:1D a t:ProperInterval;
           dc:description ?desc.
  }
- method: SELECT
  namespaces:
    dob: http://placetime.com/interval/gregorian/1977-01-18T04:00:00Z/P
    t: http://www.ai.sri.com/daml/ontologies/time/Time.daml#
    dc: http://purl.org/dc/elements/1.1/
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          - &1 !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://placetime.com/interval/gregorian/1977-01-18T04:00:00Z/P1D
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#type
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.ai.sri.com/daml/ontologies/time/Time.daml#ProperInterval
        - !!perl/array:RDF::Query::Algebra::Triple
          - *1
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://purl.org/dc/elements/1.1/description
          -
            - desc
  variables:
    -
      - desc
---
- (DAWG) syn-07.rq
- |
  # Trailing ;
  PREFIX :   <http://example/ns#>
  SELECT * WHERE
  { :s :p :o ; FILTER(?x) }
- method: SELECT
  namespaces:
    __DEFAULT__: http://example/ns#
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://example/ns#s
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://example/ns#p
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://example/ns#o
      -
        - OLDFILTER
        -
          - x
  variables:
    - !!perl/array:RDF::Query::Node::Variable
      - x
---
- (DAWG) syn-08.rq
- |
  # Broken ;
  PREFIX :   <http://example/ns#>
  SELECT * WHERE
  { :s :p :o ; . }
- method: SELECT
  namespaces:
    __DEFAULT__: http://example/ns#
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://example/ns#s
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://example/ns#p
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://example/ns#o
  variables: []
---
- (DAWG) syn-11.rq
- |
  PREFIX : <http://example.org/>
  SELECT *
  WHERE
  {
    _:a ?p ?v .  FILTER(true) . [] ?q _:a
  }
- method: SELECT
  namespaces:
    __DEFAULT__: http://example.org/
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          - !!perl/array:RDF::Query::Node::Blank
            - BLANK
            - a
          -
            - p
          -
            - v
        - !!perl/array:RDF::Query::Algebra::Triple
          - !!perl/array:RDF::Query::Node::Blank
            - BLANK
            - a1
          -
            - q
          - !!perl/array:RDF::Query::Node::Blank
            - BLANK
            - a
      -
        - OLDFILTER
        - !!perl/array:RDF::Query::Node::Literal
          - LITERAL
          - true
          - ~
          - http://www.w3.org/2001/XMLSchema#boolean
  variables:
    - !!perl/array:RDF::Query::Node::Variable
      - p
    - !!perl/array:RDF::Query::Node::Variable
      - v
    - !!perl/array:RDF::Query::Node::Variable
      - q
---
- (DAWG) syntax-form-describe01.rq
- |
  DESCRIBE <u>
- method: DESCRIBE
  namespaces: {}
  sources: []
  triples: []
  variables:
    -
      - URI
      - u
---
- (DAWG) syntax-form-construct04.rq
- |
  PREFIX  rdf:    <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
  CONSTRUCT { [] rdf:subject ?s ;
                 rdf:predicate ?p ;
                 rdf:object ?o . }
  WHERE {?s ?p ?o}
- method: CONSTRUCT
  namespaces:
    rdf: http://www.w3.org/1999/02/22-rdf-syntax-ns#
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          -
            - s
          -
            - p
          -
            - o
  construct_triples:
    - !!perl/array:RDF::Query::Algebra::Triple
      - &1 !!perl/array:RDF::Query::Node::Blank
        - BLANK
        - a1
      - !!perl/array:RDF::Query::Node::Resource
        - URI
        - http://www.w3.org/1999/02/22-rdf-syntax-ns#subject
      -
        - s
    - !!perl/array:RDF::Query::Algebra::Triple
      - *1
      - !!perl/array:RDF::Query::Node::Resource
        - URI
        - http://www.w3.org/1999/02/22-rdf-syntax-ns#predicate
      -
        - p
    - !!perl/array:RDF::Query::Algebra::Triple
      - *1
      - !!perl/array:RDF::Query::Node::Resource
        - URI
        - http://www.w3.org/1999/02/22-rdf-syntax-ns#object
      -
        - o
---
- (DAWG) syntax-lists-02.rq
- |
  PREFIX : <http://example.org/ns#> 
  SELECT * WHERE { ?x :p ( ?z ) }
- method: SELECT
  namespaces:
    __DEFAULT__: http://example.org/ns#
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          -
            - x
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://example.org/ns#p
          - &1 !!perl/array:RDF::Query::Node::Blank
            - BLANK
            - a1
        - !!perl/array:RDF::Query::Algebra::Triple
          - *1
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#first
          -
            - z
        - !!perl/array:RDF::Query::Algebra::Triple
          - *1
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#rest
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#nil
  variables:
    - !!perl/array:RDF::Query::Node::Variable
      - x
    - !!perl/array:RDF::Query::Node::Variable
      - z
---
- (DAWG) syntax-qname-03.rq
- |
  PREFIX : <http://example.org/ns#> 
  SELECT *
  WHERE { :_1 :p.rdf :z.z . }
- method: SELECT
  namespaces:
    __DEFAULT__: http://example.org/ns#
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://example.org/ns#_1
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://example.org/ns#p.rdf
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://example.org/ns#z.z
  variables: []
---
- (DAWG) syntax-qname-08.rq
- |
  BASE   <http://example.org/>
  PREFIX :  <#>
  PREFIX x.y:  <x#>
  SELECT *
  WHERE { :a.b  x.y:  : . }
- method: SELECT
  namespaces:
    __DEFAULT__: #
    x.y: x#
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://example.org/#a.b
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://example.org/x#
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://example.org/#
  base:
    - URI
    - http://example.org/
  variables: []
---
- (DAWG) syntax-lit-07.rq
- |
  BASE   <http://example.org/>
  PREFIX :  <#> 
  SELECT * WHERE { :x :p 123 }
- method: SELECT
  namespaces:
    __DEFAULT__: #
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://example.org/#x
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://example.org/#p
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - 123
            - ~
            - http://www.w3.org/2001/XMLSchema#integer
  base:
    - URI
    - http://example.org/
  variables: []
---
- (DAWG) syntax-lit-08.rq
- |
  BASE   <http://example.org/>
  PREFIX :  <#> 
  SELECT * WHERE { :x :p 123. . }
- method: SELECT
  namespaces:
    __DEFAULT__: #
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://example.org/#x
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://example.org/#p
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - 123.
            - ~
            - http://www.w3.org/2001/XMLSchema#decimal
  base:
    - URI
    - http://example.org/
  variables: []
---
- (DAWG) syntax-lit-12.rq
- |
  BASE   <http://example.org/>
  PREFIX :  <#> 
  SELECT * WHERE { :x :p '''Long''\'Literal''' }
- method: SELECT
  namespaces:
    __DEFAULT__: #
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://example.org/#x
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://example.org/#p
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - Long'''Literal
  base:
    - URI
    - http://example.org/
  variables: []
---
- (DAWG) syntax-lit-13.rq
- |
  BASE   <http://example.org/>
  PREFIX :  <#> 
  SELECT * WHERE { :x :p """Long\"""Literal""" }
- method: SELECT
  namespaces:
    __DEFAULT__: #
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://example.org/#x
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://example.org/#p
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - Long"""Literal
  base:
    - URI
    - http://example.org/
  variables: []
---
- (DAWG) syntax-general-07.rq
- |
  SELECT * WHERE { <a><b>+1.0 }
- method: SELECT
  namespaces: {}
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - a
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - b
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - +1.0
            - ~
            - http://www.w3.org/2001/XMLSchema#decimal
  variables: []
---
- (DAWG) syntax-general-09.rq
- |
  SELECT * WHERE { <a><b>1.0e0 }
- method: SELECT
  namespaces: {}
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - a
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - b
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - 1.0e0
            - ~
            - http://www.w3.org/2001/XMLSchema#double
  variables: []
---
- (DAWG) syntax-general-10.rq
- |
  SELECT * WHERE { <a><b>+1.0e+1 }
- method: SELECT
  namespaces: {}
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - a
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - b
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - +1.0e+1
            - ~
            - http://www.w3.org/2001/XMLSchema#double
  variables: []
---
- (DAWG) syntax-lists-03.rq
- |
  PREFIX : <http://example.org/>
  SELECT * WHERE { ( 
  ) :p 1 }
- method: SELECT
  namespaces:
    __DEFAULT__: http://example.org/
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#nil
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://example.org/p
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - 1
            - ~
            - http://www.w3.org/2001/XMLSchema#integer
  variables: []
---
- (DAWG) syntax-lists-04.rq
- |
  PREFIX : <http://example.org/>
  SELECT * WHERE { ( 1 2
  ) :p 1 }
- method: SELECT
  namespaces:
    __DEFAULT__: http://example.org/
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          - &1 !!perl/array:RDF::Query::Node::Blank
            - BLANK
            - a1
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#first
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - 1
            - ~
            - http://www.w3.org/2001/XMLSchema#integer
        - !!perl/array:RDF::Query::Algebra::Triple
          - *1
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#rest
          - &2 !!perl/array:RDF::Query::Node::Blank
            - BLANK
            - a2
        - !!perl/array:RDF::Query::Algebra::Triple
          - *2
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#first
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - 2
            - ~
            - http://www.w3.org/2001/XMLSchema#integer
        - !!perl/array:RDF::Query::Algebra::Triple
          - *2
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#rest
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#nil
        - !!perl/array:RDF::Query::Algebra::Triple
          - *1
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://example.org/p
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - 1
            - ~
            - http://www.w3.org/2001/XMLSchema#integer
  variables: []
---
- (DAWG) syntax-lists-02.rq
- |
  PREFIX : <http://example.org/>
  SELECT * WHERE { ( ) :p 1 }
- method: SELECT
  namespaces:
    __DEFAULT__: http://example.org/
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#nil
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://example.org/p
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - 1
            - ~
            - http://www.w3.org/2001/XMLSchema#integer
  variables: []
---
- (DAWG) syntax-lists-04.rq
- |
  PREFIX : <http://example.org/>
  SELECT * WHERE { ( 1 2
  ) :p 1 }
- method: SELECT
  namespaces:
    __DEFAULT__: http://example.org/
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          - &1 !!perl/array:RDF::Query::Node::Blank
            - BLANK
            - a1
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#first
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - 1
            - ~
            - http://www.w3.org/2001/XMLSchema#integer
        - !!perl/array:RDF::Query::Algebra::Triple
          - *1
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#rest
          - &2 !!perl/array:RDF::Query::Node::Blank
            - BLANK
            - a2
        - !!perl/array:RDF::Query::Algebra::Triple
          - *2
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#first
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - 2
            - ~
            - http://www.w3.org/2001/XMLSchema#integer
        - !!perl/array:RDF::Query::Algebra::Triple
          - *2
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#rest
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#nil
        - !!perl/array:RDF::Query::Algebra::Triple
          - *1
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://example.org/p
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - 1
            - ~
            - http://www.w3.org/2001/XMLSchema#integer
  variables: []
---
- (DAWG) dawg-eval
- |
  PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
  PREFIX ex: <http://example.com/#>
  SELECT ?val
  WHERE {
    ex:foo rdf:value ?val .
    FILTER regex(str(?val), "example\\.com")
  }
- method: SELECT
  namespaces:
    rdf: http://www.w3.org/1999/02/22-rdf-syntax-ns#
    ex: http://example.com/#
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://example.com/#foo
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#value
          -
            - val
      -
        - OLDFILTER
        -
          - '~~'
          - !!perl/array:RDF::Query::Algebra::Function
            - FUNCTION
            - !!perl/array:RDF::Query::Node::Resource
              - URI
              - sop:str
            -
              - val
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - example\.com
  variables:
    -
      - val
---
- (DAWG) dawg-eval: sameTerm
- |
  PREFIX : <http://example.org/things#>
  SELECT * {
    ?x1 :p ?v1 .
    ?x2 :p ?v2 .
    FILTER ( !sameTerm(?v1, ?v2) && ?v1 = ?v2 )
  } 
- method: SELECT
  namespaces:
    __DEFAULT__: http://example.org/things#
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          -
            - x1
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://example.org/things#p
          -
            - v1
        - !!perl/array:RDF::Query::Algebra::Triple
          -
            - x2
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://example.org/things#p
          -
            - v2
      -
        - OLDFILTER
        -
          - '&&'
          -
            - '!'
            - !!perl/array:RDF::Query::Algebra::Function
              - FUNCTION
              - !!perl/array:RDF::Query::Node::Resource
                - URI
                - sparql:sameTerm
              -
                - v1
              -
                - v2
          -
            - ==
            -
              - v1
            -
              - v2
  variables:
    - !!perl/array:RDF::Query::Node::Variable
      - x1
    - !!perl/array:RDF::Query::Node::Variable
      - v1
    - !!perl/array:RDF::Query::Node::Variable
      - x2
    - !!perl/array:RDF::Query::Node::Variable
      - v2
---
- (DAWG) dawg-eval: basic/manifest#term-8
- |
  PREFIX : <http://example.org/ns#>
  PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
  # DOT is part of the decimal.
  SELECT * { :x ?p +5 }
- method: SELECT
  namespaces:
    __DEFAULT__: http://example.org/ns#
    xsd: http://www.w3.org/2001/XMLSchema#
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://example.org/ns#x
          -
            - p
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - +5
            - ~
            - http://www.w3.org/2001/XMLSchema#integer
  variables:
    - !!perl/array:RDF::Query::Node::Variable
      - p
---
- (DAWG) dawg-eval: algebra/manifest#filter-nested-2
- |
  PREFIX : <http://example/>
  SELECT ?v { :x :p ?v . { FILTER(?v = 1) } }
- method: SELECT
  namespaces:
    __DEFAULT__: http://example/
  sources: []
  triples:
    - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
      - !!perl/array:RDF::Query::Algebra::Triple
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://example/x
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://example/p
        - !!perl/array:RDF::Query::Node::Variable
          - v
    - !!perl/array:RDF::Query::Algebra::GroupGraphPattern
      - !!perl/array:RDF::Query::Algebra::OldFilter
        - OLDFILTER
        -
          - ==
          - !!perl/array:RDF::Query::Node::Variable
            - v
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - 1
            - ~
            - http://www.w3.org/2001/XMLSchema#integer
  variables:
    -
      - v
---
- (DAWG) dawg-eval: optional/manifest#dawg-optional-complex-4
- |
  PREFIX  foaf:   <http://xmlns.com/foaf/0.1/>
  PREFIX    ex:   <http://example.org/things#>
  SELECT ?name ?plan ?dept ?img
  FROM <...>
  FROM NAMED <...>
  WHERE { 
  	?person foaf:name ?name  
  	{ ?person ex:healthplan ?plan } UNION { ?person ex:department ?dept } 
  	OPTIONAL { 
  		?person a foaf:Person
  		GRAPH ?g { 
  			[] foaf:name ?name;
  			   foaf:depiction ?img 
  		} 
  	} 
  }
- method: SELECT
  namespaces:
    ex: http://example.org/things#
    foaf: http://xmlns.com/foaf/0.1/
  sources:
    -
      - URI
      - ...
    -
      - URI
      - ...
      - NAMED
  triples:
    - !!perl/array:RDF::Query::Algebra::Optional
      - OPTIONAL
      - !!perl/array:RDF::Query::Algebra::GroupGraphPattern
        - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
          - !!perl/array:RDF::Query::Algebra::Triple
            - !!perl/array:RDF::Query::Node::Variable
              - person
            - !!perl/array:RDF::Query::Node::Resource
              - URI
              - http://xmlns.com/foaf/0.1/name
            - !!perl/array:RDF::Query::Node::Variable
              - name
        - !!perl/array:RDF::Query::Algebra::Union
          - UNION
          - !!perl/array:RDF::Query::Algebra::GroupGraphPattern
            - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
              - !!perl/array:RDF::Query::Algebra::Triple
                - !!perl/array:RDF::Query::Node::Variable
                  - person
                - !!perl/array:RDF::Query::Node::Resource
                  - URI
                  - http://example.org/things#healthplan
                - !!perl/array:RDF::Query::Node::Variable
                  - plan
          - !!perl/array:RDF::Query::Algebra::GroupGraphPattern
            - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
              - !!perl/array:RDF::Query::Algebra::Triple
                - !!perl/array:RDF::Query::Node::Variable
                  - person
                - !!perl/array:RDF::Query::Node::Resource
                  - URI
                  - http://example.org/things#department
                - !!perl/array:RDF::Query::Node::Variable
                  - dept
      - !!perl/array:RDF::Query::Algebra::GroupGraphPattern
        - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
          - !!perl/array:RDF::Query::Algebra::Triple
            - !!perl/array:RDF::Query::Node::Variable
              - person
            - !!perl/array:RDF::Query::Node::Resource
              - URI
              - http://www.w3.org/1999/02/22-rdf-syntax-ns#type
            - !!perl/array:RDF::Query::Node::Resource
              - URI
              - http://xmlns.com/foaf/0.1/Person
        - !!perl/array:RDF::Query::Algebra::NamedGraph
          - GRAPH
          - !!perl/array:RDF::Query::Node::Variable
            - g
          - !!perl/array:RDF::Query::Algebra::GroupGraphPattern
            - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
              - !!perl/array:RDF::Query::Algebra::Triple
                - &1 !!perl/array:RDF::Query::Node::Blank
                  - BLANK
                  - a1
                - !!perl/array:RDF::Query::Node::Resource
                  - URI
                  - http://xmlns.com/foaf/0.1/name
                - !!perl/array:RDF::Query::Node::Variable
                  - name
              - !!perl/array:RDF::Query::Algebra::Triple
                - *1
                - !!perl/array:RDF::Query::Node::Resource
                  - URI
                  - http://xmlns.com/foaf/0.1/depiction
                - !!perl/array:RDF::Query::Node::Variable
                  - img
  variables:
    -
      - name
    -
      - plan
    -
      - dept
    -
      - img
---
- (DAWG) dawg-eval: i18n/manifest#kanji-1
- |
  PREFIX foaf: <http://xmlns.com/foaf/0.1/>
  PREFIX 食: <http://www.w3.org/2001/sw/DataAccess/tests/data/i18n/kanji.ttl#>
  SELECT ?name ?food WHERE {
    [ foaf:name ?name ;
      食:食べる ?food ] . }
- method: SELECT
  namespaces:
    foaf: http://xmlns.com/foaf/0.1/
    食: http://www.w3.org/2001/sw/DataAccess/tests/data/i18n/kanji.ttl#
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          - &1 !!perl/array:RDF::Query::Node::Blank
            - BLANK
            - a1
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://xmlns.com/foaf/0.1/name
          -
            - name
        - !!perl/array:RDF::Query::Algebra::Triple
          - *1
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/2001/sw/DataAccess/tests/data/i18n/kanji.ttl#食べる
          -
            - food
  variables:
    -
      - name
    -
      - food
---
- (DAWG) dawg-syntax: syntax-sparql4/manifest#syn-10
- |
  PREFIX : <http://example.org/>
  SELECT *
  WHERE
  {
    { _:a ?p ?v .  _:a ?q _:a } UNION { _:b ?q _:c }
  }
- method: SELECT
  namespaces:
    __DEFAULT__: http://example.org/
  sources: []
  triples:
    - !!perl/array:RDF::Query::Algebra::Union
      - UNION
      - !!perl/array:RDF::Query::Algebra::GroupGraphPattern
        - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
          - !!perl/array:RDF::Query::Algebra::Triple
            - !!perl/array:RDF::Query::Node::Blank
              - BLANK
              - a
            - !!perl/array:RDF::Query::Node::Variable
              - p
            - !!perl/array:RDF::Query::Node::Variable
              - v
          - !!perl/array:RDF::Query::Algebra::Triple
            - !!perl/array:RDF::Query::Node::Blank
              - BLANK
              - a
            - !!perl/array:RDF::Query::Node::Variable
              - q
            - !!perl/array:RDF::Query::Node::Blank
              - BLANK
              - a
      - !!perl/array:RDF::Query::Algebra::GroupGraphPattern
        - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
          - !!perl/array:RDF::Query::Algebra::Triple
            - !!perl/array:RDF::Query::Node::Blank
              - BLANK
              - b
            - !!perl/array:RDF::Query::Node::Variable
              - q
            - !!perl/array:RDF::Query::Node::Blank
              - BLANK
              - c
  variables:
    - !!perl/array:RDF::Query::Node::Variable
      - p
    - !!perl/array:RDF::Query::Node::Variable
      - v
    - !!perl/array:RDF::Query::Node::Variable
      - q
---
- (DAWG) dawg-syntax: syntax-sparql1/manifest#syntax-pat-04
- |
  PREFIX : <http://example.org/ns#> 
  SELECT *
  {
    OPTIONAL{:x :y :z} 
    ?a :b :c 
    { :x1 :y1 :z1 } UNION { :x2 :y2 :z2 }
  }
- method: SELECT
  namespaces:
    __DEFAULT__: http://example.org/ns#
  sources: []
  triples:
    - !!perl/array:RDF::Query::Algebra::Optional
      - OPTIONAL
      - !!perl/array:RDF::Query::Algebra::GroupGraphPattern []
      - !!perl/array:RDF::Query::Algebra::GroupGraphPattern
        - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
          - !!perl/array:RDF::Query::Algebra::Triple
            - !!perl/array:RDF::Query::Node::Resource
              - URI
              - http://example.org/ns#x
            - !!perl/array:RDF::Query::Node::Resource
              - URI
              - http://example.org/ns#y
            - !!perl/array:RDF::Query::Node::Resource
              - URI
              - http://example.org/ns#z
    - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
      - !!perl/array:RDF::Query::Algebra::Triple
        - !!perl/array:RDF::Query::Node::Variable
          - a
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://example.org/ns#b
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://example.org/ns#c
    - !!perl/array:RDF::Query::Algebra::Union
      - UNION
      - !!perl/array:RDF::Query::Algebra::GroupGraphPattern
        - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
          - !!perl/array:RDF::Query::Algebra::Triple
            - !!perl/array:RDF::Query::Node::Resource
              - URI
              - http://example.org/ns#x1
            - !!perl/array:RDF::Query::Node::Resource
              - URI
              - http://example.org/ns#y1
            - !!perl/array:RDF::Query::Node::Resource
              - URI
              - http://example.org/ns#z1
      - !!perl/array:RDF::Query::Algebra::GroupGraphPattern
        - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
          - !!perl/array:RDF::Query::Algebra::Triple
            - !!perl/array:RDF::Query::Node::Resource
              - URI
              - http://example.org/ns#x2
            - !!perl/array:RDF::Query::Node::Resource
              - URI
              - http://example.org/ns#y2
            - !!perl/array:RDF::Query::Node::Resource
              - URI
              - http://example.org/ns#z2
  variables:
    - !!perl/array:RDF::Query::Node::Variable
      - a
---
- (DAWG) dawg-syntax: syntax-sparql1/manifest#syntax-struct-10
- |
  PREFIX :  <http://example.org/ns#> 
  SELECT *
  { OPTIONAL { :a :b :c } . ?x ?y ?z }
- method: SELECT
  namespaces:
    __DEFAULT__: http://example.org/ns#
  sources: []
  triples:
    - !!perl/array:RDF::Query::Algebra::Optional
      - OPTIONAL
      - !!perl/array:RDF::Query::Algebra::GroupGraphPattern []
      - !!perl/array:RDF::Query::Algebra::GroupGraphPattern
        - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
          - !!perl/array:RDF::Query::Algebra::Triple
            - !!perl/array:RDF::Query::Node::Resource
              - URI
              - http://example.org/ns#a
            - !!perl/array:RDF::Query::Node::Resource
              - URI
              - http://example.org/ns#b
            - !!perl/array:RDF::Query::Node::Resource
              - URI
              - http://example.org/ns#c
    - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
      - !!perl/array:RDF::Query::Algebra::Triple
        - !!perl/array:RDF::Query::Node::Variable
          - x
        - !!perl/array:RDF::Query::Node::Variable
          - y
        - !!perl/array:RDF::Query::Node::Variable
          - z
  variables:
    - !!perl/array:RDF::Query::Node::Variable
      - x
    - !!perl/array:RDF::Query::Node::Variable
      - y
    - !!perl/array:RDF::Query::Node::Variable
      - z
---
- (DAWG) dawg-syntax: expr-equals/manifest#eq-2-1
- |
  PREFIX  xsd: <http://www.w3.org/2001/XMLSchema#>
  PREFIX  : <http://example.org/things#>
  SELECT  ?v1 ?v2
  WHERE
      { ?x1 :p ?v1 .
        ?x2 :p ?v2 . 
        FILTER ( ?v1 = ?v2 ) .
      }
- method: SELECT
  namespaces:
    __DEFAULT__: http://example.org/things#
    xsd: http://www.w3.org/2001/XMLSchema#
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          -
            - x1
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://example.org/things#p
          -
            - v1
        - !!perl/array:RDF::Query::Algebra::Triple
          -
            - x2
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://example.org/things#p
          -
            - v2
      -
        - OLDFILTER
        -
          - ==
          -
            - v1
          -
            - v2
  variables:
    -
      - v1
    -
      - v2
---
- (DAWG) dawg-syntax: expr-ops/manifest#minus-1
- |
  PREFIX : <http://example.org/>
  SELECT ?s WHERE {
      ?s :p ?o .
      ?s2 :p ?o2 .
      FILTER(?o - ?o2 = 3) .
  }
- method: SELECT
  namespaces:
    __DEFAULT__: http://example.org/
  sources: []
  triples:
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          -
            - s
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://example.org/p
          -
            - o
        - !!perl/array:RDF::Query::Algebra::Triple
          -
            - s2
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://example.org/p
          -
            - o2
      -
        - OLDFILTER
        -
          - ==
          -
            - -
            -
              - o
            -
              - o2
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - 3
            - ~
            - http://www.w3.org/2001/XMLSchema#integer
  variables:
    -
      - s
---
- FILTER with Qname function needing qualifying
- |
  PREFIX	rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
  PREFIX	rdfs: <http://www.w3.org/2000/01/rdf-schema#>
  PREFIX	foaf: <http://xmlns.com/foaf/0.1/>
  PREFIX	myrdf: <http://kasei.us/e/ns/rdf#>
  PREFIX	wn: <http://xmlns.com/wordnet/1.6/>
  SELECT	?image ?thing ?type ?name
  WHERE	{
  		?image foaf:depicts ?thing .
  		?thing rdf:type ?type .
  		?type rdfs:label ?name .
  		FILTER myrdf:isa(?thing, wn:Object) .
  }
- method: SELECT
  namespaces:
    foaf: http://xmlns.com/foaf/0.1/
    rdf: http://www.w3.org/1999/02/22-rdf-syntax-ns#
    rdfs: http://www.w3.org/2000/01/rdf-schema#
    wn: http://xmlns.com/wordnet/1.6/
    myrdf: http://kasei.us/e/ns/rdf#
  sources: []
  triples: !!perl/array:RDF::Query::Algebra::GroupGraphPattern
    - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
      - !!perl/array:RDF::Query::Algebra::Triple
        - !!perl/array:RDF::Query::Node::Variable
          - image
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://xmlns.com/foaf/0.1/depicts
        - !!perl/array:RDF::Query::Node::Variable
          - thing
      - !!perl/array:RDF::Query::Algebra::Triple
        - !!perl/array:RDF::Query::Node::Variable
          - thing
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://www.w3.org/1999/02/22-rdf-syntax-ns#type
        - !!perl/array:RDF::Query::Node::Variable
          - type
      - !!perl/array:RDF::Query::Algebra::Triple
        - !!perl/array:RDF::Query::Node::Variable
          - type
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://www.w3.org/2000/01/rdf-schema#label
        - !!perl/array:RDF::Query::Node::Variable
          - name
    - !!perl/array:RDF::Query::Algebra::OldFilter
      - OLDFILTER
      - !!perl/array:RDF::Query::Algebra::Function
        - FUNCTION
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://kasei.us/e/ns/rdf#isa
        - !!perl/array:RDF::Query::Node::Variable
          - thing
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://xmlns.com/wordnet/1.6/Object
  variables:
    - !!perl/array:RDF::Query::Node::Variable
      - image
    - !!perl/array:RDF::Query::Node::Variable
      - thing
    - !!perl/array:RDF::Query::Node::Variable
      - type
    - !!perl/array:RDF::Query::Node::Variable
      - name
---
- FILTER with Literal in expression
- |
  PREFIX	rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
  PREFIX	rdfs: <http://www.w3.org/2000/01/rdf-schema#>
  PREFIX	foaf: <http://xmlns.com/foaf/0.1/>
  PREFIX	myrdf: <http://kasei.us/e/ns/rdf#>
  PREFIX	wn: <http://xmlns.com/wordnet/1.6/>
  SELECT	?image ?thing ?type ?name
  WHERE	{
  			?image foaf:depicts ?thing .
  			?thing rdf:type ?type .
  			?type rdfs:label ?name .
  			FILTER(REGEX(STR(?type),"Flower")) .
  		}
- method: SELECT
  namespaces:
    foaf: http://xmlns.com/foaf/0.1/
    rdf: http://www.w3.org/1999/02/22-rdf-syntax-ns#
    rdfs: http://www.w3.org/2000/01/rdf-schema#
    wn: http://xmlns.com/wordnet/1.6/
    myrdf: http://kasei.us/e/ns/rdf#
  sources: []
  triples: !!perl/array:RDF::Query::Algebra::GroupGraphPattern
    - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
      - !!perl/array:RDF::Query::Algebra::Triple
        - !!perl/array:RDF::Query::Node::Variable
          - image
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://xmlns.com/foaf/0.1/depicts
        - !!perl/array:RDF::Query::Node::Variable
          - thing
      - !!perl/array:RDF::Query::Algebra::Triple
        - !!perl/array:RDF::Query::Node::Variable
          - thing
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://www.w3.org/1999/02/22-rdf-syntax-ns#type
        - !!perl/array:RDF::Query::Node::Variable
          - type
      - !!perl/array:RDF::Query::Algebra::Triple
        - !!perl/array:RDF::Query::Node::Variable
          - type
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://www.w3.org/2000/01/rdf-schema#label
        - !!perl/array:RDF::Query::Node::Variable
          - name
    - !!perl/array:RDF::Query::Algebra::OldFilter
      - OLDFILTER
      -
        - '~~'
        - !!perl/array:RDF::Query::Algebra::Function
          - FUNCTION
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - sop:str
          - !!perl/array:RDF::Query::Node::Variable
            - type
        - !!perl/array:RDF::Query::Node::Literal
          - LITERAL
          - Flower
  variables:
    - !!perl/array:RDF::Query::Node::Variable
      - image
    - !!perl/array:RDF::Query::Node::Variable
      - thing
    - !!perl/array:RDF::Query::Node::Variable
      - type
    - !!perl/array:RDF::Query::Node::Variable
      - name
---
- temporal query with time variable
- |
  # select the person who held a given email address on 2007-01-01
  PREFIX foaf: <http://xmlns.com/foaf/0.1/>
  SELECT ?t ?p WHERE {
      TIME ?t { ?p foaf:mbox <mailto:gtw@cs.umd.edu> } .
  }
- method: SELECT
  namespaces:
    foaf: http://xmlns.com/foaf/0.1/
  sources: []
  triples: !!perl/array:RDF::Query::Algebra::GroupGraphPattern
    - !!perl/array:RDF::Query::Algebra::TimeGraph
      - TIME
      - !!perl/array:RDF::Query::Node::Variable
        - t
      - !!perl/array:RDF::Query::Algebra::GroupGraphPattern
        - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
          - !!perl/array:RDF::Query::Algebra::Triple
            - !!perl/array:RDF::Query::Node::Variable
              - p
            - !!perl/array:RDF::Query::Node::Resource
              - URI
              - http://xmlns.com/foaf/0.1/mbox
            - !!perl/array:RDF::Query::Node::Resource
              - URI
              - mailto:gtw@cs.umd.edu
      - ~
  variables:
    -
      - t
    -
      - p
---
- temporal query with empty time bNode
- |
  # select the person who held a given email address on 2007-01-01
  PREFIX foaf: <http://xmlns.com/foaf/0.1/>
  SELECT ?p WHERE {
      TIME [] { ?p foaf:mbox <mailto:gtw@cs.umd.edu> } .
  }
- method: SELECT
  namespaces:
    foaf: http://xmlns.com/foaf/0.1/
  sources: []
  triples: !!perl/array:RDF::Query::Algebra::GroupGraphPattern
    - !!perl/array:RDF::Query::Algebra::TimeGraph
      - TIME
      - !!perl/array:RDF::Query::Node::Blank
        - BLANK
        - a1
      - !!perl/array:RDF::Query::Algebra::GroupGraphPattern
        - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
          - !!perl/array:RDF::Query::Algebra::Triple
            - !!perl/array:RDF::Query::Node::Variable
              - p
            - !!perl/array:RDF::Query::Node::Resource
              - URI
              - http://xmlns.com/foaf/0.1/mbox
            - !!perl/array:RDF::Query::Node::Resource
              - URI
              - mailto:gtw@cs.umd.edu
      - ~
  variables:
    -
      - p
---
- temporal query with time bNode
- |
  # select the person who held a given email address on 2007-01-01
  PREFIX foaf: <http://xmlns.com/foaf/0.1/>
  PREFIX : <http://www.w3.org/2006/09/time#>
  SELECT ?p WHERE {
      TIME [ :inside "2007-01-01" ] { ?p foaf:mbox <mailto:gtw@cs.umd.edu> } .
  }
- method: SELECT
  namespaces:
    foaf: http://xmlns.com/foaf/0.1/
    __DEFAULT__: http://www.w3.org/2006/09/time#
  sources: []
  triples:
    - !!perl/array:RDF::Query::Algebra::TimeGraph
      - TIME
      - &1 !!perl/array:RDF::Query::Node::Variable
        - _____rdfquery_private_0
      - !!perl/array:RDF::Query::Algebra::GroupGraphPattern
        - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
          - !!perl/array:RDF::Query::Algebra::Triple
            - !!perl/array:RDF::Query::Node::Variable
              - p
            - !!perl/array:RDF::Query::Node::Resource
              - URI
              - http://xmlns.com/foaf/0.1/mbox
            - !!perl/array:RDF::Query::Node::Resource
              - URI
              - mailto:gtw@cs.umd.edu
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          - *1
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/2006/09/time#inside
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - 2007-01-01
  variables:
    -
      - p
---
- temporal query with time bNode and extra triple
- |
  # select all the email addresses ever held by the person
  # who held a given email address on 2007-01-01
  PREFIX foaf: <http://xmlns.com/foaf/0.1/>
  PREFIX : <http://www.w3.org/2006/09/time#>
  SELECT ?mbox WHERE {
      TIME [ :inside "2007-01-01" ] { ?p foaf:mbox <mailto:gtw@cs.umd.edu> } .
      ?p foaf:mbox ?mbox
  }
- method: SELECT
  namespaces:
    foaf: http://xmlns.com/foaf/0.1/
    __DEFAULT__: http://www.w3.org/2006/09/time#
  sources: []
  triples:
    - !!perl/array:RDF::Query::Algebra::TimeGraph
      - TIME
      - &1 !!perl/array:RDF::Query::Node::Variable
        - _____rdfquery_private_1
      - !!perl/array:RDF::Query::Algebra::GroupGraphPattern
        - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
          - !!perl/array:RDF::Query::Algebra::Triple
            - !!perl/array:RDF::Query::Node::Variable
              - p
            - !!perl/array:RDF::Query::Node::Resource
              - URI
              - http://xmlns.com/foaf/0.1/mbox
            - !!perl/array:RDF::Query::Node::Resource
              - URI
              - mailto:gtw@cs.umd.edu
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          - *1
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/2006/09/time#inside
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - 2007-01-01
    - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
      - !!perl/array:RDF::Query::Algebra::Triple
        - !!perl/array:RDF::Query::Node::Variable
          - p
        - !!perl/array:RDF::Query::Node::Resource
          - URI
          - http://xmlns.com/foaf/0.1/mbox
        - !!perl/array:RDF::Query::Node::Variable
          - mbox
  variables:
    -
      - mbox
---
- select with TIME
- |
  PREFIX t: <http://www.w3.org/2006/09/time#>
  PREFIX foaf: <http://xmlns.com/foaf/0.1/>
  SELECT ?name WHERE {
  	TIME [ t:begins "2000-01-01" ] { ?p foaf:name ?name . }
  }
- method: SELECT
  namespaces:
    foaf: http://xmlns.com/foaf/0.1/
    t: http://www.w3.org/2006/09/time#
  sources: []
  triples:
    - !!perl/array:RDF::Query::Algebra::TimeGraph
      - TIME
      - &1 !!perl/array:RDF::Query::Node::Variable
        - _____rdfquery_private_2
      - !!perl/array:RDF::Query::Algebra::GroupGraphPattern
        - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
          - !!perl/array:RDF::Query::Algebra::Triple
            - !!perl/array:RDF::Query::Node::Variable
              - p
            - !!perl/array:RDF::Query::Node::Resource
              - URI
              - http://xmlns.com/foaf/0.1/name
            - !!perl/array:RDF::Query::Node::Variable
              - name
      - !!perl/array:RDF::Query::Algebra::BasicGraphPattern
        - !!perl/array:RDF::Query::Algebra::Triple
          - *1
          - !!perl/array:RDF::Query::Node::Resource
            - URI
            - http://www.w3.org/2006/09/time#begins
          - !!perl/array:RDF::Query::Node::Literal
            - LITERAL
            - 2000-01-01
  variables:
    -
      - name
