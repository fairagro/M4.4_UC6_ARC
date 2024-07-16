load("mapped_dssat.RData")
load("weather_comments.RData")

library(csmTools)
library(dplyr)
library(lubridate)
library(DSSAT)
# DSSAT data formatting ---------------------------------------------------


BNR_dssat_yr <- split_by_year(BNR_dssat)

# Append non-year-specific data
BNR_dssat_yr <- lapply(BNR_dssat_yr, function(x)
  append(x, list(GENERAL = BNR_dssat$GENERAL, FIELDS = BNR_dssat$FIELDS))
)



# Build FILE X ------------------------------------------------------------


BNR_yr_filex <- lapply(BNR_dssat_yr, function(ls) {
  build_filex(ls,
              title = attr(BNR_dssat, "EXP_DETAILS"),
              site_code = attr(BNR_dssat, "SITE_CODE"))
})



# Build FILE A ------------------------------------------------------------


BNR_yr_filea <- lapply(BNR_dssat_yr, function(ls) {
  build_filea(ls,
              title = attr(BNR_dssat, "EXP_DETAILS"),
              site_code = attr(BNR_dssat, "SITE_CODE"))
})
BNR_yr_filea <- BNR_yr_filea[lengths(BNR_yr_filea) > 0]


# Build FILE T ------------------------------------------------------------


BNR_yr_filet <- lapply(BNR_dssat_yr, function(ls) {
  build_filet(ls,
              title = attr(BNR_dssat, "EXP_DETAILS"),
              site_code = attr(BNR_dssat, "SITE_CODE"))
})
BNR_yr_filet <- BNR_yr_filet[lengths(BNR_yr_filet) > 0]


# Build SOL FILE ----------------------------------------------------------


BNR_soil <- list(SOIL_Header = BNR_dssat$SOIL_Header, SOIL_Layers = BNR_dssat$SOIL_Layers)
BNR_sol <- build_sol(BNR_soil)



# Build WTH FILE ----------------------------------------------------------


# Append weather station metadata in the comment section for each year
BNR_dssat_yr <- mapply(function(x, y) {
  attr(x[["WEATHER_Daily"]], "comments") <- 
    c(paste0("Source data downloaded from: DWD Open Data Server on ", Sys.Date(), " with csmTools"), y)
  return(x)
}, BNR_dssat_yr, WEATHER_comments)

BNR_yr_wth <- lapply(BNR_dssat_yr, function(ls) build_wth(ls))



# Export data -------------------------------------------------------------


# Merge the outputs
BNR_yr_merged <- list()
for (i in names(BNR_yr_filex)) {
  BNR_yr_merged[[i]] <- list(FILEX = BNR_yr_filex[[i]],
                             FILEA = BNR_yr_filea[[i]],
                             FILET = BNR_yr_filet[[i]],
                             WTH = BNR_yr_wth[[i]])
}

# Drop missing tables
BNR_yr_merged <- lapply(BNR_yr_merged, function(ls) ls[lengths(ls) > 0])

# Export the data
path <- paste0("runs/01_raw") # hardcoded, needs run id or so in the future
if (dir.exists(path) == FALSE) {
  dir.create(path)
}

for (i in names(BNR_yr_merged)) {
  dir.create(paste0(path, "/", i))
  write_dssat(BNR_yr_merged[[i]], path = paste0(path, "/", i))
}

BNR_sol <- BNR_sol %>% rename(`SCS FAMILY` = SCS.FAMILY)  # problematic variable name with space
write_sol(BNR_sol, title = "General DSSAT Soil Input File", file_name = paste0(path, "/SEDE.SOL"),
          append = FALSE)
#TODO: generate file_name and title in the build_sol function

save(BNR_yr_merged, file="format_dssat.RData")