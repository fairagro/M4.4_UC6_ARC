load("transformed.RData")
load("uc6_csmTools/data/wth_data_maps.Rda") # TODO: how to get from package?

library(dplyr)
library(rdwd)
library(lubridate)
library(csmTools)

# Download and format corresponding weather data --------------------

WEATHER_raw  <- get_weather(
  lat = unique(FIELDS$FL_LAT),
  lon = unique(FIELDS$FL_LON),
  years = sort(unique(TREATMENTS[["Year"]])),
  src = "dwd",
  map_to = "icasa",
  vars = c("air_temperature", "precipitation", "solar_radiation", "dewpoint", "relative_humidity", "wind_speed"),
  res = list("hourly", c("daily", "hourly"), c("daily", "hourly"), "hourly", "hourly", "hourly") ,
  max_radius = c(50, 10, 50, 20, 20, 20)
)

save(WEATHER_raw, file = "weather_stations.RData")