#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: CommandLineTool

requirements:
- class: InitialWorkDirRequirement
  listing:
  - entryname: load_metadata.R
    entry:
      $include: load_metadata.R
- class: DockerRequirement
  dockerFile:
    $include: ../Dockerfile
  dockerImageId: uc6_arc

inputs:
- id: data
  type: File
  inputBinding:
    prefix: --data

outputs:
- id: metadata.RData
  type: File
  outputBinding:
    glob: metadata.RData

baseCommand:
- Rscript
- load_metadata.R

