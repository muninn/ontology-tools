#!/usr/bin/python3
import sys
# temp log library for debugging
# from log import *
import rdflib
import time

spec_url = None
spec_ns = None
spec_pre = None
lang = None

ns_list = {
    "content": "http://purl.org/rss/1.0/modules/content/",
    "dbpedia": "http://dbpedia.org/resource/",
    "dc": "http://purl.org/dc/elements/1.1/",
    "dct": "http://purl.org/dc/terms/",
    "doap": "http://usefulinc.com/ns/doap#",
    "foaf": "http://xmlns.com/foaf/0.1/",
    "geo": "http://www.w3.org/2003/01/geo/wgs84_pos#",
    "mil": "http://rdf.muninn-project.org/ontologies/military#",
    "naval": "http://rdf.muninn-project.org/ontologies/naval#",
    "ott": "http://rdf.muninn-project.org/ontologies/ott#",
    "owl": "http://www.w3.org/2002/07/owl#",
    "prov": "http://www.w3.org/ns/prov#",
    "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
    "rdfs": "http://www.w3.org/2000/01/rdf-schema#",
    "sioc": "http://rdfs.org/sioc/ns#",
    "skos": "http://www.w3.org/2004/02/skos/core#",
    "status": "http://www.w3.org/2003/06/sw-vocab-status/ns#",
    "vs": "http://www.w3.org/2003/06/sw-vocab-status/ns#",
    "xsd": "http://www.w3.org/2001/XMLSchema#"
}

# Important nspaces
RDF = rdflib.Namespace(ns_list["rdf"])
RDFS = rdflib.Namespace(ns_list["rdfs"])
SKOS = rdflib.Namespace(ns_list["skos"])
OWL = rdflib.Namespace(ns_list["owl"])
VS = rdflib.Namespace(ns_list["vs"])
PROV = rdflib.Namespace(ns_list["prov"])

# log = Log("log/docgen")
# log.test_name("Debugging Document Generator")

def print_usage():
    script = sys.argv[0]
    print("Usage:")
    print("\t%s ontology prefix template destination [flags]\n" % script)
    print("\t\tontology    : path to ontology file")
    print("\t\tprefix      : prefix for CURIEs")
    print("\t\ttemplate    : HTML template path")
    print("\t\tdestination : specification destination")
    print("\t\tlanguage flags:")
    print("\t\t\ten   : english")
    print("\t\t\tfr   : french")
    print("\nExamples:")
    print("%s example.owl ex template.html destination.html en" % script)
    sys.exit(-1)


def insert_dictionary(where, key, value):
    if key not in where:
        where[key] = []
    if value not in where[key]:
        where[key].append(value)


def get_domain_range_dict(graph):
    range_list = set(sorted(graph.objects(None, RDFS.range)))
    domain_list = set(sorted(graph.objects(None, RDFS.domain)))

    domain_dict = {}
    for domain_class in domain_list:
        query_str = "select ?x where {?x rdfs:domain <" + str(domain_class) + ">}"
        dom_props = []
        for row in graph.query(query_str):
            dom_props.append(str(row.x))
        domain_dict[str(domain_class)] = dom_props

    range_dict = {}
    for range_class in range_list:
        query_str = "select ?x where {?x rdfs:range <" + str(range_class) + ">}"
        rang_props = []
        for row in graph.query(query_str):
            rang_props.append(str(row.x))
        range_dict[str(range_class)] = rang_props

    return domain_dict, range_dict


def get_instances(graph, class_list):
    instances = []
    for owl_class in class_list:
        class_uri = spec_ns[owl_class]
        for s, p, o in graph.triples((None, RDF.type, class_uri)):
            instances.append(str(s).split("#")[1])

    instances = sorted(list(set(instances)))
    return instances


def create_link_lists(list, name):
    string = "<p>%s" % name
    for x in list:
        string += '<span class="list-item"><a href="#%s">%s</a>,</span>' % (x, x)
    string += "</p>"
    ' '.join(string.split())
    return(string)


