# Check for Duplicate Plot Coordinates

Detects rows with identical (row, col) positions.

## Usage

``` r
qc_check_duplicates(data, row_col = "row", col_col = "col")
```

## Arguments

- data:

  A data frame.

- row_col:

  Character. Name of the row column.

- col_col:

  Character. Name of the column column.

## Value

A tibble of duplicated positions with all columns from the original
data.
