#!/usr/bin/python3
"""Summary

Attributes:
    classdomains (dict): Description
    classranges (dict): Description
    lang (TYPE): Description
    ns_list (TYPE): Description
    OWL (TYPE): Description
    PROV (TYPE): Description
    RDF (TYPE): Description
    RDFS (TYPE): Description
    SKOS (TYPE): Description
    spec_ns (TYPE): Description
    spec_pre (str): Description
    spec_url (TYPE): Description
    VS (TYPE): Description
"""
# import os
# import codecs
import sys
from log import *

# import time
# import re
# import urllib
import rdflib

classranges = {}
classdomains = {}
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

log = Log("log/docgen")
log.test_name("Debugging Document Generator")


def print_usage():
    """Summary
    Print msg explaining usage of application
    """
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
    """Summary

    Args:
        where (TYPE): Description
        key (TYPE): Description
        value (TYPE): Description
    """
    if key not in where:
        where[key] = []
    if value not in where[key]:
        where[key].append(value)


def get_domain_range_dict(graph):
    """Summary

    Args:
        graph (TYPE): Description

    Returns:
        TYPE: Description
    """
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
    """Summary

    Args:
        graph (TYPE): Description
        class_list (TYPE): Description

    Returns:
        TYPE: Description
    """
    instances = []
    for owl_class in class_list:
        class_uri = spec_ns[owl_class]
        for s, p, o in graph.triples((None, RDF.type, class_uri)):
            instances.append(str(s).split("#")[1])

    instances = sorted(list(set(instances)))
    return instances


def create_link_lists(list, name):
    """

    Args:
        list (list): Description
        name (str): Description

    Returns:
        TYPE: Description
    """
    string = "<p>%s" % name
    for x in list:
        string += '<span class="list-item"><a href="#%s">%s</a>,</span>' % (x, x)
    string += "</p>"
    # string.trim
    ' '.join(string.split())
    return(string)


def get_azlist_html(az_dict, list):
    """Summary

    Args:
        az_dict (dictionary): Description
        list (list): Description

    Returns:
        TYPE: Description
    """
    string = '<div class="az_list">'
    for key in list:
        string += create_link_lists(az_dict[key], key)
    string += '</div>'
    return string


def specgen(specloc, template, language):
    """Summary

    Args:
        specloc (str): owl path
        template (str): template path
        language (str):

    Returns:
        str: raw html of spec

    Raises:
        e: Description
    """
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
    # log.separ("#")
    # log.msg("domain:")
    # log.msg(domain_dict)
    # log.separ("#")
    # log.msg("Range:")
    # log.msg(range_dict)
    # log.separ("#")

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
    azlist_html = get_azlist_html(az_dict, temp_list)

    dict_html = create_dictionary_html(graph, skos_concepts)
    classes_html = "<h3 id='classes'>Classes</h3>" + create_term_html(graph, class_list, "Class")
    prop_html = "<h3 id='properties'>Properties</h3>" + create_term_html(graph, prop_list, "Property")
    instance_html = "<h3 id='instances'>Instances</h3>" + create_term_html(graph, instance_list, "Instance")
    deprecated_html = create_deprecated_html(graph)

    terms_html = dict_html + classes_html + prop_html + instance_html

    template = template.format(_authors_=get_authors(graph), _azlist_=azlist_html,
                               _terms_=terms_html, _deprecated_=deprecated_html)

    # template = template % (azlist_html, terms_html, deprecated_html)
    print(template)

    # temp_str = "lol{dict}".format(dict=dict_html)
    # print(temp_str)

    return template


def create_term_html(graph, list, list_type):
    # html_str = "<h3>%s</h3>" % List_type
    html_str = ""
    log.msg("domain")
    log.msg(domain_dict)
    log.msg("range")
    log.msg(range_dict)
    for x in list:
        uri = get_full_uri(x)
        term_dict = {
            "uri": uri,
            "label": get_label_dict(graph, uri),
            "defn": get_definition_dict(graph, uri),
            "comment": get_comment_dict(graph, uri),
            "derived": get_prov_derivedFrom(graph, uri),
        }
        log.msg(uri)
        if list_type == "Instance":
            log.msg("rdf-type")
            term_dict["rdf-type"] = get_rdf_type(graph, uri)
            log.msg(term_dict["rdf-type"])
        elif list_type == "Class":
            if get_owl_sameas(graph, uri):
                term_dict["same-as"] = get_owl_sameas(graph, uri)
            if get_rdfs_subclass(graph, uri):
                term_dict["subclass"] = get_rdfs_subclass(graph, uri)
            if uri in domain_dict:
                log.msg(domain_dict[uri])
                term_dict["in-domain"] = domain_dict[uri]
            if uri in range_dict:
                log.msg(range_dict[uri])
                term_dict["in-range"] = range_dict[uri]

        elif list_type == "Property":
            if get_rdfs_range(graph, uri):
                term_dict["range"] = get_rdfs_range(graph, uri)
            if get_rdfs_domain(graph, uri):
                term_dict["domain"] = get_rdfs_domain(graph, uri)
            if get_rdfs_subproperty(graph, uri):
                term_dict["subproperty"] = get_rdfs_subproperty(graph, uri)
        log.separ()
        # exit()
        html_str += get_term_html(term_dict, list_type)
    return html_str


