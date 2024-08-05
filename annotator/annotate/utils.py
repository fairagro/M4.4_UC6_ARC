import os
import re

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
            with open(file, 'r') as f:
                content = f.read()
            if "docker" in content.lower():
                return True
        return False
    
def append_to_file(file, text):
    try:
        with open(file, 'a') as f:
                # Append the text to the file
                f.write(text)
    except FileNotFoundError:
            print(f"The file '{file}' does not exist.")
    except IOError as e:
            print(f"I/O error({e.errno}): {e.strerror}")


def check_metadata_description(file, expected_nb_steps):
    try:
        with open(file, 'r') as file:
            content = file.read()
            nb_steps = content.count("run:")
            if nb_steps == expected_nb_steps:
                return True
            else:
                raise ValueError(f"Error: The string 'run:' was found {nb_steps} time(s), which does not match the expected number of workflow setps {expected_nb_steps}.")
                return False
    except FileNotFoundError:
        print(f"Error: The file at path '{file}' could not be found.")
        return False