parser <- optparse::OptionParser()
parser <- optparse::add_option(parser, c("-s", "--soil"), type="character", help="Path to the SOL file")
parser <- optparse::add_option(parser, c("-i", "--soil_id"), type="character", help="Soil Id in SOL")
opt <- optparse::parse_args(parser)

library(dplyr)
library(tidyr)
library(DSSAT)
library(csmTools)

SOIL_generic <- read_sol(file_name = opt$soil, id_soil = opt$soil_id)
#SOIL_dssat_icasa <- read.csv("uc6_csmTools/data/soil_dssat_icasa.csv", fileEncoding = "latin1") # is in /data so no argument needed
SOIL_dssat_icasa <- soil_dssat_icasa # from datasets in package!

for (i in seq_along(colnames(SOIL_generic))) {
  for (j in 1:nrow(SOIL_dssat_icasa)){
    # Does not work with SCS FAMILY for some reason (likely because of space in colname)'
    # Not mapped for now, problem should be addressed
    if (colnames(SOIL_generic)[i] == SOIL_dssat_icasa$dssat_header[j]){
      colnames(SOIL_generic)[i] <- SOIL_dssat_icasa$icasa_header[j]
    }
  }
}

# Split header and profile data
SOIL_Header <- as.data.frame(SOIL_generic[1:20])  # Also make soil metadata???
SOIL_Layers <- unnest(SOIL_generic[21:ncol(SOIL_generic)],
                       cols = colnames(SOIL_generic)[21:ncol(SOIL_generic)]) %>%
  mutate(SOIL_ID = SOIL_Header$SOIL_ID) %>%
  relocate(SOIL_ID, .before = everything())

save(SOIL_Header, SOIL_Layers, file="soil_data.RData")