from script.types import InputOption, Script, VarType
from cwl_utils.parser.cwl_v1_2 import CommandLineTool, CommandInputParameter, CommandOutputParameter, CommandLineBinding, CommandOutputBinding, InitialWorkDirRequirement

type_dict = {
    VarType.character: "string",
    VarType.string: "string",
    VarType.file: "File",
    VarType.int: "int",
    VarType.float: "float",
    VarType.directory: "Directory"
}


def file(input: str):
    old_idx = input.rfind("_")
    return input[:old_idx] + "." + input[old_idx+len("_"):]


def convert(script: Script):
    script.inputs = [InputOption(input.name.replace(
        ".", "_"), input.binding, input.type) for input in script.inputs]
    cwl = CommandLineTool(
        cwlVersion="v1.2",
        baseCommand=[script.interpreter, script.file_name],
        inputs=[CommandInputParameter(id=option.name, type_=type_dict[option.type], inputBinding=(
            CommandLineBinding(prefix=option.binding) if option.binding != "" else None)) for option in script.inputs],
        outputs=[CommandOutputParameter(id=option.name, type_=type_dict[option.type], outputBinding=CommandOutputBinding(
            glob=option.name)) for option in script.outputs]
    )

    for i in range(len(cwl.outputs)):
        if cwl.outputs[i].id == "/":
            cwl.outputs[i].id = "output"
            cwl.outputs[i].outputBinding.glob = "$(runtime.outdir)"

    workDirInputs = [{"entryname": file(input.name), "entry": f"$(inputs.{input.name})"} for input in script.inputs if input.binding ==
                     "" and input.type == VarType.file]
    workDirInputs.append({"entryname": script.file_name,
                         "entry": {"$include": script.file_path}})
    workDirInputs
    cwl.requirements = [
        InitialWorkDirRequirement(listing=workDirInputs)
    ]
    return cwl