def get_comment_dict(graph, uri):
    comment = [o for s, p, o in graph.triples(((uri, RDFS.comment, None)))]

    for x in comment:
        if x.language == lang:
            return x
    return (None)


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
        log.msg("*prefix*")
        log.separ("&")
        log.msg(uri_list[0])
        log.msg(uri_list[1])
        log.separ("&")
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


def get_owl_sameas(graph, uri):
    uris = [str(o) for s, p, o in graph.triples(((uri, OWL.sameAs, None)))]
    ns_dict = {}
    for uri in uris:
        ns_dict.update(get_prefix_ns_with_link(uri))
    return ns_dict


def get_rdfs_subclass(graph, uri):
    uris = [str(o) for s, p, o in graph.triples(((uri, RDFS.subClassOf, None)))]
    ns_dict = {}
    for uri in uris:
        ns_dict.update(get_prefix_ns_with_link(uri))

    return ns_dict


def get_rdfs_subproperty(graph, uri):
    uris = [str(o) for s, p, o in graph.triples(((uri, RDFS.subPropertyOf, None)))]
    ns_dict = {}
    for uri in uris:
        ns_dict.update(get_prefix_ns_with_link(uri))

    return ns_dict


def get_rdfs_range(graph, uri):
    uris = [str(o) for s, p, o in graph.triples(((uri, RDFS.range, None)))]
    ns_dict = {}
    for uri in uris:
        ns_dict.update(get_prefix_ns_with_link(uri))

    return ns_dict


def get_rdfs_domain(graph, uri):
    uris = [str(o) for s, p, o in graph.triples(((uri, RDFS.domain, None)))]
    ns_dict = {}
    for uri in uris:
        ns_dict.update(get_prefix_ns_with_link(uri))

    return ns_dict


def get_prov_derivedFrom(graph, uri):
    uris = [str(o) for s, p, o in graph.triples(((uri, PROV.derivedFrom, None)))]
    ns_dict = {}
    for uri in uris:
        ns_dict.update(get_prefix_ns_with_link(uri))

    log.msg("prov-derivedfrom")
    log.msg(ns_dict)
    return ns_dict


def get_rdf_type(graph, uri):
    rdf_uris = [str(o) for s, p, o in graph.triples(((uri, RDF.type, None)))]
    rdf_dict = {}
    for uri in rdf_uris:
        rdf_dict.update(get_prefix_ns_with_link(uri))
    return (rdf_dict)


