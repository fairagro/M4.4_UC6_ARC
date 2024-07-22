#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: CommandLineTool

requirements:
- class: InitialWorkDirRequirement
  listing:
  - entryname: transformed.RData
    entry: $(inputs.transformed_RData)
  - entryname: reshaped.RData
    entry: $(inputs.reshaped_RData)
  - entryname: map_icasa.R
    entry:
      $include: ./scripts/map_icasa.R
- class: DockerRequirement
  dockerFile:
    $include: Dockerfile
  dockerImageId: uc6_arc

inputs:
- id: transformed_RData
  type: File
- id: reshaped_RData
  type: File

outputs:
- id: mapped_icasa.RData
  type: File
  outputBinding:
    glob: mapped_icasa.RData

baseCommand:
- Rscript
- map_icasa.R

