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


def dict_equal(d1, d2):
    return all(k in d2 and d1[k] == d2[k] for k in d1)


def biotools_recommendations(search_term, biotools_key, max_recommendations=11):
    opener = urllib.request.build_opener()
    opener.addheaders = [('Authorization', 'apikey token=' + biotools_key)]
    annotations =  json.loads(opener.open(BIOTOOLS_URL + "/annotator?text=" + urllib.parse.quote(search_term)).read())
    recommendations = []
    for result in annotations[:max_recommendations]:
        class_details = result["annotatedClass"]
        try:
            class_details = get_json_biotools(result["annotatedClass"]["links"]["self"], biotools_key)
        except urllib.error.HTTPError:
            #print(f"Error retrieving {result['annotatedClass']['@id']}")
            continue
        recommendations.append({
            "accession": class_details["@id"],
            "ref": get_term_source_ref(class_details["@id"]),
            "value": class_details["prefLabel"]
        })
    
    unique_recommendations = [d for i, d in enumerate(recommendations) if not any(dict_equal(d, dd) for dd in recommendations[:i])]
    return unique_recommendations

def ontology_mapper_recommendations(search_term, ontology, max_recommendations=11):
    df = text2term.map_terms(source_terms=list(search_term), target_ontology=ontology, use_cache=False)
    recommendations = []
   
    if(not df.empty):  
        for index, row in df.iterrows():  
            term_iri = df['Mapped Term IRI'][index]
            term_label = df['Mapped Term Label'][index]
            term_source_ref = get_term_source_ref(term_iri)
            recommendations.append({
                "accession": term_iri,
                "ref": term_source_ref,
                "value": term_label
            })
    return recommendations[:max_recommendations]


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

def zooma_recommendations(search_term, ontology, max_recommendations=10):
    # see https://www.ebi.ac.uk/spot/zooma/docs/api for details of API parameters
    # If 'required:[none]' is specified, Zooma will search the OLS without looking into the datasources.  
    required = ontology
    ontologies = 'all'
    params = {
        "propertyValue": search_term,
        "filter": "required:["+required+"],ontologies:[" + ontologies  + "]"
    }
    recommendations = []
    response = requests.get(ZOOMA_URL, params=params, verify=True)
    if response.ok:
        json_resp = json.loads(response.content)
        for mapping in json_resp:
                # get ontology term IRI of first term
                term_iri = mapping["semanticTags"][0]
                recommendations.append({
                    "accession": term_iri,
                    "ref": get_term_source_ref(term_iri),
                    "value": mapping["annotatedProperty"]["propertyValue"]
                })
    return recommendations[:max_recommendations]
