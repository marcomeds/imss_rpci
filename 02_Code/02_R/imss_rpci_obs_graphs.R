#' @Nombre: imss_rpci_obs_graphs.R
#' 
#' @Author: Marco Medina
#' 
#' @Descripción: Create graphs about RPCI.
#' 
#' @In: panel_rpci.csv (exported from clean_panel_rpci.do)
#' @Out: 

# Libraries
library(readr)
library(tidyverse)
library(ggthemes)
library(scales)
library(zoo)
library(mxmaps)
library(ggrepel)

# Set working directory
setwd("~/ITAM Seira Research Dropbox/Marco Alejandro Medina/IMSS_RPCI_Obs")

# Load data
data <- read_delim("01_Data/03_Working/panel_rpci.csv",
                   delim = "|") %>%
  mutate(periodo_date = as.Date(periodo_date, format = "%d%b%Y"),
         download_date = as.Date(download_date, format = "%d%b%Y"))

# ---- Descarga ----
data_descarga <- data %>%
  distinct(idnss, .keep_all = TRUE) %>%
  filter(descarga == 1)

# Get the cumulative distribution
max_date <- max(data_descarga$download_date)
min_date <- min(data_descarga$download_date)
z <- c(min_date:max_date)
cum_dist <- ecdf(data_descarga$download_date)
cdf <- cum_dist(z)

data_descarga_cum_dist <- data.frame(download_date = as.Date(z), cdf = cdf)

# Plot the histogram and the cumulative distribution
ggplot() +
  geom_histogram(data = data_descarga,
                 aes(x = download_date),
                 color = "white",
                 fill = "#4E79A7",
                 binwidth = 5) +
  geom_line(data = data_descarga_cum_dist,
            aes(x = download_date,
                y = 96*cdf),
            color = "#E15759", 
            size = 1, 
            linetype = 1) +
  scale_x_date(date_breaks = "1 month",
               date_labels = "%b/%y") +
  scale_y_continuous(limits = c(0,100), sec.axis = sec_axis(~.*1920, name = "Distribución acumulada")) +
  scale_fill_tableau(name = "") +
  labs(title = "Descargas del RPCI por fecha de descarga",
       x = "Fecha de descarga",
       y = "Número de descargas") +
  theme_classic() + 
  theme(axis.text.x = element_text(angle = 45, hjust = 1))


ggsave("04_Figures/histogram_descarga_fecha.pdf")


# --- Trabajador por estado ---
data_estado <- data %>%
  filter(!is.na(cve_ent_final)) %>%
  group_by(cve_ent_final) %>%
  summarise(trabajadores = n(),
            descargas = sum(treated, na.rm = T)) %>%
  rename(region = cve_ent_final)

# Get state names from mxmaps
nom_estado <- df_mxstate %>%
  mutate(region = as.numeric(region))

data_nom_estado <- data_estado %>%
  merge(nom_estado) %>%
  mutate(state = ifelse(state_name == "Ciudad de México", "CDMX",
                        ifelse(state_name == "Jalisco" | state_name == "Nuevo León" | state_name == "México",
                               state_name,
                               ""))) %>%
  # The database is 30 times smaller than the 10% sample.
  # There are 25 period observations for each worker.
  # We count in thousands
  mutate(descargas = 30*descargas/25000,
         trabajadores = 30*trabajadores/25000)

# Graph the number of workers vs. the number of downloads
ggplot(data_nom_estado, aes(x = trabajadores, y = descargas)) +
  geom_point() +
  geom_text_repel(aes(label = state)) +
  geom_abline(slope = 0.03, lty = 2) +
  scale_x_continuous() +
  labs(x = "Número de Trabajadores (miles)",
       y = "Descargas (miles)") +
  theme_minimal() +
  theme(aspect.ratio = 1)

ggsave("04_Figures/decargas_estados.pdf")
