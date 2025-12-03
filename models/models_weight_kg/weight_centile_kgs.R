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

# Add weight in kg
data <- data %>%
  mutate(weight_kg = weight_g / 1000)

# 4. Merge duplicates ----
cleaned_data <- data %>%
  group_by(infant_id, pma_weeks) %>%
  summarise(
    weight_g = mean(weight_g, na.rm = TRUE),
    weight_kg = weight_g / 1000,
    length_cm = ifelse(all(is.na(length_cm)), NA, max(length_cm, na.rm = TRUE)),
    head_cm = ifelse(all(is.na(head_circumference_cm)), NA, max(head_circumference_cm, na.rm = TRUE)),
    .groups = "drop"
  )

# 5. Filter model data (non-NA) ----
n_missing <- cleaned_data %>% filter(is.na(weight_kg) | is.na(pma_weeks)) %>% nrow()
model_data <- cleaned_data %>%
  filter(!is.na(weight_kg) & !is.na(pma_weeks))

# Save cleaned data
write.csv(cleaned_data, "cleaned_unique_growth_data_kg.csv", row.names = FALSE)

# 6. Normality check ----
model_data_trim <- model_data %>% select(weight_kg, pma_weeks)
lillie.test(model_data_trim$weight_kg)

qqnorm(model_data_trim$weight_kg,
       main = "Q-Q Plot of Weight (kg)",
       xlab = "Theoretical Quantiles",
       ylab = "Sample Quantiles")
qqline(model_data_trim$weight_kg, col = "red", lwd = 2)

# 7. Build LMS models (BCCG, BCPE, BCT) ----
model_weight <- gamlss(
  weight_kg ~ pb(pma_weeks, df = 4),
  sigma.formula = ~ pb(pma_weeks, df = 2),
  nu.formula = ~ pb(pma_weeks, df = 2),
  data = model_data_trim,
  family = BCCG
)

model_weight_bcpe <- gamlss(
  weight_kg ~ pb(pma_weeks, df = 4),
  sigma.formula = ~ pb(pma_weeks, df = 2),
  nu.formula = ~ pb(pma_weeks, df = 2),
  tau.formula = ~ pb(pma_weeks, df = 3),
  data = model_data_trim,
  family = BCPE
)

model_weight_bct <- gamlss(
  weight_kg ~ pb(pma_weeks, df = 4),
  sigma.formula = ~ pb(pma_weeks, df = 2),
  nu.formula = ~ pb(pma_weeks, df = 2),
  tau.formula = ~ pb(pma_weeks, df = 2),
  data = model_data_trim,
  family = BCT
)

# 8. Compare models ----
GAIC(model_weight, model_weight_bcpe, model_weight_bct, k = 2)

# 9. Save centile plots ----
x11()
centiles(
  model_weight,
  xvar = model_data_trim$pma_weeks,
  cent = c(3, 10, 25, 50, 75, 90, 97),
  main = "Neonatal Weight Centiles (BCCG)",
  xlab = "Postmenstrual Age (weeks)",
  ylab = "Weight (g)",
  legend = TRUE
)
par(mfrow = c(1, 3))  # 3 plots side by side

centiles(model_weight, xvar = model_data_trim$pma_weeks,
         main = "BCCG", cent = c(3,10,25,50,75,90,97),
         xlab = "PMA", ylab = "Weight (g)")

centiles(model_weight_bcpe, xvar = model_data_trim$pma_weeks,
         main = "BCPE", cent = c(3,10,25,50,75,90,97),
         xlab = "PMA", ylab = "Weight (g)")

centiles(model_weight_bct, xvar = model_data_trim$pma_weeks,
         main = "BCT", cent = c(3,10,25,50,75,90,97),
         xlab = "PMA", ylab = "Weight (g)")

par(mfrow = c(1, 1))  # reset
# Create plots folder if not present
if (!dir.exists("plots_weight_kg")) dir.create("plots_weight_kg", recursive = TRUE)

# BCCG only (in kg)
png("plots_weight_kg/weight_centile_BCCG_kg.png", width = 800, height = 600)
centiles(
  model_weight,
  xvar = model_data_trim$pma_weeks,
  cent = c(3,10,25,50,75,90,97),
  main = "Neonatal Weight Centiles (BCCG)",
  xlab = "PMA (weeks)", ylab = "Weight (kg)", legend = TRUE
)
dev.off()

# Combined model comparison
png("plots_weight_kg/weight_centile_model_comparison_kg.png", width = 1200, height = 600)
par(mfrow = c(1, 3))  # side-by-side plots

centiles(model_weight, xvar = model_data_trim$pma_weeks,
         cent = c(3,10,25,50,75,90,97), main = "BCCG", xlab = "PMA", ylab = "Weight (kg)")
centiles(model_weight_bcpe, xvar = model_data_trim$pma_weeks,
         cent = c(3,10,25,50,75,90,97), main = "BCPE", xlab = "PMA", ylab = "Weight (kg)")
centiles(model_weight_bct, xvar = model_data_trim$pma_weeks,
         cent = c(3,10,25,50,75,90,97), main = "BCT", xlab = "PMA", ylab = "Weight (kg)")

dev.off()
par(mfrow = c(1, 1))  # reset

# 10. Save models ----
if (!dir.exists("models_weight_kg")) dir.create("models_weight_kg")
save(model_weight, file = "models_weight_kg/model_weight_BCCG_kg.RData")
