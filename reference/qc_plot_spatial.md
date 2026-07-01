# Plot Spatial Field Heatmap

Creates a field layout heatmap showing raw values, fitted trend, or
residuals.

## Usage

``` r
qc_plot_spatial(
  data,
  trait,
  row_col = "row",
  col_col = "col",
  what = c("raw", "trend", "residual")
)
```

## Arguments

- data:

  A data frame (with trend/residual columns from
  [`qc_spatial_trend()`](https://josh45-source.github.io/phenoQC/reference/qc_spatial_trend.md)).

- trait:

  Character. Base trait name.

- row_col:

  Character. Row position column. Default `"row"`.

- col_col:

  Character. Column position column. Default `"col"`.

- what:

  Character vector. What to display: `"raw"`, `"trend"`, and/or
  `"residual"`. Default shows all three.

## Value

A ggplot object (faceted if multiple `what` values).
