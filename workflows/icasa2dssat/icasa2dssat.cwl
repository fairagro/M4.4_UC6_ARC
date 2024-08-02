#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: CommandLineTool

requirements:
- class: InitialWorkDirRequirement
  listing:
  - entryname: mapped_phenology.RData
    entry: $(inputs.mapped_phenology_RData)
  - entryname: icasa2dssat.R
    entry:
      $include: icasa2dssat.R
- class: DockerRequirement
  dockerFile:
    $include: ../Dockerfile
  dockerImageId: uc6_arc

inputs:
- id: mapped_phenology_RData
  type: File

outputs:
- id: mapped_dssat.RData
  type: File
  outputBinding:
    glob: mapped_dssat.RData

baseCommand:
- Rscript
- icasa2dssat.R

