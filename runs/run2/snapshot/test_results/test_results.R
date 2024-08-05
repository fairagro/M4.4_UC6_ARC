parser <- optparse::OptionParser()
parser <- optparse::add_option(parser, c("-s", "--simulation_dir"), type="character", help="Directory with Sim Output")
opt <- optparse::parse_args(parser)

library(DSSAT) 
library(csmTools)
library(testthat)

expect_equal_by_last_digit <- function(actual, expected) {
    if (!is.numeric(actual) || !is.numeric(expected)) {
        stop("Both arguments must be numeric")
    }

    # Function to determine the number of decimal places
    get_decimal_places <- function(num) {
        if (num %% 1 == 0) {
            return(0)
        } else {
            return(nchar(strsplit(as.character(num), "\\.")[[1]][2]))
        }
    }

    # Determine the maximum number of decimal places between actual and expected
    decimal_places_actual <- get_decimal_places(actual)
    decimal_places_expected <- get_decimal_places(expected)
    max_decimal_places <- max(decimal_places_actual, decimal_places_expected)

    # Calculate the tolerance
    tolerance <- 10^(-max_decimal_places) * (1 + 1e-8) # floating point precision, multiply tolerance by 1.00000001
    difference <- abs(actual - expected)
    expect_true(difference <= tolerance, info = sprintf("Expected %s to differ from %s only in the last digit (%s) - difference is %s", actual, expected, tolerance, difference))
}

is_numeric <- function(inpt) {
    # suppress warning: NAs introduced by coercion 
    return (suppressWarnings(!is.na(as.numeric(inpt))))
}

file <- paste0(opt$simulation_dir, "/PlantGro.OUT")
test_that("PlantGro.OUT is plausible", {
    valid <- system.file("extdata/test_fixtures/PlantGro.OUT", package = "csmTools")

    expected <- DSSAT::read_output(file_name = valid)
    actual <- DSSAT::read_output(file_name = file)

    for (i in 1:nrow(expected)) {
        for (j in 1:ncol(expected)) {
            if (is_numeric(expected[i, j]) && is_numeric(actual[i, j])) {
                expect_equal_by_last_digit(as.numeric(actual[i, j]), as.numeric(expected[i, j]))
            } else {
                expect_equal(expected[i, j], actual[i, j])
            }
        }
    }
})
