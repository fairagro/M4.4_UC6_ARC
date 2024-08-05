#!/usr/bin/env cwl-runner


cwlVersion: v1.2
class: Workflow

hints:
  - class: SoftwareRequirement
    packages:
      R:
        version: [4.4.0]
      DSSAT:
        version: [4.8.2.12]

requirements:
  NetworkAccess:
    networkAccess: true
  

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
    outputSource: plot_results/Rplots.pdf
steps:
  load_metadata:
    in:
      data: metadata
    run: load_metadata/load_metadata.cwl
    out:
    - metadata.RData
  preprocess_data:
    in:
      data: data_dir
    run: preprocess_data/preprocess_data.cwl
    out:
    - preprocessed.RData
  reshape_data:
    in:
      metadata_RData: load_metadata/metadata.RData
      preprocessed_RData: preprocess_data/preprocessed.RData
    run: reshape_data/reshape_data.cwl
    out:
    - reshaped.RData
  transform_data:
    in:
      reshaped_RData: reshape_data/reshaped.RData
    run: transform_data/transform_data.cwl
    out:
    - transformed.RData
  
  map_icasa:
    in: 
      transformed_RData: transform_data/transformed.RData
      reshaped_RData: reshape_data/reshaped.RData
    run: map_icasa/map_icasa.cwl
    out:
    - mapped_icasa.RData

  get_weather:
    in:    
      transformed_RData: transform_data/transformed.RData
    run: get_weather/get_weather.cwl
    out:
    - weather_stations.RData
  map_weather:
    in: 
      weather_stations_RData: get_weather/weather_stations.RData
      mapped_icasa_RData: map_icasa/mapped_icasa.RData
    run: map_weather/map_weather.cwl
    out:
    - mapped_weather.RData
    - weather_comments.RData
  get_soil_data:
    in: 
      soil: soil_file
      soil_id: soil_id
    run: get_soil_data/get_soil_data.cwl
    out:
    - soil_data.RData

  map_soil_data:
    in: 
      soil_data_RData: get_soil_data/soil_data.RData
      mapped_weather_RData: map_weather/mapped_weather.RData
    run: map_soil_data/map_soil_data.cwl
    out:
    - mapped_soil.RData
  
  estimate_phenology:
    in:
      mapped_soil_RData: map_soil_data/mapped_soil.RData
    run: estimate_phenology/estimate_phenology.cwl
    out:
    - mapped_phenology.RData

  icasa2dssat:
    in:
      mapped_phenology_RData: estimate_phenology/mapped_phenology.RData
    run: icasa2dssat/icasa2dssat.cwl
    out:
    - mapped_dssat.RData
  
  format_dssat:
    in:
      mapped_dssat_RData: icasa2dssat/mapped_dssat.RData
      weather_comments_RData: map_weather/weather_comments.RData
    run: format_dssat/format_dssat.cwl
    out:
    - format_dssat.RData
    - SEDE.SOL

  simulation:
    in:
      format_dssat_RData: format_dssat/format_dssat.RData
      sol: format_dssat/SEDE.SOL
      soil: soil_file
    run: simulation/simulation.cwl
    out: 
    - output

  plot_results:
    in:
      format_dssat_RData: format_dssat/format_dssat.RData
      simulation_dir: simulation/output
    run: plot_results/plot_results.cwl
    out:
      - Rplots.pdf
  test_results:
    in:      
      simulation_dir: simulation/output
    run: test_results/test_results.cwl
    out: []



arc:has technology type:
- class: arc:technology type
  arc:annotation value: Docker Container

arc:performer:
- class: arc:Person
  arc:first name: John
  arc:last name: Doe
  arc:email: mail@institue.com
  arc:affiliation: RPTU Kaiserslautern/Landau
  arc:has role:
  - class: arc:role
    arc:term accession: http://edamontology.org/operation_3214
    arc:annotation value: Spectral analysis

