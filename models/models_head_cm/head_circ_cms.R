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

data <- data %>%
  mutate(across(everything(), ~na_if(trimws(tolower(.)), "na"))) %>%
  mutate(across(everything(), ~na_if(., "")))

suppressWarnings({
  data <- data %>%
    mutate(across(c(weight_g, length_cm, head_circumference_cm, pma_weeks), as.numeric))
})

data <- data %>% mutate(weight_kg = weight_g / 1000)

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
n_missing_head <- cleaned_data %>% filter(is.na(head_cm) | is.na(pma_weeks)) %>% nrow()
model_data_head <- cleaned_data %>%
  filter(!is.na(head_cm) & !is.na(pma_weeks)) %>%
  select(head_cm, pma_weeks)

# (Optional) sanity check: must be > 0
stopifnot(all(model_data_head$head_cm > 0))

# 6. Normality check ----
lillie.test(model_data_head$head_cm)
qqnorm(model_data_head$head_cm, main = "Q-Q Plot of Head Circumference (cm)")
qqline(model_data_head$head_cm, col = "red", lwd = 2)

# 7. Build LMS models (BCCG, BCPE, BCT) ----
model_head <- gamlss(
  head_cm ~ pb(pma_weeks, df = 4),
  sigma.formula = ~ pb(pma_weeks, df = 2),
  nu.formula    = ~ pb(pma_weeks, df = 2),
  data = model_data_head,
  family = BCCG
)

# 👇 key change: log link for mu to keep it positive
model_head_bcpe <- gamlss(
  head_cm ~ pb(pma_weeks, df = 4),
  sigma.formula = ~ pb(pma_weeks, df = 2),
  nu.formula    = ~ pb(pma_weeks, df = 2),
  tau.formula   = ~ pb(pma_weeks, df = 3),
  data = model_data_head,
  family = BCPE(mu.link = "log")
)

model_head_bct <- gamlss(
  head_cm ~ pb(pma_weeks, df = 4),
  sigma.formula = ~ pb(pma_weeks, df = 2),
  nu.formula    = ~ pb(pma_weeks, df = 2),
  tau.formula   = ~ pb(pma_weeks, df = 2),
  data = model_data_head,
  family = BCT(mu.link = "log")
)

# 8. Compare models ----
GAIC(model_head, model_head_bcpe, model_head_bct, k = 2)

# 9. Save centile plots ----
x11()
centiles(
  model_head,
  xvar = model_data_head$pma_weeks,
  cent = c(3,10,25,50,75,90,97),
  main = "Neonatal Head Circumference Centiles (BCCG)",
  xlab = "Postmenstrual Age (weeks)",
  ylab = "Head Circumference (cm)",
  legend = TRUE
)
par(mfrow = c(1, 3))

centiles(model_head,       xvar = model_data_head$pma_weeks,
         main = "BCCG", cent = c(3,10,25,50,75,90,97),
         xlab = "PMA", ylab = "Head Circumference (cm)")
centiles(model_head_bcpe,  xvar = model_data_head$pma_weeks,
         main = "BCPE", cent = c(3,10,25,50,75,90,97),
         xlab = "PMA", ylab = "Head Circumference (cm)")
centiles(model_head_bct,   xvar = model_data_head$pma_weeks,
         main = "BCT",  cent = c(3,10,25,50,75,90,97),
         xlab = "PMA", ylab = "Head Circumference (cm)")

par(mfrow = c(1, 1))

if (!dir.exists("plots_head_cm")) dir.create("plots_head_cm", recursive = TRUE)

png("plots_head_cm/headcirc_centile_BCCG_cm.png", width = 800, height = 600)
centiles(model_head,
         xvar = model_data_head$pma_weeks,
         cent = c(3,10,25,50,75,90,97),
         main = "Neonatal Head Circumference Centiles (BCCG)",
         xlab = "PMA (weeks)", ylab = "Head Circumference (cm)", legend = TRUE)
dev.off()

png("plots_head_cm/headcirc_centile_model_comparison_cm.png", width = 1200, height = 600)
par(mfrow = c(1, 3))
centiles(model_head,      xvar = model_data_head$pma_weeks,
         cent = c(3,10,25,50,75,90,97), main = "BCCG", xlab = "PMA", ylab = "Head Circumference (cm)")
centiles(model_head_bcpe, xvar = model_data_head$pma_weeks,
         cent = c(3,10,25,50,75,90,97), main = "BCPE", xlab = "PMA", ylab = "Head Circumference (cm)")
centiles(model_head_bct,  xvar = model_data_head$pma_weeks,
         cent = c(3,10,25,50,75,90,97), main = "BCT",  xlab = "PMA", ylab = "Head Circumference (cm)")
dev.off()
par(mfrow = c(1, 1))

# 10. Save models ----
if (!dir.exists("models_head_cm")) dir.create("models_head_cm")
save(model_head, file = "models_head_cm/model_head_BCCG_cm.RData")
