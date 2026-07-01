# Detect and Extract Spatial Trends

Fits a 2D loess surface to a trait using field coordinates and returns
the trend, residuals, and a diagnostic indicating whether a significant
spatial trend exists.

## Usage

``` r
qc_spatial_trend(data, trait, row_col = "row", col_col = "col", span = 0.5)
```

## Arguments

- data:

  A data frame.

- trait:

  Character. Name of the trait column.

- row_col:

  Character. Row position column. Default `"row"`.

- col_col:

  Character. Column position column. Default `"col"`.

- span:

  Numeric. Smoothing parameter for loess. Default 0.5.

## Value

The input data frame with `{trait}_trend` and `{trait}_residual` columns
added. An attribute `"spatial_diagnostic"` contains a tibble with trend
strength metrics.
