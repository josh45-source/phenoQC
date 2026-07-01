# Flag Outliers Using Multiple Methods

Convenience wrapper that runs multiple outlier detection methods and
creates a combined flag for each trait.

## Usage

``` r
qc_flag_outliers(
  data,
  trait_cols,
  methods = c("iqr", "spatial"),
  row_col = "row",
  col_col = "col",
  iqr_threshold = 1.5,
  spatial_k = 8L
)
```

## Arguments

- data:

  A data frame.

- trait_cols:

  Character vector. Names of numeric trait columns.

- methods:

  Character vector. Methods to use: `"iqr"`, `"spatial"`, `"zscore"`,
  `"mad"`. Default `c("iqr", "spatial")`.

- row_col:

  Character. Row position column. Default `"row"`.

- col_col:

  Character. Column position column. Default `"col"`.

- iqr_threshold:

  Numeric. IQR multiplier. Default 1.5.

- spatial_k:

  Integer. Neighbors for spatial method. Default 8.

## Value

The input data with `{trait}_flagged` (logical) and `flag_count`
(integer) columns added.
