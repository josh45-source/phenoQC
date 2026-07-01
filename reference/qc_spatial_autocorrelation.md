# Test Spatial Autocorrelation (Moran's I)

Calculates Moran's I statistic to test whether trait values are
spatially autocorrelated in the field layout.

## Usage

``` r
qc_spatial_autocorrelation(data, trait, row_col = "row", col_col = "col")
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

## Value

A list with components: `statistic` (Moran's I value), `expected`
(expected I under null), `p_value`, `interpretation`.
