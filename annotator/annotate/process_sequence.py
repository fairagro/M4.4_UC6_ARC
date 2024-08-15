from mappers import biotools_recommendations, zooma_recommendations, ontology_mapper_recommendations
from arc_annotation import annotate_process_sequence
from utility_functions import load_cwl_file
from rich.console import Console
from beaupy import prompt, select
import yaml


def get_recommendations(term, mapper, ontology, biotools_key):
    console = Console()
    if mapper == 'biotools':
        recommendations = biotools_recommendations(term, biotools_key)
        print(recommendations)
    elif mapper == 'ontology_mapper':
        recommendations = ontology_mapper_recommendations(term, ontology)
        print(recommendations)
    else:
            recommendations =zooma_recommendations(term, ontology)
            print(recommendations)
    console.print("Annotate: ")
    recommendations.insert(0, {'accession': None, 'ref': None, 'value': term})
    annotation_term = select(recommendations, cursor="->", cursor_style="cyan")
    print("term", annotation_term)
    return annotation_term

def update_process_sequence(cwl, cwl_dict):
    """Updates the CWL file with a new process sequence."""
    del cwl_dict['arc:has process sequence']
    yaml_str = yaml.dump(cwl_dict, Dumper=yaml.CDumper, allow_unicode=True, sort_keys=False)
    with open(cwl, 'w', encoding='utf-8') as f:
        f.write(yaml_str)

def get_term_parameters(mapper, ontology, biotools_key, metadata_protocol_param=None):
    """Gets term parameters based on user input or default values."""
    if metadata_protocol_param:
        return get_recommendations(metadata_protocol_param, mapper, ontology, biotools_key)
    else:
        return {"accession": "http://edamontology.org/operation_0004", "ref": "EMBRACE", "value": "Operation"}

def get_term_values(mapper, ontology, biotools_key, metadata_protocol_param_value=None):
    """Gets term values based on user input or default values."""
    if metadata_protocol_param_value:
        return get_recommendations(metadata_protocol_param_value, mapper, ontology, biotools_key)
    else:
        return {"accession": "http://purl.obolibrary.org/obo/NCIT_C43582", "ref": "NCIT", "value": "Data Transformation"}

def add_process_step(cwl, arc_name, mapper="zooma", ontology=None, biotools_key=None):
    console = Console()
    process_seq = find_process_sequence(cwl)
    cwl_dict = load_cwl_file(cwl)
    steps = []
    if process_seq:
        console.print(f"Found process sequence {process_seq} for file {cwl}")
        should_update_seq = select(["Update", "Skip"], cursor="->", cursor_style="cyan")
        if should_update_seq == "Update":
            update_process_sequence(cwl, cwl_dict)
        elif should_update_seq == "Skip":
            return None
    while True:
        metadata_param = select(["Annotate Default protocol parameter", "Add protocol parameter", "Leave"], cursor="->", cursor_style="cyan")
        if metadata_param == "Leave":
            annotate_process_sequence(cwl, arc_name, steps)
            break
        elif metadata_param == "Annotate Default protocol parameter":
            term_param = get_term_parameters(mapper, ontology, biotools_key)
        elif metadata_param == "Add protocol parameter":
            metadata_protocol_param = prompt("Enter a term to describe protocol parameter: ")
            term_param = get_term_parameters(mapper, ontology, biotools_key, metadata_protocol_param)
        metadata_param_value = select(["Annotate Default protocol parameter value", "Add protocol parameter value"], cursor="->", cursor_style="cyan")
        if metadata_param_value == "Add protocol parameter value":
            metadata_protocol_param_value = prompt("Enter a term to describe protocol parameter value: ")
            term_value = get_term_values(mapper, ontology, biotools_key, metadata_protocol_param_value)
        elif metadata_param_value == "Annotate Default protocol parameter value":
            term_value = get_term_values(mapper, ontology, biotools_key)

        steps.append((term_param, term_value))


def find_process_sequence(cwl_path):
    cwl_dict = load_cwl_file(cwl_path) 
    if 'arc:has process sequence' in cwl_dict and isinstance(cwl_dict['arc:has process sequence'], list):
        for process_seq in cwl_dict['arc:has process sequence']:
            return process_seq
    return None