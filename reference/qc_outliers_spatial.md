# Detect Spatial Outliers

Flags observations that are outliers relative to their spatial neighbors
in the field layout. Uses k-nearest-neighbor local means to compute
residuals, then flags observations with extreme residuals.

## Usage

``` r
qc_outliers_spatial(
  data,
  trait_cols,
  row_col = "row",
  col_col = "col",
  k = 8L,
  threshold = 3
)
```

## Arguments

- data:

  A data frame.

- trait_cols:

  Character vector. Names of numeric trait columns.

- row_col:

  Character. Name of the row position column. Default `"row"`.

- col_col:

  Character. Name of the column position column. Default `"col"`.

- k:

  Integer. Number of nearest neighbors to use. Default 8.

- threshold:

  Numeric. MAD multiplier for flagging. Default 3.

## Value

The input data frame with `{trait}_spatial_outlier` (logical) and
`{trait}_spatial_residual` (numeric) columns added.
