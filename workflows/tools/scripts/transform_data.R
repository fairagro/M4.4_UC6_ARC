load("reshaped.RData")

library(dplyr)
library(lubridate)
library(tidyr)

# Advanced data transformation --------------------------------------

#' Files that are currently used for data mapping only handle exact matches between variables and unit conversion.
#' Producing advanced mapping standards and functions to handles more complex transformations (e.g., concatenation of
#' n columns, conditional variable naming, etc.) will be the main focus in early 2024. For now, we used the example
#' dataset to retrieve and manually transform the data. The information collected in such examples will be exploited
#' to design the mapping standards and functions. These specific adjustments are provided below with descriptions.

# ==== GENERAL section ----------------------------------------------------


GENERAL <- seehausen_fmt$GENERAL %>%
  mutate(SITE_NAME = paste(SITE, COUNTRY, sep = ", "))



# ==== FIELDS table -------------------------------------------------------


FIELDS <- seehausen_fmt$FIELDS %>%
  mutate(FLELE = (PARZELLE.Hoehenlage_Min+PARZELLE.Hoehenlage_Max)/2) %>%  #? Make mutate fun that replaces components
  mutate(SOIL_ID = "IB00000001",  # Currently generic soil is used
         WEATHER_ID = "SEDE")  # Institute + Site: TU Munich, Muenchenberg
  


# ==== INITIAL CONDITIONS tables ------------------------------------------

INITIAL_CONDITIONS <- seehausen_fmt$OTHER_FRUCHTFOLGE %>% arrange(seehausen_fmt$OTHER_FRUCHTFOLGE, Year)

INITIAL_CONDITIONS$ICPCR <- NA
for (i in 2:nrow(INITIAL_CONDITIONS)) {
  if (INITIAL_CONDITIONS[["Year"]][i] - 1 == INITIAL_CONDITIONS[["Year"]][i-1]) {
    INITIAL_CONDITIONS$ICPCR[i] <- INITIAL_CONDITIONS$KULTUR.Kultur_Englisch[i-1]
  }
}

INITIAL_CONDITIONS <- INITIAL_CONDITIONS %>%
  group_by(Year, ICPCR) %>%
  mutate(IC_ID = cur_group_id()) %>% ungroup() %>%
  select(IC_ID, Year, KULTUR.Kultur_Englisch, ICPCR) %>%
  arrange(IC_ID)
  

# ==== HARVEST table ------------------------------------------------------

HARVEST <- bind_rows(
  seehausen_fmt$OBSERVED_TimeSeries %>%
    select(Year, Plot_id, TRTNO, starts_with(c("ERNTE","TECHNIK"))),
  seehausen_fmt$OBSERVED_Summary %>%
    select(Year, Plot_id, TRTNO, starts_with(c("ERNTE","TECHNIK")))
) %>%
  # Drop all records with only NAs in the harvest categories
  # Those were created when splitting the BNR Harvest table into Observed summary and time series 
  # and then merging with observed data from other tables
  filter(!if_all(all_of(setdiff(names(.), c("Plot_id", "Year", "TRTNO"))), is.na)) %>%
  # Rank different date within year and treatment in decreasing order to separate i-s and e-o-s harvests
  # Currently assumes that all plots have been harvested e-o-s.
  # TODO: add a crop specific control to check whether dates are realistic?
  group_by(Plot_id, Year, TRTNO) %>%
  mutate(HA_type = ifelse(
    dense_rank(desc(as_date(ERNTE.Termin))) > 1, "is", "eos")) %>% ungroup() %>%
  #mutate(HA_type = ifelse(ymd(ERNTE.Termin) == max(ymd(ERNTE.Termin)), "eos", "is")) %>%  # alternative
  # Keep only latest harvest date ("actual harvest")
  filter(HA_type == "eos") %>%
  # Drop Harvest sorting variable and keep unique records
  select(-c(Plot_id, TRTNO, HA_type)) %>%
  distinct() %>%
  # Generate harvest ID
  group_by(Year) %>%
  mutate(HA_ID = cur_group_id()) %>% ungroup() %>%
  relocate(HA_ID, .before = everything())  # split for updated matrix and mngt only



# ==== FERTILIZERS table --------------------------------------------------

# FERTILIZERS and ORGANIC_MATERIALS tables
FERTILIZERS_join <- seehausen_fmt$DUENGUNG %>%
  # Separate inorganic and organic fertilizers
  filter(DUENGUNG.Mineralisch == 1) %>%
  separate(DU_ID, into = c("OM_ID", "FE_ID"), remove = FALSE, sep = "_") %>%
  # Update the ID accordingly
  group_by(Year, FE_ID) %>% mutate(FE_ID = cur_group_id()) %>% ungroup() %>%
  # Drop unused columns
  select(c(where(~!all(is.na(.))), -DUENGUNG.Mineralisch, -DUENGUNG.Organisch, -DUENGUNG.Gesamt_Stickstoff, -OM_ID)) %>%
  mutate(across(where(is.numeric), ~ifelse(is.na(.x), 0, .x)))

FERTILIZERS <- FERTILIZERS_join %>%
  select(-DU_ID) %>%
  arrange(FE_ID) %>%
  distinct()


# ==== ORGANIC_MATERIALS table --------------------------------------------

#' NB: one challenge here is that OM is applied only every 2-4 years, though it is considered a treatment for the 2-4 years
#' following application. For modelling this should be somewhat reflected into the initial conditions in the years with no
#' application. For now we just consider the OM only on the year when it is applied, which will lead to innacurate model
#' predictions in the years between applications

