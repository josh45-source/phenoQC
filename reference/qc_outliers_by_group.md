# Detect Outliers Within Groups

Runs IQR outlier detection within each level of a grouping variable
(e.g. within each genotype or each replicate).

## Usage

``` r
qc_outliers_by_group(data, trait_cols, group_col, threshold = 1.5)
```

## Arguments

- data:

  A data frame.

- trait_cols:

  Character vector. Names of numeric trait columns.

- group_col:

  Character. Name of the grouping column.

- threshold:

  Numeric. IQR multiplier. Default 1.5.

## Value

The input data frame with `{trait}_group_outlier` columns.
