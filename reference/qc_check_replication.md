# Check Replication Balance

Checks whether each genotype has the expected number of replicates.

## Usage

``` r
qc_check_replication(data, gen_col = "genotype", rep_col = "rep")
```

## Arguments

- data:

  A data frame.

- gen_col:

  Character. Name of the genotype column.

- rep_col:

  Character. Name of the replicate column.

## Value

A tibble with columns: `genotype`, `expected_reps`, `actual_reps`,
`status` ("balanced", "under-replicated", "over-replicated").
