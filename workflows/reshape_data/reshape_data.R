load("preprocessed.RData")
load("metadata.RData")

library(csmTools)
library(dplyr)

seehausen_fmt <- reshape_exp_data(db = db_list, metadata = metadata, mother_tbl = db_list$VERSUCHSAUFBAU)

save(seehausen_fmt, file="reshaped.RData")