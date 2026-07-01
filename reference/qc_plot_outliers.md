# Plot Outliers on Field Layout

Creates a field heatmap showing trait values with outliers highlighted.

## Usage

``` r
qc_plot_outliers(data, trait, row_col = "row", col_col = "col")
```

## Arguments

- data:

  A data frame (with outlier columns from `qc_flag_outliers` or
  `qc_outliers_statistical`).

- trait:

  Character. Name of the trait column to plot.

- row_col:

  Character. Row position column. Default `"row"`.

- col_col:

  Character. Column position column. Default `"col"`.

## Value

A ggplot object.
