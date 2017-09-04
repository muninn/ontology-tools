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
use RDF::Query::Client;
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
use open ':std', ':encoding(UTF-8)';
if (! -f $ARGV[0]) {
 print "mods2rdf.pl - Create bibo linked open data from a mods file.\n";
 print "\nUsage:\n";
 print "mods2rdf.pl [filename] [BaseURI]\n";
 print "Where:\n";
 print "[filename] - The filename of the mods file to read.\n";
 print "[BaseURI] - (optional) The Base URI fragment to append to for this citation.\n";
 exit 0;
}
my $xml_parser = XML::LibXML->new();
$xml_parser->clean_namespaces(1);
my $mods = MODS::Record->from_xml(IO::File->new($ARGV[0]));
my $baseuri = "#local";

if ($ARGV[1]) {
 $baseuri = $ARGV[1];
}#if
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
#  if ($mods->get_abstract()) {
#   $atitle = $dom->createElementNS("http://purl.org/ontology/bibo/", "bibo:abstract");
#   $atitle->addChild($dom->createTextNode($mods->get_abstract()));
#   $docNode->addChild($atitle);
#  }
#  my $mypublisher;
#  if ($mods->get_originInfo()) {
#   $mypublisher = publisher($mods->get_originInfo()->get_publisher(), $dom);      
#   if ($mods->get_originInfo()->get_place) {
#      $atitle = $dom->createElementNS("http://xmlns.com/foaf/0.1/", "foaf:based_near");
#      $atitle->addChild($dom->createTextNode($mods->get_originInfo()->get_place()->get_placeTerm()));
#      $mypublisher->addChild($atitle);
#   }#place
#   my $relator = $dom->createElementNS("http://purl.org/dc/terms/", "dcterms:publisher");
#   $relator->addChild($mypublisher);
#   $docNode->addChild($relator);        
#   if ($mods->get_originInfo()->get_copyrightDate()) {
#     $atitle = $dom->createElementNS("http://purl.org/dc/terms/", "dcterms:issued");
#     $atitle->addChild($dom->createTextNode($mods->get_originInfo()->get_copyrightDate()));
#     $docNode->addChild($atitle);
#   }#id
#  }#if
# } 
# else {
#  print $docNode->toString(2);
  $docNode = createHostItem($docNode, $mods, $dom, $baseuri);
