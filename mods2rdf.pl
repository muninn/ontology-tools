#!/usr/bin/env perl
#
#
#mods2rdf.pl
#
# Converts Library of Congress mods records into BIBO RDF instances.
# This is not a comprehensive translation of all MODS variants.
#
use strict;
use Data::Dumper;
use MODS::Record qw(xml_string); 
use JSON::Parse 'parse_json';
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
#use open ':std', ':encoding(UTF-8)';
binmode(STDOUT, ":utf8");
my $baseuricmd = "";
if (! -f $ARGV[0]) {
 print "mods2rdf.pl - Create bibo linked open data from a mods file.\n";
 print "\nUsage:\n";
 print "mods2rdf.pl [filename] [BaseURI]\n";
 print "Where:\n";
 print "[filename] - The filename of the mods file to read.\n";
 print "[BaseURI] - (optional) The Base URI fragment to append to for this citation.\n";
 exit 0;
}
#
#
my %marcLanguages = (
"afar"=>"aar",
"abkhaz"=>"abk",
"achinese"=>"ace",
"acoli"=>"ach",
"adangme"=>"ada",
"adygei"=>"ady",
"afroasiatic (other)"=>"afa",
"afrihili (artificial language)"=>"afh",
"afrikaans"=>"afr",
"ainu"=>"ain",
"akan"=>"aka",
"akkadian"=>"akk",
"albanian"=>"alb",
"aleut"=>"ale",
"algonquian (other)"=>"alg",
"altai"=>"alt",
"amharic"=>"amh",
"english, old (ca. 450-1100)"=>"ang",
"angika"=>"anp",
"apache languages"=>"apa",
"arabic"=>"ara",
"aramaic"=>"arc",
"aragonese"=>"arg",
"armenian"=>"arm",
"mapuche"=>"arn",
"arapaho"=>"arp",
"artificial (other)"=>"art",
"arawak"=>"arw",
"assamese"=>"asm",
"bable"=>"ast",
"athapascan (other)"=>"ath",
"australian languages"=>"aus",
"avaric"=>"ava",
"avestan"=>"ave",
"awadhi"=>"awa",
"aymara"=>"aym",
"azerbaijani"=>"aze",
"banda languages"=>"bad",
"bamileke languages"=>"bai",
"bashkir"=>"bak",
"baluchi"=>"bal",
"bambara"=>"bam",
"balinese"=>"ban",
"basque"=>"baq",
"basa"=>"bas",
"baltic (other)"=>"bat",
"beja"=>"bej",
"belarusian"=>"bel",
"bemba"=>"bem",
"bengali"=>"ben",
"berber (other)"=>"ber",
"bhojpuri"=>"bho",
"bihari (other)"=>"bih",
"bikol"=>"bik",
"edo"=>"bin",
"bislama"=>"bis",
"siksika"=>"bla",
"bantu (other)"=>"bnt",
"bosnian"=>"bos",
"braj"=>"bra",
"breton"=>"bre",
"batak"=>"btk",
"buriat"=>"bua",
"bugis"=>"bug",
"bulgarian"=>"bul",
"burmese"=>"bur",
"bilin"=>"byn",
"caddo"=>"cad",
"central american indian (other)"=>"cai",
"carib"=>"car",
"catalan"=>"cat",
"caucasian (other)"=>"cau",
"cebuano"=>"ceb",
"celtic (other)"=>"cel",
"chamorro"=>"cha",
"chibcha"=>"chb",
"chechen"=>"che",
"chagatai"=>"chg",
"chinese"=>"chi",
"chuukese"=>"chk",
"mari"=>"chm",
"chinook jargon"=>"chn",
"choctaw"=>"cho",
"chipewyan"=>"chp",
"cherokee"=>"chr",
"church slavic"=>"chu",
"chuvash"=>"chv",
"cheyenne"=>"chy",
"chamic languages"=>"cmc",
"coptic"=>"cop",
"cornish"=>"cor",
"corsican"=>"cos",
"creoles and pidgins, english-based (othe"=>"cpe",
"creoles and pidgins, french-based (other"=>"cpf",
"creoles and pidgins, portuguese-based (o"=>"cpp",
"cree"=>"cre",
"crimean tatar"=>"crh",
"creoles and pidgins (other)"=>"crp",
"kashubian"=>"csb",
"cushitic (other)"=>"cus",
"czech"=>"cze",
"dakota"=>"dak",
"danish"=>"dan",
"dargwa"=>"dar",
"dayak"=>"day",
"delaware"=>"del",
"slavey"=>"den",
"dogrib"=>"dgr",
"dinka"=>"din",
"divehi"=>"div",
"dogri"=>"doi",
"dravidian (other)"=>"dra",
"lower sorbian"=>"dsb",
"duala"=>"dua",
"dutch, middle (ca. 1050-1350)"=>"dum",
"dutch"=>"dut",
"dyula"=>"dyu",
"dzongkha"=>"dzo",
"efik"=>"efi",
"egyptian"=>"egy",
"ekajuk"=>"eka",
"elamite"=>"elx",
"english"=>"eng",
"english, middle (1100-1500)"=>"enm",
"esperanto"=>"epo",
"estonian"=>"est",
"ewe"=>"ewe",
"ewondo"=>"ewo",
"fang"=>"fan",
"faroese"=>"fao",
"fanti"=>"fat",
"fijian"=>"fij",
"filipino"=>"fil",
"finnish"=>"fin",
"finno-ugrian (other)"=>"fiu",
"fon"=>"fon",
"french"=>"fre",
"french, middle (ca. 1300-1600)"=>"frm",
"french, old (ca. 842-1300)"=>"fro",
"north frisian"=>"frr",
"east frisian"=>"frs",
"frisian"=>"fry",
"fula"=>"ful",
"friulian"=>"fur",
"gã"=>"gaa",
"gayo"=>"gay",
"gbaya"=>"gba",
"germanic (other)"=>"gem",
"georgian"=>"geo",
"german"=>"ger",
"ethiopic"=>"gez",
"gilbertese"=>"gil",
"scottish gaelic"=>"gla",
"irish"=>"gle",
"galician"=>"glg",
"manx"=>"glv",
"german, middle high (ca. 1050-1500)"=>"gmh",
"german, old high (ca. 750-1050)"=>"goh",
"gondi"=>"gon",
"gorontalo"=>"gor",
"gothic"=>"got",
"grebo"=>"grb",
"greek, ancient (to 1453)"=>"grc",
"greek, modern (1453-)"=>"gre",
"guarani"=>"grn",
"swiss german"=>"gsw",
"gujarati"=>"guj",
"gwich'in"=>"gwi",
"haida"=>"hai",
"haitian french creole"=>"hat",
"hausa"=>"hau",
"hawaiian"=>"haw",
"hebrew"=>"heb",
"herero"=>"her",
"hiligaynon"=>"hil",
"western pahari languages"=>"him",
"hindi"=>"hin",
"hittite"=>"hit",
"hmong"=>"hmn",
"hiri motu"=>"hmo",
"croatian"=>"hrv",
"upper sorbian"=>"hsb",
"hungarian"=>"hun",
"hupa"=>"hup",
"iban"=>"iba",
"igbo"=>"ibo",
"icelandic"=>"ice",
"ido"=>"ido",
"sichuan yi"=>"iii",
"ijo"=>"ijo",
"inuktitut"=>"iku",
"interlingue"=>"ile",
"iloko"=>"ilo",
"interlingua (international auxiliary lan"=>"ina",
"indic (other)"=>"inc",
"indonesian"=>"ind",
"indo-european (other)"=>"ine",
"ingush"=>"inh",
"inupiaq"=>"ipk",
"iranian (other)"=>"ira",
"iroquoian (other)"=>"iro",
"italian"=>"ita",
"javanese"=>"jav",
"lojban (artificial language)"=>"jbo",
"japanese"=>"jpn",
"judeo-persian"=>"jpr",
"judeo-arabic"=>"jrb",
"kara-kalpak"=>"kaa",
"kabyle"=>"kab",
"kachin"=>"kac",
"kalâtdlisut"=>"kal",
"kamba"=>"kam",
"kannada"=>"kan",
"karen languages"=>"kar",
"kashmiri"=>"kas",
"kanuri"=>"kau",
"kawi"=>"kaw",
"kazakh"=>"kaz",
"kabardian"=>"kbd",
"khasi"=>"kha",
"khoisan (other)"=>"khi",
"khmer"=>"khm",
"khotanese"=>"kho",
"kikuyu"=>"kik",
"kinyarwanda"=>"kin",
"kyrgyz"=>"kir",
"kimbundu"=>"kmb",
"konkani"=>"kok",
"komi"=>"kom",
"kongo"=>"kon",
"korean"=>"kor",
"kosraean"=>"kos",
"kpelle"=>"kpe",
"karachay-balkar"=>"krc",
"karelian"=>"krl",
"kru (other)"=>"kro",
"kurukh"=>"kru",
"kuanyama"=>"kua",
"kumyk"=>"kum",
"kurdish"=>"kur",
"kootenai"=>"kut",
"ladino"=>"lad",
"lahndā"=>"lah",
"lamba (zambia and congo)"=>"lam",
"lao"=>"lao",
"latin"=>"lat",
"latvian"=>"lav",
"lezgian"=>"lez",
"limburgish"=>"lim",
"lingala"=>"lin",
"lithuanian"=>"lit",
"mongo-nkundu"=>"lol",
"lozi"=>"loz",
"luxembourgish"=>"ltz",
"luba-lulua"=>"lua",
"luba-katanga"=>"lub",
"ganda"=>"lug",
"luiseño"=>"lui",
"lunda"=>"lun",
"luo (kenya and tanzania)"=>"luo",
"lushai"=>"lus",
"macedonian"=>"mac",
"madurese"=>"mad",
"magahi"=>"mag",
"marshallese"=>"mah",
"maithili"=>"mai",
"makasar"=>"mak",
"malayalam"=>"mal",
"mandingo"=>"man",
"maori"=>"mao",
"austronesian (other)"=>"map",
"marathi"=>"mar",
"maasai"=>"mas",
"malay"=>"may",
"moksha"=>"mdf",
"mandar"=>"mdr",
"mende"=>"men",
"irish, middle (ca. 1100-1550)"=>"mga",
"micmac"=>"mic",
"minangkabau"=>"min",
"miscellaneous languages"=>"mis",
"mon-khmer (other)"=>"mkh",
"malagasy"=>"mlg",
"maltese"=>"mlt",
"manchu"=>"mnc",
"manipuri"=>"mni",
"manobo languages"=>"mno",
"mohawk"=>"moh",
"mongolian"=>"mon",
"mooré"=>"mos",
"multiple languages"=>"mul",
"munda (other)"=>"mun",
"creek"=>"mus",
"mirandese"=>"mwl",
"marwari"=>"mwr",
"mayan languages"=>"myn",
"erzya"=>"myv",
"nahuatl"=>"nah",
"north american indian (other)"=>"nai",
"neapolitan italian"=>"nap",
"nauru"=>"nau",
"navajo"=>"nav",
"ndebele (south africa)"=>"nbl",
"ndebele (zimbabwe)"=>"nde",
"ndonga"=>"ndo",
"low german"=>"nds",
"nepali"=>"nep",
"newari"=>"new",
"nias"=>"nia",
"niger-kordofanian (other)"=>"nic",
"niuean"=>"niu",
"norwegian (nynorsk)"=>"nno",
"norwegian (bokmål)"=>"nob",
"nogai"=>"nog",
"old norse"=>"non",
"norwegian"=>"nor",
"n'ko"=>"nqo",
"northern sotho"=>"nso",
"nubian languages"=>"nub",
"newari, old"=>"nwc",
"nyanja"=>"nya",
"nyamwezi"=>"nym",
"nyankole"=>"nyn",
"nyoro"=>"nyo",
"nzima"=>"nzi",
"occitan (post-1500)"=>"oci",
"ojibwa"=>"oji",
"oriya"=>"ori",
"oromo"=>"orm",
"osage"=>"osa",
"ossetic"=>"oss",
"turkish, ottoman"=>"ota",
"otomian languages"=>"oto",
"papuan (other)"=>"paa",
"pangasinan"=>"pag",
"pahlavi"=>"pal",
"pampanga"=>"pam",
"panjabi"=>"pan",
"papiamento"=>"pap",
"palauan"=>"pau",
"old persian (ca. 600-400 b.c.)"=>"peo",
"persian"=>"per",
"philippine (other)"=>"phi",
"phoenician"=>"phn",
"pali"=>"pli",
"polish"=>"pol",
"pohnpeian"=>"pon",
"portuguese"=>"por",
"prakrit languages"=>"pra",
"provençal (to 1500)"=>"pro",
"pushto"=>"pus",
"quechua"=>"que",
"rajasthani"=>"raj",
"rapanui"=>"rap",
"rarotongan"=>"rar",
"romance (other)"=>"roa",
"raeto-romance"=>"roh",
"romani"=>"rom",
"romanian"=>"rum",
"rundi"=>"run",
"aromanian"=>"rup",
"russian"=>"rus",
"sandawe"=>"sad",
"sango (ubangi creole)"=>"sag",
"yakut"=>"sah",
"south american indian (other)"=>"sai",
"salishan languages"=>"sal",
"samaritan aramaic"=>"sam",
"sanskrit"=>"san",
"sasak"=>"sas",
"santali"=>"sat",
"sicilian italian"=>"scn",
"scots"=>"sco",
"selkup"=>"sel",
"semitic (other)"=>"sem",
"irish, old (to 1100)"=>"sga",
"sign languages"=>"sgn",
"shan"=>"shn",
"sidamo"=>"sid",
"sinhalese"=>"sin",
"siouan (other)"=>"sio",
"sino-tibetan (other)"=>"sit",
"slavic (other)"=>"sla",
"slovak"=>"slo",
"slovenian"=>"slv",
"southern sami"=>"sma",
"northern sami"=>"sme",
"sami"=>"smi",
"lule sami"=>"smj",
"inari sami"=>"smn",
"samoan"=>"smo",
"skolt sami"=>"sms",
"shona"=>"sna",
"sindhi"=>"snd",
"soninke"=>"snk",
"sogdian"=>"sog",
"somali"=>"som",
"songhai"=>"son",
"sotho"=>"sot",
"spanish"=>"spa",
"sardinian"=>"srd",
"sranan"=>"srn",
"serbian"=>"srp",
"serer"=>"srr",
"nilo-saharan (other)"=>"ssa",
"swazi"=>"ssw",
"sukuma"=>"suk",
"sundanese"=>"sun",
"susu"=>"sus",
"sumerian"=>"sux",
"swahili"=>"swa",
"swedish"=>"swe",
"syriac"=>"syc",
"syriac, modern"=>"syr",
"tahitian"=>"tah",
"tai (other)"=>"tai",
"tamil"=>"tam",
"tatar"=>"tat",
"telugu"=>"tel",
"temne"=>"tem",
"terena"=>"ter",
"tetum"=>"tet",
"tajik"=>"tgk",
"tagalog"=>"tgl",
"thai"=>"tha",
"tibetan"=>"tib",
"tigré"=>"tig",
"tigrinya"=>"tir",
"tiv"=>"tiv",
"tokelauan"=>"tkl",
"klingon (artificial language)"=>"tlh",
"tlingit"=>"tli",
"tamashek"=>"tmh",
"tonga (nyasa)"=>"tog",
"tongan"=>"ton",
"tok pisin"=>"tpi",
"tsimshian"=>"tsi",
"tswana"=>"tsn",
"tsonga"=>"tso",
"turkmen"=>"tuk",
"tumbuka"=>"tum",
"tupi languages"=>"tup",
"turkish"=>"tur",
"altaic (other)"=>"tut",
"tuvaluan"=>"tvl",
"twi"=>"twi",
"tuvinian"=>"tyv",
"udmurt"=>"udm",
"ugaritic"=>"uga",
"uighur"=>"uig",
"ukrainian"=>"ukr",
"umbundu"=>"umb",
"undetermined"=>"und",
"urdu"=>"urd",
"uzbek"=>"uzb",
"vai"=>"vai",
"venda"=>"ven",
"vietnamese"=>"vie",
"volapük"=>"vol",
"votic"=>"vot",
"wakashan languages"=>"wak",
"wolayta"=>"wal",
"waray"=>"war",
"washoe"=>"was",
"welsh"=>"wel",
"sorbian (other)"=>"wen",
"walloon"=>"wln",
"wolof"=>"wol",
"oirat"=>"xal",
"xhosa"=>"xho",
"yao (africa)"=>"yao",
"yapese"=>"yap",
"yiddish"=>"yid",
"yoruba"=>"yor",
"yupik languages"=>"ypk",
"zapotec"=>"zap",
"blissymbolics"=>"zbl",
"zenaga"=>"zen",
"zhuang"=>"zha",
"zande languages"=>"znd",
"zulu"=>"zul",
"zuni"=>"zun",
"no linguistic content"=>"zxx",
"zaza"=>"zza");

