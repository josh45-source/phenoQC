# Detect Statistical Outliers

Flags observations as outliers using IQR, z-score, or MAD methods.

## Usage

``` r
qc_outliers_statistical(data, trait_cols, method = "iqr", threshold = NULL)
```

## Arguments

- data:

  A data frame.

- trait_cols:

  Character vector. Names of numeric trait columns.

- method:

  Character. One of `"iqr"`, `"zscore"`, or `"mad"`.

- threshold:

  Numeric. Multiplier for the outlier boundary. Default 1.5 for IQR, 3
  for z-score/MAD.

## Value

The input data frame with additional columns for each trait:
`{trait}_outlier` (logical) and `{trait}_zscore` (numeric). An
`"outlier_summary"` attribute is attached with per-trait counts.

## Examples

``` r
if (FALSE) { # \dontrun{
data(example_trial)
result <- qc_outliers_statistical(example_trial, c("yield", "plant_height"))
attr(result, "outlier_summary")
} # }
```