def get_azlist_html(az_dict, list):
    string = '<div class="az_list">'
    for key in list:
        string += create_link_lists(az_dict[key], key)
    string += '</div>'
    return string


def specgen(specloc, template, language):
    global spec_url
    global spec_ns
    global ns_list

    # Creating rdf graph
    graph = rdflib.Graph()
    namespace_manager = rdflib.namespace.NamespaceManager(rdflib.Graph())
    graph.namespace_manager = namespace_manager
    try:
        graph.open("store", create=True)
        graph.parse(specloc)
    except Exception as e:
        raise e
        print_usage()

    # getting all namespaces from graph
    all_ns = [n for n in graph.namespace_manager.namespaces()]

    # creating a dictionary of the names spaces - {identifier:uri}
    global namespace_dict
    namespace_dict = {key: value for (key, value) in all_ns}

    spec_url = namespace_dict['']
    spec_ns = rdflib.Namespace(spec_url)
    ns_list[spec_pre] = spec_url

    # Gets sorted classes & property labels
    class_list = [x.split("#")[1] for x in sorted(graph.subjects(None, OWL.Class))]
    prop_list = [x.split("#")[1] for x in sorted(graph.subjects(None, OWL.ObjectProperty))]

    global domain_dict
    global range_dict
    domain_dict, range_dict = get_domain_range_dict(graph)

    # Dict_list in specgen
    skos_concepts = [str(s).split("#")[1] for s, p, o in sorted(
        graph.triples((None, RDF.type, SKOS.ConceptScheme)))]

    instance_list = get_instances(graph, class_list)

    # Build HTML list of terms.
    az_dict = {
        "Classes:": class_list,
        "Properties:": prop_list,
        "Instances:": instance_list,
        "Dictionaries:": skos_concepts,
    }
    temp_list = ["Dictionaries:", "Classes:", "Properties:", "Instances:"]

    # create global cross reference
    azlist_html = get_azlist_html(az_dict, temp_list)

    # Creating rest of html
    dict_html = create_dictionary_html(graph, skos_concepts)
    classes_html = "<h3 id='classes'>Classes</h3>" + create_term_html(graph, class_list, "Class")
    prop_html = "<h3 id='properties'>Properties</h3>" + create_term_html(graph, prop_list, "Property")
    instance_html = "<h3 id='instances'>Instances</h3>" + create_term_html(graph, instance_list, "Instance")
    deprecated_html = create_deprecated_html(graph)

    terms_html = dict_html + classes_html + prop_html + instance_html

    template = template.format(_authors_=get_authors(graph), _azlist_=azlist_html,
                               _terms_=terms_html, _deprecated_=deprecated_html)
    return template


def create_term_html(graph, list, list_type):
    html_str = ""
    for x in list:
        uri = get_full_uri(x)
        term_dict = {
            "uri": uri,
            "label": get_label_dict(graph, uri),
            "defn": get_definition_list(graph, uri),
            "comment": get_comment_list(graph, uri),
            "derived": get_ns_obj(graph, uri, PROV.derivedFrom)
        }

        if list_type == "Instance":
            term_dict["rdf-type"] = get_ns_obj(graph, uri, RDF.type)
        elif list_type == "Class":
            if get_ns_obj(graph, uri, OWL.sameAs):
                term_dict["same-as"] = get_ns_obj(graph, uri, OWL.sameAs)
            if get_ns_obj(graph, uri, RDFS.subClassOf):
                term_dict["subclass"] = get_ns_obj(graph, uri, RDFS.subClassOf)
            if str(uri) in domain_dict:
                temp = domain_dict[str(uri)]
                temp_dict = {}
                for y in temp:
                    temp_dict.update(get_prefix_ns_with_link(y))
                term_dict["in-domain"] = temp_dict
            if str(uri) in range_dict:
                temp = range_dict[str(uri)]
                temp_dict = {}
                for y in temp:
                    temp_dict.update(get_prefix_ns_with_link(y))
                term_dict["in-range"] = temp_dict

        elif list_type == "Property":
            if get_ns_obj(graph, uri, RDFS.range):
                term_dict["range"] = get_ns_obj(graph, uri, RDFS.range)
            if get_ns_obj(graph, uri, RDFS.domain):
                term_dict["domain"] = get_ns_obj(graph, uri, RDFS.domain)
            if get_ns_obj(graph, uri, RDFS.subPropertyOf):
                term_dict["subproperty"] = get_ns_obj(graph, uri, RDFS.subPropertyOf)
        
        html_str += get_term_html(term_dict, list_type)
    return html_str


