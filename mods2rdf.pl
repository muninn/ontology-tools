#!/usr/bin/env perl
#
#book
#Book Chapter
#Born Digital
#book
#bookSection
#conference publication
#conferencePaper
#document
#journal
#journalArticle
use strict;
use MODS::Record qw(xml_string); 
use XML::LibXML;#
use Digest::MD5 qw(md5_hex);
use XML::XPath;
use XML::XPath::XMLParser;
use RDF::Trine;
use RDF::Query;
use XML::LibXML;
use Digest::MD5 qw(md5 md5_hex);
use open qw(:utf8);
use Switch;
my $xml_parser = XML::LibXML->new();
$xml_parser->clean_namespaces(1);
my $mods = MODS::Record->from_xml(IO::File->new($ARGV[0]));
my $baseuri = "#local";
if ($ARGV[1]) {
 $baseuri = $ARGV[1];
}#if
my $dom = XML::LibXML::Document->new( "1.0", "UTF-8" );
my $docNode= $dom->createElementNS( "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdf:RDF" );
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
#print $mods->get_genre();
print lc($mods->get_genre()) . "\n";
switch (lc($mods->get_genre()) . "") {
 case "book"		{ 
  print "It's a book.\n";
  my $atitle = $dom->createElementNS("http://purl.org/ontology/bibo/", "bibo:Book");
  $atitle->setAttributeNS("http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdf:about", $baseuri); 
  $docNode->addChild($atitle);
  $docNode = $atitle;
  for ($mods->get_name()) { 
   $docNode->addChild(people($_, $dom)); 
  }
  print "Title\n";
  $atitle = createTitle($mods, $dom);
  if ($atitle) {
   $docNode->addChild($atitle);
  }  
  print "SubjectHeading\n";
  $atitle = createSubjectHeadings($docNode, $mods, $dom);
  if ($atitle) {
   $docNode->addChild($atitle);
  }  
  print "Identifiers\n";
  $docNode = createIdentifiers($docNode, $mods, $dom);
  if ($mods->get_abstract()) {
   $atitle = $dom->createElementNS("http://purl.org/ontology/bibo/", "bibo:abstract");
   $atitle->addChild($dom->createTextNode($mods->get_abstract()));
   $docNode->addChild($atitle);
  }
  my $mypublisher;
  if ($mods->get_originInfo()) {
   $mypublisher = publisher($mods->get_originInfo()->get_publisher(), $dom);      
   if ($mods->get_originInfo()->get_place) {
      $atitle = $dom->createElementNS("http://xmlns.com/foaf/0.1/", "foaf:based_near");
      $atitle->addChild($dom->createTextNode($mods->get_originInfo()->get_place()->get_placeTerm()));
      $mypublisher->addChild($atitle);
   }#place
   my $relator = $dom->createElementNS("http://purl.org/dc/terms/", "dcterms:publisher");
   $relator->addChild($mypublisher);
   $docNode->addChild($relator);        
   if ($mods->get_originInfo()->get_copyrightDate()) {
     $atitle = $dom->createElementNS("http://purl.org/dc/terms/", "dcterms:issued");
     $atitle->addChild($dom->createTextNode($mods->get_originInfo()->get_copyrightDate()));
     $docNode->addChild($atitle);
   }#id
  }#if
 } 
 case "journalarticle" {
  print $mods->get_relatedItem()->get_genre() . "\n";  
  my $atitle = $dom->createElementNS("http://purl.org/ontology/bibo/", "bibo:AcademicArticle");
  $atitle->setAttributeNS("http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdf:about", $baseuri); 
  $docNode->addChild($atitle);
  $docNode = $atitle;
  $atitle = createTitle($mods, $dom);
  if ($atitle) {
   $docNode->addChild($atitle);
  }  
 }  
 else		{ print "previous case not true [" . lc($mods->get_genre())  . "]."; }
}
print $docNode->toString(2);
############
#   <subject>
#      <topic>Social aspects</topic>
#   </subject>
###########
sub createSubjectHeadings {
 my $docNode = $_[0];
 my $mods =  $_[1];
 my $dom = $_[2];
 my $store = RDF::Trine::Store::Memory->new();
 my $model = RDF::Trine::Model->new($store);
 if ($mods->get_subject()) {
  print "Loading subject heading.";
  RDF::Trine::Parser->parse_url_into_model( "file:authoritiessubjects.rdfxml.skos", $model );
  print " Loaded.\n";
  for ($mods->get_subject()) {
   my $queryString = $_->get_title();
   print "[" . $queryString . "]\n";
   my $query = RDF::Query->new('SELECT distinct ?uri WHERE { 
   ?uri <http://www.w3.org/2004/02/skos/core#inScheme> <http://id.loc.gov/authorities/subjects> .
   ?uri <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/2004/02/skos/core#Concept> .
   ?uri <http://www.w3.org/2004/02/skos/core#prefLabel> "' . $_. '" .  }');
   my $iterator = $query->execute( $model );
   while (my $row = $iterator->next) {
    my $astring = $row->{"uri"}->as_string(); 
    print "[" . $astring . "]\n";
   }#while
  }##for 
 }
}
###########
#createIdentifiers($docNode, $mods, $dom);
sub createIdentifiers {
 my $docNode = $_[0];
 my $mods =  $_[1];
 my $dom = $_[2];
 my $atitle;
 if ($mods->get_identifier(type => "doi")) {
  $atitle = $dom->createElementNS("http://www.w3.org/2002/07/owl#", "owl:sameAs");
  $atitle->setAttributeNS("http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdf:resource", "http://doi.org/" . $mods->get_identifier(type => "doi"));
  $docNode->addChild($atitle);
 }#doi
 for ($mods->get_identifier(type => "isbn")) {
  $atitle = $dom->createElementNS("http://purl.org/ontology/bibo/", "bibo:isbn");
  $atitle->addChild($dom->createTextNode($_));
  $docNode->addChild($atitle);
 }#isbn
 for ($mods->get_identifier(type => "issn")) {
  $atitle = $dom->createElementNS("http://purl.org/ontology/bibo/", "bibo:issn");
  $atitle->addChild($dom->createTextNode($_));
  $docNode->addChild($atitle);
 }#isbn   
 return($docNode);
}

############
#createTitle($mods, $dom))
sub createTitle {
  my $mods = $_[0];
  my $dom = $_[1]; 
  my $titleString ="";
  if ($mods->get_titleInfo()) {  
   $titleString = $mods->get_titleInfo()->get_title();
   if (((! $titleString) ||
       (length($titleString) < 1)) && ($mods->get_titleInfo(type=>"abbreviated")) ) {
    $titleString = $mods->get_titleInfo(type=>"abbreviated")->get_title();    
   } 
   if (($titleString) &&  (length($titleString) > 1))  {    
    my $atitle = $dom->createElementNS("http://purl.org/dc/terms/", "dcterms:title");
    $atitle->addChild($dom->createTextNode($titleString));
    $docNode->addChild($atitle);
    return($atitle);
   }
  }
  return (undef);
}

############
sub publisher
{
  my $publish = $_[0];
  my $dom = $_[1];  
  my $personalNode = $dom->createElement("foaf:Organization");  
  $personalNode->setAttributeNS("http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdf:about", "#" . md5_hex($publish));
  my $anode = $dom->createElementNS("http://xmlns.com/foaf/0.1/", "foaf:name");
   $anode->addChild($dom->createTextNode($publish));
   $personalNode->addChild($anode);  
  return($personalNode);
}
############
sub people
{
#      <namePart type="family">Nakamura</namePart>
#      <namePart type="given">Lisa</namePart>
  my $name = $_[0];
  my $dom = $_[1];
  my $relator = $dom->createElementNS("http://id.loc.gov/vocabulary/relators/", "rel:" . $name->get_role()->get_roleTerm());
  my $personalNode = $dom->createElement("foaf:Person");  
  $relator->addChild($personalNode);
  my $mystring =   $name->get_namePart(type => "family") . " " . $name->get_namePart(type => "given") ;
  if ($name->get_namePart(type => "termsOfAddress")) {
   $mystring = $name->get_namePart(type => "termsOfAddress") . " " . $mystring;
  }
  $personalNode->setAttributeNS("http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdf:about", "#" . md5_hex($mystring));
#
  print "[" . $mystring . "]";
  my $anode = $dom->createElementNS("http://purl.org/", "purl:dc");
  if ($name->get_namePart(type => "family")) {
   $anode = $dom->createElementNS("http://purl.org/dc/terms/", "foaf:lastName");
   $anode->addChild($dom->createTextNode($name->get_namePart(type => "family")));
   $personalNode->addChild($anode);
  }
  if ($name->get_namePart(type => "given")) {
   $anode = $dom->createElementNS("http://purl.org/dc/terms/", "foaf:firstName");
   $anode->addChild($dom->createTextNode($name->get_namePart(type => "given")));
   $personalNode->addChild($anode);
  }
  if ($name->get_namePart(type => "termsOfAddress")) {
   $anode = $dom->createElementNS("http://purl.org/dc/terms/", "foaf:title");
   $anode->addChild($dom->createTextNode($name->get_namePart(type => "termsOfAddress")));
   $personalNode->addChild($anode);
  }
  $anode = $dom->createElementNS("http://xmlns.com/foaf/0.1/", "foaf:name");
  $anode->addChild($dom->createTextNode($mystring));
  $personalNode->addChild($anode);
  return($relator);
#  for ($name->get_abstract) {
#  ->get_role()->get_roleTerm(); 
#  print "$arg1, $arg2\n";
}	

#print "\n";
#print $mods->get_titleInfo()->get_title() . "\n";
#print "\n";
