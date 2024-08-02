from .types import InputOption, OutputOption, Script, Infer
import re

def load_and_parse(path: str) -> Script:
    with open(path, "r") as f:
        content = f.read() # TODO: strip comments
        return parse(content, path)

def parse(content: str, file_name: str) -> Script:
    script = Script(file_name, "Rscript")
    options = get_optparse(content)
    loads = get_load(content)
    script.inputs = options + loads

    saves = get_save(content)
    hints = get_exportHint(content)
    script.outputs = saves + hints
    return script

def get_optparse(content: str) -> list[InputOption]:
    options_pattern = r"add_option\((.*)\)"
    parameter_pattern = r'--([^"]*)'
    type_pattern = r'type\s?=\s?\"([^"]*)'
    help_pattern = r'help\s?=\s?\"([^"]*)'

    raw_options = re.findall(options_pattern, content)

    options = []
    for option in raw_options:
        name = re.findall(parameter_pattern, option)[0]
        type = re.findall(type_pattern, option)[0]
        # could also be a file or path! make some guessing
        help = str.lower(re.findall(help_pattern, option)[0])
        if "path" in help or "folder" in help or "directory" in help:
            type = "directory"
        if "file" in help:
            type = "file"

        options.append(InputOption(name, "--" + name, type))

    return options

def get_load(content: str) -> list[InputOption]:
    load_pattern = r'load\("([^"]*)'
    loads = re.findall(load_pattern, content)

    return [InputOption(load, "", "file") for load in loads]


def get_save(content: str) -> list[OutputOption]:
    save_pattern = r'save\(.*file\s?=\s?"([^"]*)'
    saves = re.findall(save_pattern, content)

    return [OutputOption(save, "file") for save in saves]

def get_exportHint(content: str) -> list[OutputOption]:
    exportPattern = r"#'\s*@exportHint\s*([\w\-_./\\]*)"
    exportHints = re.findall(exportPattern, content)
    
    return [OutputOption(exportHint, Infer(exportHint)) for exportHint in exportHints]