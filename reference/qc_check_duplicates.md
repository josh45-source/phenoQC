# Check for Duplicate Plot Coordinates

Detects rows with identical (row, col) positions. In multi-environment
or multi-replicate trials the same physical grid is normally reused for
every environment/rep, so duplicates should be checked *within* those
groups rather than across the whole dataset.

## Usage

``` r
qc_check_duplicates(data, row_col = "row", col_col = "col", group_cols = NULL)
```

## Arguments

- data:

  A data frame.

- row_col:

  Character. Name of the row column.

- col_col:

  Character. Name of the column column.

- group_cols:

  Character vector or `NULL`. Columns that define separate trials/blocks
  (e.g. `c("env", "rep")`) within which `(row, col)` must be unique. If
  `NULL` (default), auto-detects any of `env`, `rep`, `location`,
  `site`, `trial`, `study` present in `data` (case insensitive) and uses
  those as the grouping columns. Pass `character(0)` to force a global
  (ungrouped) check.

## Value

A tibble of duplicated positions with all columns from the original
data.
