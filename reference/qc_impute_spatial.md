# Impute Missing Values Using Spatial Neighbors

Fills missing trait values using the k nearest non-missing neighbors in
the field layout.

## Usage

``` r
qc_impute_spatial(
  data,
  trait,
  row_col = "row",
  col_col = "col",
  method = "knn",
  k = 5L
)
```

## Arguments

- data:

  A data frame.

- trait:

  Character. Name of the trait column to impute.

- row_col:

  Character. Row position column. Default `"row"`.

- col_col:

  Character. Column position column. Default `"col"`.

- method:

  Character. Imputation method: `"knn"` (weighted mean) or `"median"`
  (median of neighbors). Default `"knn"`.

- k:

  Integer. Number of nearest neighbors. Default 5.

## Value

The data frame with imputed values in the trait column and a new
`{trait}_imputed` logical column flagging which values were imputed.
