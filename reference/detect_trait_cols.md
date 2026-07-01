# Auto-detect Numeric Trait Columns

Returns the names of all numeric columns in a data frame, excluding
common non-trait columns like row, col, rep, block, and ID columns.

## Usage

``` r
detect_trait_cols(data, exclude = NULL)
```

## Arguments

- data:

  A data frame.

- exclude:

  Character vector. Additional column names to exclude.

## Value

Character vector of numeric column names.

## Examples

``` r
if (FALSE) { # \dontrun{
data(example_trial)
detect_trait_cols(example_trial)
# [1] "yield" "plant_height" "days_to_flower"
} # }
```
