import urllib.error, urllib.parse
import yaml
from utils import append_to_file, find_docker
from mappers import map_term_biotools, map_term_ontology_mapper, map_term_zooma


def annotate_namespace(file):
    namespace = {
        "$namespaces": {
            "arc": "https://github.com/nfdi4plants/ARC_ontology"
        },
        "$schemas": [
            "https://raw.githubusercontent.com/nfdi4plants/ARC_ontology/main/ARC_v2.0.owl"
        ]
    }
    append_to_file(file, "\n" + yaml.dump(namespace, Dumper=yaml.CDumper, default_flow_style=False, sort_keys=False) + "\n")


def annotate_performer(file, first_name, last_name, email, affiliation, role, mapper, biotools_key, ontology):
    if(mapper == "biotools"):
        role_values = map_term_biotools(role, biotools_key)
    elif(mapper=="ontology_mapper"): 
        role_values = map_term_ontology_mapper(role, ontology)
    else:
        role_values = map_term_zooma(role, ontology)
    performer = {
        "arc:performer": [
            {
                "class": "arc:Person",
                "arc:first name": first_name,
                "arc:last name": last_name, 
                "arc:email": email,
                "arc:affiliation": affiliation,
                "arc:has role": [
                {
                    "class": "arc:role",
                    "arc:term accession": role_values["accession"],
                    "arc:annotation value": role_values["value"]
                }
                ]
            }
        ]
    }
    append_to_file(file, yaml.dump(performer, Dumper=yaml.CDumper, default_flow_style=False, sort_keys=False))


def process_value(parameter_value, annotation_value):
    return {
        "class": "arc:process parameter value",
        "arc:has parameter": [
            {
                "class": "arc:protocol parameter",
                "arc:has parameter name": [
                    {
                        "class": "arc:parameter name",
                        "arc:term accession": parameter_value["accession"],
                        "arc:term source REF": parameter_value["ref"],
                        "arc:annotation value": parameter_value["value"]
                    }
                ]
            }
        ],
        "arc:value": [
            {
                "class": "arc:ontology annotation",
                "arc:term accession": annotation_value["accession"],
                "arc:term source REF": annotation_value["ref"],
                "arc:annotation value": annotation_value["value"]
            }
        ]
    }

def annotate_process_sequence(file, arc_name, metadata_steps, mapper, biotools_key, ontology):
    process_sequence = {
        "arc:has process sequence": [
            {
                "class": "arc:process sequence",
                "arc:name": arc_name,
                "arc:has parameter value": []
            }
        ]
    }
    #each step is operation, ask user for this info or find pattern behind annotations
    param_process = {
        "accession": "http://edamontology.org/operation_0004",
        "ref": "EMBRACE",
        "value": "Operation"
    }
    # Dynamically add parameter value dictionaries
    for step in metadata_steps:
        if(mapper=="biotools"):
            param_values = map_term_biotools(step, biotools_key)
        elif(mapper=="ontology_mapper"): 
            param_values = map_term_ontology_mapper(step, ontology)
        else:
            param_values = map_term_zooma(step, ontology)
        step_dict = process_value(param_process, param_values)
        process_sequence["arc:has process sequence"][0]["arc:has parameter value"].append(step_dict)
    
    append_to_file(file, "\n" + yaml.dump(process_sequence, Dumper=yaml.CDumper, default_flow_style=False, sort_keys=False) + "\n")




def annotate_docker_info(file):
    if find_docker:  
        docker = {
            "arc:has technology type": [
                {
                    "class": "arc:technology type",
                    "arc:annotation value": "Docker Container"
                }
            ]
        }
        append_to_file(file, "\n\n" + yaml.dump(docker, Dumper=yaml.CDumper, default_flow_style=False, sort_keys=False) + "\n")
