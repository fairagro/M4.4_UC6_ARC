import os
from argparse import ArgumentParser
from arc_annotation import annotate_docker_info, annotate_performer, annotate_process_sequence, annotate_namespace
from utils import check_metadata_description


def annotate(file, metadata_steps, f, l, email, affiliation, role, mapper="zooma", biotools_key=None, ontology="https://edamontology.org/EDAM.owl"):
    current_script_path = os.path.abspath(__file__)
    arc_name = current_script_path.split('/')[-4]
    annotate_docker_info(file)
    #maybe require less, later get performer info from login
    if(f and l and email and affiliation and role):
        annotate_performer(file, f, l, email, affiliation, role, mapper, biotools_key, ontology)
    if(check_metadata_description(file, len(metadata_steps))):
        annotate_process_sequence(file, arc_name, metadata_steps, mapper, biotools_key, ontology)
    annotate_namespace(file)
  


if __name__ == "__main__":
    parser = ArgumentParser(description="Annotate a CWL workflow with metadata.")
    parser.add_argument("file", type=str, help="File with complete CWL workflow")
    parser.add_argument("--metadata_steps", type=str, nargs='+', help="List of descriptions for each step of the workflow pipelines.")
    parser.add_argument("--f", type=str, help="First name of workflow creator")
    parser.add_argument("--l", type=str, help="Last name of workflow creator")
    parser.add_argument("--email", type=str, help="Email of workflow creator")
    parser.add_argument("--affiliation", type=str, help="Affiliation of workflow creator")
    parser.add_argument("--role", type=str, help="Role of workflow creator")
    parser.add_argument('--mapper', choices=['zooma', 'biotools', 'ontology_mapper'],
                   default='zooma', help='Select the mapper. Choices are zooma, biotools, and ontology mapper. Default is zooma.')
    parser.add_argument("--biotools_key", type=str, default=None, help="If you want to use biotools as a mapper provide a key to use API")
    parser.add_argument("--ontology", type=str, default="https://edamontology.org/EDAM.owl", help="If you use zooma or ontology_mapper you can provide an ontology. Default is https://edamontology.org/EDAM.owl")
    
    args = parser.parse_args()

    if not args.file:
        parser.print_help()
        exit(1)

    annotate(args.file, args.metadata_steps, args.f, args.l, args.email, args.affiliation, args.role, args.mapper, args.biotools_key, args.ontology)
