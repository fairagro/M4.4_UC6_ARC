#! /bin/bash
Rscript $(dirname "$0")/preprocess_data.R -d uc6_csmTools/inst/extdata/lte_seehausen/0_raw/
Rscript $(dirname "$0")/load_metadata.R -d uc6_csmTools/inst/extdata/lte_seehausen/0_raw/lte_seehausen_xls_metadata.xls
Rscript $(dirname "$0")/reshape_data.R
Rscript $(dirname "$0")/transform_data.R
Rscript $(dirname "$0")/map_icasa.R
Rscript $(dirname "$0")/get_weather.R
Rscript $(dirname "$0")/map_weather.R
Rscript $(dirname "$0")/get_soil_data.R -s uc6_csmTools/inst/extdata/SOIL.SOL -i IB00000001
Rscript $(dirname "$0")/map_soil_data.R
Rscript $(dirname "$0")/estimate_phenology.R
Rscript $(dirname "$0")/icasa2dssat.R
Rscript $(dirname "$0")/format_dssat.R
Rscript $(dirname "$0")/prepare_simulation.R --dir ~/dssat/
Rscript $(dirname "$0")/simulate.R --executable ~/dssat/dscsm048
Rscript $(dirname "$0")/plot_results.R