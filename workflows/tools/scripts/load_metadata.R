parser <- optparse::OptionParser()
parser <- optparse::add_option(parser, c("-d", "--data"), type="character", help="Path to the meta data xls file")
opt <- optparse::parse_args(parser)

metadata <- readxl::read_excel(opt$data)

save(metadata, file="metadata.RData")