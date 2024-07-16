# Changelog

## 2024-05-16 (JK)
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
