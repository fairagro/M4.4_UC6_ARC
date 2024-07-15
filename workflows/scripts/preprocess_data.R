parser <- optparse::OptionParser()
parser <- optparse::add_option(parser, c("-d", "--data"), type="character", help="Path to the experimental data")
opt <- optparse::parse_args(parser)


db_files <- list.files(path = opt$data, pattern = "\\.csv$")
db_paths <- sapply(db_files, function(x){ paste0(opt$data, x) })
db_list <- lapply(db_paths, function(x) { file <- read.csv(x, fileEncoding = "iso-8859-1") })

# Simplify names
names(db_list) <- stringr::str_extract(names(db_list), "_V[0-9]+_[0-9]+_(.*)") # cut names after version number
names(db_list) <- gsub("_V[0-9]+_[0-9]+_", "", names(db_list)) # drop version number,
names(db_list) <- sub("\\..*$", "", names(db_list)) # drop file extension

save(db_list, file="preprocessed.RData")