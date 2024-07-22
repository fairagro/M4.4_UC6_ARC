#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: CommandLineTool

requirements:
- class: InitialWorkDirRequirement
  listing:
  - entryname: mapped_soil.RData
    entry: $(inputs.mapped_soil_RData)
  - entryname: estimate_phenology.R
    entry:
      $include: ./scripts/estimate_phenology.R
- class: DockerRequirement
  dockerFile:
    $include: Dockerfile
  dockerImageId: uc6_arc

inputs:
- id: mapped_soil_RData
  type: File

outputs:
- id: mapped_phenology.RData
  type: File
  outputBinding:
    glob: mapped_phenology.RData

baseCommand:
- Rscript
- estimate_phenology.R

