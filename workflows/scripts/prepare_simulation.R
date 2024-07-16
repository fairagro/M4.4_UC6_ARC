parser <- optparse::OptionParser()
parser <- optparse::add_option(parser, c("-d", "--dir"), type="character", help="Directory containing DSSAT data")
opt <- optparse::parse_args(parser)

load("format_dssat.RData")

library(DSSAT)
library(lubridate)
library(csmTools)

# Simulations -------------------------------------------------------------

dssat_dir <- opt$dir

path <- paste0("runs/2_sim") # hardcoded, needs run id or so in the future
if (dir.exists(path) == FALSE) {
  dir.create(path)
}

old_wd <- paste0(getwd(), "/") # trailing slash to avoid path issues
sim_wd <- paste0(old_wd, path)
setwd(sim_wd)


# ==== Input data adjustments ---------------------------------------------

# Set missing required variables
# NB: this is a temporary fix, should be done in the build functions with robust estimation methods + warning
# (imputation sould be documented in the input files as notes)
lteSe_1995_filex <- BNR_yr_merged$Y1995$FILEX
lteSe_1995_filex$PLANTING_DETAILS$PLDP <- 5.5  # planting depth

lteSe_1995_filex$TILLAGE$TDEP <- 
  ifelse(lteSe_1995_filex$TILLAGE$TIMPL == "TI038", 2.5, lteSe_1995_filex$TILLAGE$TDEP)  # missing tillage depth
lteSe_1995_filex$FERTILIZERS$FDEP <- 10  # fertilizer application depth

# Add cultivar to the cultivar file
# NB: parameter fitting script should be used eventually, for now we use a median cultivar based on the provided
# minima and maxima for genetic parameters

whaps_cul <- read_cul(paste0(dssat_dir, "/Genotype/WHAPS048.CUL"))

cul_median_pars <- apply(whaps_cul[1:2, 5:ncol(whaps_cul)], 2, function(x) sum(x)/2)

try(whaps_cul <- add_cultivar(whaps_cul,  # if the cultivar is still in the file (error) just ignore and move on 
                          ccode = "IB9999", 
                          cname = "Borenos",
                          ecode = "IB0001",
                          ppars = as.numeric(cul_median_pars[1:5]),
                          gpars = as.numeric(cul_median_pars[6:ncol(whaps_cul)]))
) # errored as commented, just wrap into a try() function
lteSe_1995_filex$CULTIVARS$INGENO <- "IB9999"  # cultivat code in file X links to cultivar file

write_cul(whaps_cul, paste0(dssat_dir, "/Genotype/WHAPS048.CUL"))  # export the updated file


# Set simulation controls

# Simulation start date: by default at the earliest management event carried out
all_dates <- na.omit(  # ignore warning
  as.POSIXct(
    as.numeric(
  unlist(lapply(lteSe_1995_filex, function(df) {
    df[grepl("DAT", colnames(df))]
  }), use.names = FALSE)
)))
lteSe_1995_filex$SIMULATION_CONTROLS$SDATE <- min(all_dates)

# Set simulation options
lteSe_1995_filex$SIMULATION_CONTROLS$WATER <- "Y"  # water (rain/irrigation)
lteSe_1995_filex$SIMULATION_CONTROLS$NITRO <- "Y"  # nitrogen
lteSe_1995_filex$SIMULATION_CONTROLS$CHEM <- "Y"  # chemicals
lteSe_1995_filex$SIMULATION_CONTROLS$TILL <- "Y"  # tillage

# Set management settings
lteSe_1995_filex$SIMULATION_CONTROLS$FERTI <- "R"  # fertilizer application: on reported dates (R)
lteSe_1995_filex$SIMULATION_CONTROLS$HARVS <- "R"  # harvest: on reported dates (R)

# Set model (for this example we use NWheat)
lteSe_1995_filex$SIMULATION_CONTROLS$SMODEL <- "WHAPS"  # NWheat code, from DSSAT source code
lteSe_1995_filex$SIMULATION_CONTROLS$PHOTO <- "C"  # photosynthesis method set to canopy curve as required by NWheat

# Set output files options (only growth for this example)
lteSe_1995_filex$SIMULATION_CONTROLS$GROUT <- "Y"
lteSe_1995_filex$SIMULATION_CONTROLS$VBOSE <- "Y"  # verbose 

# Write example data files (X, A, T) in the simulation directory
# Prototype data: seehausen LTE, year 1995 (wheat - rainfed)
write_filex(lteSe_1995_filex, paste0(sim_wd, "/SEDE9501.WHX"))  # ignore warnings
write_filea(BNR_yr_merged$Y1995$FILEA, paste0(sim_wd, "/SEDE9501.WHA")) 

# Weather, soil and cultivar files must be located within the DSSAT CSM directory (locally installed)
# For weather files, two years may be required if management events took place in the fall/winter preceding
# the harvest years (typically planting/tillage)
unique(year(all_dates))  # 1994, 1995 ==> two weather files required

write_wth2(BNR_yr_merged$Y1994$WTH, paste0(dssat_dir, "/Weather/SEDE9401.WTH"))
write_wth2(BNR_yr_merged$Y1995$WTH, paste0(dssat_dir, "/Weather/SEDE9501.WTH"))

# Soil profile not copied as generic soil was used in this example(already in DSSAT Soil directory)
#write_sol(BNR_yr_merged$Y1995$WTH, paste0(sim_wd, "Soil/SEDE.SOL"))  # soil profile

setwd(old_wd)
save(sim_wd, old_wd, file="sim_wd.RData")