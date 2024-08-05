#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: CommandLineTool

requirements:
- class: InitialWorkDirRequirement
  listing:
  - entryname: test_results.R
    entry:
      $include: test_results.R
- class: DockerRequirement
  dockerFile:
    $include: ../Dockerfile
  dockerImageId: uc6_arc

inputs:
- id: simulation_dir
  type: Directory
  inputBinding:
    prefix: --simulation_dir

outputs: []

baseCommand:
- Rscript
- test_results.R

