# Validate Trial Structure

Runs all structure validation checks on a trial data frame and returns a
summary of issues found. This is the first step in any QC pipeline.

## Usage

``` r
qc_validate_structure(
  data,
  row_col = "row",
  col_col = "col",
  rep_col = "rep",
  gen_col = "genotype",
  trait_cols = NULL
)
```

## Arguments

- data:

  A data frame of trial data.

- row_col:

  Character. Name of the row position column. Default `"row"`.

- col_col:

  Character. Name of the column position column. Default `"col"`.

- rep_col:

  Character. Name of the replicate column. Default `"rep"`.

- gen_col:

  Character. Name of the genotype column. Default `"genotype"`.

- trait_cols:

  Character vector. Names of trait (numeric) columns to check.

## Value

A tibble with columns: `check`, `status` (pass/warn/fail), `n_issues`,
`details`.

## Examples

``` r
if (FALSE) { # \dontrun{
data(example_trial)
qc_validate_structure(
  example_trial,
  trait_cols = c("yield", "plant_height", "days_to_flower")
)
} # }
```
