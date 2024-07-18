load("mapped_phenology.RData")

# ICASA to DSSAT variable mapping -----------------------------------

# Map from ICASA to DSSAT
BNR_dssat <- BNR_mapped
for (i in seq_along(names(BNR_mapped))) {
  BNR_dssat[[i]] <- csmTools::map_data(df = BNR_mapped[[i]],
                             tbl_name = names(BNR_mapped)[i],
                             map = icasa_dssat,
                             keep_unmapped = FALSE,
                             col_exempt = "Year")
}

save(BNR_dssat, file="mapped_dssat.RData")