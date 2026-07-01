# Example Field Trial Dataset

A simulated field trial dataset with 200 observations for testing
phenoQC functions. The trial has 50 genotypes in 4 reps laid out in a
10-column x 20-row grid. Includes deliberate quality issues: duplicate
plot coordinates, missing values, a non-numeric entry in yield, and an
unreplicated genotype.

## Usage

``` r
example_trial
```

## Format

A data frame with 200 rows and 8 columns:

- row:

  Integer. Row position in the field (1-20).

- col:

  Integer. Column position in the field (1-10).

- rep:

  Integer. Replicate number (1-4).

- block:

  Integer. Incomplete block within rep (1-8).

- genotype:

  Character. Genotype identifier (G001-G050 plus checks).

- yield:

  Numeric. Grain yield in t/ha. Contains outliers and missing values.

- plant_height:

  Numeric. Plant height in cm. Contains spatial trend.

- days_to_flower:

  Numeric. Days from planting to 50% flowering.

## Source

Simulated data for package testing.

## Details

Known quality issues embedded in this dataset:

- 2 duplicate plot coordinates (same row+col)

- 3 missing values in yield

- 2 missing values in plant_height

- 1 extreme yield outlier (value \> 15 t/ha)

- 1 genotype with only 1 rep instead of 4

- Spatial gradient in plant_height (increases from left to right)

## Examples

``` r
data(example_trial)
head(example_trial)
#>   row col rep block genotype yield plant_height days_to_flower
#> 1   1   1   1     1   CHECK1  5.39         83.8             67
#> 2   1   2   1     1     G037  4.84         83.3             66
#> 3   1   3   1     1     G001  4.26         81.9             64
#> 4   1   4   1     1     G025  4.85         85.3             64
#> 5   1   5   1     1     G010  4.06         82.6             62
#> 6   1   5   1     1     G036  5.91         92.3             69
dim(example_trial)
#> [1] 197   8
```
