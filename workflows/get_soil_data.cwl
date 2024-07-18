#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: CommandLineTool

requirements:
- class: InitialWorkDirRequirement
  listing:
  - entryname: get_soil_data.R
    entry:
      $include: ./scripts/get_soil_data.R
- class: DockerRequirement
  dockerFile:
    $include: Dockerfile
  dockerImageId: uc6_arc

inputs:
- id: soil
  type: File
  inputBinding:
    prefix: --soil
- id: soil_id
  type: string
  inputBinding:
    prefix: --soil_id

outputs:
- id: soil_data.RData
  type: File
  outputBinding:
    glob: soil_data.RData

baseCommand:
- Rscript
- get_soil_data.R

