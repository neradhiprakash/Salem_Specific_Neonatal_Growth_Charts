#Set working directory
setwd("C:/Users/nerad/Documents/Growth Chart/neonatal_growth_chart/Cleaned")

#Read excel 
library(readxl)

#Load the data into data and check the first few rows
data <- read_excel("cleansed.xlsx", sheet = 'test')
options(digits = 10)
head(data,10)
tail(data,7)

#We hit NAS introduced by coercion warning so let's removes spaces, NA, blanks
library(dplyr)

# Replace blanks, "NA", "na", " ", etc. with actual NA
data <- data %>%
  mutate(across(everything(), ~na_if(trimws(tolower(.)), "na"))) %>%
  mutate(across(everything(), ~na_if(., "")))



# Convert text characters to numeric
data$weight_g <- as.numeric(data$weight_g)
data$length_cm <- as.numeric(data$length_cm)
data$head_circumference_cm <- as.numeric(data$head_circumference_cm)
data$pma_weeks <- as.numeric(data$pma_weeks)

# Merging duplicate rows
cleaned_data <- data %>%
  group_by(infant_id, pma_weeks) %>%
  summarise(
    weight_g = mean(weight_g, na.rm = TRUE),
    length_cm = ifelse(all(is.na(length_cm)), NA, max(length_cm, na.rm = TRUE)),
    head_cm = ifelse(all(is.na(head_circumference_cm)), NA, max(head_circumference_cm, na.rm = TRUE)),
    .groups = "drop"
  )

#We are getting an error for missing values in pma weeks and weight. So let's only keep rows that weight & pma weeks are present in
n_missing <- cleaned_data %>% filter(is.na(weight_g) | is.na(pma_weeks)) %>% nrow()
model_data <- cleaned_data %>%
  filter(!is.na(weight_g) & !is.na(pma_weeks))

sum(is.na(model_data$weight_g))     # should be 0
sum(is.na(model_data$pma_weeks))    # should be 0

write.csv(cleaned_data, "cleaned_unique_growth_data.csv", row.names = FALSE)

#gamlss
library(gamlss)

#Trim the model as gamlss takes in the entire dataframe
model_data_trim <- model_data %>% 
  select(weight_g, pma_weeks)

# Normality test
length(na.omit(model_data_trim$weight_g))
library(nortest)
lillie.test(model_data_trim$weight_g)

# Q-Q Plot for weight_g
qqnorm(model_data_trim$weight_g, 
       main = "Q-Q Plot of Weight (g)",
       xlab = "Theoretical Quantiles", 
       ylab = "Sample Quantiles")

qqline(model_data_trim$weight_g, col = "red", lwd = 2)


#LMS Model
model_weight <- gamlss(
  weight_g ~ pb(pma_weeks, df = 4),
  sigma.formula = ~ pb(pma_weeks, df = 2),
  nu.formula = ~ pb(pma_weeks, df = 2),
  data = model_data_trim,
  family = BCCG
)

model_weight_bcpe <- gamlss(
  weight_g ~ pb(pma_weeks, df = 4),
  sigma.formula = ~ pb(pma_weeks, df = 2),
  nu.formula = ~ pb(pma_weeks, df = 2),
  tau.formula = ~ pb(pma_weeks, df = 3),  # extra for BCPE
  data = model_data_trim,
  family = BCPE
)

model_weight_bct <- gamlss(
  weight_g ~ pb(pma_weeks, df = 4),
  sigma.formula = ~ pb(pma_weeks, df = 2),
  nu.formula = ~ pb(pma_weeks, df = 2),
  tau.formula = ~ pb(pma_weeks, df = 2),  # required for BCT too
  data = model_data_trim,
  family = BCT
)

GAIC(model_weight, model_weight_bcpe, model_weight_bct, k = 2)  # BIC if k = log(n)


#Centile chart plot
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


if (!dir.exists("plots")) dir.create("plots", recursive = TRUE)
png("plots/weight_centile_BCCG.png", width = 1200, height = 600)
centiles(
  model_weight,
  xvar = model_data_trim$pma_weeks,
  cent = c(3,10,25,50,75,90,97),
  main = "BCCG",
  xlab = "PMA", ylab = "Weight (g)"
)

centiles(
  model_weight_bcpe,
  xvar = model_data_trim$pma_weeks,
  cent = c(3,10,25,50,75,90,97),
  main = "BCPE",
  xlab = "PMA", ylab = "Weight (g)"
)

centiles(
  model_weight_bct,
  xvar = model_data_trim$pma_weeks,
  cent = c(3,10,25,50,75,90,97),
  main = "BCT",
  xlab = "PMA", ylab = "Weight (g)"
)

dev.off()
par(mfrow = c(1, 1))

if (!dir.exists("models")) dir.create("models")
save(model_weight, file = "models/model_weight_BCCG.RData")




