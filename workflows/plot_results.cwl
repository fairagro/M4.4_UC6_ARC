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
      $include: ./scripts/plot_results.R
- class: DockerRequirement
  dockerFile:
    $include: Dockerfile
  dockerImageId: uc6_arc

inputs:
- id: format_dssat_RData
  type: File

outputs: []

baseCommand:
- Rscript
- plot_results.R

