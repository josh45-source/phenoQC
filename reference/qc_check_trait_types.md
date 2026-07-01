# Check Trait Column Types

Verifies that trait columns are numeric. Reports columns with
non-numeric values and provides examples.

## Usage

``` r
qc_check_trait_types(data, trait_cols)
```

## Arguments

- data:

  A data frame.

- trait_cols:

  Character vector. Names of trait columns to check.

## Value

A tibble with columns: `trait`, `is_numeric`, `n_non_numeric`,
`example_values`.
