load("soil_data.RData")
load("mapped_weather.RData")

BNR_mapped$SOIL_Layers <- SOIL_Layers  # TODO: ?integrate weather mapping with other data?
BNR_mapped$SOIL_Header <- SOIL_Header

save(BNR_mapped, file="mapped_soil.RData")