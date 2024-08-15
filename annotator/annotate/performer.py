#import annotate.arc_annotation
#import annotate.utils # type: ignore
from arc_annotation import annotate_docker_info, annotate_performer, annotate_namespace, performer_dict

from utility_functions import load_cwl_file, has_docker_annotation, has_namespace, has_performer
from beaupy import prompt, select

from rich.console import Console
import pandas as pd
import glob
import yaml

def update_performer(cwl_path, performer_dict):
    console = Console()
    try:
        cwl_dict = load_cwl_file(cwl_path)
        action_needed = "Skip"
        if 'arc:performer' in cwl_dict and isinstance(cwl_dict['arc:performer'], list):
            for performer in cwl_dict['arc:performer']:
                if performer.get('arc:first name') is None or performer.get('arc:last name') is None:
                    action_needed = "Update"
                else:
                    if performer['arc:first name'] == performer_dict['arc:performer'][0]['arc:first name'] and performer['arc:last name'] == performer_dict['arc:performer'][0]['arc:last name']: 
                        console.print(f"[green]Same performer, Skip[/green]")
                    else:
                        console.print("[yellow]Found performer[/yellow] ", performer, "for file ", cwl_path)
                        action_needed = select(["Update", "Skip"], cursor="->", cursor_style="cyan")
            
            if action_needed == "Update":
                # Update the first performer in the list
                cwl_dict['arc:performer'][0].update(performer_dict['arc:performer'][0])
                yaml_str = yaml.dump(cwl_dict, Dumper=yaml.CDumper, allow_unicode=True, sort_keys=False)
                with open(cwl_path, 'w', encoding='utf-8') as f:
                    f.write(yaml_str)
                console.print("[green]CWL file updated successfully.[/green]")
                return True
    
    except Exception as e:
        console.print(f"[red]Error updating performer: {str(e)}[/red]")
    
    return None


def add_performer_from_config(dir):
    config_files = glob.glob(f'{dir}/**/*.wfaconfig', recursive=True)
    if not config_files:
        console = Console()
        console.print("[red]No config file found.[/red]")
    for file in config_files: 
        with open(file, 'r') as file:
            cwl_dict = yaml.safe_load(file)
            first_name = cwl_dict['arc:performer'][0]['arc:first name']
            last_name = cwl_dict['arc:performer'][0]['arc:last name']
            email = cwl_dict['arc:performer'][0]['arc:email']
            affiliation = cwl_dict['arc:performer'][0]['arc:affiliation']
            role = cwl_dict['arc:performer'][0]['arc:has role'][0]['arc:annotation value']
            return performer_dict(first_name, last_name, email, affiliation, role)


def add_new_performer(df, index): 
    first_name = prompt("Enter your first name (or hit enter to skip): ")
    last_name = prompt("Enter your last name (or hit enter to skip): ")
    email = prompt("Enter your email (or hit enter to skip): ")
    affiliation = prompt("Enter your affiliation (or hit enter to skip): ")
    role = prompt("Enter your role (or hit enter to skip): ")
    performer = performer_dict(first_name, last_name, email, affiliation, role)
    save_performer_isa_investigation(df, index, performer)
    return performer

def add_performer_from_isa(df, index):
    first_name = df["Investigation Person First Name"][index]
    last_name = df["Investigation Person Last Name"][index]
    email = df["Investigation Person Email"][index]
    affiliation = df["Investigation Person Affiliation"][index]
    role = df["Investigation Person Roles"][index]
    role_term_acc = df["Investigation Person Roles Term Accession Number"][index]
    return performer_dict(first_name, last_name, email, affiliation, role, role_term_acc)
  

#currently only writes new file in annotator for testing purpose
def save_performer_isa_investigation(df, idx, performer_dict, isa_file="isa_investigation.xlsx"): 
    df.loc[idx, "Investigation Person First Name"] = performer_dict['arc:performer'][0]['arc:first name'] 
    df.loc[idx, "Investigation Person Last Name"] = performer_dict['arc:performer'][0]['arc:last name'] 
    df.loc[idx, "Investigation Person Email"] = performer_dict['arc:performer'][0]['arc:email'] 
    df.loc[idx, "Investigation Person Affiliation"] = performer_dict['arc:performer'][0]['arc:affiliation'] 
    df.loc[idx, "Investigation Person Roles"]= performer_dict['arc:performer'][0]['arc:has role'][0]['arc:annotation value']
    df = df.T
    df_with_index_first = df.reset_index()
    df_with_index_first.to_excel(isa_file, sheet_name="isa_investigation", header=False, index=False)    


#check first is there non default performer, if so ask user skip, update or add
def add_performer_default_each_file(cwl_file, performer): 
    if not has_docker_annotation(cwl_file): 
        annotate_docker_info(cwl_file)
    if not has_performer(cwl_file) and performer is not None:
        annotate_performer(cwl_file, performer)
    elif has_performer(cwl_file) and len(performer) is not None:
        update_performer(cwl_file, performer)
    if not has_namespace(cwl_file): 
        annotate_namespace(cwl_file)


def select_performer(df: pd.DataFrame, arc_path: str):
    names = [f"{f} {l}" for f, l in zip(df["Investigation Person First Name"].values, df["Investigation Person Last Name"].values)]
    names.insert(0, "Leave performer annotation empty")
    names.append("Add performer from config file")
    names.append("Add a new performer")
    console = Console()
    console.print("Select performer:")
    # Choose one item from a list
    name = select(names, cursor="->", cursor_style="cyan")
    index = names.index(name)
    if(index == len(names)-1): 
        #add new performer interactively
        return add_new_performer(df, index)
    elif(index == len(names)-2):
        #add performer from config file
        return add_performer_from_config(arc_path)
    elif(index>0):
        return add_performer_from_isa(df, index)
    else: 
        #default performer
        return annotate_performer()

def add_performer_all(cwl_files: list[str], df: pd.DataFrame, arc_path: str) -> None:
    performer = select_performer(df, arc_path)
    for file in cwl_files:
        add_performer_default_each_file(file, performer)

