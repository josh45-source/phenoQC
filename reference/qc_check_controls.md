# Check Control/Check Genotype Distribution

Verifies that control genotypes appear in every replicate or block.

## Usage

``` r
qc_check_controls(
  data,
  gen_col = "genotype",
  rep_col = "rep",
  control_names = NULL
)
```

## Arguments

- data:

  A data frame.

- gen_col:

  Character. Name of the genotype column.

- rep_col:

  Character. Name of the replicate column.

- control_names:

  Character vector or NULL. Names of known controls. If NULL,
  auto-detects genotypes appearing in all reps.

## Value

A tibble with control names and their rep/block coverage.
