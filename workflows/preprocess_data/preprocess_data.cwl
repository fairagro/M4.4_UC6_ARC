#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: CommandLineTool

requirements:
- class: InitialWorkDirRequirement
  listing:
  - entryname: preprocess_data.R
    entry:
      $include: preprocess_data.R
- class: DockerRequirement
  dockerFile:
    $include: ../Dockerfile
  dockerImageId: uc6_arc

inputs:
- id: data
  type: Directory
  inputBinding:
    prefix: --data

outputs:
- id: preprocessed.RData
  type: File
  outputBinding:
    glob: preprocessed.RData

baseCommand:
- Rscript
- preprocess_data.R

