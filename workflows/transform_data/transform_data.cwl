#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: CommandLineTool

requirements:
- class: InitialWorkDirRequirement
  listing:
  - entryname: reshaped.RData
    entry: $(inputs.reshaped_RData)
  - entryname: transform_data.R
    entry:
      $include: transform_data.R
- class: DockerRequirement
  dockerFile:
    $include: ../Dockerfile
  dockerImageId: uc6_arc

inputs:
- id: reshaped_RData
  type: File

outputs:
- id: transformed.RData
  type: File
  outputBinding:
    glob: transformed.RData

baseCommand:
- Rscript
- transform_data.R

