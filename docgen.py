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

    template = template.format(authors=get_authors(graph), azlist=azlist_html,
                               terms=terms_html, deprecated=deprecated_html)

    # template = template % (azlist_html, terms_html, deprecated_html)
    # print(template)

    # temp_str = "lol{dict}".format(dict=dict_html)
    # print(temp_str)

    return template


def create_term_html(graph, list, list_type):
    # html_str = "<h3>%s</h3>" % list_type
    html_str = ""
    for x in list:
        uri = get_full_uri(x)
        # print(uri)
        # print(get_label_dict(graph, uri))
        # print(get_definition_dict(graph, uri))
        # print(get_comment_dict(graph, uri))
        # print("\n")

        term_dict = {
            "uri": uri,
            "label": get_label_dict(graph, uri),
            "defn": get_definition_dict(graph, uri),
            "comment": get_comment_dict(graph, uri),
            # "replacement": replacement,
        }
        print(list_type)
        if list_type == "Instance":
            print("it's a fucking instance")
            term_dict["rdf-type"] = get_rdf_type(graph, uri)
        html_str += get_term_html(term_dict, list_type)
        # print(get_term_html(term_dict))
        # print("\n\n\n\n\n")
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

    # <rdf:type rdf:resource="http://www.w3.org/2004/02/skos/core#Concept"/>
    # <skos:inScheme rdf:resource="#Religion"/>


def split_uri(uri):
    uri_list = []
    if "#" in uri:
        uri_list.append(uri.split("#")[0] + "#")
        uri_list.append(uri.split("#")[1])
    else:
        temp = uri.split("/")
        ident = temp[-1]
        uri_list.append(uri.split(ident)[0] + "/")
        uri_list.append(ident)
    return uri_list


def get_rdf_type(graph, uri):
    rdf = [o for s, p, o in graph.triples(((uri, RDF.type, None)))]
    # print(type(rdf))
    rdf_list = []
    # print(uri)
    # print(rdf)
    test = "http://xmlns.com/foaf/0.1#Organization"
    split_uri(test)
    exit()
    for x in rdf:
        print(x)
        if '#' not in x:
            # if str(x) == "http://xmlns.com/foaf/0.1/Organization":
            temp = split_uri(uri)[1]
        else:
            temp = x.split("#")[1]

        rdf_list.append(temp)
        # exit()
        # rdf_list.append(x.split("#")[1])
    print("\n\n")
    return (rdf_list)


def get_definition_dict(graph, uri):
    defn = [o for s, p, o in graph.triples(((uri, SKOS.definition, None)))]
    for x in defn:
        if x.language == lang:
            return x


def create_dictionary_html(graph, dictionary):
    html_str = "<h3 id= 'Dictionaries'>Dictionaries</h3>"

    for term in dictionary:
        uri = spec_url + term
        label = get_label_dict(graph, uri)
        comment = get_comment_dict(graph, uri)

        # print("Term: %s\n" % term)
        html_str += '<div class="specterm" id="%s">\n<h3>Dictionary: %s:%s</h3>\n' % (term, spec_pre, term)
        html_str += '<p>[<a href="#definition_list">back to top</a>]</p>'
        html_str += """<p class="uri">URI: <a href="%s">%s</a></p>\n""" % (uri, uri)
        html_str += """<p><em>%s</em>- %s</p>""" % (label, get_definition_dict(graph, uri))
        html_str += """<div class = "conceptlist">"""
        instance_list = [str(s).split("#")[1] for s, p, o in graph.triples((None, SKOS.inScheme, uri))]
        html_str += create_link_lists(instance_list, "Concepts:")
        html_str += "</div>\n"
        if comment:
            html_str += "<p>Comment: %s</p>" % comment
        html_str += "</div>\n"
    return html_str


def get_term_html(term_dict, term_type):
    label = str(term_dict["label"])
    uri = str(term_dict["uri"])
    term = uri.split("#")[1]
    comment = term_dict["comment"]
    defn = str(term_dict["defn"])
    # rdf_type1 = str(term_dict["rdf-type"])
    if term_type == "Instance":
        rdf_types = term_dict["rdf-type"]
        # rdf_type1 = str(term_dict["rdf-type"][0])

    html_str = ""
    html_str += '<div class="specterm" id="%s">\n<h3>%s: %s:%s</h3>\n' % (term, term_type, spec_pre, term)
    html_str += '<p>[<a href="#definition_list">back to top</a>]</p>'
    html_str += """<p class="uri">URI: <a href="%s">%s</a></p>\n""" % (uri, uri)
    html_str += """<p><em>%s</em>- %s</p>""" % (label, defn)
    if comment:
        html_str += "<p>Comment: %s</p>" % comment

    if term_type == "Instance":
        html_str += "<dl>\n"
        html_str += "<dt>RDF Type:</dt>\n"
        for x in rdf_types:
            html_str += '<dd><a href="#%s" style="font-family: monospace;">cwrc:%s</a></dd>' % (str(x), str(x))
        html_str += "</dl>"

    # html_str += """<p class="uri">Replaced by: <a href="%s">%s</a></p>\n""" % (replacement, replacement)
    html_str += "</div>\n"
    return html_str


def get_dep_term_html(term_dict):
    label = str(term_dict["label"])
    uri = str(term_dict["uri"])
    term = uri.split("#")[1]
    comment = term_dict["comment"]
    defn = str(term_dict["defn"])
    replacement = str(term_dict["replacement"])

    html_str = ""
    html_str += '<div class="specterm" id="%s">\n<h3>Term: %s:%s</h3>\n' % (term, spec_pre, term)
    html_str += """<p class="uri">URI: <a href="%s">%s</a></p>\n""" % (uri, uri)
    html_str += """<p><em>%s</em>- %s</p>""" % (label, defn)
    if comment:
        html_str += "<p>Comment: %s</p>" % comment
    html_str += """<p class="uri">Replaced by: <a href="%s">%s</a></p>\n""" % (replacement, replacement)
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

    html_str = '<h3>Global Cross Reference of Deprecated Terms</h3><div class="az_list">'
    html_str += create_link_lists(terms, "Deprecated Terms:")
    html_str += '</div><h3>Detailed references for all terms, classes and properties</h3>'
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

        # print("here")

        label = ""
        comment = ""
        defn = ""
        replacement = ""
        for row in graph.query(query_str):
            label = row.label
            comment = row.comment
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
        # print(get_dep_term_html(term_dict))

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