def get_definition_dict(graph, uri):
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
        comment = get_comment_dict(graph, uri)

        html_str += '<div class="specterm" id="%s">\n' % term
        html_str += '<p id="top">[<a href="#definition_list">back to top</a>]</p>'
        html_str += '<h3>Dictionary: %s:%s</h3>\n' % (spec_pre, term)
        html_str += """<p class="uri">URI: <a href="#%s">%s</a></p>\n""" % (term, uri)
        html_str += """<p><em>%s</em></p>""" % (label)
        html_str += """<div class="defn">%s</div>""" % (get_defn_html(get_definition_dict(graph, uri)))
        html_str += """<div class = "conceptlist">"""
        instance_list = [str(s).split("#")[1] for s, p, o in graph.triples((None, SKOS.inScheme, uri))]
        html_str += create_link_lists(instance_list, "Concepts:")
        html_str += "</div>\n"

        if comment:
            html_str += "<p>Comment: %s</p>" % comment
        html_str += "</div>\n"
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
        html_str += "<p>Comment: %s</p>\n" % comment
    if derived:
        html_str += "<dl>\n"
        html_str += "<dt>PROV Derived From:</dt>\n"
        for link in derived:
            html_str += "<dd><a href=\"%s\">%s</a></dd>" % (derived[link], link)
        html_str += "</dl>\n"
    if "rdf-type" in term_dict:
        html_str += "<dl>\n"
        html_str += "<dt>RDF Type:</dt>\n"
        for x in term_dict["rdf-type"]:
            html_str += '<dd><a href="%s" style="font-family: monospace;">%s</a></dd>' % (term_dict["rdf-type"][
                x], str(x))
        html_str += "</dl>\n"

    if "same-as" in term_dict:
        html_str += "<dl>\n"
        html_str += "<dt>same-as:</dt>\n"
        for x in term_dict["same-as"]:
            html_str += '<dd><a href="%s" style="font-family:monospace;">%s</a></dd>' % (term_dict["same-as"][
                x], str(x))
        html_str += "</dl>\n"
    if "subclass" in term_dict:
        html_str += "<dl>\n"
        html_str += "<dt>sub-class-of:</dt>\n"
        for x in term_dict["subclass"]:
            html_str += '<dd><a href="%s" style="font-family:monospace;">%s</a></dd>' % (term_dict["subclass"][
                x], str(x))
        html_str += "</dl>\n"
    if "in-domain" in term_dict:
        html_str += "<dl>\n"
        html_str += "<dt>in-domain-of:</dt>\n"
        for x in term_dict["in-domain"]:
            html_str += '<dd><a href="%s" style="font-family:monospace;">%s</a></dd>' % (term_dict["in-domain"][
                x], str(x))
        html_str += "</dl>\n"
    if "in-range" in term_dict:
        html_str += "<dl>\n"
        html_str += "<dt>in-range-of:</dt>\n"
        for x in term_dict["in-range"]:
            html_str += '<dd><a href="%s" style="font-family:monospace;">%s</a></dd>' % (term_dict["in-range"][
                x], str(x))
        html_str += "</dl>\n"

    if "range" in term_dict:
        html_str += "<dl>\n"
        html_str += "<dt>range:</dt>\n"
        for x in term_dict["range"]:
            html_str += '<dd><a href="%s" style="font-family:monospace;">%s</a></dd>' % (term_dict["range"][
                x], str(x))
        html_str += "</dl>\n"
    if "domain" in term_dict:
        html_str += "<dl>\n"
        html_str += "<dt>domain:</dt>\n"
        for x in term_dict["domain"]:
            html_str += '<dd><a href="%s" style="font-family:monospace;">%s</a></dd>' % (term_dict["domain"][
                x], str(x))
        html_str += "</dl>\n"
    if "subproperty" in term_dict:
        html_str += "<dl>\n"
        html_str += "<dt>subproperty:</dt>\n"
        for x in term_dict["subproperty"]:
            html_str += '<dd><a href="%s" style="font-family:monospace;">%s</a></dd>' % (term_dict["subproperty"][
                x], str(x))
        html_str += "</dl>\n"

    html_str += "\n</div>\n"
    # if term_type == "Instance":
    #     print(html_str)
    #     exit()
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
    html_str += """<p><em>%s</em>- %s</p>""" % (label, defn)
    if comment:
        html_str += "<p>Comment: %s</p>" % comment
    # temp =
    if replacement:
        html_str += """<p class="uri">Replaced by: <a href="#%s">%s</a></p>\n""" % (replacement.split("#")[
            1], replacement)
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

    # for x in deprecated_uris:
    #     print(x)

    deprecated_uris = sorted(deprecated_uris)
    terms = [str(s).split("#")[1] for s in deprecated_uris]
    # print("Deprecated terms\n\n")

    html_str = '<h3 id="deprecated_list" >Global Cross Reference of Deprecated Terms</h3><div class="az_list deprecated_list">'
    html_str += create_link_lists(terms, "Deprecated&nbsp;Terms:")
    html_str += '</div><h3>Detailed references for all terms, classes and properties</h3>'
    html_str += "<div class=\"deprecated_term\">"
    for uri in deprecated_uris:

        query_str = """
        select distinct ?label ?y ?defn ?comment where {
            <%s> rdfs:label ?label.
            <%s> dcterms:isReplacedBy ?y.
            <%s> skos:definition ?defn.
            OPTIONAL { <%s> rdfs:comment ?comment }.
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

            comment = ""
            temp = row.comment
            if temp:
                if temp.language == lang:
                    comment = temp

            defn = row.defn
            replacement = row.y

        # print("done")
        term_dict = {
            "uri": uri,
            "label": label,
            "comment": comment,
            "defn": defn,
            "replacement": replacement,
        }
        html_str += get_dep_term_html(term_dict)
        log.separ()
        # print(get_dep_term_html(term_dict))
    html_str += "</div>"
    # print(html_str)
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


def set_term_dir(directory):
    """Summary
# Sets directory for terminology --> to get rid of

    Args:
        directory (TYPE): Description
    """
    global termdir
    termdir = directory


def main():
    """Summary
    """
    global lang
    if (len(sys.argv) != 6):
        print_usage()

    specloc = sys.argv[1]
    global spec_pre
    spec_pre = sys.argv[2]
    specdoc = spec_pre + "-docs"
    temploc = sys.argv[3]
    dest = sys.argv[4]
    lang = sys.argv[5]
    template = None

    set_term_dir(specdoc)

    try:
        f = open(temploc, "r")
        template = f.read()
    except Exception as e:
        print("Error reading from template \"" + temploc + "\": " + str(e))
        print_usage()

    if lang.lower() not in ["en", "fr"]:
        print("Language selected is currently not supported")
        print_usage()

    specgen(specloc, template, lang)

    # save(dest, specgen(specloc, template, instances=instances))


if __name__ == "__main__":
    main()
