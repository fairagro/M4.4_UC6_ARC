#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: CommandLineTool

requirements:
- class: InitialWorkDirRequirement
  listing:
  - entryname: mapped_dssat.RData
    entry: $(inputs.mapped_dssat_RData)
  - entryname: weather_comments.RData
    entry: $(inputs.weather_comments_RData)
  - entryname: format_dssat.R
    entry:
      $include: ./scripts/format_dssat.R
- class: DockerRequirement
  dockerFile:
    $include: Dockerfile
  dockerImageId: uc6_arc

inputs:
- id: mapped_dssat_RData
  type: File
- id: weather_comments_RData
  type: File

outputs:
- id: format_dssat.RData
  type: File
  outputBinding:
    glob: format_dssat.RData
- id: SEDE.SOL
  type: File
  outputBinding:
    glob: SEDE.SOL

baseCommand:
- Rscript
- format_dssat.R

