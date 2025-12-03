# 1. Set working directory ----
setwd("C:/Users/nerad/Documents/Growth Chart/neonatal_growth_chart/Cleaned")

# 2. Load libraries ----
library(readxl)
library(dplyr)
library(gamlss)
library(nortest)

# 3. Read and clean data ----
data <- read_excel("cleansed.xlsx", sheet = "test")
options(digits = 10)

# Replace blanks, "NA", "na", " ", etc. with NA
data <- data %>%
  mutate(across(everything(), ~na_if(trimws(tolower(.)), "na"))) %>%
  mutate(across(everything(), ~na_if(., "")))

# Convert selected columns to numeric
suppressWarnings({
  data <- data %>%
    mutate(across(c(weight_g, length_cm, head_circumference_cm, pma_weeks), as.numeric))
})

# Add weight in kg (not used here, but keeps this block identical in structure)
data <- data %>%
  mutate(weight_kg = weight_g / 1000)

# 4. Merge duplicates ----
cleaned_data <- data %>%
  group_by(infant_id, pma_weeks) %>%
  summarise(
    weight_g  = mean(weight_g, na.rm = TRUE),
    weight_kg = weight_g / 1000,
    length_cm = ifelse(all(is.na(length_cm)), NA, max(length_cm, na.rm = TRUE)),
    head_cm   = ifelse(all(is.na(head_circumference_cm)), NA, max(head_circumference_cm, na.rm = TRUE)),
    .groups = "drop"
  )

# 5. Filter model data (non-NA) ----
n_missing_len <- cleaned_data %>% filter(is.na(length_cm) | is.na(pma_weeks)) %>% nrow()
model_data_length <- cleaned_data %>%
  filter(!is.na(length_cm) & !is.na(pma_weeks)) %>%
  select(length_cm, pma_weeks)

# 6. Normality check ----
lillie.test(model_data_length$length_cm)

qqnorm(model_data_length$length_cm,
       main = "Q-Q Plot of Length (cm)",
       xlab = "Theoretical Quantiles",
       ylab = "Sample Quantiles")
qqline(model_data_length$length_cm, col = "red", lwd = 2)

# 7. Build LMS models (BCCG, BCPE, BCT) ----
model_length <- gamlss(
  length_cm ~ pb(pma_weeks, df = 4),
  sigma.formula = ~ pb(pma_weeks, df = 2),
  nu.formula    = ~ pb(pma_weeks, df = 2),
  data = model_data_length,
  family = BCCG
)

model_length_bcpe <- gamlss(
  length_cm ~ pb(pma_weeks, df = 4),
  sigma.formula = ~ pb(pma_weeks, df = 2),
  nu.formula    = ~ pb(pma_weeks, df = 2),
  tau.formula   = ~ pb(pma_weeks, df = 3),
  data = model_data_length,
  family = BCPE
)

model_length_bct <- gamlss(
  length_cm ~ pb(pma_weeks, df = 4),
  sigma.formula = ~ pb(pma_weeks, df = 2),
  nu.formula    = ~ pb(pma_weeks, df = 2),
  tau.formula   = ~ pb(pma_weeks, df = 2),
  data = model_data_length,
  family = BCT
)

# 8. Compare models ----
GAIC(model_length, model_length_bcpe, model_length_bct, k = 2)

# 9. Save centile plots ----
x11()
centiles(
  model_length,
  xvar = model_data_length$pma_weeks,
  cent = c(3,10,25,50,75,90,97),
  main = "Neonatal Length Centiles (BCCG)",
  xlab = "Postmenstrual Age (weeks)",
  ylab = "Length (cm)",
  legend = TRUE
)
par(mfrow = c(1, 3))  # 3 plots side by side

centiles(model_length, xvar = model_data_length$pma_weeks,
         main = "BCCG", cent = c(3,10,25,50,75,90,97),
         xlab = "PMA", ylab = "Length (cm)")

centiles(model_length_bcpe, xvar = model_data_length$pma_weeks,
         main = "BCPE", cent = c(3,10,25,50,75,90,97),
         xlab = "PMA", ylab = "Length (cm)")

centiles(model_length_bct, xvar = model_data_length$pma_weeks,
         main = "BCT", cent = c(3,10,25,50,75,90,97),
         xlab = "PMA", ylab = "Length (cm)")

par(mfrow = c(1, 1))  # reset

# Create plots folder if not present
if (!dir.exists("plots_length_cm")) dir.create("plots_length_cm", recursive = TRUE)

# BCCG only (in cm)
png("plots_length_cm/length_centile_BCCG_cm.png", width = 800, height = 600)
centiles(
  model_length,
  xvar = model_data_length$pma_weeks,
  cent = c(3,10,25,50,75,90,97),
  main = "Neonatal Length Centiles (BCCG)",
  xlab = "PMA (weeks)", ylab = "Length (cm)", legend = TRUE
)
dev.off()

# Combined model comparison
png("plots_length_cm/length_centile_model_comparison_cm.png", width = 1200, height = 600)
par(mfrow = c(1, 3))  # side-by-side plots

centiles(model_length, xvar = model_data_length$pma_weeks,
         cent = c(3,10,25,50,75,90,97), main = "BCCG", xlab = "PMA", ylab = "Length (cm)")
centiles(model_length_bcpe, xvar = model_data_length$pma_weeks,
         cent = c(3,10,25,50,75,90,97), main = "BCPE", xlab = "PMA", ylab = "Length (cm)")
centiles(model_length_bct, xvar = model_data_length$pma_weeks,
         cent = c(3,10,25,50,75,90,97), main = "BCT",  xlab = "PMA", ylab = "Length (cm)")

dev.off()
par(mfrow = c(1, 1))  # reset

# 10. Save models ----
if (!dir.exists("models_length_cm")) dir.create("models_length_cm")
save(model_length, file = "models_length_cm/model_length_BCCG_cm.RData")
