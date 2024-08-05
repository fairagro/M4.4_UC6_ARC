import requests
import urllib.request, urllib.error, urllib.parse
from urllib.parse import urlparse
import json
import text2term 


ZOOMA_URL = "http://www.ebi.ac.uk/spot/zooma/v2/api/services/annotate"
BIOTOOLS_URL = "http://data.bioontology.org"



def get_json_biotools(url, biotools_key):
    opener = urllib.request.build_opener()
    opener.addheaders = [('Authorization', 'apikey token=' + biotools_key)]
    return json.loads(opener.open(url).read())

def map_term_biotools(search_term, biotools_key):
    opener = urllib.request.build_opener()
    opener.addheaders = [('Authorization', 'apikey token=' + biotools_key)]
    annotations =  json.loads(opener.open(BIOTOOLS_URL + "/annotator?text=" + urllib.parse.quote(search_term)).read())
    for result in annotations:
        class_details = get_json_biotools(result["annotatedClass"]["links"]["self"], biotools_key)
        return{
            "accession": class_details["@id"],
            "ref": get_term_source_ref(class_details["@id"]),
            "value": class_details["prefLabel"]
        }
    # in case no annotations were found
    return handle_no_annotations()


def map_term_ontology_mapper(search_term, ontology):
    df = text2term.map_terms(source_terms=list(search_term), target_ontology=ontology, use_cache=False)
    if(not df.empty):    
        term_iri = df['Mapped Term IRI'][0]
        term_label = df['Mapped Term Label'][0]
        term_source_ref = get_term_source_ref(term_iri)
        return{
            "accession": term_iri,
            "ref": term_source_ref,
            "value": term_label
        }
    return handle_no_annotations()

def get_term_source_ref(url):
    parsed_url = urlparse(url)
    path = parsed_url.path
    if "edam" in url:
        return "EMBRACE"
    else:
        prefix_parts = path.split('/')
        prefix = prefix_parts[-2].strip('_')
        uppercased_prefix = prefix.upper()
        return uppercased_prefix


def map_term_zooma(search_term, ontology):
    # see https://www.ebi.ac.uk/spot/zooma/docs/api for details of API parameters
    #   If 'required:[none]' is specified, Zooma will search the OLS without looking into the datasources.  
    required = ontology
    #ontologies = 'EDAM,HPO'
    ontologies = 'all'
    params = {
        "propertyValue": search_term,
        "filter": "required:["+required+"],ontologies:[" + ontologies  + "]"
    }
    response = requests.get(ZOOMA_URL, params=params, verify=True)
    if response.ok:
        json_resp = json.loads(response.content)
        if json_resp is not None:
            for mapping in json_resp:
                # get ontology term IRI of first term
                term_iri = mapping["semanticTags"][0]
                return{
                    "accession": term_iri,
                    "ref": get_term_source_ref(term_iri),
                    "value": mapping["annotatedProperty"]["propertyValue"]
                }
    return handle_no_annotations()

def handle_no_annotations():
    print("No ontology found")
    return {
        "accession": None,
        "ref": None,
        "value": None
    }
