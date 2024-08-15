import os
import click
from utility_functions import get_investigation_df, find_file_types
from arc_annotation import annotate_default_metadata
from performer import add_performer_all, select_performer, add_performer_default_each_file
from process_sequence import add_process_step
from beaupy import select
from rich.console import Console
    



 
@click.command()
@click.option('--mapper', type=click.Choice(['zooma', 'biotools', 'ontology_mapper']),
              prompt='Please choose an option, default is zooma', default='zooma',
              help='Select the mapper. Choices are zooma, biotools, and ontology mapper. Default is zooma.')
@click.option("--biotools_key", type=str, default=None, help="If you want to use biotools as a mapper provide a key to use API")
@click.option("--ontology", type=str, default="https://edamontology.org/EDAM.owl",
              help="If you use zooma or ontology_mapper you can provide an ontology. Default is https://edamontology.org/EDAM.owl")
def annotate_files(mapper, biotools_key, ontology):
    console = Console()
    current_dir = os.getcwd()
    arc_path = os.path.dirname(current_dir)
    df = get_investigation_df()
    arc_name = df["Investigation Identifier"].values[0]
    cwl_files = find_file_types("cwl", arc_path + os.sep + "workflows")
    console.print("The following cwl files were found:", cwl_files)
    annotation_options = ["Annotate all cwl files without annotations with default values",
                          "Annotate performer for all cwl files and add default values docker and namespace",
                          "Annotate cwl file individually"]
    annotation_option = select(annotation_options, cursor="->", cursor_style="cyan")
    if annotation_option == "Annotate all cwl files without annotations with default values":
        annotate_default_metadata(cwl_files, arc_name)
    elif annotation_option == "Annotate performer for all cwl files and add default values docker and namespace":
        add_performer_all(cwl_files, df, arc_path)
    elif annotation_option == "Annotate cwl file individually":
        console.print("Select file", style="green")
        cwl_file = select(cwl_files, cursor="->", cursor_style="cyan")
        single_file_options = ["Add performer", "Add process description"]
        single_file_option = select(single_file_options, cursor="->", cursor_style="cyan")
        if single_file_option == "Add performer":
            performer = select_performer(df, arc_path)
            add_performer_default_each_file(cwl_file, performer)
        elif single_file_option == "Add process description":
            add_process_step(cwl_file, arc_name, mapper, ontology, biotools_key)



#still need to improve imports and code
if __name__ == "__main__":
    annotate_files()
   
 