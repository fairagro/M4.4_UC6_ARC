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
- id: dir
  type: Directory
  inputBinding:
    prefix: --dir
- id: format_dssat_RData
  type: File

outputs:
- id: sim_wd.RData
  type: File
  outputBinding:
    glob: sim_wd.RData

baseCommand:
- Rscript
- prepare_simulation.R

