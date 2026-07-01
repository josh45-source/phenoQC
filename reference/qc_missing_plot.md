# Visualise Missing Data Patterns

Creates a ggplot showing missing data across traits, either as a summary
bar chart or a field layout showing where values are missing.

## Usage

``` r
qc_missing_plot(
  data,
  trait_cols,
  type = "bar",
  row_col = "row",
  col_col = "col"
)
```

## Arguments

- data:

  A data frame.

- trait_cols:

  Character vector. Names of trait columns.

- type:

  Character. Plot type: `"bar"` for summary or `"field"` for spatial
  layout (requires row/col columns).

- row_col:

  Character. Row column (used if `type = "field"`).

- col_col:

  Character. Column column (used if `type = "field"`).

## Value

A ggplot object.