# }#journalarticle  
#}
print $docNode->toString(2);
############
#
# <relatedItem type="host"> 
#
############
sub createHostItem {
 my $docNode = $_[0];
 my $mods =  $_[1];
 my $dom = $_[2];
 my $baseURI = $_[3];
 my %documentTypes = (
  "journal" => "Journal",
  "journalarticle" => "AcademicArticle",
  "book" => "Book",
  "book chapter" => "Chapter",
  "booksection" => "BookSection",
  "born digital" => "Webpage",
  "document" => "Document",
  "conference publication" => "Proceedings",
  "conferencePaper" => "AcademicArticle");
  my $BiboClass=""; 
  if (! exists $documentTypes{lc($mods->get_genre())}) {
   #print "Warning, unknown genre " . lc($mods->get_genre()) . " replace with plain bibo:Document."; 
   $BiboClass="Document";
  } else {
   $BiboClass= $documentTypes{lc($mods->get_genre())};
  } 
  my $localDoc = $dom->createElementNS("http://purl.org/ontology/bibo/", "bibo:" . $BiboClass);
  $localDoc->setAttributeNS("http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdf:about", $baseURI); 
  $docNode->addChild($localDoc);
  ## Title
  my $atitle = createTitle($mods, $dom);
  if ($atitle) {
   $localDoc->addChild($atitle);
  }
  ## People
  for ($mods->get_name()) { 
   $localDoc->addChild(people($_, $dom)); 
  }  
  ## SubjectHeading
  $atitle = createSubjectHeadings($localDoc, $mods, $dom);
  if ($atitle) {
   $localDoc->addChild($atitle);
  }  
  ##Identifiers
  $localDoc = createIdentifiers($localDoc, $mods, $dom);
  if ($mods->get_abstract()) {
   $atitle = $dom->createElementNS("http://purl.org/ontology/bibo/", "bibo:abstract");
   $atitle->addChild($dom->createTextNode($mods->get_abstract()));
   $localDoc->addChild($atitle);
  }
  ## 
  my $mypublisher;
  if ($mods->get_originInfo()) {
   if ($mods->get_originInfo()->get_publisher()) {
    $mypublisher = publisher($mods->get_originInfo()->get_publisher(), $dom);      
    if ($mods->get_originInfo()->get_place) {
       $atitle = $dom->createElementNS("http://xmlns.com/foaf/0.1/", "foaf:based_near");
       $atitle->addChild($dom->createTextNode($mods->get_originInfo()->get_place()->get_placeTerm()));
      $mypublisher->addChild($atitle);
    }#place
    my $relator = $dom->createElementNS("http://purl.org/dc/terms/", "dcterms:publisher");
    $relator->addChild($mypublisher);
    $localDoc->addChild($relator);        
   } 
   if ($mods->get_originInfo()->get_copyrightDate()) {
     $atitle = $dom->createElementNS("http://purl.org/dc/terms/", "dcterms:issued");
     $atitle->addChild($dom->createTextNode($mods->get_originInfo()->get_copyrightDate()));
     $localDoc->addChild($atitle);
   }#id
  }#if  
  ##
  ##Check part data
  if ($mods->get_part()) {
    ##*** PART DATA ***
    my $mainDocument = $dom->findnodes("/*[local-name()='RDF']/*")->pop();
    if ($mods->get_part->get_detail(type => 'issue')) {
      $atitle = $dom->createElementNS("http://purl.org/ontology/bibo/","bibo:issue");
      $atitle->addChild($dom->createTextNode($mods->get_part->get_detail(type => 'issue')->get_number()));
      $mainDocument->addChild($atitle);
    } #issue
    if ($mods->get_part->get_detail(type => 'volume')) {
      $atitle = $dom->createElementNS("http://purl.org/ontology/bibo/","bibo:volume");
      $atitle->addChild($dom->createTextNode($mods->get_part->get_detail(type => 'volume')->get_number()));
      $mainDocument->addChild($atitle);
    } #issue
    if ($mods->get_part->get_detail(type => 'chapter')) {
      $atitle = $dom->createElementNS("http://purl.org/ontology/bibo/","bibo:chapter");
      $atitle->addChild($dom->createTextNode($mods->get_part->get_detail(type => 'chapter')->get_number()));
      $mainDocument->addChild($atitle);
    } #issue
    if ($mods->get_part->get_extent(unit => 'pages')) {    
     if ($mods->get_part->get_extent(unit => 'pages')->get_start()) {
      $atitle = $dom->createElementNS("http://purl.org/ontology/bibo/","bibo:pageStart");
      $atitle->addChild($dom->createTextNode($mods->get_part->get_extent(unit => 'pages')->get_start()));
      $mainDocument->addChild($atitle);
     }
     if ($mods->get_part->get_extent(unit => 'pages')->get_end()) {
      $atitle = $dom->createElementNS("http://purl.org/ontology/bibo/","bibo:pageEnd");
      $atitle->addChild($dom->createTextNode($mods->get_part->get_extent(unit => 'pages')->get_end()));
      $mainDocument->addChild($atitle);      
     }
    }#extent    
    print $mainDocument->nodeName . "------\n" ;
  }
  ##
  if ($mods->get_relatedItem(type=>"host")) {
   $atitle = $dom->createElementNS("http://purl.org/ontology/bibo/", "bibo:isPartOf");
   $localDoc->addChild($atitle);
   my $nextDoc = createHostItem($atitle, $mods->get_relatedItem(type=>"host"),$dom,$baseURI . "-partof");
  }    
 return ($docNode);
} 
############
#   <subject>
#      <topic>Social aspects</topic>
#   </subject>
###########
sub createSubjectHeadings {
 my $docNode = $_[0];
 my $mods =  $_[1];
 my $dom = $_[2];
 if ($mods->get_subject()) {
#  RDF::Trine::Parser->parse_url_into_model( "file:authoritiessubjects.rdfxml.skos", $model );
  for ($mods->get_subject()) {
   my $queryString = $_->get_topic();
   print "[" . $queryString . "]\n";
#   ?uri <http://www.w3.org/2004/02/skos/core#inScheme> <http://id.loc.gov/authorities/subjects> .
  my $queryString ="SELECT distinct ?uri WHERE {    
   {   
   ?uri <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/2004/02/skos/core#Concept> .
   ?uri <http://www.w3.org/2004/02/skos/core#prefLabel> ?alabel .
   FILTER (REGEX(?alabel, \"^" . lc($queryString) . "\$\",\"i\")) 
   } UNION
   {
   ?uri <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/2004/02/skos/core#Concept> .
   ?uri <http://www.w3.org/2004/02/skos/core#altLabel> ?blabel .
   FILTER (REGEX(?blabel, \"^" . lc($queryString) . "\$\",\"i\"))  
   }
   }";
   my $query = RDF::Query::Client->new($queryString);
   my $iterator = $query->execute("http://canlink.library.ualberta.ca/sparql" );
   print "Warning: " . $query->error . "\n";
   while (my $row = $iterator->next()) {
    my $astring = $row->{"uri"}->as_string(); 
    my $atitle = $dom->createElementNS("http://purl.org/dc/terms/", "dc:subject");
    $atitle->setAttributeNS("http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdf:resource", $astring);
    $docNode->addChild($atitle);
    print "Found [" . $astring . "]\n";
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
  ## Deals with broken mods.
  foreach my $aisbn (split(' ', $_)) {
   $atitle = $dom->createElementNS("http://purl.org/ontology/bibo/", "bibo:isbn");
   $atitle->addChild($dom->createTextNode($aisbn));
   $docNode->addChild($atitle);
  }
 }#isbn
 for ($mods->get_identifier(type => "issn")) {
  foreach my $aissn (split(' ', $_)) {
   $atitle = $dom->createElementNS("http://purl.org/ontology/bibo/", "bibo:issn");
   $atitle->addChild($dom->createTextNode($aissn));
   $docNode->addChild($atitle);
  }
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
