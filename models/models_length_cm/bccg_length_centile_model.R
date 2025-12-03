# Set working directory (update if needed)
setwd("C:/Users/nerad/Documents/Growth Chart/neonatal_growth_chart/Cleaned")

# Load libraries
library(readxl)
library(dplyr)
library(gamlss)
library(nortest)

# Load preprocessed + cleaned dataset
cleaned_data <- read.csv("cleaned_unique_growth_data.csv")


# Filter rows
model_data_length <- cleaned_data %>%
  filter(!is.na(length_cm) & !is.na(pma_weeks)) %>%
  select(length_cm, pma_weeks)


lillie.test(model_data$length_cm)

# Q-Q Plot for Length
qqnorm(model_data$length_cm, main = "Q-Q Plot of Length (cm)")
qqline(model_data$length_cm, col = "blue")

# LMS Model
model_length <- gamlss(
  length_cm ~ pb(pma_weeks),
  sigma.formula = ~ pb(pma_weeks),
  nu.formula = ~ pb(pma_weeks),
  data = model_data_length,
  family = BCCG
)

# Summary of model fit
summary(model_length)

# Plot centile curves and save PNG
x11()
centiles(model_length,
         xvar = model_data_length$pma_weeks,
         cent = c(3,10,25,50,75,90,97),
         main = "Neonatal Length Centiles (BCCG)",
         xlab = "PMA (weeks)", ylab = "Length (cm)", legend = TRUE)

if (!dir.exists("plots")) dir.create("plots")
png("plots/length_centile_BCCG.png", width = 800, height = 600)
centiles(model_length,
         xvar = model_data_length$pma_weeks,
         cent = c(3,10,25,50,75,90,97),
         main = "Neonatal Length Centiles (BCCG)",
         xlab = "PMA (weeks)", ylab = "Length (cm)", legend = TRUE)
dev.off()

if (!dir.exists("models")) dir.create("models")
save(model_weight, file = "models/model_length_BCCG.RData")