# Check for Missing Plot Positions

Compares the observed (row, col) grid against a complete rectangular
grid and identifies gaps.

## Usage

``` r
qc_check_missing_plots(data, row_col = "row", col_col = "col")
```

## Arguments

- data:

  A data frame.

- row_col:

  Character. Name of the row column.

- col_col:

  Character. Name of the column column.

## Value

A tibble of (row, col) positions that are missing from the data.
