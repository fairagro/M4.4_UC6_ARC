import yaml
from utility_functions import has_docker_annotation, has_namespace, has_performer, has_process_sequence, find_docker



def annotate_namespace(file):
    namespace = {
        "$namespaces": {"arc": "https://github.com/nfdi4plants/ARC_ontology"},
        "$schemas": ["https://raw.githubusercontent.com/nfdi4plants/ARC_ontology/main/ARC_v2.0.owl"]
    }
    append_to_file(file, "\n" + yaml.dump(namespace, Dumper=yaml.CDumper, default_flow_style=False, sort_keys=False) + "\n")



def performer_dict(first_name=None, last_name=None, email=None, affiliation=None, role=None, role_term_acc=None):
    return{
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
                    "arc:term accession": role_term_acc,
                    "arc:annotation value": role
                }
                ]
            }
        ]
    }

def annotate_performer(file, performer=None):
    if performer is None: 
        performer = performer_dict()
    if file:
        append_to_file(file, yaml.dump(performer, Dumper=yaml.CDumper, default_flow_style=False, sort_keys=False))



def add_process_step(parameter_value={"accession":"http://edamontology.org/operation_0004", "ref":"EMBRACE", "value":"Operation"}, annotation_value={"accession": "http://purl.obolibrary.org/obo/NCIT_C43582", "ref":"NCIT", "value":"Data Transformation"}):
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


def annotate_process_sequence(file, arc_name, steps=None):
    process_sequence = {
        "arc:has process sequence": [
            {
                "class": "arc:process sequence",
                "arc:name": arc_name,
                "arc:has parameter value": []
            }
        ]
    }
    if steps is None: 
        process_sequence["arc:has process sequence"][0]["arc:has parameter value"].append(add_process_step())
    # Dynamically add parameter value dictionaries
    else: 
        for step in steps:
            step_dict = add_process_step(step[0], step[1])
            process_sequence["arc:has process sequence"][0]["arc:has parameter value"].append(step_dict)
    
    append_to_file(file, "\n" + yaml.dump(process_sequence, Dumper=yaml.CDumper, default_flow_style=False, sort_keys=False) + "\n")




def append_to_file(file, text):
    try:
        with open(file, 'a') as f:
                f.write(text)
    except FileNotFoundError:
            print(f"The file '{file}' does not exist.")
    except IOError as e:
            print(f"I/O error({e.errno}): {e.strerror}")


def annotate_default_metadata(cwl_files, arc_name):
    for file in cwl_files:
        print("annotate file: ", file)
        if not has_docker_annotation(file): 
            annotate_docker_info(file)
        if not has_performer(file):
            annotate_performer(file)
        if not has_process_sequence(file, arc_name): 
            annotate_process_sequence(file, arc_name)
        if not has_namespace(file):
            annotate_namespace(file)



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
