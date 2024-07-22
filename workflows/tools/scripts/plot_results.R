parser <- optparse::OptionParser()
parser <- optparse::add_option(parser, c("-s", "--simulation_dir"), type="character", help="Directory with Sim Output")
opt <- optparse::parse_args(parser)

load("format_dssat.RData")
library(DSSAT)
library(ggplot2)
library(dplyr)

# ==== Result plots -------------------------------------------------------


# TODO: eventually a wrapper for plotting essential results likes the obs vs. sim comparisons
# Should link to the input data to retrieve treatment names and levels
# Plot results: phenology

lteSe_sim_growth <- read_output(file_name = paste0(opt$simulation_dir,"/PlantGro.OUT"))

# Format observed data for plotting
lteSe_obs_growth <- BNR_yr_merged$Y1995$FILEA %>%
  filter(TRTNO %in% 1:4) %>%
  mutate(MDAT = as.POSIXct(as.Date(MDAT, format = "%y%j")),
         ADAT = as.POSIXct(as.Date(ADAT, format = "%y%j")))

# Plot results: yield
lteSe_sim_growth %>%
  mutate(TRNO = as.factor(TRNO)) %>%
  ggplot(aes(x = DATE, y = GWAD)) +
  # Line plot for simulated data
  geom_line(aes(group = TRNO, colour = TRNO, linewidth = "Simulated")) +
  # Points for observed data
  geom_point(data = lteSe_obs_growth, aes(x = MDAT, y = HWAH, colour = as.factor(TRTNO), size = "Observed"), 
             shape = 20) +  # obs yield at harvest
  # General appearance
  scale_colour_manual(name = "Fertilization (kg[N]/ha)",
                    breaks = c("1","2","3","4"),
                    labels = c("0","100","200","300"),
                    values = c("#20854E","#FFDC91", "#E18727", "#BC3C29")) +
  scale_size_manual(values = c("Simulated" = 1, "Observed" = 2), limits = c("Simulated", "Observed")) +
  scale_linewidth_manual(values = c("Simulated" = 1, "Observed" = 2), limits = c("Simulated", "Observed")) +
  labs(size = NULL, linewidth = NULL, y = "Yield (kg/ha)") +
  guides(
    size = guide_legend(
      override.aes = list(linetype = c("solid", "blank"), shape = c(NA, 16))
    )
  ) +
  theme_bw() + 
  theme(legend.text = element_text(size = 8), legend.title = element_text(size = 8),
        axis.title.x = element_blank(), axis.title.y = element_text(size = 10),
        axis.text = element_text(size = 9, colour = "black"))

# Plot results: phenology
lteSe_sim_growth %>%
  mutate(TRNO = as.factor(TRNO)) %>%
  ggplot(aes(x = DATE, y = DCCD)) +
  # Zadoks lines for comparison
  geom_hline(yintercept = 69, linetype = "dashed", colour = "black") +  # anthesis date (Zadoks65)
  geom_hline(yintercept = 95, linetype = "dashed", colour = "black") +  # maturity date (Zadoks95)
  # Line plot for simulated data
  geom_line(aes(group = TRNO, colour = TRNO, linewidth = "Simulated")) +
  # Points for observed data
  geom_point(data = lteSe_obs_growth, aes(x = ADAT, y = 69, colour = as.factor(TRTNO), size = "Observed"),
             shape = 20) +  # obs anthesis date (Zadosk65)
  geom_point(data = lteSe_obs_growth, aes(x = MDAT, y = 95, colour = as.factor(TRTNO), size = "Observed"),
             shape = 20) +  # obs maturity data (Zadoks95)
  # General appearance
  scale_colour_manual(name = "Fertilization (kg[N]/ha)",
                      breaks = c("1","2","3","4"),
                      labels = c("0","100","200","300"),
                      values = c("#20854E","#FFDC91", "#E18727", "#BC3C29")) +
  scale_size_manual(values = c("Simulated" = 1, "Observed" = 2), limits = c("Simulated", "Observed")) +
  scale_linewidth_manual(values = c("Simulated" = 1, "Observed" = 2), limits = c("Simulated", "Observed")) +
  labs(size = NULL, linewidth = NULL, y = "Zadoks scale") +
  guides(
    size = guide_legend(
      override.aes = list(linetype = c("solid", "blank"), shape = c(NA, 16))
    )
  ) +
  theme_bw() + 
  theme(legend.text = element_text(size = 8), legend.title = element_text(size = 8),
        axis.title.x = element_blank(), axis.title.y = element_text(size = 10),
        axis.text = element_text(size = 9, colour = "black"))

# Results are off, but it works!

#' @exportHint Rplots.pdf