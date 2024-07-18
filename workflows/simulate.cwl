#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: CommandLineTool

requirements:
- class: InitialWorkDirRequirement
  listing:
  - entryname: sim_wd.RData
    entry: $(inputs.sim_wd_RData)
  - entryname: simulate.R
    entry:
      $include: ./scripts/simulate.R
- class: DockerRequirement
  dockerFile:
    $include: Dockerfile
  dockerImageId: uc6_arc

inputs:
- id: executable
  type: Directory
  inputBinding:
    prefix: --executable
- id: sim_wd_RData
  type: File

outputs: []

baseCommand:
- Rscript
- simulate.R

