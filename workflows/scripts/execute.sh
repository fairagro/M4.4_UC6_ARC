#! /bin/bash
Rscript workflows/scripts/preprocess_data.R -d uc6_csmTools/inst/extdata/lte_seehausen/0_raw/
Rscript workflows/scripts/load_metadata.R -d uc6_csmTools/inst/extdata/lte_seehausen/0_raw/lte_seehausen_xls_metadata.xls