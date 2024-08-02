load("mapped_soil.RData")

library(lubridate)
library(tibble)

pheno_estimates <- mapply(function(x, y){
  csmTools::estimate_phenology(sdata <- BNR_mapped$OBSERVED_Summary,
                     wdata <- BNR_mapped$WEATHER_Daily,
                     crop <- y,
                     lat <- unique(BNR_mapped$FIELDS$FL_LAT),
                     lon <- unique(BNR_mapped$FIELDS$FL_LONG),
                     year <- x,
                     irrigated = FALSE)
}, BNR_mapped$CULTIVARS$Year, BNR_mapped$CULTIVARS$CRID, SIMPLIFY = FALSE)  # ignore warnings
# TODO: estimation in TimeSeries?

BNR_mapped$OBSERVED_Summary <- as_tibble(do.call(rbind, pheno_estimates))

save(BNR_mapped, file="mapped_phenology.RData")