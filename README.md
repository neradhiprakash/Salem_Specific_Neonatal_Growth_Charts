# Salem-Specific Neonatal Growth Charts

This repository contains the complete modelling pipeline, plots, and final report for constructing **longitudinal growth centile charts** (weight, length, and head circumference) for **preterm infants** using the **GAMLSS** framework.  
The models use LMS-style age-varying smoothers to estimate centiles from postmenstrual age (PMA) 25–40 weeks.

> **Note:** No patient-level hospital data is included. All sensitive datasets were excluded in compliance with confidentiality requirements.


## Table of Contents
- [Project Overview](#project-overview)
- [Summary of Findings](#summary-of-findings)
- [Methodology](#methodology)
  - [1. Data Preparation](#1-data-preparation-performed-locally)
  - [2. Normality Testing](#2-normality-testing)
  - [3. Modelling Approach](#3-modelling-approach)
  - [4. Centile Extraction](#4-centile-extraction)
- [Repository Structure](#repository-structure)
- [Citation](#citation)


## Project Overview

The goal of this project is to build **neonatal growth standards specific to a specific population to understand the needs and benchmarks in that geography** by fitting smooth, biologically interpretable centile curves using three GAMLSS families:

- **BCCG** — Box-Cox Cole–Green (3-parameter)
- **BCPE** — Box-Cox Power Exponential (4-parameter)
- **BCT** — Box-Cox t (4-parameter)

These families allow modelling of:
- **Location** (median)
- **Scale** (spread)
- **Skewness**
- **Tail weight** (BCPE, BCT only)

The final model for each anthropometric measure is selected using **GAIC (k = 2)**.

---

## Summary of Findings

Across all three measures — **weight**, **length**, and **head circumference** — the **BCPE** family produced the best fit (lowest GAIC), with strongest improvement in:

- **Weight:** ΔGAIC 44–61 across other families  
- **Head circumference:** ΔGAIC ~15–23  
- **Length:** Smaller but consistent improvement  

BCPE’s flexibility in modelling skewness and tail heaviness produced more reliable extreme centiles (3rd and 97th), which is clinically critical.

Full details are available in the **final report**:  
📄 [`report/Growth_Charts.pdf`](report/Growth_Charts.pdf)



## Methodology

### 1. Data Preparation (performed locally)
- Standardised missing values  
- Converted weight_g → weight_kg  
- Trimmed text fields  
- Deduplicated repeated infant × PMA measurements  
  - Weight → **average**  
  - Length/head circumference → **maximum**  
- Cleaned dataset (5207 observations, 320 infants)

> The cleaned dataset is **not included** in the repository.


### 2. Normality Testing  
Both **Shapiro–Wilk** and **Lilliefors** tests were applied  
(see report for plots & p-values).  
All three measures showed non-normality, supporting flexible distribution modelling.


### 3. Modelling Approach  
Each model includes smooth penalised B-spline terms:

- **µ (median):** `pb(PMA, df = 4)`  
- **σ (scale):** `pb(PMA, df = 2)`  
- **ν (skewness):** `pb(PMA, df = 2)`  
- **τ (tail weight):** `pb(PMA, df = 2 or 3)` for BCPE/BCT  


### 4. Centile Extraction  
Centiles generated:  
**3rd, 10th, 25th, 50th, 75th, 90th, 97th**

Using:

```r
centiles(model, cent = c(3, 10, 25, 50, 75, 90, 97))

```
## Repository Structure

```text
Salem_Specific_Neonatal_Growth_Charts/
│
├── models/
│   ├── head_cm/
│   │   ├── head_circ_cms.R
│   │   └── bccg_headcirc_centile_model.R
│   │
│   ├── length_cm/
│   │   ├── length_centile_cms.R
│   │   └── bccg_length_centile_model.R
│   │
│   └── weight_kg/
│       ├── weight_centile_log.R
│       ├── weight_centile_kgs.R
│       └── bccg_weight_centile_model.R
│
├── plots/
│   ├── head_cm/
│   ├── length_cm/
│   └── weight_kg/
│
├── report/
│   └── Growth_Charts.pdf
│
└── .gitignore

```
## How to Run This Project

1. Prepare your own cleaned neonatal dataset (not included in this repo).
2. Update the file path in each model script under `models/<measure>/`.
3. Run the scripts in the following order:
   - Data loading + preprocessing (if using your own pipeline)
   - Model fitting (`bccg_*.R`, `bcpe_*.R`, `bct_*.R`)
   - Centile extraction
4. To reproduce the charts, run the plotting scripts in:
  plots/head_cm/
  plots/length_cm/
  plots/weight_kg/
5. Refer to the final PDF report for expected outputs and diagnostic tables.

## Data Confidentiality

This project was developed using sensitive hospital-derived neonatal data.  
To ensure privacy and compliance:

- No `.csv`, `.xlsx`, `.RData`, or `.rds` files are included.
- `.gitignore` fully excludes patient-level data from version control.
- Only model scripts, plots, and non-identifiable outputs are shared.

Users of this repository must supply their own dataset to reproduce results.

## Citation

If you use or reference this work, please cite both:

### 1. This Repository
Prakash, N. (2025). *Salem-Specific Neonatal Growth Charts using GAMLSS.*  
GitHub Repository: https://github.com/neradhiprakash/Salem_Specific_Neonatal_Growth_Charts

### 2. Reference Methodology (LMS-based longitudinal growth chart construction)
Young, A., Andrews, E. T., Ashton, J. J., Pearson, F., Beattie, R. M., & Johnson, M. J. (2020).  
*Generating longitudinal growth charts from preterm infants fed to current recommendations.*  
**Archives of Disease in Childhood – Fetal and Neonatal Edition, 105**, F646–F651.  
https://doi.org/10.1136/archdischild-2019-318404 :contentReference[oaicite:1]{index=1}

## Contact

For questions, feedback, or collaboration:  
**aneradhiprakash@gmail.com**

