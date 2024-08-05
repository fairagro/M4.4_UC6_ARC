#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: CommandLineTool

requirements:
- class: InitialWorkDirRequirement
  listing:
  - entryname: preprocessed.RData
    entry: $(inputs.preprocessed_RData)
  - entryname: metadata.RData
    entry: $(inputs.metadata_RData)
  - entryname: reshape_data.R
    entry:
      $include: reshape_data.R
- class: DockerRequirement
  dockerFile:
    $include: ../Dockerfile
  dockerImageId: uc6_arc

inputs:
- id: preprocessed_RData
  type: File
- id: metadata_RData
  type: File

outputs:
- id: reshaped.RData
  type: File
  outputBinding:
    glob: reshaped.RData

baseCommand:
- Rscript
- reshape_data.R

