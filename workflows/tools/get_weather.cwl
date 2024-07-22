#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: CommandLineTool

requirements:
- class: InitialWorkDirRequirement
  listing:
  - entryname: transformed.RData
    entry: $(inputs.transformed_RData)
  - entryname: get_weather.R
    entry:
      $include: ./scripts/get_weather.R
- class: DockerRequirement
  dockerFile:
    $include: Dockerfile
  dockerImageId: uc6_arc

inputs:
- id: transformed_RData
  type: File

outputs:
- id: weather_stations.RData
  type: File
  outputBinding:
    glob: weather_stations.RData

baseCommand:
- Rscript
- get_weather.R

