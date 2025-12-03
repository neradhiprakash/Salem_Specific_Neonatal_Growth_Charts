# Load libraries
library(gamlss)
library(dplyr)
library(nortest)

# Filter out rows with NA in head circumference or PMA
model_data_head <- cleaned_data %>%
  filter(!is.na(head_cm) & !is.na(pma_weeks)) %>%
  select(head_cm, pma_weeks)

lillie.test(model_data$head_cm)
# Q-Q Plot for Head Circumference
qqnorm(model_data$head_cm, main = "Q-Q Plot of Head Circumference (cm)")
qqline(model_data$head_cm, col = "darkgreen")

# Fit LMS model using BCCG distribution
model_head <- gamlss(
  head_cm ~ pb(pma_weeks),
  sigma.formula = ~ pb(pma_weeks),
  nu.formula = ~ pb(pma_weeks),
  data = model_data_head,
  family = BCCG
)

# Optional: Preview percentiles in the console
centiles(model_head,
         xvar = model_data_head$pma_weeks,
         cent = c(3,10,25,50,75,90,97),
         main = "Neonatal Head Circumference Centiles (BCCG)",
         xlab = "PMA (weeks)", ylab = "Head Circumference (cm)",
         legend = TRUE)

# Open a window to display the chart (Windows fix)
x11()
centiles(model_head,
         xvar = model_data_head$pma_weeks,
         cent = c(3,10,25,50,75,90,97),
         main = "Neonatal Head Circumference Centiles (BCCG)",
         xlab = "PMA (weeks)", ylab = "Head Circumference (cm)",
         legend = TRUE)

# Save plot as PNG
if (!dir.exists("plots")) dir.create("plots")
png("plots/headcirc_centile_BCCG.png", width = 800, height = 600)
centiles(model_head,
         xvar = model_data_head$pma_weeks,
         cent = c(3,10,25,50,75,90,97),
         main = "Neonatal Head Circumference Centiles (BCCG)",
         xlab = "PMA (weeks)", ylab = "Head Circumference (cm)",
         legend = TRUE)
dev.off()

# Save the model for reuse
if (!dir.exists("models")) dir.create("models")
save(model_head, file = "models/model_head_BCCG.RData")
