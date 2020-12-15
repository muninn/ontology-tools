#!/usr/bin/env perl
#
#
#mods2rdf.pl
#
# Converts bibtex records into BIBO RDF instances.
#
use strict;
use Data::Dumper;
use RDF::Query::Client;
use BibTeX::Parser;
use IO::File;
use XML::LibXML;#
use Digest::MD5 qw(md5_hex);
use XML::XPath;
use XML::XPath::XMLParser;
use RDF::Trine;
use RDF::Trine::Store::SPARQL;
use RDF::Query;
use XML::LibXML;
use Digest::MD5 qw(md5 md5_hex);
use open qw(:utf8);
use Switch;
use utf8;
#use open ':std', ':encoding(UTF-8)';
binmode(STDOUT, ":utf8");
my $baseuricmd = "";
if (! -f $ARGV[0]) {
 print "bibtex2rdf.pl - Create bibo linked open data from a bibtex file.\n";
 print "\nUsage:\n";
 print "mods2rdf.pl [filename] [BaseURI]\n";
 print "Where:\n";
 print "[filename] - The filename of the mods file to read.\n";
 print "[BaseURI] - (optional) The Base URI fragment to append to for this citation.\n";
 exit 0;
}
#
#
my $dom = XML::LibXML::Document->new( "1.0", "UTF-8" );
my $docNode= $dom->createElementNS( "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdf:RDF" );
$dom->setDocumentElement($docNode);
$docNode->setAttribute("xmlns","http://localhost/OrlandoPubs");
$docNode->setAttribute("foaf", "http://xmlns.com/foaf/0.1/");
$docNode->setAttribute("dcterms", "http://purl.org/dc/terms/");
$docNode->setAttribute("rel", "http://id.loc.gov/vocabulary/relators/");
$docNode->setAttribute("schema", "http://schema.org/");
$docNode->setAttribute("bibo", "http://purl.org/ontology/bibo/");
$docNode->setAttribute("rdf", "http://www.w3.org/1999/02/22-rdf-syntax-ns#");
$docNode->setAttribute("rdfs", "http://www.w3.org/2000/01/rdf-schema#");
$docNode->setAttribute("cwrc", "http://www.cwrc.ca/ontologies/cwrc#");
$docNode->setAttribute("frbr", "http://purl.org/vocab/frbr/core#");
$dom->setEncoding("UTF-8");
 my %documentTypes = (
 "article" => "AcademicArticle",
 "book" => "Book",
 "webpage" => "Book",
 "techreport" => "Book",
 "electronic" => "Book",
 "manual" => "Book",
 "inbook" => "BookSection",
  "inproceedings" => "Article",
  "proceedings" => "Proceedings");
 my $fh     = IO::File->new($ARGV[0]);
 my $parser = BibTeX::Parser->new($fh);
  while (my $entry = $parser->next ) {
            if ($entry->parse_ok) {
                    my $type    = $entry->type;
                    #print "bibo:" . $documentTypes{lc($type)} . "\n";
                    #print "#" . $entry->key . "\n";
  my $localDoc = $dom->createElementNS("http://purl.org/ontology/bibo/", "bibo:" . $documentTypes{lc($type)});
  $localDoc->setAttributeNS("http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdf:about", "#" . $entry->key); 
  my $localTitle = $dom->createElementNS("http://purl.org/dc/terms/", "dcterms:title");
  $localTitle->addChild($dom->createTextNode($entry->field("title") ));  
  $localDoc->addChild($localTitle);
  $docNode->addChild($localDoc);
  my @authors = $entry->author;
  my @editors = $entry->editor;


  foreach my $author (@editors) {
   my $localName = $dom->createElementNS("http://xmlns.com/foaf/0.1/", "foaf:Person");
   $localName->setAttributeNS("http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdf:about", "#" . $entry->key . "-" . md5_hex( $author) );
   my $localProp = $dom->createElementNS("http://xmlns.com/foaf/0.1/", "foaf:firstName");
   $localProp->addChild($dom->createTextNode( $author->first));
   $localName->addChild($localProp);
   $localProp = $dom->createElementNS("http://xmlns.com/foaf/0.1/", "foaf:lastName");
   $localName->addChild($localProp);
   $localProp->addChild($dom->createTextNode( $author->last));
   $localProp = $dom->createElementNS("http://purl.org/dc/terms/", "dcterms:editor");
   $localProp->addChild($localName);
   $localDoc->addChild($localProp);
#    print $author->first . " "
#                                . $author->von . " "
#                                . $author->last . ", "
#                                . $author->jr;
   }        


  foreach my $author (@authors) {
   my $localName = $dom->createElementNS("http://xmlns.com/foaf/0.1/", "foaf:Person");
   $localName->setAttributeNS("http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdf:about", "#" . $entry->key . "-" . md5_hex( $author) );
   my $localProp = $dom->createElementNS("http://xmlns.com/foaf/0.1/", "foaf:firstName");
   $localProp->addChild($dom->createTextNode( $author->first));
   $localName->addChild($localProp);
   $localProp = $dom->createElementNS("http://xmlns.com/foaf/0.1/", "foaf:lastName");
   $localName->addChild($localProp);
   $localProp->addChild($dom->createTextNode( $author->last));
   $localProp = $dom->createElementNS("http://purl.org/dc/terms/", "dcterms:creator");
   $localProp->addChild($localName);
   $localDoc->addChild($localProp);
#    print $author->first . " "
#                                . $author->von . " "
#                                . $author->last . ", "
#                                . $author->jr;
    }
    
   if ($entry->has("pages")) {
    my $localName = $dom->createElementNS("http://purl.org/ontology/bibo/","bibo:numPages");
    $localDoc->addChild($localName);
    $localName->addChild($dom->createTextNode($entry->field("pages")));
   }# 
    
   }        
   
  }                  
 
#  if (! exists $documentTypes{lc($mods->get_genre())}) {
print $dom->toString(1);