def get_comment_list(graph, uri):
    comment = [o for s, p, o in graph.triples(((uri, RDFS.comment, None)))]
    comment_list = []
    for x in comment:
        if x.language == lang:
            comment_list.append(str(x))

    return comment_list


def get_label_dict(graph, uri):
    label = [o for s, p, o in graph.triples(((uri, RDFS.label, None)))]
    for x in label:
        if x.language == lang:
            return x
    return (None)


def get_prefix_ns_with_link(uri):
    uri_list = []
    if "#" in uri:
        uri_list.append(uri.split("#")[0] + "#")
        uri_list.append(uri.split("#")[1])
    else:
        temp = uri.split("/")
        ident = temp[-1]
        uri_list.append(uri.split(ident)[0])
        uri_list.append(ident)

    uri_dict = {}
    for k, v in namespace_dict.items():
        if uri_list[0] == str(v):
            if k == "":
                # Must be base xml
                temp = uri_list[0].split("/")[-1][:-1]
                tempkey = (temp) + ":" + uri_list[1]
                uri_dict[tempkey] = "#" + uri_list[1]
            else:
                tempkey = str(k) + ":" + uri_list[1]
                uri_dict[tempkey] = uri

    if len(uri_dict.keys()) == 0:
        uri_dict[uri] = uri
    return uri_dict


def get_ns_obj(graph, uri, ns_uri):
    uris = [str(o) for s, p, o in graph.triples(((uri, ns_uri, None)))]
    ns_dict = {}
    for uri in uris:
        ns_dict.update(get_prefix_ns_with_link(uri))
    return ns_dict


def get_definition_list(graph, uri):
    defn = [o for s, p, o in graph.triples(((uri, SKOS.definition, None)))]
    defn_list = []
    for x in defn:
        if x.language == lang:
            defn_list.append(str(x))
    return defn_list


def create_dictionary_html(graph, dictionary):
    html_str = "<h3 id= 'dictionaries'>Dictionaries</h3>"

    for term in dictionary:
        uri = spec_url + term
        label = get_label_dict(graph, uri)
        comment = get_comment_list(graph, uri)

        html_str += '<div class="specterm" id="%s">\n' % term
        html_str += '<p id="top">[<a href="#definition_list">back to top</a>]</p>'
        html_str += '<h3>Dictionary: %s:%s</h3>\n' % (spec_pre, term)
        html_str += """<p class="uri">URI: <a href="#%s">%s</a></p>\n""" % (term, uri)
        html_str += """<p><em>%s</em></p>""" % (label)
        html_str += """<div class="defn">%s</div>""" % (get_defn_html(get_definition_list(graph, uri)))
        html_str += """<div class = "conceptlist">"""
        instance_list = [str(s).split("#")[1] for s, p, o in graph.triples((None, SKOS.inScheme, uri))]
        html_str += create_link_lists(instance_list, "Concepts:")
        html_str += "</div>\n"

        if comment:
            html_str += get_comment_html(comment)
        html_str += "</div>\n"
    return html_str


def get_comment_html(comm_list):
    html_str = "<div class=\"comment\">"
    html_str += "<p>Comment:</p>\n<p>"
    for x in comm_list:
        if x:
            html_str += "%s<br>" % x
    html_str += "</p></div>\n"
    return html_str


