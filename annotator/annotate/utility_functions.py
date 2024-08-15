import os
import re
import yaml
import pandas
import glob


def find_file_types(file_format, directory='.'):
    return glob.glob(f'{directory}/**/*.{file_format}', recursive=True)

def get_investigation_df():
    file_name = "isa.investigation.xlsx"
    current_dir = os.getcwd()
    parent_dir = os.path.dirname(current_dir)
    path = os.path.join(parent_dir, file_name)
    df = pandas.read_excel(path, header=None).T
    column_names = df.iloc[0].tolist()
    df.columns = column_names
    return df.drop(df.index[0])


def has_docker_annotation(cwl_file): 
    with open(cwl_file, 'r') as f:
        content = f.read()
        if "arc:has technology typ" in content.lower():
            return True
    return False

def has_namespace(cwl_file):
    with open(cwl_file, 'r') as f:
        content = f.read()
        if "namespace" in content.lower():
            return True
    return False

def has_performer(cwl_file):
    with open(cwl_file, 'r') as f:
        content = f.read()
        if "arc:performer" in content.lower():
            return True
    return False

def has_process_sequence(cwl_file, arc_name):
    with open(cwl_file, 'r') as f:
        content = f.read()
        if "arc:has process sequence" in content.lower():
            return True
    return False


def load_cwl_file(file_path):
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            cwl_content = yaml.safe_load(file)
        return cwl_content
    except FileNotFoundError:
        print(f"File not found: {file_path}")
        return {}
    except yaml.YAMLError as e:
        print(f"Error parsing YAML file: {e}")
        return {}
    
def save_dict_yaml(file, dict):
    try:
        with open(file, 'w', encoding='utf-8') as f:
            yaml.dump(file, Dumper=yaml.CDumper, allow_unicode=True, sort_keys=False)
        return True
    except Exception as e:
        print(f"[red]Error saving file: {e}")
        return False

def find_docker(file):
    with open(file, 'r') as f:
        content = f.read()
    if "docker" in content.lower():
        return True
    else: 
        #find all cwl files that main.cwl uses and check for docker
        pattern = r'tools/\w+\.cwl'
        cwl_files = re.findall(pattern, content, re.MULTILINE)
        current_directory = os.path.dirname(os.path.abspath(file))
        for file_name in cwl_files:
            file = current_directory + "/" + file_name
            print("find docker file: ", file)
            with open(file, 'r') as f:
                content = f.read()
            if "docker" in content.lower():
                return True
        return False
    