ORGANIC_MATERIALS_join <- seehausen_fmt$DUENGUNG %>%
  # Separate inorganic and organic fertilizers
  filter(DUENGUNG.Organisch == 1) %>%
  separate(DU_ID, into = c("OM_ID", "FE_ID"), remove = FALSE, sep = "_") %>%
  # Update the ID accordingly
  group_by(Year, OM_ID) %>% mutate(OM_ID = cur_group_id()) %>% ungroup() %>%
  # Calculate the amount of OM applied in each year based on average nitrogen concentration
  # source: https://www.epa.gov/nutrientpollution/estimated-animal-agriculture-nitrogen-and-phosphorus-manure
  # NB: this is a US estimate, we might need to add a routine to estimate based on experiment metadata
  mutate(OMNPC = 3,  # OM nitrogen concentration (3%)
         OMAMT = DUENGUNG.Stickstoff_org * OMNPC * 0.01) %>%
  # Drop unused columns
  select(c(where(~!all(is.na(.))), -DUENGUNG.Mineralisch, -DUENGUNG.Organisch, -DUENGUNG.Gesamt_Stickstoff, -FE_ID)) %>%
  mutate(across(where(is.numeric), ~ifelse(is.na(.x), 0, .x)))

ORGANIC_MATERIALS <- ORGANIC_MATERIALS_join %>%
  select(-DU_ID) %>%
  arrange(OM_ID) %>%
  distinct()


# ==== CULTIVARS table ----------------------------------------------------

CULTIVARS <- seehausen_fmt$AUSSAAT %>% 
  select(Year, starts_with(c("SORTE","KULTUR"))) %>% ## TODO: not only update ID by year but also by crop
  distinct() %>%
  # Generate cultivar ID
  group_by(Year) %>%
  mutate(CU_ID = cur_group_id()) %>% ungroup() %>%
  relocate(CU_ID, .before = everything()) # split for updated matrix and mngt only


# ==== PLANTINGS table ----------------------------------------------------

# AUSSAAT.Keimfaehige_Koerner has variable units depending on crop
POT_years <- unique(INITIAL_CONDITIONS[which(INITIAL_CONDITIONS$KULTUR.Kultur_Englisch == "Potato"), "Year"])

PLANTINGS <- seehausen_fmt$AUSSAAT %>%
  select(-starts_with("SORTE")) %>%
  mutate(AUSSAAT.Keimfaehige_Koerner = ifelse(Year %in% POT_years,
                                              AUSSAAT.Keimfaehige_Koerner * 0.0001, AUSSAAT.Keimfaehige_Koerner),
         PLMA = "S",
         PLDS = "R")


# ==== TREATMENTS matrix --------------------------------------------------

TREATMENTS <- seehausen_fmt$TREATMENTS %>%
  left_join(INITIAL_CONDITIONS %>% select(IC_ID, Year), by = "Year") %>%
  left_join(HARVEST %>% select(HA_ID, Year), by = "Year") %>%
  left_join(CULTIVARS %>% select(CU_ID, Year), by = "Year") %>%
  left_join(FERTILIZERS_join %>% select(FE_ID, DU_ID, Year), by = c("DU_ID", "Year"))  %>%
  left_join(ORGANIC_MATERIALS_join %>% select(OM_ID, DU_ID, Year), by = c("DU_ID", "Year")) %>%
  mutate(across(where(is.numeric), ~ifelse(is.na(.x), 0, .x))) %>%
  select(-DU_ID) %>%
  # Add treatment name (concatenate both factors)
  # Should be handled in is_treatment function in the future
  mutate(TRT_NAME = paste0(Faktor1_Stufe_ID, " | ", Faktor2_Stufe_ID)) %>%
  relocate(TRT_NAME, .after = "Year") %>%
  distinct()


# ==== OBSERVED_TimeSeries table ------------------------------------------

OBSERVED_TimeSeries <- seehausen_fmt$OBSERVED_TimeSeries %>%
  # Rank different date within year and treatment in decreasing order to separate i-s and e-o-s harvests
  # as different variables characterize is and eos harvests in icasa
  group_by(Year, TRTNO) %>%
  mutate(HA_type = ifelse(
    dense_rank(desc(as_date(ERNTE.Termin))) > 1, "is", "eos")) %>% ungroup() %>%
  relocate(HA_type, .before = everything())


# ==== OBSERVED_Summary table --------------------------------------------

#' Observed summary data is (currently?) not fully exploitable, as data collection dates are missing for the different
#' analyses (soil and plant samples). For example, soil N content is provided for some years but without sampling 
#' dates, it is not possible to determine whether this corresponds to initial conditions (before the growing season)
#' or to in-season measurements to control the influence of the fertilization treatments, and therefore not possible
#' to assign it to the adequate ICASA section (INITIAL CONDITIONS / SOIL ANALYSES).
#' Perhaps the missing information can be retrieved from the metadata or associated publications?

OBSERVED_Summary <- seehausen_fmt$OBSERVED_Summary 

save(GENERAL, FIELDS, INITIAL_CONDITIONS, HARVEST, FERTILIZERS, ORGANIC_MATERIALS, CULTIVARS, PLANTINGS, TREATMENTS, OBSERVED_TimeSeries, OBSERVED_Summary, file="transformed.RData")