def get_defn_html(defn_list):
    counter = 1
    html_str = ""
    for x in defn_list:
        if x:
            if len(defn_list) != 1:
                html_str += "<p><em>%d</em>- %s</p>\n" % (counter, x)
            else:
                html_str += "<p>%s</p>\n" % (x)
        counter += 1
    return html_str

def get_dl_html(prefix_str,term_dict,prefix):
    html_str = ""
    if prefix in term_dict:
        html_str += "<dl>\n"
        html_str += "<dt>%s:</dt>\n" % prefix_str
        for x in term_dict[prefix]:
            html_str += '<dd><a href="%s" style="font-family: monospace;">%s</a></dd>' % (term_dict[prefix][
                x], str(x))
        html_str += "</dl>\n"
    return html_str

def get_term_html(term_dict, term_type):
    label = str(term_dict["label"])
    uri = str(term_dict["uri"])
    term = uri.split("#")[1]
    comment = term_dict["comment"]
    defn = term_dict["defn"]
    derived = term_dict["derived"]

    html_str = ""
    html_str += '<div class="specterm" id="%s">\n' % term
    html_str += '<p id="top">[<a href="#definition_list">back to top</a>]</p>'
    html_str += '<h3>%s: %s:%s</h3>\n' % (term_type, spec_pre, term)
    html_str += """<p class="uri">URI: <a href="#%s">%s</a></p>\n""" % (term, uri)
    html_str += """<p><em>%s</em></p>""" % (label)
    html_str += """<div class="defn">%s</div>""" % (get_defn_html(defn))
    if comment:
        html_str += get_comment_html(comment)

    prefix_list = ["derived","rdf-type", "same-as", "subclass" , "in-domain", "in-range", "range" , "domain" , "subproperty"]
    prefix_dict = {
        "derived": "PROV Derived From",
        "rdf-type": "RDF Type",
        "same-as" : "Same As",
        "subclass" : "Sub Class Of",
        "in-domain" : "In Domain Of:",
        "in-range" : "In Range Of:",
        "range" : "Range",
        "domain" : "Domain",
        "subproperty" : "Subproperty",
    }

    for prefix in prefix_list:
        html_str += get_dl_html(prefix_dict[prefix],term_dict,prefix)
    html_str += "\n</div>\n"

    return html_str


def get_dep_term_html(term_dict):
    label = str(term_dict["label"])
    uri = str(term_dict["uri"])
    term = uri.split("#")[1]
    comment = term_dict["comment"]
    defn = str(term_dict["defn"])
    replacement = str(term_dict["replacement"])

    html_str = ""
    html_str += '<div class="specterm" id="%s">\n' % term
    html_str += '<p id="top">[<a href="#deprecated_list">back to top</a>]</p>'
    html_str += '<h3>Term: %s:%s</h3>\n' % (spec_pre, term)
    html_str += """<p class="uri">URI: <a href="%s">%s</a></p>\n""" % (uri, uri)
    if label:
        html_str += "<p><em>%s</em></p>" % label
    if defn:
        html_str += """<p>%s</p>""" % (defn)
    if comment:
        # html_str += get_comment_html(comment)
        html_str += "<p>Comment: %s</p>" % comment
    # temp =
    if replacement:
        if spec_pre in replacement:
            html_str += """<p class="uri">Replaced by: <a href="#%s">%s</a></p>\n""" % (replacement.split("#")[
                1], replacement)
        else:
            html_str += """<p class="uri">Replaced by: <a href="%s">%s</a></p>\n""" % (replacement, replacement)

        # pass
    html_str += "</div>\n"
    return html_str


