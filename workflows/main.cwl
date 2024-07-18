#!/usr/bin/env cwl-runner


cwlVersion: v1.2
class: Workflow

inputs:
  data_dir:
    type: Directory
  metadata:
    type: File
  soil_file:
    type: File
  soil_id:
    type: string

outputs:
  plot:
    type: File
    outputSource: reshape_data/reshaped.RData

steps:
  load_metadata:
    in:
      data: metadata
    run: load_metadata.cwl
    out:
    - metadata.RData
  preprocess_data:
    in:
      data: data_dir
    run: preprocess_data.cwl
    out:
    - preprocessed.RData
  reshape_data:
    in:
      metadata_RData: load_metadata/metadata.RData
      preprocessed_RData: preprocess_data/preprocessed.RData
    run: reshape_data.cwl
    out:
    - reshaped.RData
  transform_data:
    in:
      reshaped_RData: reshape_data/reshaped.RData
    run: transform_data.cwl
    out:
    - transformed.RData
  
  map_icasa:
    in: 
      transformed_RData: transform_data/transformed.RData
      reshaped_RData: reshape_data/reshaped.RData
    run: map_icasa.cwl
    out:
    - mapped_icasa.RData

  get_weather:
    in:    
      transformed_RData: transform_data/transformed.RData
    run: get_weather.cwl
    out:
    - weather_stations.RData
  map_weather:
    in: 
      weather_stations_RData: get_weather/weather_stations.RData
      mapped_icasa_RData: map_icasa/mapped_icasa.RData
    run: map_weather.cwl
    out:
    - mapped_weather.RData
    - weather_comments.RData
  get_soil_data:
    in: 
      soil: soil_file
      soil_id: soil_id
    run: get_soil_data.cwl
    out:
    - soil_data.RData
