from argparse import ArgumentParser
from typing import Tuple
from cwlformat.formatter import cwl_format
from cwl_utils.utils import yaml_dumps
from cwl_utils.parser.cwl_v1_2 import CommandLineTool, DockerRequirement
from script import r_optparse
from convert import script2cwl

def convert(file: str, docker: str = None) -> Tuple[str, str]:
    tools: list[Tuple[str, CommandLineTool]] = []
    if file.endswith(".R"):
        script = r_optparse.load_and_parse(file)
        cwl = script2cwl.convert(script)
        name = file.split("/")[-1].replace(".R", "")
        tools.append((name, cwl))
   
    for name, cwl in tools:
        if docker:
            if not cwl.requirements:
                cwl.requirements = []
            if "Dockerfile" in docker:  
                id = docker.split(":")[1] if ":" in docker else None   
                path = docker.split(":")[0] 
                cwl.requirements.append(DockerRequirement(dockerFile={"$include": path}, dockerImageId=id))
            else:
                cwl.requirements.append(DockerRequirement(dockerPull=docker))
    
    formatted = cwl_format(yaml_dumps(cwl.save()))
    return formatted

if __name__ == "__main__":
    parser = ArgumentParser()
    parser.add_argument("file", type=str, help="File to convert")
    parser.add_argument("--docker", type=str, help="Docker image or Dockerfile:your_tag to use in Workflow")

    args = parser.parse_args()

    if not args.file or args.file == "":
        raise ValueError("No file provided")

    print(convert(args.file, args.docker))