def get_deprecated_terms(graph):
    query_str = """
select * where {
    ?uri vs:term_status ?literal.
}   
    """
    deprecated_uris = []
    for row in graph.query(query_str):
        if str(row.literal) == "deprecated":
            deprecated_uris.append(str(row.uri))

    deprecated_uris = sorted(deprecated_uris)
    terms = [str(s).split("#")[1] for s in deprecated_uris]

    html_str = '<h3 id="deprecated_list" >Global Cross Reference of Deprecated Terms</h3><div class="az_list deprecated_list">'
    html_str += create_link_lists(terms, "Deprecated Terms:<br>")
    html_str += '</div><h3>Detailed references for all terms, classes and properties</h3>'
    html_str += "<div class=\"deprecated_term\">"
    for uri in deprecated_uris:

        query_str = """
        select distinct ?label ?y ?defn ?comment where {
            OPTIONAL { <%s> rdfs:comment ?comment. }.
            OPTIONAL { <%s> rdfs:label ?label. }.
            OPTIONAL { <%s> skos:definition ?defn. }.
            OPTIONAL { <%s> dcterms:isReplacedBy ?y. }.
            filter(
                langMatches(lang(?defn), "%s") && langMatches(lang(?label), "%s")
            )
        }   
            """ % (uri, uri, uri, uri, lang, lang)

        label = ""
        comment = ""
        defn = ""
        replacement = ""
        for row in graph.query(query_str):
            label = row.label

            temp = row.comment
            if temp:
                if temp.language == lang:
                    comment = temp

            defn = row.defn
            replacement = row.y

        term_dict = {
            "uri": uri,
            "label": label,
            "comment": comment,
            "defn": defn,
            "replacement": replacement,
        }
        html_str += get_dep_term_html(term_dict)
    html_str += "</div>"
    return html_str


def get_full_uri(string):
    return spec_url + string


def create_deprecated_html(graph):
    return get_deprecated_terms(graph)


def get_contributors(graph):

    query_str = """
select distinct ?x ?y where {
    ?person dcterms:creator ?name .
        ?name foaf:name ?x .
    OPTIONAL { ?name owl:sameAs ?y }.
}
    """
    print(query_str)
    names = {}
    for row in graph.query(query_str):
        names[str(row.x)] = str(row.y)


def get_authors(graph):

    query_str = """
select distinct ?x ?y where {
    ?person dcterms:creator ?name .
        ?name foaf:name ?x .
    OPTIONAL { ?name foaf:homepage ?y }.
}
    """
    names = {}
    for row in graph.query(query_str):
        names[str(row.x)] = str(row.y)

    # sort names based on last name
    name_list = [str(x) for x in names.keys()]
    name_list = sorted(sorted(name_list), key=lambda n: n.split()[1])
    html_str = ""
    for x in name_list:
        html_str += "<dd>"
        if names[x] != 'None':
            html_str += '<a href="%s">%s</a>' % (names[x], x)
        else:
            html_str += x
        html_str += "</dd>\n"
    return html_str


def save(template, dest, stdout=False):
    if stdout:
        print(template)
    else:
        f = open(dest, "w")
        f.write(template)
        f.close()


def main():
    global lang
    global spec_pre

    if (len(sys.argv) != 6):
        print_usage()

    specloc = sys.argv[1]
    # get rid of get --> <vann:preferredNamespacePrefix>cwrc</vann:preferredNamespacePrefix>
    spec_pre = sys.argv[2]
    temploc = sys.argv[3]
    dest = sys.argv[4]
    lang = sys.argv[5]
    template = None

    try:
        f = open(temploc, "r")
        template = f.read()
    except Exception as e:
        print("Error reading from template \"" + temploc + "\": " + str(e))
        print_usage()

    if lang.lower() not in ["en", "fr"]:
        print("Language selected is currently not supported")
        print_usage()

    template = specgen(specloc, template, lang)
    template += "<!-- specification regenerated by DocGen on %s-->" % time.strftime("%A, %B %d at %I:%M:%S %p %Z")
    save(template, dest)


if __name__ == "__main__":
    main()
