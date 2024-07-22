#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: CommandLineTool

requirements:
- class: InitialWorkDirRequirement
  listing:
  - entryname: soil_data.RData
    entry: $(inputs.soil_data_RData)
  - entryname: mapped_weather.RData
    entry: $(inputs.mapped_weather_RData)
  - entryname: map_soil_data.R
    entry:
      $include: ./scripts/map_soil_data.R
- class: DockerRequirement
  dockerFile:
    $include: Dockerfile
  dockerImageId: uc6_arc

inputs:
- id: soil_data_RData
  type: File
- id: mapped_weather_RData
  type: File

outputs:
- id: mapped_soil.RData
  type: File
  outputBinding:
    glob: mapped_soil.RData

baseCommand:
- Rscript
- map_soil_data.R

