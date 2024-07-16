load("transformed.RData")
load("reshaped.RData")
load("uc6_csmTools/data/BnR_seehausen_icasa.Rda") # TODO: how to get from package?

BNR_full <- list(GENERAL = GENERAL,
                 FIELDS = FIELDS,
                 TREATMENTS = TREATMENTS,
                 INITIAL_CONDITIONS = INITIAL_CONDITIONS,
                 TILLAGE = seehausen_fmt$BODENBEARBEITUNG,
                 PLANTING_DETAILS = PLANTINGS,
                 CULTIVARS = CULTIVARS,
                 FERTILIZERS = FERTILIZERS,
                 RESIDUES = ORGANIC_MATERIALS, 
                 IRRIGATION = seehausen_fmt$BEREGNUNG,
                 CHEMICALS = seehausen_fmt$PFLANZENSCHUTZ,
                 HARVEST = HARVEST,
                 OBSERVED_Summary = OBSERVED_Summary,
                 OBSERVED_TimeSeries = OBSERVED_TimeSeries)

# Transfer metadata attributes to new dataframe
attr(BNR_full, "EXP_DETAILS") <- attr(seehausen_fmt, "EXP_DETAILS")
attr(BNR_full, "SITE_CODE") <- attr(seehausen_fmt, "SITE_CODE")


# Apply mappings (currently, only exaxt matches headers, codes and unit conversions)
BNR_mapped <- BNR_full
for (i in seq_along(names(BNR_full))) {
  BNR_mapped[[i]] <- csmTools::map_data(df = BNR_full[[i]],
                              tbl_name = names(BNR_full)[i],
                              map = bnr_seehausen_icasa,
                              keep_unmapped = FALSE,
                              col_exempt = "Year")
}

save(BNR_mapped, file="mapped_icasa.RData")