arc:has process sequence:
- class: arc:process sequence
  arc:name: M4.4_UC6_ARC
  arc:has parameter value:
  - class: arc:process parameter value
    arc:has parameter:
    - class: arc:protocol parameter
      arc:has parameter name:
      - class: arc:parameter name
        arc:term accession: http://edamontology.org/operation_0004
        arc:term source REF: EMBRACE
        arc:annotation value: Operation
    arc:value:
    - class: arc:ontology annotation
      arc:term accession: http://edamontology.org/operation_3557
      arc:term source REF: EMBRACE
      arc:annotation value: Imputation
  - class: arc:process parameter value
    arc:has parameter:
    - class: arc:protocol parameter
      arc:has parameter name:
      - class: arc:parameter name
        arc:term accession: http://edamontology.org/operation_0004
        arc:term source REF: EMBRACE
        arc:annotation value: Operation
    arc:value:
    - class: arc:ontology annotation
      arc:term accession: http://edamontology.org/operation_3557
      arc:term source REF: EMBRACE
      arc:annotation value: Imputation
  - class: arc:process parameter value
    arc:has parameter:
    - class: arc:protocol parameter
      arc:has parameter name:
      - class: arc:parameter name
        arc:term accession: http://edamontology.org/operation_0004
        arc:term source REF: EMBRACE
        arc:annotation value: Operation
    arc:value:
    - class: arc:ontology annotation
      arc:term accession: http://edamontology.org/operation_3557
      arc:term source REF: EMBRACE
      arc:annotation value: Imputation
  - class: arc:process parameter value
    arc:has parameter:
    - class: arc:protocol parameter
      arc:has parameter name:
      - class: arc:parameter name
        arc:term accession: http://edamontology.org/operation_0004
        arc:term source REF: EMBRACE
        arc:annotation value: Operation
    arc:value:
    - class: arc:ontology annotation
      arc:term accession: http://edamontology.org/operation_3557
      arc:term source REF: EMBRACE
      arc:annotation value: Imputation
  - class: arc:process parameter value
    arc:has parameter:
    - class: arc:protocol parameter
      arc:has parameter name:
      - class: arc:parameter name
        arc:term accession: http://edamontology.org/operation_0004
        arc:term source REF: EMBRACE
        arc:annotation value: Operation
    arc:value:
    - class: arc:ontology annotation
      arc:term accession: http://edamontology.org/operation_3557
      arc:term source REF: EMBRACE
      arc:annotation value: Imputation
  - class: arc:process parameter value
    arc:has parameter:
    - class: arc:protocol parameter
      arc:has parameter name:
      - class: arc:parameter name
        arc:term accession: http://edamontology.org/operation_0004
        arc:term source REF: EMBRACE
        arc:annotation value: Operation
    arc:value:
    - class: arc:ontology annotation
      arc:term accession: http://edamontology.org/operation_3557
      arc:term source REF: EMBRACE
      arc:annotation value: Imputation
  - class: arc:process parameter value
    arc:has parameter:
    - class: arc:protocol parameter
      arc:has parameter name:
      - class: arc:parameter name
        arc:term accession: http://edamontology.org/operation_0004
        arc:term source REF: EMBRACE
        arc:annotation value: Operation
    arc:value:
    - class: arc:ontology annotation
      arc:term accession: http://edamontology.org/operation_3557
      arc:term source REF: EMBRACE
      arc:annotation value: Imputation
  - class: arc:process parameter value
    arc:has parameter:
    - class: arc:protocol parameter
      arc:has parameter name:
      - class: arc:parameter name
        arc:term accession: http://edamontology.org/operation_0004
        arc:term source REF: EMBRACE
        arc:annotation value: Operation
    arc:value:
    - class: arc:ontology annotation
      arc:term accession: http://edamontology.org/operation_3557
      arc:term source REF: EMBRACE
      arc:annotation value: Imputation
  - class: arc:process parameter value
    arc:has parameter:
    - class: arc:protocol parameter
      arc:has parameter name:
      - class: arc:parameter name
        arc:term accession: http://edamontology.org/operation_0004
        arc:term source REF: EMBRACE
        arc:annotation value: Operation
    arc:value:
    - class: arc:ontology annotation
      arc:term accession: http://edamontology.org/operation_3557
      arc:term source REF: EMBRACE
      arc:annotation value: Imputation
  - class: arc:process parameter value
    arc:has parameter:
    - class: arc:protocol parameter
      arc:has parameter name:
      - class: arc:parameter name
        arc:term accession: http://edamontology.org/operation_0004
        arc:term source REF: EMBRACE
        arc:annotation value: Operation
    arc:value:
    - class: arc:ontology annotation
      arc:term accession: http://edamontology.org/operation_3557
      arc:term source REF: EMBRACE
      arc:annotation value: Imputation
  - class: arc:process parameter value
    arc:has parameter:
    - class: arc:protocol parameter
      arc:has parameter name:
      - class: arc:parameter name
        arc:term accession: http://edamontology.org/operation_0004
        arc:term source REF: EMBRACE
        arc:annotation value: Operation
    arc:value:
    - class: arc:ontology annotation
      arc:term accession: http://edamontology.org/operation_3557
      arc:term source REF: EMBRACE
      arc:annotation value: Imputation
  - class: arc:process parameter value
    arc:has parameter:
    - class: arc:protocol parameter
      arc:has parameter name:
      - class: arc:parameter name
        arc:term accession: http://edamontology.org/operation_0004
        arc:term source REF: EMBRACE
        arc:annotation value: Operation
    arc:value:
    - class: arc:ontology annotation
      arc:term accession: http://edamontology.org/operation_3557
      arc:term source REF: EMBRACE
      arc:annotation value: Imputation
  - class: arc:process parameter value
    arc:has parameter:
    - class: arc:protocol parameter
      arc:has parameter name:
      - class: arc:parameter name
        arc:term accession: http://edamontology.org/operation_0004
        arc:term source REF: EMBRACE
        arc:annotation value: Operation
    arc:value:
    - class: arc:ontology annotation
      arc:term accession: http://edamontology.org/topic_3572
      arc:term source REF: EMBRACE
      arc:annotation value: Data quality management
  - class: arc:process parameter value
    arc:has parameter:
    - class: arc:protocol parameter
      arc:has parameter name:
      - class: arc:parameter name
        arc:term accession: http://edamontology.org/operation_0004
        arc:term source REF: EMBRACE
        arc:annotation value: Operation
    arc:value:
    - class: arc:ontology annotation
      arc:term accession: http://edamontology.org/operation_3435
      arc:term source REF: EMBRACE
      arc:annotation value: Standardisation and normalisation


$namespaces:
  arc: https://github.com/nfdi4plants/ARC_ontology
$schemas:
- https://raw.githubusercontent.com/nfdi4plants/ARC_ontology/main/ARC_v2.0.owl

