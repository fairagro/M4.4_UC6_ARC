parser <- optparse::OptionParser()
parser <- optparse::add_option(parser, c("-e", "--executable"), type="character", help="Directory containing DSSAT exe")
opt <- optparse::parse_args(parser)

options(DSSAT.CSM = opt$executable)
load("sim_wd.RData")
library(DSSAT)

setwd(sim_wd) # most probably problematic in CWL
batch_tbl <- data.frame(FILEX = "SEDE9501.WHX",
                        TRTNO = 1:4,
                        RP = 1,
                        SQ = 0,
                        OP = 0,
                        CO = 0)

# Write example batch file
write_dssbatch(batch_tbl)
# Run simulations
run_dssat(run_mode = "B")

setwd(old_wd)  # reset wd