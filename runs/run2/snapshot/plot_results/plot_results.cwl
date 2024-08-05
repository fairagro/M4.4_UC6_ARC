#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: CommandLineTool

requirements:
- class: InitialWorkDirRequirement
  listing:
  - entryname: format_dssat.RData
    entry: $(inputs.format_dssat_RData)
  - entryname: plot_results.R
    entry:
      $include: plot_results.R
- class: DockerRequirement
  dockerFile:
    $include: ../Dockerfile
  dockerImageId: uc6_arc

inputs:
- id: simulation_dir
  type: Directory
  inputBinding:
    prefix: --simulation_dir
- id: format_dssat_RData
  type: File

outputs:
- id: Rplots.pdf
  type: File
  outputBinding:
    glob: Rplots.pdf

baseCommand:
- Rscript
- plot_results.R

