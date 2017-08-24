#!/usr/bin/env perl
#Usage:
# ./createTaxonomy ontology.owl Class lang
# Class that you're interested in building a taxonomy for ex.
# ./createTaxonomy cwrc.owl Religion en
# ./createTaxonomy cwrc.owl PoliticalAffiliation en
use strict;
use RDF::Trine;
use RDF::Query;
use XML::LibXML;
use Digest::MD5 qw(md5 md5_hex);
 
my $xml_parser = XML::LibXML->new();
$xml_parser->clean_namespaces(1);
my $store = RDF::Trine::Store::Memory->new();
my $model = RDF::Trine::Model->new($store);
# parse some web data into the model, and print the count of resulting RDF statements
if (scalar(@ARGV) != 3) {
    print "Insufficent Arguments Provided\n";
    print "Expected Usage:\n";
    print "\t./createTaxonomy ontology.owl Class lang\n";
    print "\t./createTaxonomy cwrc.owl Religion en\n";
    print "Will output a diagraph with instance nodes of that class linking to their uri's\n";
    exit(0);
}
my $raw_file = 'file:'. $ARGV[0];
my $taxonomy = $ARGV[1];
my $lang = $ARGV[2];


RDF::Trine::Parser->parse_url_into_model( $raw_file, $model );
my @allmaps ;
my $query = RDF::Query->new('SELECT * WHERE { ?uri <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://sparql.cwrc.ca/ontologies/cwrc#'.$taxonomy.'> .
?uri <http://www.w3.org/2000/01/rdf-schema#label> ?label .
FILTER(LANG(?label) = "" || LANGMATCHES(LANG(?label), "'.$lang.'"))
}');
my $iterator = $query->execute( $model );
print "digraph ".$taxonomy."Graph {\n
 size=\"30,30\";
 margin=0;\n";

while (my $row = $iterator->next) {
    my $astring = $row->{"uri"}->as_string();
    my $innerquery =  RDF::Query->new('SELECT * WHERE { ' . $astring . '  <http://www.w3.org/2004/02/skos/core#broaderTransitive> ?upper . }');
    my $inneriterator = $innerquery->execute( $model );
    my $lhs = "X" . substr(md5_hex($astring),1,5);
    while (my $tworow = $inneriterator->next) {
        my $rhs = "X" . substr(md5_hex($tworow->{"upper"}->as_string()),1,5);
        print " " .$lhs . " -> " . $rhs . "\n";
    }
    my $uri = $astring;
    $uri =~ s/</"/;
    $uri =~ s/>/"/;
    print " $lhs [label=\"" . $row->{"label"}->value()."\" URL=".$uri."target=\"_parent\"]\n";
}
print "}";
exit 0;