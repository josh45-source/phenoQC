
<!-- README.md is generated from README.Rmd. Please edit that file -->

# phenoQC <a href="https://github.com/josh45-source/phenoQC"><img src="man/figures/logo.png" align="right" height="139" alt="phenoQC logo" /></a>

<!-- badges: start -->

[![R-CMD-check](https://github.com/josh45-source/phenoQC/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/josh45-source/phenoQC/actions/workflows/R-CMD-check.yaml)
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

**phenoQC** provides automated, reproducible quality control for
phenotypic data from plant breeding field trials. It detects spatial
outliers, validates trial structure, diagnoses spatial trends, and
generates HTML QC reports — all from a single function call.

## How it differs from AllInOne-P

| Feature             | phenoQC                       | AllInOne-P               |
|---------------------|-------------------------------|--------------------------|
| Interface           | Programmatic (pipe-friendly)  | Shiny GUI                |
| Use case            | Automated pipelines, batch QC | Interactive exploration  |
| Spatial outliers    | k-NN neighbor residuals       | Quantile/Cook’s distance |
| Field heatmaps      | Built-in ggplot2              | Shiny widgets            |
| Reports             | Automated HTML generation     | Interactive dashboard    |
| brapiR2 integration | Direct                        | None                     |

**phenoQC complements AllInOne-P** — use AllInOne-P for interactive data
exploration, use phenoQC for reproducible QC pipelines you run on every
trial.

## Installation

``` r
# install.packages("remotes")
remotes::install_github("josh45-source/phenoQC")
```

## Quick Start

``` r
library(phenoQC)

# Load example data
data(example_trial)

# Run full QC with one function call
result <- phenoqc(
  example_trial,
  trait_cols = c("yield", "plant_height", "days_to_flower")
)

# View summary
summary(result)

# Generate HTML report
qc_report(result, "trial_qc_report.html")
```

## Use Individual Functions

``` r
# Validate trial structure
qc_validate_structure(example_trial,
  trait_cols = c("yield", "plant_height"))

# Detect statistical outliers
flagged <- qc_outliers_statistical(example_trial, "yield", method = "iqr")

# Detect spatial outliers (catches what IQR misses)
flagged <- qc_outliers_spatial(example_trial, "yield")

# Visualise outliers on field layout
qc_plot_outliers(flagged, "yield")

# Check for spatial trends
trended <- qc_spatial_trend(example_trial, "plant_height")
qc_plot_spatial(trended, "plant_height")

# Impute missing values using spatial neighbors
imputed <- qc_impute_spatial(example_trial, "yield")
```

## Integration with brapiR2

``` r
library(brapiR2)
library(phenoQC)

# Pull data from BreedBase
con <- brapi_connection("https://my-breedbase.org")
con <- brapi_login(con, "user", "pass")
data <- brapi_study_data(con, "my_study")

# QC it
result <- phenoqc(data, trait_cols = c("yield", "plant_height"))
qc_report(result, "breedbase_qc.html")

# Use cleaned data for analysis
clean <- result$cleaned_data
```

## License

MIT

## Support This Project

If phenoQC has been useful to you, please consider sponsoring its development on Patreon — it helps keep the project maintained.

[![Support on Patreon](https://img.shields.io/badge/Patreon-Support-f96854?logo=patreon&logoColor=white)](https://www.patreon.com/cw/Joshfarm)
