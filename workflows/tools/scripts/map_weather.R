load("weather_stations.RData")
load("mapped_icasa.RData")

library(dplyr)
library(csmTools)

WEATHER_Daily <- WEATHER_raw$data %>% 
  mutate(WST_ID = "SEDE") %>%
  relocate(WST_ID, .before = everything())

# TODO: implement metadata mapping inside get_weather() function
WEATHER_Header <- lapply(names(WEATHER_raw$metadata), function(df_name){
  
  df <- WEATHER_raw$metadata[[df_name]]
  
  if (length(unique(df$wst_id)) == 1) {
    data.frame(Year = gsub("Y", "", df_name),
               WST_ID = "SEDE",
               WST_LAT = df$wst_lat[1],
               WST_LONG = df$wst_lon[1],
               WST_ELEV = df$wst_elev[1],
               TAV = df$TAV[1],
               TAMP = df$AMP[1],
               REFHT = 2, WNDHT = 2)  # so far not extractable for DWD metadata
  } else {
    data.frame(Year = gsub("Y", "", df_name),
               WST_ID = "SEDE",
               WST_LAT = mean(df$wst_lat),
               WST_LONG = mean(df$wst_lon),
               WST_ELEV = mean(df$wst_elev),  # TODO: add note that data is drawn from multiple stations
               TAV = df$TAV[1],
               TAMP = df$AMP[1],
               REFHT = 2, WNDHT = 2)  # so far not extractable for DWD metadata
  }
}) %>%
  do.call(rbind, .)

WEATHER_comments <- lapply(WEATHER_raw$metadata, function(df) {
  df <- df %>%
    select(-res) %>%
    collapse_cols("var") %>%
    mutate(comments = paste0(var, ": Station ", wst_id, " - ", wst_name, " (", wst_lat, " ",
                             wst_lon, "; ELEV = ", wst_elev, " m); Distance from site: ",
                             round(dist, 1), " km"))
  return(df$comments)
} )

BNR_mapped$WEATHER_Daily <- WEATHER_Daily  # TODO: ?integrate weather mapping with other data?
BNR_mapped$WEATHER_Header <- WEATHER_Header


save(BNR_mapped, file="mapped_weather.RData")
save(WEATHER_comments, file="weather_comments.RData")