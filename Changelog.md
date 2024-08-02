# Changelog
## 2024-08-02 (JK)
* Added the arc-export Tool to our CI Pipeline

## 2024-08-01 (JK)
* Added arc-validate CI Pipeline
* BLs Repo now has an automated integration test running
* The ARC does not pass the Validation `[07:35:44 ERR] Critical.Arc contains workflow in workflow directory failed in 00:00:00.0160000.`, see #34 for explaination

## 2024-07-23 (JK)
* Run Workflow with provenance flag, result in `./runs/run1/`
```bash
cwltool --provenance run1/ \
        --enable-user-provenance --enable-host-provenance \
        --full-name "Jens Krumsieck" --orcid https://orcid.org/0000-0001-6242-5846 \
        ../workflows/main.cwl main_inputs.yml
```

## 2024-07-22 (JK)
* `main.cwl` now contains the full workflow and WORKS!!
    * Execution: `cwltool main.cwl inputs.yml`
    * May takes a while to build docker and execute workflow (~20 mins?)
* Workflow overview image added to README, created with `cwltool --print-dot main.cwl | dot -Tsvg > ../.github/workflow.svg`
* deleted old cwl test repo as being completely obsolete now

## 2024-07-19 (JK)
* continued with the `main.cwl` Workflow and added `inputs.yml`
    * To execute Workflow call `cwltool main.cwl inputs.yml`
    * 12/14 steps are working - `dssat` simulation missing
* fixed some issues with BLs Repo when working in CWL
    * correct handling of contents in `data` folder
        * especially the csv-File was a big issue, as R saves and loads text files with `stringsAsFactors` enabled
    * specify GitHub requirements in `DESCRIPTION` File
        * only `devtools::install_github("fairagro/uc6_csmTools@feature/package_management")` is needed, no more updating `rdwd` or installing `cropCalendars` prior.
* improved `Dockerfile` which is now in Workflows-Folder
* creating Workflows is not an easy task, you have to know what you are doing!

## 2024-07-18 (JK)
* Added Dockerfile for our CWL Workflows. GitHub CI always pushed as a private package - so the temporary CI was removed.
* Added primitive R file parsing to generate CWL CommandLineTools
* Added CWL CommandLineTools by using aforementioned tools `./generate.sh` 
* manually created main.cwl file

## 2024-07-16 (JK)
* Initialized renv in root directory and installed `csmTools` with its dependecies by using `renv::install("fairagro/uc6_csmTools@feature/package_management")`. The `cropcalendars` package needed to be installed prior to csmTools by using `renv::install("AgMIP-GGCMI/cropCalendars")`.

* Issues with `rdwd` could be fixed by using `rdwd::updateRdwd()` to update its indexes.

* Issues with `DSST` could be fixed by using Version 0.0.8.

* The `csmTools::get_weather` function is dependent on a file in the data directory. Maybe it should load the file automatically instead of offloading that to the consumer. Is that possible?

* separated the csmTools Pipeline in 15 subscripts which can be used in workflow later

## 2024-07-15 (JK)
* Added uc6_csmTools as submodule by using 
`git submodule add -b "feature/package_management" https://github.com/fairagro/uc6_csmTools/`. The branch [`feature/package_management`](https://github.com/fairagro/uc6_csmTools/tree/feature/package_management) was created to ensure installability of the package.

* Reason: The module also contains the data from BonaRes, etc. which is needed for the pipeline.

* Consideration: Is root (`./`) the appropriate path for that?

## 2024-07-02 (PK)

* Created ARC skeleton with ARCitect
