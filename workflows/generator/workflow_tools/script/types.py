from enum import StrEnum

class VarType(StrEnum):
    string = "string"
    int = "int"
    float = "float"
    file = "file"
    directory = "directory"
    character = "character"


class InputOption:
    def __init__(self, name: str, binding: str, type: VarType):
        self.name = name
        self.binding = binding
        self.type = type

    def __repr__(self):
        return f"InputOption({self.name}, {self.binding}, {self.type})"


class OutputOption:
    def __init__(self, name: str, type: VarType):
        self.name = name
        self.type = type

    def __repr__(self):
        return f"OutputOption({self.name}, {self.type})"


class Script:
    file_name: str
    file_path: str
    inputs: list[InputOption]
    outputs: list[OutputOption]
    interpreter: str

    def __init__(self, path: str, interpreter: str):
        self.file_name = path.split("/")[-1]
        self.file_path = path
        self.interpreter = interpreter
        self.outputs = []

    def __repr__(self):
        return f"{self.interpreter}({self.file_name}, in:{self.inputs}, out:{self.outputs})"
