# Run Complete Phenotypic Quality Control

The main entry point for phenoQC. Runs the full QC pipeline on a trial
data frame: structure validation, missing data summary, outlier
detection, and spatial trend diagnostics.

## Usage

``` r
phenoqc(
  data,
  trait_cols,
  row_col = "row",
  col_col = "col",
  gen_col = "genotype",
  rep_col = "rep",
  control_names = NULL,
  outlier_methods = c("iqr", "spatial"),
  iqr_threshold = 1.5,
  spatial_k = 8L,
  check_spatial_trend = TRUE,
  impute_missing = FALSE
)
```

## Arguments

- data:

  A data frame of trial data.

- trait_cols:

  Character vector. Names of numeric trait columns to QC.

- row_col:

  Character. Row position column. Default `"row"`.

- col_col:

  Character. Column position column. Default `"col"`.

- gen_col:

  Character. Genotype column. Default `"genotype"`.

- rep_col:

  Character. Replicate column. Default `"rep"`.

- control_names:

  Character vector or NULL. Known check/control names.

- outlier_methods:

  Character vector. Outlier methods to apply. Default
  `c("iqr", "spatial")`.

- iqr_threshold:

  Numeric. IQR multiplier for outlier detection. Default 1.5.

- spatial_k:

  Integer. Neighbors for spatial outlier detection. Default 8.

- check_spatial_trend:

  Logical. Whether to run spatial trend analysis. Default TRUE.

- impute_missing:

  Logical. Whether to impute missing values using spatial neighbors.
  Default FALSE.

## Value

An S3 object of class `"phenoqc_result"` containing:

- data:

  The original data with all QC flag columns added.

- validation:

  Trial structure validation summary.

- outliers:

  Outlier summary per trait.

- missing:

  Missing data summary.

- spatial:

  Spatial trend diagnostics (if run).

- cleaned_data:

  Data with outliers set to NA.

- summary:

  One-line-per-trait overview.

- params:

  Parameters used for the QC run.

## Examples

``` r
if (FALSE) { # \dontrun{
data(example_trial)
result <- phenoqc(
  example_trial,
  trait_cols = c("yield", "plant_height", "days_to_flower")
)
result
summary(result)
} # }
```
