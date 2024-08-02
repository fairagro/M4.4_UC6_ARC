#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: CommandLineTool

requirements:
- class: InitialWorkDirRequirement
  listing:
  - entryname: weather_stations.RData
    entry: $(inputs.weather_stations_RData)
  - entryname: mapped_icasa.RData
    entry: $(inputs.mapped_icasa_RData)
  - entryname: map_weather.R
    entry:
      $include: map_weather.R
- class: DockerRequirement
  dockerFile:
    $include: ../Dockerfile
  dockerImageId: uc6_arc

inputs:
- id: weather_stations_RData
  type: File
- id: mapped_icasa_RData
  type: File

outputs:
- id: mapped_weather.RData
  type: File
  outputBinding:
    glob: mapped_weather.RData
- id: weather_comments.RData
  type: File
  outputBinding:
    glob: weather_comments.RData

baseCommand:
- Rscript
- map_weather.R