#
#
my $xml_parser = XML::LibXML->new();
$xml_parser->clean_namespaces(1);
my $mods = MODS::Record->from_xml(IO::File->new($ARGV[0]));
$baseuricmd = "#local";
if (length($ARGV[1])>1) {
 $baseuricmd = '#' . $ARGV[1];
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
  $docNode = createHostItem($docNode, $mods, $dom, $baseuricmd);
# }#journalarticle  
#}
$dom->setEncoding("UTF-8");
 
print $dom->toString(1);
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
  "conferencepaper" => "Article",
  "web page" => "Webpage");
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
  ##<language>/<languageTerm type="text">
  for ($mods->get_language()) {
   $localDoc->addChild(language($_, $dom,$baseURI));
  }
  ## People
  for ($mods->get_name()) { 
   $localDoc->addChild(people($_, $dom,$baseURI)); 
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
    $mypublisher = publisher($mods->get_originInfo()->get_publisher(), $dom, $baseURI);      
    if ($mods->get_originInfo()->get_place) {
       $atitle = $dom->createElementNS("http://xmlns.com/foaf/0.1/", "foaf:based_near");
       $atitle->addChild($dom->createTextNode($mods->get_originInfo()->get_place()->get_placeTerm()));
      $mypublisher->addChild($atitle);
    }#place
    my $relator = $dom->createElementNS("http://purl.org/dc/terms/", "dcterms:publisher");
    $relator->addChild($mypublisher);
    $localDoc->addChild($relator);        
   } 
   # dateCreated
   if ($mods->get_originInfo()->get_copyrightDate()) {
     $atitle = $dom->createElementNS("http://purl.org/dc/terms/", "dcterms:issued");
     $atitle->addChild($dom->createTextNode($mods->get_originInfo()->get_copyrightDate()));
     $localDoc->addChild($atitle);
   }#if
   # dateIssued
   if ($mods->get_originInfo()->get_dateIssued()) {
     $atitle = $dom->createElementNS("http://purl.org/dc/terms/", "dcterms:issued");
     $atitle->addChild($dom->createTextNode($mods->get_originInfo()->get_dateIssued()));
     $localDoc->addChild($atitle);
   }#if
   
   if ($mods->get_originInfo()->get_dateCreated()) {
    $atitle = $dom->createElementNS("http://purl.org/dc/terms/", "dcterms:date");
    $atitle->addChild($dom->createTextNode($mods->get_originInfo()->get_dateCreated()));
    $localDoc->addChild($atitle); 
   }#if
  }#if  
  ##
  # <location><url>
  for ($mods->get_location()) { 
   if ($_->get_url()) {
     $atitle = $dom->createElementNS("http://purl.org/ontology/bibo/", "uri");
     $atitle->setAttributeNS("http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdf:resource", $_->get_url());
     $localDoc->addChild($atitle);
   }
  }
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
   #print "[" . $queryString . "]\n";
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
   #print "Warning: " . $query->error . "\n";
   while (my $row = $iterator->next()) {
    my $astring = $row->{"uri"}->as_string(); 
    my $atitle = $dom->createElementNS("http://purl.org/dc/terms/", "dc:subject");
    $atitle->setAttributeNS("http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdf:resource", $astring);
    $docNode->addChild($atitle);
    #print "Found [" . $astring . "]\n";
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
  $atitle = $dom->createElementNS("http://purl.org/ontology/bibo/", "doi");
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
  my $baseuri = $_[2];
  my $personalNode = $dom->createElementNS("http://xmlns.com/foaf/0.1/","foaf:Organization");  
  $personalNode->setAttributeNS("http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdf:about", $baseuri . "-" . substr(md5_hex($publish),1,10) );
  my $anode = $dom->createElementNS("http://xmlns.com/foaf/0.1/", "foaf:name");
   $anode->addChild($dom->createTextNode($publish));
   $personalNode->addChild($anode);  
  return($personalNode);
}
#######
#
#<languageTerm type="text">
sub language 
{
  my $currentLang = $_[0];
  my $dom = $_[1];
  my $baseuri = $_[2];
  if ($currentLang->get_languageTerm(type =>'text')) {
   my $localString = lc($currentLang->get_languageTerm(type =>'text'));
   if (exists $marcLanguages{$localString}) {
     my $relator = $dom->createElementNS("http://purl.org/dc/terms/", "dcterms:language");
     $relator->setAttributeNS("http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdf:resource","http://id.loc.gov/vocabulary/languages/" . $marcLanguages{$localString});
     return($relator);   
    }
  }
  my $relator = $dom->createElementNS("http://purl.org/dc/terms/", "dcterms:language");
  $relator->addChild($dom->createTextNode($currentLang->get_languageTerm()));
  return($relator);   

}
############
sub people
{  
#      <name type="corporate">
#      <namePart type="family">Nakamura</namePart>
#      <namePart type="given">Lisa</namePart>
  my $name = $_[0];
  my $dom = $_[1];
  my $baseuri = $_[2];
  my $anode = $dom->createElementNS("http://purl.org/", "purl:dc");
  my $relator = $dom->createElementNS("http://id.loc.gov/vocabulary/relators/", "rel:" . $name->get_role()->get_roleTerm());
  my $personalNode = $dom->createElementNS("http://xmlns.com/foaf/0.1/","foaf:Person");  
  $relator->addChild($personalNode);
  my $mystring =    $name->get_namePart(type => "given") . " " . $name->get_namePart(type => "family")  ;
  if ($name->get_namePart(type => "termsOfAddress")) {
   $mystring = $name->get_namePart(type => "termsOfAddress") . " " . $mystring;
  }
  $personalNode->setAttributeNS("http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdf:about", $baseuri . "-" . substr(md5_hex($mystring),1,10));
  #valueURI
  if ($name->{'valueURI'}) {
   $anode = $dom->createElementNS("http://www.w3.org/2002/07/owl#", "owl:sameAs");
   $anode->setAttributeNS("http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdf:resource", $name->{'valueURI'});
   $personalNode->addChild($anode);      
  }
  #
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
