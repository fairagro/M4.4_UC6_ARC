{
    "$graph": [
        {
            "class": "CommandLineTool",
            "requirements": [
                {
                    "class": "InitialWorkDirRequirement",
                    "listing": [
                        {
                            "entryname": "mapped_soil.RData",
                            "entry": "$(inputs.mapped_soil_RData)"
                        },
                        {
                            "entryname": "estimate_phenology.R",
                            "entry": "load(\"mapped_soil.RData\")\n\nlibrary(lubridate)\nlibrary(tibble)\n\npheno_estimates <- mapply(function(x, y){\n  csmTools::estimate_phenology(sdata <- BNR_mapped$OBSERVED_Summary,\n                     wdata <- BNR_mapped$WEATHER_Daily,\n                     crop <- y,\n                     lat <- unique(BNR_mapped$FIELDS$FL_LAT),\n                     lon <- unique(BNR_mapped$FIELDS$FL_LONG),\n                     year <- x,\n                     irrigated = FALSE)\n}, BNR_mapped$CULTIVARS$Year, BNR_mapped$CULTIVARS$CRID, SIMPLIFY = FALSE)  # ignore warnings\n# TODO: estimation in TimeSeries?\n\nBNR_mapped$OBSERVED_Summary <- as_tibble(do.call(rbind, pheno_estimates))\n\nsave(BNR_mapped, file=\"mapped_phenology.RData\")"
                        }
                    ]
                },
                {
                    "class": "DockerRequirement",
                    "dockerFile": "FROM rocker/r-ver:4.4\n\nRUN apt-get update && apt-get install -y git sudo wget\n\nRUN wget https://raw.githubusercontent.com/fairagro/uc6_csmTools/feature/package_management/install_requirements.sh\nRUN chmod +x ./install_requirements.sh && ./install_requirements.sh\n\nRUN wget https://raw.githubusercontent.com/fairagro/uc6_csmTools/feature/package_management/install_dssat.sh\nRUN chmod +x ./install_dssat.sh && ./install_dssat.sh /usr/local/dssat\n\nRUN R -e 'install.packages(\"devtools\")'\nRUN R -e 'install.packages(\"optparse\")'\nRUN R -e 'devtools::install_github(\"fairagro/uc6_csmTools@feature/package_management\")'",
                    "dockerImageId": "uc6_arc"
                }
            ],
            "inputs": [
                {
                    "id": "#estimate_phenology.cwl/mapped_soil_RData",
                    "type": "File"
                }
            ],
            "baseCommand": [
                "Rscript",
                "estimate_phenology.R"
            ],
            "id": "#estimate_phenology.cwl",
            "outputs": [
                {
                    "id": "#estimate_phenology.cwl/mapped_phenology.RData",
                    "type": "File",
                    "outputBinding": {
                        "glob": "mapped_phenology.RData"
                    }
                }
            ]
        },
        {
            "class": "CommandLineTool",
            "requirements": [
                {
                    "class": "InitialWorkDirRequirement",
                    "listing": [
                        {
                            "entryname": "mapped_dssat.RData",
                            "entry": "$(inputs.mapped_dssat_RData)"
                        },
                        {
                            "entryname": "weather_comments.RData",
                            "entry": "$(inputs.weather_comments_RData)"
                        },
                        {
                            "entryname": "format_dssat.R",
                            "entry": "load(\"mapped_dssat.RData\")\nload(\"weather_comments.RData\")\n\nlibrary(csmTools)\nlibrary(dplyr)\nlibrary(lubridate)\nlibrary(DSSAT)\n# DSSAT data formatting ---------------------------------------------------\n\n\nBNR_dssat_yr <- split_by_year(BNR_dssat)\n\n# Append non-year-specific data\nBNR_dssat_yr <- lapply(BNR_dssat_yr, function(x)\n  append(x, list(GENERAL = BNR_dssat$GENERAL, FIELDS = BNR_dssat$FIELDS))\n)\n\n\n\n# Build FILE X ------------------------------------------------------------\n\n\nBNR_yr_filex <- lapply(BNR_dssat_yr, function(ls) {\n  build_filex(ls,\n              title = attr(BNR_dssat, \"EXP_DETAILS\"),\n              site_code = attr(BNR_dssat, \"SITE_CODE\"))\n})\n\n\n\n# Build FILE A ------------------------------------------------------------\n\n\nBNR_yr_filea <- lapply(BNR_dssat_yr, function(ls) {\n  build_filea(ls,\n              title = attr(BNR_dssat, \"EXP_DETAILS\"),\n              site_code = attr(BNR_dssat, \"SITE_CODE\"))\n})\nBNR_yr_filea <- BNR_yr_filea[lengths(BNR_yr_filea) > 0]\n\n\n# Build FILE T ------------------------------------------------------------\n\n\nBNR_yr_filet <- lapply(BNR_dssat_yr, function(ls) {\n  build_filet(ls,\n              title = attr(BNR_dssat, \"EXP_DETAILS\"),\n              site_code = attr(BNR_dssat, \"SITE_CODE\"))\n})\nBNR_yr_filet <- BNR_yr_filet[lengths(BNR_yr_filet) > 0]\n\n\n# Build SOL FILE ----------------------------------------------------------\n\n\nBNR_soil <- list(SOIL_Header = BNR_dssat$SOIL_Header, SOIL_Layers = BNR_dssat$SOIL_Layers)\nBNR_sol <- build_sol(BNR_soil)\n\n\n\n# Build WTH FILE ----------------------------------------------------------\n\n\n# Append weather station metadata in the comment section for each year\nBNR_dssat_yr <- mapply(function(x, y) {\n  attr(x[[\"WEATHER_Daily\"]], \"comments\") <- \n    c(paste0(\"Source data downloaded from: DWD Open Data Server on \", Sys.Date(), \" with csmTools\"), y)\n  return(x)\n}, BNR_dssat_yr, WEATHER_comments)\n\nBNR_yr_wth <- lapply(BNR_dssat_yr, function(ls) build_wth(ls))\n\n\n\n# Export data -------------------------------------------------------------\n\n\n# Merge the outputs\nBNR_yr_merged <- list()\nfor (i in names(BNR_yr_filex)) {\n  BNR_yr_merged[[i]] <- list(FILEX = BNR_yr_filex[[i]],\n                             FILEA = BNR_yr_filea[[i]],\n                             FILET = BNR_yr_filet[[i]],\n                             WTH = BNR_yr_wth[[i]])\n}\n\n# Drop missing tables\nBNR_yr_merged <- lapply(BNR_yr_merged, function(ls) ls[lengths(ls) > 0])\n\n# Export the data\npath <- paste0(\"01_raw\") # hardcoded, needs run id or so in the future\nif (dir.exists(path) == FALSE) {\n  dir.create(path)\n}\n\nfor (i in names(BNR_yr_merged)) {\n  dir.create(paste0(path, \"/\", i))\n  write_dssat(BNR_yr_merged[[i]], path = paste0(path, \"/\", i))\n}\n\nBNR_sol <- BNR_sol %>% rename(`SCS FAMILY` = SCS.FAMILY)  # problematic variable name with space\nwrite_sol(BNR_sol, title = \"General DSSAT Soil Input File\", file_name = \"SEDE.SOL\",\n          append = FALSE)\n#TODO: generate file_name and title in the build_sol function\n\nsave(BNR_yr_merged, file=\"format_dssat.RData\")\n\n#' @exportHint SEDE.SOL"
                        }
                    ]
                },
                {
                    "class": "DockerRequirement",
                    "dockerFile": "FROM rocker/r-ver:4.4\n\nRUN apt-get update && apt-get install -y git sudo wget\n\nRUN wget https://raw.githubusercontent.com/fairagro/uc6_csmTools/feature/package_management/install_requirements.sh\nRUN chmod +x ./install_requirements.sh && ./install_requirements.sh\n\nRUN wget https://raw.githubusercontent.com/fairagro/uc6_csmTools/feature/package_management/install_dssat.sh\nRUN chmod +x ./install_dssat.sh && ./install_dssat.sh /usr/local/dssat\n\nRUN R -e 'install.packages(\"devtools\")'\nRUN R -e 'install.packages(\"optparse\")'\nRUN R -e 'devtools::install_github(\"fairagro/uc6_csmTools@feature/package_management\")'",
                    "dockerImageId": "uc6_arc"
                }
            ],
            "inputs": [
                {
                    "id": "#format_dssat.cwl/mapped_dssat_RData",
                    "type": "File"
                },
                {
                    "id": "#format_dssat.cwl/weather_comments_RData",
                    "type": "File"
                }
            ],
            "outputs": [
                {
                    "id": "#format_dssat.cwl/format_dssat.RData",
                    "type": "File",
                    "outputBinding": {
                        "glob": "format_dssat.RData"
                    }
                },
                {
                    "id": "#format_dssat.cwl/SEDE.SOL",
                    "type": "File",
                    "outputBinding": {
                        "glob": "SEDE.SOL"
                    }
                }
            ],
            "baseCommand": [
                "Rscript",
                "format_dssat.R"
            ],
            "id": "#format_dssat.cwl"
        },
        {
            "class": "CommandLineTool",
            "requirements": [
                {
                    "class": "InitialWorkDirRequirement",
                    "listing": [
                        {
                            "entryname": "get_soil_data.R",
                            "entry": "parser <- optparse::OptionParser()\nparser <- optparse::add_option(parser, c(\"-s\", \"--soil\"), type=\"character\", help=\"Path to the SOL file\")\nparser <- optparse::add_option(parser, c(\"-i\", \"--soil_id\"), type=\"character\", help=\"Soil Id in SOL\")\nopt <- optparse::parse_args(parser)\n\nlibrary(dplyr)\nlibrary(tidyr)\nlibrary(DSSAT)\nlibrary(csmTools)\n\nSOIL_generic <- read_sol(file_name = opt$soil, id_soil = opt$soil_id)\n#SOIL_dssat_icasa <- read.csv(\"uc6_csmTools/data/soil_dssat_icasa.csv\", fileEncoding = \"latin1\") # is in /data so no argument needed\nSOIL_dssat_icasa <- soil_dssat_icasa # from datasets in package!\n\nfor (i in seq_along(colnames(SOIL_generic))) {\n  for (j in 1:nrow(SOIL_dssat_icasa)){\n    # Does not work with SCS FAMILY for some reason (likely because of space in colname)'\n    # Not mapped for now, problem should be addressed\n    if (colnames(SOIL_generic)[i] == SOIL_dssat_icasa$dssat_header[j]){\n      colnames(SOIL_generic)[i] <- SOIL_dssat_icasa$icasa_header[j]\n    }\n  }\n}\n\n# Split header and profile data\nSOIL_Header <- as.data.frame(SOIL_generic[1:20])  # Also make soil metadata???\nSOIL_Layers <- unnest(SOIL_generic[21:ncol(SOIL_generic)],\n                       cols = colnames(SOIL_generic)[21:ncol(SOIL_generic)]) %>%\n  mutate(SOIL_ID = SOIL_Header$SOIL_ID) %>%\n  relocate(SOIL_ID, .before = everything())\n\nsave(SOIL_Header, SOIL_Layers, file=\"soil_data.RData\")"
                        }
                    ]
                },
                {
                    "class": "DockerRequirement",
                    "dockerFile": "FROM rocker/r-ver:4.4\n\nRUN apt-get update && apt-get install -y git sudo wget\n\nRUN wget https://raw.githubusercontent.com/fairagro/uc6_csmTools/feature/package_management/install_requirements.sh\nRUN chmod +x ./install_requirements.sh && ./install_requirements.sh\n\nRUN wget https://raw.githubusercontent.com/fairagro/uc6_csmTools/feature/package_management/install_dssat.sh\nRUN chmod +x ./install_dssat.sh && ./install_dssat.sh /usr/local/dssat\n\nRUN R -e 'install.packages(\"devtools\")'\nRUN R -e 'install.packages(\"optparse\")'\nRUN R -e 'devtools::install_github(\"fairagro/uc6_csmTools@feature/package_management\")'",
                    "dockerImageId": "uc6_arc"
                }
            ],
            "inputs": [
                {
                    "id": "#get_soil_data.cwl/soil",
                    "type": "File",
                    "inputBinding": {
                        "prefix": "--soil"
                    }
                },
                {
                    "id": "#get_soil_data.cwl/soil_id",
                    "type": "string",
                    "inputBinding": {
                        "prefix": "--soil_id"
                    }
                }
            ],
            "outputs": [
                {
                    "id": "#get_soil_data.cwl/soil_data.RData",
                    "type": "File",
                    "outputBinding": {
                        "glob": "soil_data.RData"
                    }
                }
            ],
            "baseCommand": [
                "Rscript",
                "get_soil_data.R"
            ],
            "id": "#get_soil_data.cwl"
        },
        {
            "class": "CommandLineTool",
            "requirements": [
                {
                    "class": "InitialWorkDirRequirement",
                    "listing": [
                        {
                            "entryname": "transformed.RData",
                            "entry": "$(inputs.transformed_RData)"
                        },
                        {
                            "entryname": "get_weather.R",
                            "entry": "load(\"transformed.RData\")\n\nlibrary(dplyr)\nlibrary(rdwd)\nlibrary(lubridate)\nlibrary(csmTools)\n\n# Download and format corresponding weather data --------------------\n\nWEATHER_raw  <- get_weather(\n  lat = unique(FIELDS$FL_LAT),\n  lon = unique(FIELDS$FL_LON),\n  years = sort(unique(TREATMENTS[[\"Year\"]])),\n  src = \"dwd\",\n  map_to = \"icasa\",\n  vars = c(\"air_temperature\", \"precipitation\", \"solar_radiation\", \"dewpoint\", \"relative_humidity\", \"wind_speed\"),\n  res = list(\"hourly\", c(\"daily\", \"hourly\"), c(\"daily\", \"hourly\"), \"hourly\", \"hourly\", \"hourly\") ,\n  max_radius = c(50, 10, 50, 20, 20, 20)\n)\n\nsave(WEATHER_raw, file = \"weather_stations.RData\")"
                        }
                    ]
                },
                {
                    "class": "DockerRequirement",
                    "dockerFile": "FROM rocker/r-ver:4.4\n\nRUN apt-get update && apt-get install -y git sudo wget\n\nRUN wget https://raw.githubusercontent.com/fairagro/uc6_csmTools/feature/package_management/install_requirements.sh\nRUN chmod +x ./install_requirements.sh && ./install_requirements.sh\n\nRUN wget https://raw.githubusercontent.com/fairagro/uc6_csmTools/feature/package_management/install_dssat.sh\nRUN chmod +x ./install_dssat.sh && ./install_dssat.sh /usr/local/dssat\n\nRUN R -e 'install.packages(\"devtools\")'\nRUN R -e 'install.packages(\"optparse\")'\nRUN R -e 'devtools::install_github(\"fairagro/uc6_csmTools@feature/package_management\")'",
                    "dockerImageId": "uc6_arc"
                }
            ],
            "inputs": [
                {
                    "id": "#get_weather.cwl/transformed_RData",
                    "type": "File"
                }
            ],
            "outputs": [
                {
                    "id": "#get_weather.cwl/weather_stations.RData",
                    "type": "File",
                    "outputBinding": {
                        "glob": "weather_stations.RData"
                    }
                }
            ],
            "baseCommand": [
                "Rscript",
                "get_weather.R"
            ],
            "id": "#get_weather.cwl"
        },
        {
            "class": "CommandLineTool",
            "requirements": [
                {
                    "class": "InitialWorkDirRequirement",
                    "listing": [
                        {
                            "entryname": "mapped_phenology.RData",
                            "entry": "$(inputs.mapped_phenology_RData)"
                        },
                        {
                            "entryname": "icasa2dssat.R",
                            "entry": "load(\"mapped_phenology.RData\")\nlibrary(csmTools)\n\n# ICASA to DSSAT variable mapping -----------------------------------\n\n# Map from ICASA to DSSAT\nBNR_dssat <- BNR_mapped\nfor (i in seq_along(names(BNR_mapped))) {\n  BNR_dssat[[i]] <- csmTools::map_data(df = BNR_mapped[[i]],\n                             tbl_name = names(BNR_mapped)[i],\n                             map = icasa_dssat,\n                             keep_unmapped = FALSE,\n                             col_exempt = \"Year\")\n}\n\nsave(BNR_dssat, file=\"mapped_dssat.RData\")"
                        }
                    ]
                },
                {
                    "class": "DockerRequirement",
                    "dockerFile": "FROM rocker/r-ver:4.4\n\nRUN apt-get update && apt-get install -y git sudo wget\n\nRUN wget https://raw.githubusercontent.com/fairagro/uc6_csmTools/feature/package_management/install_requirements.sh\nRUN chmod +x ./install_requirements.sh && ./install_requirements.sh\n\nRUN wget https://raw.githubusercontent.com/fairagro/uc6_csmTools/feature/package_management/install_dssat.sh\nRUN chmod +x ./install_dssat.sh && ./install_dssat.sh /usr/local/dssat\n\nRUN R -e 'install.packages(\"devtools\")'\nRUN R -e 'install.packages(\"optparse\")'\nRUN R -e 'devtools::install_github(\"fairagro/uc6_csmTools@feature/package_management\")'",
                    "dockerImageId": "uc6_arc"
                }
            ],
            "inputs": [
                {
                    "id": "#icasa2dssat.cwl/mapped_phenology_RData",
                    "type": "File"
                }
            ],
            "outputs": [
                {
                    "id": "#icasa2dssat.cwl/mapped_dssat.RData",
                    "type": "File",
                    "outputBinding": {
                        "glob": "mapped_dssat.RData"
                    }
                }
            ],
            "baseCommand": [
                "Rscript",
                "icasa2dssat.R"
            ],
            "id": "#icasa2dssat.cwl"
        },
        {
            "class": "CommandLineTool",
            "requirements": [
                {
                    "class": "InitialWorkDirRequirement",
                    "listing": [
                        {
                            "entryname": "load_metadata.R",
                            "entry": "parser <- optparse::OptionParser()\nparser <- optparse::add_option(parser, c(\"-d\", \"--data\"), type=\"character\", help=\"Path to the meta data xls file\")\nopt <- optparse::parse_args(parser)\n\nmetadata <- readxl::read_excel(opt$data)\n\nsave(metadata, file=\"metadata.RData\")"
                        }
                    ]
                },
                {
                    "class": "DockerRequirement",
                    "dockerFile": "FROM rocker/r-ver:4.4\n\nRUN apt-get update && apt-get install -y git sudo wget\n\nRUN wget https://raw.githubusercontent.com/fairagro/uc6_csmTools/feature/package_management/install_requirements.sh\nRUN chmod +x ./install_requirements.sh && ./install_requirements.sh\n\nRUN wget https://raw.githubusercontent.com/fairagro/uc6_csmTools/feature/package_management/install_dssat.sh\nRUN chmod +x ./install_dssat.sh && ./install_dssat.sh /usr/local/dssat\n\nRUN R -e 'install.packages(\"devtools\")'\nRUN R -e 'install.packages(\"optparse\")'\nRUN R -e 'devtools::install_github(\"fairagro/uc6_csmTools@feature/package_management\")'",
                    "dockerImageId": "uc6_arc"
                }
            ],
            "inputs": [
                {
                    "id": "#load_metadata.cwl/data",
                    "type": "File",
                    "inputBinding": {
                        "prefix": "--data"
                    }
                }
            ],
            "outputs": [
                {
                    "id": "#load_metadata.cwl/metadata.RData",
                    "type": "File",
                    "outputBinding": {
                        "glob": "metadata.RData"
                    }
                }
            ],
            "baseCommand": [
                "Rscript",
                "load_metadata.R"
            ],
            "id": "#load_metadata.cwl"
        },
        {
            "class": "Workflow",
            "hints": [
                {
                    "class": "SoftwareRequirement",
                    "packages": [
                        {
                            "version": [
                                "4.8.2.12"
                            ],
                            "package": "DSSAT"
                        },
                        {
                            "version": [
                                "4.4.0"
                            ],
                            "package": "R"
                        }
                    ]
                }
            ],
            "requirements": [
                {
                    "networkAccess": true,
                    "class": "NetworkAccess"
                }
            ],
            "inputs": [
                {
                    "type": "Directory",
                    "id": "#main/data_dir"
                },
                {
                    "type": "File",
                    "id": "#main/metadata"
                },
                {
                    "type": "File",
                    "id": "#main/soil_file"
                },
                {
                    "type": "string",
                    "id": "#main/soil_id"
                }
            ],
            "outputs": [
                {
                    "type": "File",
                    "outputSource": "#main/plot_results/Rplots.pdf",
                    "id": "#main/plot"
                }
            ],
            "steps": [
                {
                    "in": [
                        {
                            "source": "#main/map_soil_data/mapped_soil.RData",
                            "id": "#main/estimate_phenology/mapped_soil_RData"
                        }
                    ],
                    "run": "#estimate_phenology.cwl",
                    "out": [
                        "#main/estimate_phenology/mapped_phenology.RData"
                    ],
                    "id": "#main/estimate_phenology"
                },
                {
                    "in": [
                        {
                            "source": "#main/icasa2dssat/mapped_dssat.RData",
                            "id": "#main/format_dssat/mapped_dssat_RData"
                        },
                        {
                            "source": "#main/map_weather/weather_comments.RData",
                            "id": "#main/format_dssat/weather_comments_RData"
                        }
                    ],
                    "run": "#format_dssat.cwl",
                    "out": [
                        "#main/format_dssat/format_dssat.RData",
                        "#main/format_dssat/SEDE.SOL"
                    ],
                    "id": "#main/format_dssat"
                },
                {
                    "in": [
                        {
                            "source": "#main/soil_file",
                            "id": "#main/get_soil_data/soil"
                        },
                        {
                            "source": "#main/soil_id",
                            "id": "#main/get_soil_data/soil_id"
                        }
                    ],
                    "run": "#get_soil_data.cwl",
                    "out": [
                        "#main/get_soil_data/soil_data.RData"
                    ],
                    "id": "#main/get_soil_data"
                },
                {
                    "in": [
                        {
                            "source": "#main/transform_data/transformed.RData",
                            "id": "#main/get_weather/transformed_RData"
                        }
                    ],
                    "run": "#get_weather.cwl",
                    "out": [
                        "#main/get_weather/weather_stations.RData"
                    ],
                    "id": "#main/get_weather"
                },
                {
                    "in": [
                        {
                            "source": "#main/estimate_phenology/mapped_phenology.RData",
                            "id": "#main/icasa2dssat/mapped_phenology_RData"
                        }
                    ],
                    "run": "#icasa2dssat.cwl",
                    "out": [
                        "#main/icasa2dssat/mapped_dssat.RData"
                    ],
                    "id": "#main/icasa2dssat"
                },
                {
                    "in": [
                        {
                            "source": "#main/metadata",
                            "id": "#main/load_metadata/data"
                        }
                    ],
                    "run": "#load_metadata.cwl",
                    "out": [
                        "#main/load_metadata/metadata.RData"
                    ],
                    "id": "#main/load_metadata"
                },
                {
                    "in": [
                        {
                            "source": "#main/reshape_data/reshaped.RData",
                            "id": "#main/map_icasa/reshaped_RData"
                        },
                        {
                            "source": "#main/transform_data/transformed.RData",
                            "id": "#main/map_icasa/transformed_RData"
                        }
                    ],
                    "run": "#map_icasa.cwl",
                    "out": [
                        "#main/map_icasa/mapped_icasa.RData"
                    ],
                    "id": "#main/map_icasa"
                },
                {
                    "in": [
                        {
                            "source": "#main/map_weather/mapped_weather.RData",
                            "id": "#main/map_soil_data/mapped_weather_RData"
                        },
                        {
                            "source": "#main/get_soil_data/soil_data.RData",
                            "id": "#main/map_soil_data/soil_data_RData"
                        }
                    ],
                    "run": "#map_soil_data.cwl",
                    "out": [
                        "#main/map_soil_data/mapped_soil.RData"
                    ],
                    "id": "#main/map_soil_data"
                },
                {
                    "in": [
                        {
                            "source": "#main/map_icasa/mapped_icasa.RData",
                            "id": "#main/map_weather/mapped_icasa_RData"
                        },
                        {
                            "source": "#main/get_weather/weather_stations.RData",
                            "id": "#main/map_weather/weather_stations_RData"
                        }
                    ],
                    "run": "#map_weather.cwl",
                    "out": [
                        "#main/map_weather/mapped_weather.RData",
                        "#main/map_weather/weather_comments.RData"
                    ],
                    "id": "#main/map_weather"
                },
                {
                    "in": [
                        {
                            "source": "#main/format_dssat/format_dssat.RData",
                            "id": "#main/plot_results/format_dssat_RData"
                        },
                        {
                            "source": "#main/simulation/output",
                            "id": "#main/plot_results/simulation_dir"
                        }
                    ],
                    "run": "#plot_results.cwl",
                    "out": [
                        "#main/plot_results/Rplots.pdf"
                    ],
                    "id": "#main/plot_results"
                },
                {
                    "in": [
                        {
                            "source": "#main/data_dir",
                            "id": "#main/preprocess_data/data"
                        }
                    ],
                    "run": "#preprocess_data.cwl",
                    "out": [
                        "#main/preprocess_data/preprocessed.RData"
                    ],
                    "id": "#main/preprocess_data"
                },
                {
                    "in": [
                        {
                            "source": "#main/load_metadata/metadata.RData",
                            "id": "#main/reshape_data/metadata_RData"
                        },
                        {
                            "source": "#main/preprocess_data/preprocessed.RData",
                            "id": "#main/reshape_data/preprocessed_RData"
                        }
                    ],
                    "run": "#reshape_data.cwl",
                    "out": [
                        "#main/reshape_data/reshaped.RData"
                    ],
                    "id": "#main/reshape_data"
                },
                {
                    "in": [
                        {
                            "source": "#main/format_dssat/format_dssat.RData",
                            "id": "#main/simulation/format_dssat_RData"
                        },
                        {
                            "source": "#main/soil_file",
                            "id": "#main/simulation/soil"
                        },
                        {
                            "source": "#main/format_dssat/SEDE.SOL",
                            "id": "#main/simulation/sol"
                        }
                    ],
                    "run": "#simulation.cwl",
                    "out": [
                        "#main/simulation/output"
                    ],
                    "id": "#main/simulation"
                },
                {
                    "in": [
                        {
                            "source": "#main/simulation/output",
                            "id": "#main/test_results/simulation_dir"
                        }
                    ],
                    "run": "#test_results.cwl",
                    "out": [],
                    "id": "#main/test_results"
                },
                {
                    "in": [
                        {
                            "source": "#main/reshape_data/reshaped.RData",
                            "id": "#main/transform_data/reshaped_RData"
                        }
                    ],
                    "run": "#transform_data.cwl",
                    "out": [
                        "#main/transform_data/transformed.RData"
                    ],
                    "id": "#main/transform_data"
                }
            ],
            "id": "#main",
            "https://github.com/nfdi4plants/ARC_ontologyhas technology type": [
                {
                    "class": "https://github.com/nfdi4plants/ARC_ontologytechnology type",
                    "https://github.com/nfdi4plants/ARC_ontologyannotation value": "Docker Container"
                }
            ],
            "https://github.com/nfdi4plants/ARC_ontologyperformer": [
                {
                    "class": "https://github.com/nfdi4plants/ARC_ontologyPerson",
                    "https://github.com/nfdi4plants/ARC_ontologyfirst name": "John",
                    "https://github.com/nfdi4plants/ARC_ontologylast name": "Doe",
                    "https://github.com/nfdi4plants/ARC_ontologyemail": "mail@institue.com",
                    "https://github.com/nfdi4plants/ARC_ontologyaffiliation": "RPTU Kaiserslautern/Landau",
                    "https://github.com/nfdi4plants/ARC_ontologyhas role": [
                        {
                            "class": "https://github.com/nfdi4plants/ARC_ontologyrole",
                            "https://github.com/nfdi4plants/ARC_ontologyterm accession": "http://edamontology.org/operation_3214",
                            "https://github.com/nfdi4plants/ARC_ontologyannotation value": "Spectral analysis"
                        }
                    ]
                }
            ],
            "https://github.com/nfdi4plants/ARC_ontologyhas process sequence": [
                {
                    "class": "https://github.com/nfdi4plants/ARC_ontologyprocess sequence",
                    "https://github.com/nfdi4plants/ARC_ontologyname": "M4.4_UC6_ARC",
                    "https://github.com/nfdi4plants/ARC_ontologyhas parameter value": [
                        {
                            "class": "https://github.com/nfdi4plants/ARC_ontologyprocess parameter value",
                            "https://github.com/nfdi4plants/ARC_ontologyhas parameter": [
                                {
                                    "class": "https://github.com/nfdi4plants/ARC_ontologyprotocol parameter",
                                    "https://github.com/nfdi4plants/ARC_ontologyhas parameter name": [
                                        {
                                            "class": "https://github.com/nfdi4plants/ARC_ontologyparameter name",
                                            "https://github.com/nfdi4plants/ARC_ontologyterm accession": "http://edamontology.org/operation_0004",
                                            "https://github.com/nfdi4plants/ARC_ontologyterm source REF": "EMBRACE",
                                            "https://github.com/nfdi4plants/ARC_ontologyannotation value": "Operation"
                                        }
                                    ]
                                }
                            ],
                            "https://github.com/nfdi4plants/ARC_ontologyvalue": [
                                {
                                    "class": "https://github.com/nfdi4plants/ARC_ontologyontology annotation",
                                    "https://github.com/nfdi4plants/ARC_ontologyterm accession": "http://edamontology.org/operation_3557",
                                    "https://github.com/nfdi4plants/ARC_ontologyterm source REF": "EMBRACE",
                                    "https://github.com/nfdi4plants/ARC_ontologyannotation value": "Imputation"
                                }
                            ]
                        },
                        {
                            "class": "https://github.com/nfdi4plants/ARC_ontologyprocess parameter value",
                            "https://github.com/nfdi4plants/ARC_ontologyhas parameter": [
                                {
                                    "class": "https://github.com/nfdi4plants/ARC_ontologyprotocol parameter",
                                    "https://github.com/nfdi4plants/ARC_ontologyhas parameter name": [
                                        {
                                            "class": "https://github.com/nfdi4plants/ARC_ontologyparameter name",
                                            "https://github.com/nfdi4plants/ARC_ontologyterm accession": "http://edamontology.org/operation_0004",
                                            "https://github.com/nfdi4plants/ARC_ontologyterm source REF": "EMBRACE",
                                            "https://github.com/nfdi4plants/ARC_ontologyannotation value": "Operation"
                                        }
                                    ]
                                }
                            ],
                            "https://github.com/nfdi4plants/ARC_ontologyvalue": [
                                {
                                    "class": "https://github.com/nfdi4plants/ARC_ontologyontology annotation",
                                    "https://github.com/nfdi4plants/ARC_ontologyterm accession": "http://edamontology.org/operation_3557",
                                    "https://github.com/nfdi4plants/ARC_ontologyterm source REF": "EMBRACE",
                                    "https://github.com/nfdi4plants/ARC_ontologyannotation value": "Imputation"
                                }
                            ]
                        },
                        {
                            "class": "https://github.com/nfdi4plants/ARC_ontologyprocess parameter value",
                            "https://github.com/nfdi4plants/ARC_ontologyhas parameter": [
                                {
                                    "class": "https://github.com/nfdi4plants/ARC_ontologyprotocol parameter",
                                    "https://github.com/nfdi4plants/ARC_ontologyhas parameter name": [
                                        {
                                            "class": "https://github.com/nfdi4plants/ARC_ontologyparameter name",
                                            "https://github.com/nfdi4plants/ARC_ontologyterm accession": "http://edamontology.org/operation_0004",
                                            "https://github.com/nfdi4plants/ARC_ontologyterm source REF": "EMBRACE",
                                            "https://github.com/nfdi4plants/ARC_ontologyannotation value": "Operation"
                                        }
                                    ]
                                }
                            ],
                            "https://github.com/nfdi4plants/ARC_ontologyvalue": [
                                {
                                    "class": "https://github.com/nfdi4plants/ARC_ontologyontology annotation",
                                    "https://github.com/nfdi4plants/ARC_ontologyterm accession": "http://edamontology.org/operation_3557",
                                    "https://github.com/nfdi4plants/ARC_ontologyterm source REF": "EMBRACE",
                                    "https://github.com/nfdi4plants/ARC_ontologyannotation value": "Imputation"
                                }
                            ]
                        },
                        {
                            "class": "https://github.com/nfdi4plants/ARC_ontologyprocess parameter value",
                            "https://github.com/nfdi4plants/ARC_ontologyhas parameter": [
                                {
                                    "class": "https://github.com/nfdi4plants/ARC_ontologyprotocol parameter",
                                    "https://github.com/nfdi4plants/ARC_ontologyhas parameter name": [
                                        {
                                            "class": "https://github.com/nfdi4plants/ARC_ontologyparameter name",
                                            "https://github.com/nfdi4plants/ARC_ontologyterm accession": "http://edamontology.org/operation_0004",
                                            "https://github.com/nfdi4plants/ARC_ontologyterm source REF": "EMBRACE",
                                            "https://github.com/nfdi4plants/ARC_ontologyannotation value": "Operation"
                                        }
                                    ]
                                }
                            ],
                            "https://github.com/nfdi4plants/ARC_ontologyvalue": [
                                {
                                    "class": "https://github.com/nfdi4plants/ARC_ontologyontology annotation",
                                    "https://github.com/nfdi4plants/ARC_ontologyterm accession": "http://edamontology.org/operation_3557",
                                    "https://github.com/nfdi4plants/ARC_ontologyterm source REF": "EMBRACE",
                                    "https://github.com/nfdi4plants/ARC_ontologyannotation value": "Imputation"
                                }
                            ]
                        },
                        {
                            "class": "https://github.com/nfdi4plants/ARC_ontologyprocess parameter value",
                            "https://github.com/nfdi4plants/ARC_ontologyhas parameter": [
                                {
                                    "class": "https://github.com/nfdi4plants/ARC_ontologyprotocol parameter",
                                    "https://github.com/nfdi4plants/ARC_ontologyhas parameter name": [
                                        {
                                            "class": "https://github.com/nfdi4plants/ARC_ontologyparameter name",
                                            "https://github.com/nfdi4plants/ARC_ontologyterm accession": "http://edamontology.org/operation_0004",
                                            "https://github.com/nfdi4plants/ARC_ontologyterm source REF": "EMBRACE",
                                            "https://github.com/nfdi4plants/ARC_ontologyannotation value": "Operation"
                                        }
                                    ]
                                }
                            ],
                            "https://github.com/nfdi4plants/ARC_ontologyvalue": [
                                {
                                    "class": "https://github.com/nfdi4plants/ARC_ontologyontology annotation",
                                    "https://github.com/nfdi4plants/ARC_ontologyterm accession": "http://edamontology.org/operation_3557",
                                    "https://github.com/nfdi4plants/ARC_ontologyterm source REF": "EMBRACE",
                                    "https://github.com/nfdi4plants/ARC_ontologyannotation value": "Imputation"
                                }
                            ]
                        },
                        {
                            "class": "https://github.com/nfdi4plants/ARC_ontologyprocess parameter value",
                            "https://github.com/nfdi4plants/ARC_ontologyhas parameter": [
                                {
                                    "class": "https://github.com/nfdi4plants/ARC_ontologyprotocol parameter",
                                    "https://github.com/nfdi4plants/ARC_ontologyhas parameter name": [
                                        {
                                            "class": "https://github.com/nfdi4plants/ARC_ontologyparameter name",
                                            "https://github.com/nfdi4plants/ARC_ontologyterm accession": "http://edamontology.org/operation_0004",
                                            "https://github.com/nfdi4plants/ARC_ontologyterm source REF": "EMBRACE",
                                            "https://github.com/nfdi4plants/ARC_ontologyannotation value": "Operation"
                                        }
                                    ]
                                }
                            ],
                            "https://github.com/nfdi4plants/ARC_ontologyvalue": [
                                {
                                    "class": "https://github.com/nfdi4plants/ARC_ontologyontology annotation",
                                    "https://github.com/nfdi4plants/ARC_ontologyterm accession": "http://edamontology.org/operation_3557",
                                    "https://github.com/nfdi4plants/ARC_ontologyterm source REF": "EMBRACE",
                                    "https://github.com/nfdi4plants/ARC_ontologyannotation value": "Imputation"
                                }
                            ]
                        },
                        {
                            "class": "https://github.com/nfdi4plants/ARC_ontologyprocess parameter value",
                            "https://github.com/nfdi4plants/ARC_ontologyhas parameter": [
                                {
                                    "class": "https://github.com/nfdi4plants/ARC_ontologyprotocol parameter",
                                    "https://github.com/nfdi4plants/ARC_ontologyhas parameter name": [
                                        {
                                            "class": "https://github.com/nfdi4plants/ARC_ontologyparameter name",
                                            "https://github.com/nfdi4plants/ARC_ontologyterm accession": "http://edamontology.org/operation_0004",
                                            "https://github.com/nfdi4plants/ARC_ontologyterm source REF": "EMBRACE",
                                            "https://github.com/nfdi4plants/ARC_ontologyannotation value": "Operation"
                                        }
                                    ]
                                }
                            ],
                            "https://github.com/nfdi4plants/ARC_ontologyvalue": [
                                {
                                    "class": "https://github.com/nfdi4plants/ARC_ontologyontology annotation",
                                    "https://github.com/nfdi4plants/ARC_ontologyterm accession": "http://edamontology.org/operation_3557",
                                    "https://github.com/nfdi4plants/ARC_ontologyterm source REF": "EMBRACE",
                                    "https://github.com/nfdi4plants/ARC_ontologyannotation value": "Imputation"
                                }
                            ]
                        },
                        {
                            "class": "https://github.com/nfdi4plants/ARC_ontologyprocess parameter value",
                            "https://github.com/nfdi4plants/ARC_ontologyhas parameter": [
                                {
                                    "class": "https://github.com/nfdi4plants/ARC_ontologyprotocol parameter",
                                    "https://github.com/nfdi4plants/ARC_ontologyhas parameter name": [
                                        {
                                            "class": "https://github.com/nfdi4plants/ARC_ontologyparameter name",
                                            "https://github.com/nfdi4plants/ARC_ontologyterm accession": "http://edamontology.org/operation_0004",
                                            "https://github.com/nfdi4plants/ARC_ontologyterm source REF": "EMBRACE",
                                            "https://github.com/nfdi4plants/ARC_ontologyannotation value": "Operation"
                                        }
                                    ]
                                }
                            ],
                            "https://github.com/nfdi4plants/ARC_ontologyvalue": [
                                {
                                    "class": "https://github.com/nfdi4plants/ARC_ontologyontology annotation",
                                    "https://github.com/nfdi4plants/ARC_ontologyterm accession": "http://edamontology.org/operation_3557",
                                    "https://github.com/nfdi4plants/ARC_ontologyterm source REF": "EMBRACE",
                                    "https://github.com/nfdi4plants/ARC_ontologyannotation value": "Imputation"
                                }
                            ]
                        },
                        {
                            "class": "https://github.com/nfdi4plants/ARC_ontologyprocess parameter value",
                            "https://github.com/nfdi4plants/ARC_ontologyhas parameter": [
                                {
                                    "class": "https://github.com/nfdi4plants/ARC_ontologyprotocol parameter",
                                    "https://github.com/nfdi4plants/ARC_ontologyhas parameter name": [
                                        {
                                            "class": "https://github.com/nfdi4plants/ARC_ontologyparameter name",
                                            "https://github.com/nfdi4plants/ARC_ontologyterm accession": "http://edamontology.org/operation_0004",
                                            "https://github.com/nfdi4plants/ARC_ontologyterm source REF": "EMBRACE",
                                            "https://github.com/nfdi4plants/ARC_ontologyannotation value": "Operation"
                                        }
                                    ]
                                }
                            ],
                            "https://github.com/nfdi4plants/ARC_ontologyvalue": [
                                {
                                    "class": "https://github.com/nfdi4plants/ARC_ontologyontology annotation",
                                    "https://github.com/nfdi4plants/ARC_ontologyterm accession": "http://edamontology.org/operation_3557",
                                    "https://github.com/nfdi4plants/ARC_ontologyterm source REF": "EMBRACE",
                                    "https://github.com/nfdi4plants/ARC_ontologyannotation value": "Imputation"
                                }
                            ]
                        },
                        {
                            "class": "https://github.com/nfdi4plants/ARC_ontologyprocess parameter value",
                            "https://github.com/nfdi4plants/ARC_ontologyhas parameter": [
                                {
                                    "class": "https://github.com/nfdi4plants/ARC_ontologyprotocol parameter",
                                    "https://github.com/nfdi4plants/ARC_ontologyhas parameter name": [
                                        {
                                            "class": "https://github.com/nfdi4plants/ARC_ontologyparameter name",
                                            "https://github.com/nfdi4plants/ARC_ontologyterm accession": "http://edamontology.org/operation_0004",
                                            "https://github.com/nfdi4plants/ARC_ontologyterm source REF": "EMBRACE",
                                            "https://github.com/nfdi4plants/ARC_ontologyannotation value": "Operation"
                                        }
                                    ]
                                }
                            ],
                            "https://github.com/nfdi4plants/ARC_ontologyvalue": [
                                {
                                    "class": "https://github.com/nfdi4plants/ARC_ontologyontology annotation",
                                    "https://github.com/nfdi4plants/ARC_ontologyterm accession": "http://edamontology.org/operation_3557",
                                    "https://github.com/nfdi4plants/ARC_ontologyterm source REF": "EMBRACE",
                                    "https://github.com/nfdi4plants/ARC_ontologyannotation value": "Imputation"
                                }
                            ]
                        },
                        {
                            "class": "https://github.com/nfdi4plants/ARC_ontologyprocess parameter value",
                            "https://github.com/nfdi4plants/ARC_ontologyhas parameter": [
                                {
                                    "class": "https://github.com/nfdi4plants/ARC_ontologyprotocol parameter",
                                    "https://github.com/nfdi4plants/ARC_ontologyhas parameter name": [
                                        {
                                            "class": "https://github.com/nfdi4plants/ARC_ontologyparameter name",
                                            "https://github.com/nfdi4plants/ARC_ontologyterm accession": "http://edamontology.org/operation_0004",
                                            "https://github.com/nfdi4plants/ARC_ontologyterm source REF": "EMBRACE",
                                            "https://github.com/nfdi4plants/ARC_ontologyannotation value": "Operation"
                                        }
                                    ]
                                }
                            ],
                            "https://github.com/nfdi4plants/ARC_ontologyvalue": [
                                {
                                    "class": "https://github.com/nfdi4plants/ARC_ontologyontology annotation",
                                    "https://github.com/nfdi4plants/ARC_ontologyterm accession": "http://edamontology.org/operation_3557",
                                    "https://github.com/nfdi4plants/ARC_ontologyterm source REF": "EMBRACE",
                                    "https://github.com/nfdi4plants/ARC_ontologyannotation value": "Imputation"
                                }
                            ]
                        },
                        {
                            "class": "https://github.com/nfdi4plants/ARC_ontologyprocess parameter value",
                            "https://github.com/nfdi4plants/ARC_ontologyhas parameter": [
                                {
                                    "class": "https://github.com/nfdi4plants/ARC_ontologyprotocol parameter",
                                    "https://github.com/nfdi4plants/ARC_ontologyhas parameter name": [
                                        {
                                            "class": "https://github.com/nfdi4plants/ARC_ontologyparameter name",
                                            "https://github.com/nfdi4plants/ARC_ontologyterm accession": "http://edamontology.org/operation_0004",
                                            "https://github.com/nfdi4plants/ARC_ontologyterm source REF": "EMBRACE",
                                            "https://github.com/nfdi4plants/ARC_ontologyannotation value": "Operation"
                                        }
                                    ]
                                }
                            ],
                            "https://github.com/nfdi4plants/ARC_ontologyvalue": [
                                {
                                    "class": "https://github.com/nfdi4plants/ARC_ontologyontology annotation",
                                    "https://github.com/nfdi4plants/ARC_ontologyterm accession": "http://edamontology.org/operation_3557",
                                    "https://github.com/nfdi4plants/ARC_ontologyterm source REF": "EMBRACE",
                                    "https://github.com/nfdi4plants/ARC_ontologyannotation value": "Imputation"
                                }
                            ]
                        },
                        {
                            "class": "https://github.com/nfdi4plants/ARC_ontologyprocess parameter value",
                            "https://github.com/nfdi4plants/ARC_ontologyhas parameter": [
                                {
                                    "class": "https://github.com/nfdi4plants/ARC_ontologyprotocol parameter",
                                    "https://github.com/nfdi4plants/ARC_ontologyhas parameter name": [
                                        {
                                            "class": "https://github.com/nfdi4plants/ARC_ontologyparameter name",
                                            "https://github.com/nfdi4plants/ARC_ontologyterm accession": "http://edamontology.org/operation_0004",
                                            "https://github.com/nfdi4plants/ARC_ontologyterm source REF": "EMBRACE",
                                            "https://github.com/nfdi4plants/ARC_ontologyannotation value": "Operation"
                                        }
                                    ]
                                }
                            ],
                            "https://github.com/nfdi4plants/ARC_ontologyvalue": [
                                {
                                    "class": "https://github.com/nfdi4plants/ARC_ontologyontology annotation",
                                    "https://github.com/nfdi4plants/ARC_ontologyterm accession": "http://edamontology.org/topic_3572",
                                    "https://github.com/nfdi4plants/ARC_ontologyterm source REF": "EMBRACE",
                                    "https://github.com/nfdi4plants/ARC_ontologyannotation value": "Data quality management"
                                }
                            ]
                        },
                        {
                            "class": "https://github.com/nfdi4plants/ARC_ontologyprocess parameter value",
                            "https://github.com/nfdi4plants/ARC_ontologyhas parameter": [
                                {
                                    "class": "https://github.com/nfdi4plants/ARC_ontologyprotocol parameter",
                                    "https://github.com/nfdi4plants/ARC_ontologyhas parameter name": [
                                        {
                                            "class": "https://github.com/nfdi4plants/ARC_ontologyparameter name",
                                            "https://github.com/nfdi4plants/ARC_ontologyterm accession": "http://edamontology.org/operation_0004",
                                            "https://github.com/nfdi4plants/ARC_ontologyterm source REF": "EMBRACE",
                                            "https://github.com/nfdi4plants/ARC_ontologyannotation value": "Operation"
                                        }
                                    ]
                                }
                            ],
                            "https://github.com/nfdi4plants/ARC_ontologyvalue": [
                                {
                                    "class": "https://github.com/nfdi4plants/ARC_ontologyontology annotation",
                                    "https://github.com/nfdi4plants/ARC_ontologyterm accession": "http://edamontology.org/operation_3435",
                                    "https://github.com/nfdi4plants/ARC_ontologyterm source REF": "EMBRACE",
                                    "https://github.com/nfdi4plants/ARC_ontologyannotation value": "Standardisation and normalisation"
                                }
                            ]
                        }
                    ]
                }
            ]
        },
        {
            "class": "CommandLineTool",
            "requirements": [
                {
                    "class": "InitialWorkDirRequirement",
                    "listing": [
                        {
                            "entryname": "transformed.RData",
                            "entry": "$(inputs.transformed_RData)"
                        },
                        {
                            "entryname": "reshaped.RData",
                            "entry": "$(inputs.reshaped_RData)"
                        },
                        {
                            "entryname": "map_icasa.R",
                            "entry": "load(\"transformed.RData\")\nload(\"reshaped.RData\")\n\nlibrary(csmTools)\nBNR_full <- list(GENERAL = GENERAL,\n                 FIELDS = FIELDS,\n                 TREATMENTS = TREATMENTS,\n                 INITIAL_CONDITIONS = INITIAL_CONDITIONS,\n                 TILLAGE = seehausen_fmt$BODENBEARBEITUNG,\n                 PLANTING_DETAILS = PLANTINGS,\n                 CULTIVARS = CULTIVARS,\n                 FERTILIZERS = FERTILIZERS,\n                 RESIDUES = ORGANIC_MATERIALS, \n                 IRRIGATION = seehausen_fmt$BEREGNUNG,\n                 CHEMICALS = seehausen_fmt$PFLANZENSCHUTZ,\n                 HARVEST = HARVEST,\n                 OBSERVED_Summary = OBSERVED_Summary,\n                 OBSERVED_TimeSeries = OBSERVED_TimeSeries)\n\n# Transfer metadata attributes to new dataframe\nattr(BNR_full, \"EXP_DETAILS\") <- attr(seehausen_fmt, \"EXP_DETAILS\")\nattr(BNR_full, \"SITE_CODE\") <- attr(seehausen_fmt, \"SITE_CODE\")\n\n\n# Apply mappings (currently, only exaxt matches headers, codes and unit conversions)\nBNR_mapped <- BNR_full\nfor (i in seq_along(names(BNR_full))) {\n  BNR_mapped[[i]] <- map_data(df = BNR_full[[i]],\n                              tbl_name = names(BNR_full)[i],\n                              map = bnr_seehausen_icasa,\n                              keep_unmapped = FALSE,\n                              col_exempt = \"Year\")\n}\n\nsave(BNR_mapped, file=\"mapped_icasa.RData\")"
                        }
                    ]
                },
                {
                    "class": "DockerRequirement",
                    "dockerFile": "FROM rocker/r-ver:4.4\n\nRUN apt-get update && apt-get install -y git sudo wget\n\nRUN wget https://raw.githubusercontent.com/fairagro/uc6_csmTools/feature/package_management/install_requirements.sh\nRUN chmod +x ./install_requirements.sh && ./install_requirements.sh\n\nRUN wget https://raw.githubusercontent.com/fairagro/uc6_csmTools/feature/package_management/install_dssat.sh\nRUN chmod +x ./install_dssat.sh && ./install_dssat.sh /usr/local/dssat\n\nRUN R -e 'install.packages(\"devtools\")'\nRUN R -e 'install.packages(\"optparse\")'\nRUN R -e 'devtools::install_github(\"fairagro/uc6_csmTools@feature/package_management\")'",
                    "dockerImageId": "uc6_arc"
                }
            ],
            "inputs": [
                {
                    "id": "#map_icasa.cwl/transformed_RData",
                    "type": "File"
                },
                {
                    "id": "#map_icasa.cwl/reshaped_RData",
                    "type": "File"
                }
            ],
            "outputs": [
                {
                    "id": "#map_icasa.cwl/mapped_icasa.RData",
                    "type": "File",
                    "outputBinding": {
                        "glob": "mapped_icasa.RData"
                    }
                }
            ],
            "baseCommand": [
                "Rscript",
                "map_icasa.R"
            ],
            "id": "#map_icasa.cwl"
        },
        {
            "class": "CommandLineTool",
            "requirements": [
                {
                    "class": "InitialWorkDirRequirement",
                    "listing": [
                        {
                            "entryname": "soil_data.RData",
                            "entry": "$(inputs.soil_data_RData)"
                        },
                        {
                            "entryname": "mapped_weather.RData",
                            "entry": "$(inputs.mapped_weather_RData)"
                        },
                        {
                            "entryname": "map_soil_data.R",
                            "entry": "load(\"soil_data.RData\")\nload(\"mapped_weather.RData\")\n\nBNR_mapped$SOIL_Layers <- SOIL_Layers  # TODO: ?integrate weather mapping with other data?\nBNR_mapped$SOIL_Header <- SOIL_Header\n\nsave(BNR_mapped, file=\"mapped_soil.RData\")"
                        }
                    ]
                },
                {
                    "class": "DockerRequirement",
                    "dockerFile": "FROM rocker/r-ver:4.4\n\nRUN apt-get update && apt-get install -y git sudo wget\n\nRUN wget https://raw.githubusercontent.com/fairagro/uc6_csmTools/feature/package_management/install_requirements.sh\nRUN chmod +x ./install_requirements.sh && ./install_requirements.sh\n\nRUN wget https://raw.githubusercontent.com/fairagro/uc6_csmTools/feature/package_management/install_dssat.sh\nRUN chmod +x ./install_dssat.sh && ./install_dssat.sh /usr/local/dssat\n\nRUN R -e 'install.packages(\"devtools\")'\nRUN R -e 'install.packages(\"optparse\")'\nRUN R -e 'devtools::install_github(\"fairagro/uc6_csmTools@feature/package_management\")'",
                    "dockerImageId": "uc6_arc"
                }
            ],
            "inputs": [
                {
                    "id": "#map_soil_data.cwl/soil_data_RData",
                    "type": "File"
                },
                {
                    "id": "#map_soil_data.cwl/mapped_weather_RData",
                    "type": "File"
                }
            ],
            "outputs": [
                {
                    "id": "#map_soil_data.cwl/mapped_soil.RData",
                    "type": "File",
                    "outputBinding": {
                        "glob": "mapped_soil.RData"
                    }
                }
            ],
            "baseCommand": [
                "Rscript",
                "map_soil_data.R"
            ],
            "id": "#map_soil_data.cwl"
        },
        {
            "class": "CommandLineTool",
            "requirements": [
                {
                    "class": "InitialWorkDirRequirement",
                    "listing": [
                        {
                            "entryname": "weather_stations.RData",
                            "entry": "$(inputs.weather_stations_RData)"
                        },
                        {
                            "entryname": "mapped_icasa.RData",
                            "entry": "$(inputs.mapped_icasa_RData)"
                        },
                        {
                            "entryname": "map_weather.R",
                            "entry": "load(\"weather_stations.RData\")\nload(\"mapped_icasa.RData\")\n\nlibrary(dplyr)\nlibrary(csmTools)\n\nWEATHER_Daily <- WEATHER_raw$data %>% \n  mutate(WST_ID = \"SEDE\") %>%\n  relocate(WST_ID, .before = everything())\n\n# TODO: implement metadata mapping inside get_weather() function\nWEATHER_Header <- lapply(names(WEATHER_raw$metadata), function(df_name){\n  \n  df <- WEATHER_raw$metadata[[df_name]]\n  \n  if (length(unique(df$wst_id)) == 1) {\n    data.frame(Year = gsub(\"Y\", \"\", df_name),\n               WST_ID = \"SEDE\",\n               WST_LAT = df$wst_lat[1],\n               WST_LONG = df$wst_lon[1],\n               WST_ELEV = df$wst_elev[1],\n               TAV = df$TAV[1],\n               TAMP = df$AMP[1],\n               REFHT = 2, WNDHT = 2)  # so far not extractable for DWD metadata\n  } else {\n    data.frame(Year = gsub(\"Y\", \"\", df_name),\n               WST_ID = \"SEDE\",\n               WST_LAT = mean(df$wst_lat),\n               WST_LONG = mean(df$wst_lon),\n               WST_ELEV = mean(df$wst_elev),  # TODO: add note that data is drawn from multiple stations\n               TAV = df$TAV[1],\n               TAMP = df$AMP[1],\n               REFHT = 2, WNDHT = 2)  # so far not extractable for DWD metadata\n  }\n}) %>%\n  do.call(rbind, .)\n\nWEATHER_comments <- lapply(WEATHER_raw$metadata, function(df) {\n  df <- df %>%\n    select(-res) %>%\n    collapse_cols(\"var\") %>%\n    mutate(comments = paste0(var, \": Station \", wst_id, \" - \", wst_name, \" (\", wst_lat, \" \",\n                             wst_lon, \"; ELEV = \", wst_elev, \" m); Distance from site: \",\n                             round(dist, 1), \" km\"))\n  return(df$comments)\n} )\n\nBNR_mapped$WEATHER_Daily <- WEATHER_Daily  # TODO: ?integrate weather mapping with other data?\nBNR_mapped$WEATHER_Header <- WEATHER_Header\n\n\nsave(BNR_mapped, file=\"mapped_weather.RData\")\nsave(WEATHER_comments, file=\"weather_comments.RData\")"
                        }
                    ]
                },
                {
                    "class": "DockerRequirement",
                    "dockerFile": "FROM rocker/r-ver:4.4\n\nRUN apt-get update && apt-get install -y git sudo wget\n\nRUN wget https://raw.githubusercontent.com/fairagro/uc6_csmTools/feature/package_management/install_requirements.sh\nRUN chmod +x ./install_requirements.sh && ./install_requirements.sh\n\nRUN wget https://raw.githubusercontent.com/fairagro/uc6_csmTools/feature/package_management/install_dssat.sh\nRUN chmod +x ./install_dssat.sh && ./install_dssat.sh /usr/local/dssat\n\nRUN R -e 'install.packages(\"devtools\")'\nRUN R -e 'install.packages(\"optparse\")'\nRUN R -e 'devtools::install_github(\"fairagro/uc6_csmTools@feature/package_management\")'",
                    "dockerImageId": "uc6_arc"
                }
            ],
            "inputs": [
                {
                    "id": "#map_weather.cwl/weather_stations_RData",
                    "type": "File"
                },
                {
                    "id": "#map_weather.cwl/mapped_icasa_RData",
                    "type": "File"
                }
            ],
            "outputs": [
                {
                    "id": "#map_weather.cwl/mapped_weather.RData",
                    "type": "File",
                    "outputBinding": {
                        "glob": "mapped_weather.RData"
                    }
                },
                {
                    "id": "#map_weather.cwl/weather_comments.RData",
                    "type": "File",
                    "outputBinding": {
                        "glob": "weather_comments.RData"
                    }
                }
            ],
            "baseCommand": [
                "Rscript",
                "map_weather.R"
            ],
            "id": "#map_weather.cwl"
        },
        {
            "class": "CommandLineTool",
            "requirements": [
                {
                    "class": "InitialWorkDirRequirement",
                    "listing": [
                        {
                            "entryname": "format_dssat.RData",
                            "entry": "$(inputs.format_dssat_RData)"
                        },
                        {
                            "entryname": "plot_results.R",
                            "entry": "parser <- optparse::OptionParser()\nparser <- optparse::add_option(parser, c(\"-s\", \"--simulation_dir\"), type=\"character\", help=\"Directory with Sim Output\")\nopt <- optparse::parse_args(parser)\n\nload(\"format_dssat.RData\")\nlibrary(DSSAT)\nlibrary(ggplot2)\nlibrary(dplyr)\n\n# ==== Result plots -------------------------------------------------------\n\n\n# TODO: eventually a wrapper for plotting essential results likes the obs vs. sim comparisons\n# Should link to the input data to retrieve treatment names and levels\n# Plot results: phenology\n\nlteSe_sim_growth <- read_output(file_name = paste0(opt$simulation_dir,\"/PlantGro.OUT\"))\n\n# Format observed data for plotting\nlteSe_obs_growth <- BNR_yr_merged$Y1995$FILEA %>%\n  filter(TRTNO %in% 1:4) %>%\n  mutate(MDAT = as.POSIXct(as.Date(MDAT, format = \"%y%j\")),\n         ADAT = as.POSIXct(as.Date(ADAT, format = \"%y%j\")))\n\n# Plot results: yield\nlteSe_sim_growth %>%\n  mutate(TRNO = as.factor(TRNO)) %>%\n  ggplot(aes(x = DATE, y = GWAD)) +\n  # Line plot for simulated data\n  geom_line(aes(group = TRNO, colour = TRNO, linewidth = \"Simulated\")) +\n  # Points for observed data\n  geom_point(data = lteSe_obs_growth, aes(x = MDAT, y = HWAH, colour = as.factor(TRTNO), size = \"Observed\"), \n             shape = 20) +  # obs yield at harvest\n  # General appearance\n  scale_colour_manual(name = \"Fertilization (kg[N]/ha)\",\n                    breaks = c(\"1\",\"2\",\"3\",\"4\"),\n                    labels = c(\"0\",\"100\",\"200\",\"300\"),\n                    values = c(\"#20854E\",\"#FFDC91\", \"#E18727\", \"#BC3C29\")) +\n  scale_size_manual(values = c(\"Simulated\" = 1, \"Observed\" = 2), limits = c(\"Simulated\", \"Observed\")) +\n  scale_linewidth_manual(values = c(\"Simulated\" = 1, \"Observed\" = 2), limits = c(\"Simulated\", \"Observed\")) +\n  labs(size = NULL, linewidth = NULL, y = \"Yield (kg/ha)\") +\n  guides(\n    size = guide_legend(\n      override.aes = list(linetype = c(\"solid\", \"blank\"), shape = c(NA, 16))\n    )\n  ) +\n  theme_bw() + \n  theme(legend.text = element_text(size = 8), legend.title = element_text(size = 8),\n        axis.title.x = element_blank(), axis.title.y = element_text(size = 10),\n        axis.text = element_text(size = 9, colour = \"black\"))\n\n# Plot results: phenology\nlteSe_sim_growth %>%\n  mutate(TRNO = as.factor(TRNO)) %>%\n  ggplot(aes(x = DATE, y = DCCD)) +\n  # Zadoks lines for comparison\n  geom_hline(yintercept = 69, linetype = \"dashed\", colour = \"black\") +  # anthesis date (Zadoks65)\n  geom_hline(yintercept = 95, linetype = \"dashed\", colour = \"black\") +  # maturity date (Zadoks95)\n  # Line plot for simulated data\n  geom_line(aes(group = TRNO, colour = TRNO, linewidth = \"Simulated\")) +\n  # Points for observed data\n  geom_point(data = lteSe_obs_growth, aes(x = ADAT, y = 69, colour = as.factor(TRTNO), size = \"Observed\"),\n             shape = 20) +  # obs anthesis date (Zadosk65)\n  geom_point(data = lteSe_obs_growth, aes(x = MDAT, y = 95, colour = as.factor(TRTNO), size = \"Observed\"),\n             shape = 20) +  # obs maturity data (Zadoks95)\n  # General appearance\n  scale_colour_manual(name = \"Fertilization (kg[N]/ha)\",\n                      breaks = c(\"1\",\"2\",\"3\",\"4\"),\n                      labels = c(\"0\",\"100\",\"200\",\"300\"),\n                      values = c(\"#20854E\",\"#FFDC91\", \"#E18727\", \"#BC3C29\")) +\n  scale_size_manual(values = c(\"Simulated\" = 1, \"Observed\" = 2), limits = c(\"Simulated\", \"Observed\")) +\n  scale_linewidth_manual(values = c(\"Simulated\" = 1, \"Observed\" = 2), limits = c(\"Simulated\", \"Observed\")) +\n  labs(size = NULL, linewidth = NULL, y = \"Zadoks scale\") +\n  guides(\n    size = guide_legend(\n      override.aes = list(linetype = c(\"solid\", \"blank\"), shape = c(NA, 16))\n    )\n  ) +\n  theme_bw() + \n  theme(legend.text = element_text(size = 8), legend.title = element_text(size = 8),\n        axis.title.x = element_blank(), axis.title.y = element_text(size = 10),\n        axis.text = element_text(size = 9, colour = \"black\"))\n\n# Results are off, but it works!\n\n#' @exportHint Rplots.pdf"
                        }
                    ]
                },
                {
                    "class": "DockerRequirement",
                    "dockerFile": "FROM rocker/r-ver:4.4\n\nRUN apt-get update && apt-get install -y git sudo wget\n\nRUN wget https://raw.githubusercontent.com/fairagro/uc6_csmTools/feature/package_management/install_requirements.sh\nRUN chmod +x ./install_requirements.sh && ./install_requirements.sh\n\nRUN wget https://raw.githubusercontent.com/fairagro/uc6_csmTools/feature/package_management/install_dssat.sh\nRUN chmod +x ./install_dssat.sh && ./install_dssat.sh /usr/local/dssat\n\nRUN R -e 'install.packages(\"devtools\")'\nRUN R -e 'install.packages(\"optparse\")'\nRUN R -e 'devtools::install_github(\"fairagro/uc6_csmTools@feature/package_management\")'",
                    "dockerImageId": "uc6_arc"
                }
            ],
            "inputs": [
                {
                    "id": "#plot_results.cwl/simulation_dir",
                    "type": "Directory",
                    "inputBinding": {
                        "prefix": "--simulation_dir"
                    }
                },
                {
                    "id": "#plot_results.cwl/format_dssat_RData",
                    "type": "File"
                }
            ],
            "outputs": [
                {
                    "id": "#plot_results.cwl/Rplots.pdf",
                    "type": "File",
                    "outputBinding": {
                        "glob": "Rplots.pdf"
                    }
                }
            ],
            "baseCommand": [
                "Rscript",
                "plot_results.R"
            ],
            "id": "#plot_results.cwl"
        },
        {
            "class": "CommandLineTool",
            "requirements": [
                {
                    "class": "InitialWorkDirRequirement",
                    "listing": [
                        {
                            "entryname": "preprocess_data.R",
                            "entry": "parser <- optparse::OptionParser()\nparser <- optparse::add_option(parser, c(\"-d\", \"--data\"), type=\"character\", help=\"Path to the experimental data directory\")\nopt <- optparse::parse_args(parser)\n\npath = paste0(opt$data, \"/\")\ndb_files <- list.files(path = path, pattern = \"\\\\.csv$\")\ndb_paths <- sapply(db_files, function(x){ paste0(path, x) })\ndb_list <- lapply(db_paths, function(x) { file <- read.csv(x, fileEncoding = \"iso-8859-1\") })\n\n# Simplify names\nnames(db_list) <- stringr::str_extract(names(db_list), \"_V[0-9]+_[0-9]+_(.*)\") # cut names after version number\nnames(db_list) <- gsub(\"_V[0-9]+_[0-9]+_\", \"\", names(db_list)) # drop version number,\nnames(db_list) <- sub(\"\\\\..*$\", \"\", names(db_list)) # drop file extension\n\nsave(db_list, file=\"preprocessed.RData\")"
                        }
                    ]
                },
                {
                    "class": "DockerRequirement",
                    "dockerFile": "FROM rocker/r-ver:4.4\n\nRUN apt-get update && apt-get install -y git sudo wget\n\nRUN wget https://raw.githubusercontent.com/fairagro/uc6_csmTools/feature/package_management/install_requirements.sh\nRUN chmod +x ./install_requirements.sh && ./install_requirements.sh\n\nRUN wget https://raw.githubusercontent.com/fairagro/uc6_csmTools/feature/package_management/install_dssat.sh\nRUN chmod +x ./install_dssat.sh && ./install_dssat.sh /usr/local/dssat\n\nRUN R -e 'install.packages(\"devtools\")'\nRUN R -e 'install.packages(\"optparse\")'\nRUN R -e 'devtools::install_github(\"fairagro/uc6_csmTools@feature/package_management\")'",
                    "dockerImageId": "uc6_arc"
                }
            ],
            "inputs": [
                {
                    "id": "#preprocess_data.cwl/data",
                    "type": "Directory",
                    "inputBinding": {
                        "prefix": "--data"
                    }
                }
            ],
            "outputs": [
                {
                    "id": "#preprocess_data.cwl/preprocessed.RData",
                    "type": "File",
                    "outputBinding": {
                        "glob": "preprocessed.RData"
                    }
                }
            ],
            "baseCommand": [
                "Rscript",
                "preprocess_data.R"
            ],
            "id": "#preprocess_data.cwl"
        },
        {
            "class": "CommandLineTool",
            "requirements": [
                {
                    "class": "InitialWorkDirRequirement",
                    "listing": [
                        {
                            "entryname": "preprocessed.RData",
                            "entry": "$(inputs.preprocessed_RData)"
                        },
                        {
                            "entryname": "metadata.RData",
                            "entry": "$(inputs.metadata_RData)"
                        },
                        {
                            "entryname": "reshape_data.R",
                            "entry": "load(\"preprocessed.RData\")\nload(\"metadata.RData\")\n\nlibrary(csmTools)\nlibrary(dplyr)\n\nseehausen_fmt <- reshape_exp_data(db = db_list, metadata = metadata, mother_tbl = db_list$VERSUCHSAUFBAU)\n\nsave(seehausen_fmt, file=\"reshaped.RData\")"
                        }
                    ]
                },
                {
                    "class": "DockerRequirement",
                    "dockerFile": "FROM rocker/r-ver:4.4\n\nRUN apt-get update && apt-get install -y git sudo wget\n\nRUN wget https://raw.githubusercontent.com/fairagro/uc6_csmTools/feature/package_management/install_requirements.sh\nRUN chmod +x ./install_requirements.sh && ./install_requirements.sh\n\nRUN wget https://raw.githubusercontent.com/fairagro/uc6_csmTools/feature/package_management/install_dssat.sh\nRUN chmod +x ./install_dssat.sh && ./install_dssat.sh /usr/local/dssat\n\nRUN R -e 'install.packages(\"devtools\")'\nRUN R -e 'install.packages(\"optparse\")'\nRUN R -e 'devtools::install_github(\"fairagro/uc6_csmTools@feature/package_management\")'",
                    "dockerImageId": "uc6_arc"
                }
            ],
            "inputs": [
                {
                    "id": "#reshape_data.cwl/preprocessed_RData",
                    "type": "File"
                },
                {
                    "id": "#reshape_data.cwl/metadata_RData",
                    "type": "File"
                }
            ],
            "outputs": [
                {
                    "id": "#reshape_data.cwl/reshaped.RData",
                    "type": "File",
                    "outputBinding": {
                        "glob": "reshaped.RData"
                    }
                }
            ],
            "baseCommand": [
                "Rscript",
                "reshape_data.R"
            ],
            "id": "#reshape_data.cwl"
        },
        {
            "class": "CommandLineTool",
            "requirements": [
                {
                    "class": "InitialWorkDirRequirement",
                    "listing": [
                        {
                            "entryname": "format_dssat.RData",
                            "entry": "$(inputs.format_dssat_RData)"
                        },
                        {
                            "entryname": "simulation.R",
                            "entry": "parser <- optparse::OptionParser()\nparser <- optparse::add_option(parser, c(\"-s\", \"--sol\"), type=\"character\", help=\"Path to the SEDE.SOL file\")\nparser <- optparse::add_option(parser, c(\"-l\", \"--soil\"), type=\"character\", help=\"Path to the SOIL.SOL file\")\nopt <- optparse::parse_args(parser)\n\nload(\"format_dssat.RData\")\nfile.copy(opt$sol, \"SEDE.SOL\")\nfile.copy(opt$soil, \"SOIL.SOL\")\n\nlibrary(DSSAT)\nlibrary(lubridate)\nlibrary(csmTools)\n\n# Simulations -------------------------------------------------------------\n\ndssat_dir <- \"/usr/local/dssat\"\noptions(DSSAT.CSM = \"/usr/local/dssat/dscsm048\")\nlist.files(dssat_dir)\n\n# ==== Input data adjustments ---------------------------------------------\n\n# Set missing required variables\n# NB: this is a temporary fix, should be done in the build functions with robust estimation methods + warning\n# (imputation sould be documented in the input files as notes)\nlteSe_1995_filex <- BNR_yr_merged$Y1995$FILEX\nlteSe_1995_filex$PLANTING_DETAILS$PLDP <- 5.5  # planting depth\n\nlteSe_1995_filex$TILLAGE$TDEP <- \n  ifelse(lteSe_1995_filex$TILLAGE$TIMPL == \"TI038\", 2.5, lteSe_1995_filex$TILLAGE$TDEP)  # missing tillage depth\nlteSe_1995_filex$FERTILIZERS$FDEP <- 10  # fertilizer application depth\n\n# Add cultivar to the cultivar file\n# NB: parameter fitting script should be used eventually, for now we use a median cultivar based on the provided\n# minima and maxima for genetic parameters\n\nwhaps_cul <- read_cul(paste0(dssat_dir, \"/Genotype/WHAPS048.CUL\"))\n\ncul_median_pars <- apply(whaps_cul[1:2, 5:ncol(whaps_cul)], 2, function(x) sum(x)/2)\n\ntry(whaps_cul <- add_cultivar(whaps_cul,  # if the cultivar is still in the file (error) just ignore and move on \n                          ccode = \"IB9999\", \n                          cname = \"Borenos\",\n                          ecode = \"IB0001\",\n                          ppars = as.numeric(cul_median_pars[1:5]),\n                          gpars = as.numeric(cul_median_pars[6:ncol(whaps_cul)]))\n) # errored as commented, just wrap into a try() function\nlteSe_1995_filex$CULTIVARS$INGENO <- \"IB9999\"  # cultivat code in file X links to cultivar file\n\nwrite_cul(whaps_cul, \"WHAPS048.CUL\")  # export the updated file\n\n\n# Set simulation controls\n\n# Simulation start date: by default at the earliest management event carried out\nall_dates <- na.omit(  # ignore warning\n  as.POSIXct(\n    as.numeric(\n  unlist(lapply(lteSe_1995_filex, function(df) {\n    df[grepl(\"DAT\", colnames(df))]\n  }), use.names = FALSE)\n)))\nlteSe_1995_filex$SIMULATION_CONTROLS$SDATE <- min(all_dates)\n\n# Set simulation options\nlteSe_1995_filex$SIMULATION_CONTROLS$WATER <- \"Y\"  # water (rain/irrigation)\nlteSe_1995_filex$SIMULATION_CONTROLS$NITRO <- \"Y\"  # nitrogen\nlteSe_1995_filex$SIMULATION_CONTROLS$CHEM <- \"Y\"  # chemicals\nlteSe_1995_filex$SIMULATION_CONTROLS$TILL <- \"Y\"  # tillage\n\n# Set management settings\nlteSe_1995_filex$SIMULATION_CONTROLS$FERTI <- \"R\"  # fertilizer application: on reported dates (R)\nlteSe_1995_filex$SIMULATION_CONTROLS$HARVS <- \"R\"  # harvest: on reported dates (R)\n\n# Set model (for this example we use NWheat)\nlteSe_1995_filex$SIMULATION_CONTROLS$SMODEL <- \"WHAPS\"  # NWheat code, from DSSAT source code\nlteSe_1995_filex$SIMULATION_CONTROLS$PHOTO <- \"C\"  # photosynthesis method set to canopy curve as required by NWheat\n\n# Set output files options (only growth for this example)\nlteSe_1995_filex$SIMULATION_CONTROLS$GROUT <- \"Y\"\nlteSe_1995_filex$SIMULATION_CONTROLS$VBOSE <- \"Y\"  # verbose \n\n# Write example data files (X, A, T) in the simulation directory\n# Prototype data: seehausen LTE, year 1995 (wheat - rainfed)\nwrite_filex(lteSe_1995_filex, \"SEDE9501.WHX\") # ignore warnings\nwrite_filea(BNR_yr_merged$Y1995$FILEA, \"SEDE9501.WHA\")\n\n# Weather, soil and cultivar files must be located within the DSSAT CSM directory (locally installed)\n# For weather files, two years may be required if management events took place in the fall/winter preceding\n# the harvest years (typically planting/tillage)\nunique(year(all_dates))  # 1994, 1995 ==> two weather files required\n\nwrite_wth2(BNR_yr_merged$Y1994$WTH, \"SEDE9401.WTH\")\nwrite_wth2(BNR_yr_merged$Y1995$WTH, \"SEDE9501.WTH\")\n\n# Soil profile not copied as generic soil was used in this example(already in DSSAT Soil directory)\n#write_sol(BNR_yr_merged$Y1995$WTH, paste0(sim_wd, \"Soil/SEDE.SOL\"))  # soil profile\n\nbatch_tbl <- data.frame(FILEX = \"SEDE9501.WHX\",\n                        TRTNO = 1:4,\n                        RP = 1,\n                        SQ = 0,\n                        OP = 0,\n                        CO = 0)\n\n# Write example batch file\nwrite_dssbatch(batch_tbl)\n# Run simulations\nrun_dssat(run_mode = \"B\")\n\n#' @exportHint /"
                        }
                    ]
                },
                {
                    "class": "DockerRequirement",
                    "dockerFile": "FROM rocker/r-ver:4.4\n\nRUN apt-get update && apt-get install -y git sudo wget\n\nRUN wget https://raw.githubusercontent.com/fairagro/uc6_csmTools/feature/package_management/install_requirements.sh\nRUN chmod +x ./install_requirements.sh && ./install_requirements.sh\n\nRUN wget https://raw.githubusercontent.com/fairagro/uc6_csmTools/feature/package_management/install_dssat.sh\nRUN chmod +x ./install_dssat.sh && ./install_dssat.sh /usr/local/dssat\n\nRUN R -e 'install.packages(\"devtools\")'\nRUN R -e 'install.packages(\"optparse\")'\nRUN R -e 'devtools::install_github(\"fairagro/uc6_csmTools@feature/package_management\")'",
                    "dockerImageId": "uc6_arc"
                }
            ],
            "inputs": [
                {
                    "id": "#simulation.cwl/sol",
                    "type": "File",
                    "inputBinding": {
                        "prefix": "--sol"
                    }
                },
                {
                    "id": "#simulation.cwl/soil",
                    "type": "File",
                    "inputBinding": {
                        "prefix": "--soil"
                    }
                },
                {
                    "id": "#simulation.cwl/format_dssat_RData",
                    "type": "File"
                }
            ],
            "outputs": [
                {
                    "id": "#simulation.cwl/output",
                    "type": "Directory",
                    "outputBinding": {
                        "glob": "$(runtime.outdir)"
                    }
                }
            ],
            "baseCommand": [
                "Rscript",
                "simulation.R"
            ],
            "id": "#simulation.cwl"
        },
        {
            "class": "CommandLineTool",
            "requirements": [
                {
                    "class": "InitialWorkDirRequirement",
                    "listing": [
                        {
                            "entryname": "test_results.R",
                            "entry": "parser <- optparse::OptionParser()\nparser <- optparse::add_option(parser, c(\"-s\", \"--simulation_dir\"), type=\"character\", help=\"Directory with Sim Output\")\nopt <- optparse::parse_args(parser)\n\nlibrary(DSSAT) \nlibrary(csmTools)\nlibrary(testthat)\n\nexpect_equal_by_last_digit <- function(actual, expected) {\n    if (!is.numeric(actual) || !is.numeric(expected)) {\n        stop(\"Both arguments must be numeric\")\n    }\n\n    # Function to determine the number of decimal places\n    get_decimal_places <- function(num) {\n        if (num %% 1 == 0) {\n            return(0)\n        } else {\n            return(nchar(strsplit(as.character(num), \"\\\\.\")[[1]][2]))\n        }\n    }\n\n    # Determine the maximum number of decimal places between actual and expected\n    decimal_places_actual <- get_decimal_places(actual)\n    decimal_places_expected <- get_decimal_places(expected)\n    max_decimal_places <- max(decimal_places_actual, decimal_places_expected)\n\n    # Calculate the tolerance\n    tolerance <- 10^(-max_decimal_places) * (1 + 1e-8) # floating point precision, multiply tolerance by 1.00000001\n    difference <- abs(actual - expected)\n    expect_true(difference <= tolerance, info = sprintf(\"Expected %s to differ from %s only in the last digit (%s) - difference is %s\", actual, expected, tolerance, difference))\n}\n\nis_numeric <- function(inpt) {\n    # suppress warning: NAs introduced by coercion \n    return (suppressWarnings(!is.na(as.numeric(inpt))))\n}\n\nfile <- paste0(opt$simulation_dir, \"/PlantGro.OUT\")\ntest_that(\"PlantGro.OUT is plausible\", {\n    valid <- system.file(\"extdata/test_fixtures/PlantGro.OUT\", package = \"csmTools\")\n\n    expected <- DSSAT::read_output(file_name = valid)\n    actual <- DSSAT::read_output(file_name = file)\n\n    for (i in 1:nrow(expected)) {\n        for (j in 1:ncol(expected)) {\n            if (is_numeric(expected[i, j]) && is_numeric(actual[i, j])) {\n                expect_equal_by_last_digit(as.numeric(actual[i, j]), as.numeric(expected[i, j]))\n            } else {\n                expect_equal(expected[i, j], actual[i, j])\n            }\n        }\n    }\n})\n"
                        }
                    ]
                },
                {
                    "class": "DockerRequirement",
                    "dockerFile": "FROM rocker/r-ver:4.4\n\nRUN apt-get update && apt-get install -y git sudo wget\n\nRUN wget https://raw.githubusercontent.com/fairagro/uc6_csmTools/feature/package_management/install_requirements.sh\nRUN chmod +x ./install_requirements.sh && ./install_requirements.sh\n\nRUN wget https://raw.githubusercontent.com/fairagro/uc6_csmTools/feature/package_management/install_dssat.sh\nRUN chmod +x ./install_dssat.sh && ./install_dssat.sh /usr/local/dssat\n\nRUN R -e 'install.packages(\"devtools\")'\nRUN R -e 'install.packages(\"optparse\")'\nRUN R -e 'devtools::install_github(\"fairagro/uc6_csmTools@feature/package_management\")'",
                    "dockerImageId": "uc6_arc"
                }
            ],
            "inputs": [
                {
                    "id": "#test_results.cwl/simulation_dir",
                    "type": "Directory",
                    "inputBinding": {
                        "prefix": "--simulation_dir"
                    }
                }
            ],
            "outputs": [],
            "baseCommand": [
                "Rscript",
                "test_results.R"
            ],
            "id": "#test_results.cwl"
        },
        {
            "class": "CommandLineTool",
            "requirements": [
                {
                    "class": "InitialWorkDirRequirement",
                    "listing": [
                        {
                            "entryname": "reshaped.RData",
                            "entry": "$(inputs.reshaped_RData)"
                        },
                        {
                            "entryname": "transform_data.R",
                            "entry": "load(\"reshaped.RData\")\n\nlibrary(dplyr)\nlibrary(lubridate)\nlibrary(tidyr)\n\n# Advanced data transformation --------------------------------------\n\n#' Files that are currently used for data mapping only handle exact matches between variables and unit conversion.\n#' Producing advanced mapping standards and functions to handles more complex transformations (e.g., concatenation of\n#' n columns, conditional variable naming, etc.) will be the main focus in early 2024. For now, we used the example\n#' dataset to retrieve and manually transform the data. The information collected in such examples will be exploited\n#' to design the mapping standards and functions. These specific adjustments are provided below with descriptions.\n\n# ==== GENERAL section ----------------------------------------------------\n\n\nGENERAL <- seehausen_fmt$GENERAL %>%\n  mutate(SITE_NAME = paste(SITE, COUNTRY, sep = \", \"))\n\n\n\n# ==== FIELDS table -------------------------------------------------------\n\n\nFIELDS <- seehausen_fmt$FIELDS %>%\n  mutate(FLELE = (PARZELLE.Hoehenlage_Min+PARZELLE.Hoehenlage_Max)/2) %>%  #? Make mutate fun that replaces components\n  mutate(SOIL_ID = \"IB00000001\",  # Currently generic soil is used\n         WEATHER_ID = \"SEDE\")  # Institute + Site: TU Munich, Muenchenberg\n  \n\n\n# ==== INITIAL CONDITIONS tables ------------------------------------------\n\nINITIAL_CONDITIONS <- seehausen_fmt$OTHER_FRUCHTFOLGE %>% arrange(seehausen_fmt$OTHER_FRUCHTFOLGE, Year)\n\nINITIAL_CONDITIONS$ICPCR <- NA\nfor (i in 2:nrow(INITIAL_CONDITIONS)) {\n  if (INITIAL_CONDITIONS[[\"Year\"]][i] - 1 == INITIAL_CONDITIONS[[\"Year\"]][i-1]) {\n    INITIAL_CONDITIONS$ICPCR[i] <- INITIAL_CONDITIONS$KULTUR.Kultur_Englisch[i-1]\n  }\n}\n\nINITIAL_CONDITIONS <- INITIAL_CONDITIONS %>%\n  group_by(Year, ICPCR) %>%\n  mutate(IC_ID = cur_group_id()) %>% ungroup() %>%\n  select(IC_ID, Year, KULTUR.Kultur_Englisch, ICPCR) %>%\n  arrange(IC_ID)\n  \n\n# ==== HARVEST table ------------------------------------------------------\n\nHARVEST <- bind_rows(\n  seehausen_fmt$OBSERVED_TimeSeries %>%\n    select(Year, Plot_id, TRTNO, starts_with(c(\"ERNTE\",\"TECHNIK\"))),\n  seehausen_fmt$OBSERVED_Summary %>%\n    select(Year, Plot_id, TRTNO, starts_with(c(\"ERNTE\",\"TECHNIK\")))\n) %>%\n  # Drop all records with only NAs in the harvest categories\n  # Those were created when splitting the BNR Harvest table into Observed summary and time series \n  # and then merging with observed data from other tables\n  filter(!if_all(all_of(setdiff(names(.), c(\"Plot_id\", \"Year\", \"TRTNO\"))), is.na)) %>%\n  # Rank different date within year and treatment in decreasing order to separate i-s and e-o-s harvests\n  # Currently assumes that all plots have been harvested e-o-s.\n  # TODO: add a crop specific control to check whether dates are realistic?\n  group_by(Plot_id, Year, TRTNO) %>%\n  mutate(HA_type = ifelse(\n    dense_rank(desc(as_date(ERNTE.Termin))) > 1, \"is\", \"eos\")) %>% ungroup() %>%\n  #mutate(HA_type = ifelse(ymd(ERNTE.Termin) == max(ymd(ERNTE.Termin)), \"eos\", \"is\")) %>%  # alternative\n  # Keep only latest harvest date (\"actual harvest\")\n  filter(HA_type == \"eos\") %>%\n  # Drop Harvest sorting variable and keep unique records\n  select(-c(Plot_id, TRTNO, HA_type)) %>%\n  distinct() %>%\n  # Generate harvest ID\n  group_by(Year) %>%\n  mutate(HA_ID = cur_group_id()) %>% ungroup() %>%\n  relocate(HA_ID, .before = everything())  # split for updated matrix and mngt only\n\n\n\n# ==== FERTILIZERS table --------------------------------------------------\n\n# FERTILIZERS and ORGANIC_MATERIALS tables\nFERTILIZERS_join <- seehausen_fmt$DUENGUNG %>%\n  # Separate inorganic and organic fertilizers\n  filter(DUENGUNG.Mineralisch == 1) %>%\n  separate(DU_ID, into = c(\"OM_ID\", \"FE_ID\"), remove = FALSE, sep = \"_\") %>%\n  # Update the ID accordingly\n  group_by(Year, FE_ID) %>% mutate(FE_ID = cur_group_id()) %>% ungroup() %>%\n  # Drop unused columns\n  select(c(where(~!all(is.na(.))), -DUENGUNG.Mineralisch, -DUENGUNG.Organisch, -DUENGUNG.Gesamt_Stickstoff, -OM_ID)) %>%\n  mutate(across(where(is.numeric), ~ifelse(is.na(.x), 0, .x)))\n\nFERTILIZERS <- FERTILIZERS_join %>%\n  select(-DU_ID) %>%\n  arrange(FE_ID) %>%\n  distinct()\n\n\n# ==== ORGANIC_MATERIALS table --------------------------------------------\n\n#' NB: one challenge here is that OM is applied only every 2-4 years, though it is considered a treatment for the 2-4 years\n#' following application. For modelling this should be somewhat reflected into the initial conditions in the years with no\n#' application. For now we just consider the OM only on the year when it is applied, which will lead to innacurate model\n#' predictions in the years between applications\n\nORGANIC_MATERIALS_join <- seehausen_fmt$DUENGUNG %>%\n  # Separate inorganic and organic fertilizers\n  filter(DUENGUNG.Organisch == 1) %>%\n  separate(DU_ID, into = c(\"OM_ID\", \"FE_ID\"), remove = FALSE, sep = \"_\") %>%\n  # Update the ID accordingly\n  group_by(Year, OM_ID) %>% mutate(OM_ID = cur_group_id()) %>% ungroup() %>%\n  # Calculate the amount of OM applied in each year based on average nitrogen concentration\n  # source: https://www.epa.gov/nutrientpollution/estimated-animal-agriculture-nitrogen-and-phosphorus-manure\n  # NB: this is a US estimate, we might need to add a routine to estimate based on experiment metadata\n  mutate(OMNPC = 3,  # OM nitrogen concentration (3%)\n         OMAMT = DUENGUNG.Stickstoff_org * OMNPC * 0.01) %>%\n  # Drop unused columns\n  select(c(where(~!all(is.na(.))), -DUENGUNG.Mineralisch, -DUENGUNG.Organisch, -DUENGUNG.Gesamt_Stickstoff, -FE_ID)) %>%\n  mutate(across(where(is.numeric), ~ifelse(is.na(.x), 0, .x)))\n\nORGANIC_MATERIALS <- ORGANIC_MATERIALS_join %>%\n  select(-DU_ID) %>%\n  arrange(OM_ID) %>%\n  distinct()\n\n\n# ==== CULTIVARS table ----------------------------------------------------\n\nCULTIVARS <- seehausen_fmt$AUSSAAT %>% \n  select(Year, starts_with(c(\"SORTE\",\"KULTUR\"))) %>% ## TODO: not only update ID by year but also by crop\n  distinct() %>%\n  # Generate cultivar ID\n  group_by(Year) %>%\n  mutate(CU_ID = cur_group_id()) %>% ungroup() %>%\n  relocate(CU_ID, .before = everything()) # split for updated matrix and mngt only\n\n\n# ==== PLANTINGS table ----------------------------------------------------\n\n# AUSSAAT.Keimfaehige_Koerner has variable units depending on crop\nPOT_years <- unique(INITIAL_CONDITIONS[which(INITIAL_CONDITIONS$KULTUR.Kultur_Englisch == \"Potato\"), \"Year\"])\n\nPLANTINGS <- seehausen_fmt$AUSSAAT %>%\n  select(-starts_with(\"SORTE\")) %>%\n  mutate(AUSSAAT.Keimfaehige_Koerner = ifelse(Year %in% POT_years,\n                                              AUSSAAT.Keimfaehige_Koerner * 0.0001, AUSSAAT.Keimfaehige_Koerner),\n         PLMA = \"S\",\n         PLDS = \"R\")\n\n\n# ==== TREATMENTS matrix --------------------------------------------------\n\nTREATMENTS <- seehausen_fmt$TREATMENTS %>%\n  left_join(INITIAL_CONDITIONS %>% select(IC_ID, Year), by = \"Year\") %>%\n  left_join(HARVEST %>% select(HA_ID, Year), by = \"Year\") %>%\n  left_join(CULTIVARS %>% select(CU_ID, Year), by = \"Year\") %>%\n  left_join(FERTILIZERS_join %>% select(FE_ID, DU_ID, Year), by = c(\"DU_ID\", \"Year\"))  %>%\n  left_join(ORGANIC_MATERIALS_join %>% select(OM_ID, DU_ID, Year), by = c(\"DU_ID\", \"Year\")) %>%\n  mutate(across(where(is.numeric), ~ifelse(is.na(.x), 0, .x))) %>%\n  select(-DU_ID) %>%\n  # Add treatment name (concatenate both factors)\n  # Should be handled in is_treatment function in the future\n  mutate(TRT_NAME = paste0(Faktor1_Stufe_ID, \" | \", Faktor2_Stufe_ID)) %>%\n  relocate(TRT_NAME, .after = \"Year\") %>%\n  distinct()\n\n\n# ==== OBSERVED_TimeSeries table ------------------------------------------\n\nOBSERVED_TimeSeries <- seehausen_fmt$OBSERVED_TimeSeries %>%\n  # Rank different date within year and treatment in decreasing order to separate i-s and e-o-s harvests\n  # as different variables characterize is and eos harvests in icasa\n  group_by(Year, TRTNO) %>%\n  mutate(HA_type = ifelse(\n    dense_rank(desc(as_date(ERNTE.Termin))) > 1, \"is\", \"eos\")) %>% ungroup() %>%\n  relocate(HA_type, .before = everything())\n\n\n# ==== OBSERVED_Summary table --------------------------------------------\n\n#' Observed summary data is (currently?) not fully exploitable, as data collection dates are missing for the different\n#' analyses (soil and plant samples). For example, soil N content is provided for some years but without sampling \n#' dates, it is not possible to determine whether this corresponds to initial conditions (before the growing season)\n#' or to in-season measurements to control the influence of the fertilization treatments, and therefore not possible\n#' to assign it to the adequate ICASA section (INITIAL CONDITIONS / SOIL ANALYSES).\n#' Perhaps the missing information can be retrieved from the metadata or associated publications?\n\nOBSERVED_Summary <- seehausen_fmt$OBSERVED_Summary \n\nsave(GENERAL, FIELDS, INITIAL_CONDITIONS, HARVEST, FERTILIZERS, ORGANIC_MATERIALS, CULTIVARS, PLANTINGS, TREATMENTS, OBSERVED_TimeSeries, OBSERVED_Summary, file=\"transformed.RData\")"
                        }
                    ]
                },
                {
                    "class": "DockerRequirement",
                    "dockerFile": "FROM rocker/r-ver:4.4\n\nRUN apt-get update && apt-get install -y git sudo wget\n\nRUN wget https://raw.githubusercontent.com/fairagro/uc6_csmTools/feature/package_management/install_requirements.sh\nRUN chmod +x ./install_requirements.sh && ./install_requirements.sh\n\nRUN wget https://raw.githubusercontent.com/fairagro/uc6_csmTools/feature/package_management/install_dssat.sh\nRUN chmod +x ./install_dssat.sh && ./install_dssat.sh /usr/local/dssat\n\nRUN R -e 'install.packages(\"devtools\")'\nRUN R -e 'install.packages(\"optparse\")'\nRUN R -e 'devtools::install_github(\"fairagro/uc6_csmTools@feature/package_management\")'",
                    "dockerImageId": "uc6_arc"
                }
            ],
            "inputs": [
                {
                    "id": "#transform_data.cwl/reshaped_RData",
                    "type": "File"
                }
            ],
            "outputs": [
                {
                    "id": "#transform_data.cwl/transformed.RData",
                    "type": "File",
                    "outputBinding": {
                        "glob": "transformed.RData"
                    }
                }
            ],
            "baseCommand": [
                "Rscript",
                "transform_data.R"
            ],
            "id": "#transform_data.cwl"
        }
    ],
    "cwlVersion": "v1.2",
    "$schemas": [
        "https://raw.githubusercontent.com/nfdi4plants/ARC_ontology/main/ARC_v2.0.owl"
    ],
    "$namespaces": {
        "arc": "https://github.com/nfdi4plants/ARC_ontology"
    }
}