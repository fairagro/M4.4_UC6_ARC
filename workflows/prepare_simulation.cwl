#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: CommandLineTool

requirements:
- class: InitialWorkDirRequirement
  listing:
  - entryname: format_dssat.RData
    entry: $(inputs.format_dssat_RData)
  - entryname: prepare_simulation.R
    entry:
      $include: ./scripts/prepare_simulation.R
- class: DockerRequirement
  dockerFile:
    $include: Dockerfile
  dockerImageId: uc6_arc

inputs:
- id: sol
  type: File
  inputBinding:
    prefix: --sol
- id: soil
  type: File
  inputBinding:
    prefix: --soil
- id: format_dssat_RData
  type: File

outputs: []

baseCommand:
- Rscript
- prepare_simulation.R

