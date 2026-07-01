# Summarise Missing Data

Provides a per-trait summary of missing values.

## Usage

``` r
qc_missing_summary(data, trait_cols)
```

## Arguments

- data:

  A data frame.

- trait_cols:

  Character vector. Names of trait columns to check.

## Value

A tibble with columns: `trait`, `n_total`, `n_missing`, `pct_missing`.

## Examples

``` r
if (FALSE) { # \dontrun{
data(example_trial)
qc_missing_summary(example_trial, c("yield", "plant_height", "days_to_flower"))
} # }
```
