# Spatial Outlier Detection and Trend Diagnostics

``` r

library(phenoQC)
data(example_trial)
```

## Why spatial methods?

Field trials are laid out in a grid, and neighbouring plots are rarely
independent: soil fertility gradients, moisture, shading, and management
effects all vary smoothly across a field. A purely statistical outlier
method like IQR or z-score treats every observation as exchangeable and
ignores this structure – it can miss a plot that is perfectly “normal”
relative to the whole trial but starkly different from its immediate
neighbours (and it can also over-flag values that are extreme overall
but expected given a strong field trend).

phenoQC offers both:

- [`qc_outliers_statistical()`](https://josh45-source.github.io/phenoQC/reference/qc_outliers_statistical.md)
  – IQR, z-score, or MAD outlier rules applied to the trait’s overall
  distribution.
- [`qc_outliers_spatial()`](https://josh45-source.github.io/phenoQC/reference/qc_outliers_spatial.md)
  – flags plots that deviate from the mean of their *k* nearest field
  neighbours.

This vignette shows a case in `example_trial` where the two methods
disagree, then covers the spatial trend and autocorrelation diagnostics.

## A case where spatial catches what IQR misses

`example_trial$plant_height` has a deliberate left-to-right spatial
gradient baked in (taller plants in higher-numbered columns), on top of
the usual plot-to-plot noise. Run both outlier methods on it:

``` r

ph_iqr <- qc_outliers_statistical(example_trial, "plant_height", method = "iqr")
ph_spatial <- qc_outliers_spatial(example_trial, "plant_height")

sum(ph_iqr$plant_height_outlier, na.rm = TRUE)
#> [1] 0

sum(ph_spatial$plant_height_spatial_outlier, na.rm = TRUE)
#> [1] 1
```

IQR finds nothing unusual – every plant height value falls within a
plausible range for the trial as a whole. The spatial method flags one
plot:

``` r

only_spatial <- which(ph_spatial$plant_height_spatial_outlier &
  !ph_iqr$plant_height_outlier)
example_trial[only_spatial, c("row", "col", "genotype", "plant_height")]
#>    row col genotype plant_height
#> 18   2   8     G031         79.3
```

At column 8, the field-wide gradient means most plots are quite tall
(column position pushes plant height up in this trial). A height of 79.3
cm is unremarkable trial-wide, but it is well below what its immediate
neighbours in columns 7-9 are showing – exactly the kind of local
anomaly
[`qc_outliers_spatial()`](https://josh45-source.github.io/phenoQC/reference/qc_outliers_spatial.md)
is designed to catch and that a global IQR rule, by construction, cannot
see.

Note the reverse also happens with `yield`: its single extreme value
(18.5 t/ha at row 5, col 10) is so far outside the trial’s range that
*both* methods agree on it – spatial methods complement statistical
ones, they don’t replace them. In practice,
[`qc_flag_outliers()`](https://josh45-source.github.io/phenoQC/reference/qc_flag_outliers.md)
(used internally by
[`phenoqc()`](https://josh45-source.github.io/phenoQC/reference/phenoqc.md))
runs both and combines their flags.

## Detecting and visualising spatial trends

[`qc_spatial_trend()`](https://josh45-source.github.io/phenoQC/reference/qc_spatial_trend.md)
fits a 2D loess surface over the field coordinates and reports how much
of the trait’s variance the spatial trend explains:

``` r

trend_result <- qc_spatial_trend(example_trial, "plant_height")
attr(trend_result, "spatial_diagnostic")
#> # A tibble: 1 × 6
#>   trait        var_raw var_trend var_ratio has_trend interpretation
#>   <chr>          <dbl>     <dbl>     <dbl> <lgl>     <chr>
#> 1 plant_height    43.7      22.8     0.521 TRUE      Strong spatial trend detected
```

Over half of the raw variance in `plant_height` is explained by its
position in the field (`var_ratio = 0.521`) – confirming the gradient we
know is there by design. Compare that to `yield`, which has no designed
spatial structure:

``` r

attr(qc_spatial_trend(example_trial, "yield"), "spatial_diagnostic")
#> # A tibble: 1 × 6
#>   trait var_raw var_trend var_ratio has_trend interpretation
#>   <chr>   <dbl>     <dbl>     <dbl> <lgl>     <chr>
#> 1 yield    1.58     0.103    0.0651 FALSE     No significant spatial trend
```

### Plotting raw values, trend, and residuals

[`qc_plot_spatial()`](https://josh45-source.github.io/phenoQC/reference/qc_plot_spatial.md)
facets the raw field layout, the fitted trend surface, and the residuals
side by side:

``` r

qc_plot_spatial(trend_result, "plant_height")
```

The raw and trend panels should look visibly similar (a left-to-right
colour gradient) if a genuine spatial trend is present; the residual
panel is where any remaining spatial anomalies – like row 18 above –
become easier to spot visually.

## Testing spatial autocorrelation with Moran’s I

Beyond the loess-based trend test,
[`qc_spatial_autocorrelation()`](https://josh45-source.github.io/phenoQC/reference/qc_spatial_autocorrelation.md)
computes Moran’s I, a formal statistic for whether nearby plots are more
similar than expected under spatial randomness.

``` r

qc_spatial_autocorrelation(example_trial, "plant_height")
#> $statistic
#> [1] 0.1311
#>
#> $expected
#> [1] -0.0052
#>
#> $p_value
#> [1] 0
#>
#> $interpretation
#> [1] "Significant positive spatial autocorrelation (clustering)"
```

A positive Moran’s I well above the expected value under the null, with
a p-value of essentially 0, confirms significant spatial clustering in
`plant_height` – consistent with the trend result above.

Compare with a trait that has no spatial structure:

``` r

qc_spatial_autocorrelation(example_trial, "yield")
#> $statistic
#> [1] -0.0091
#>
#> $expected
#> [1] -0.0052
#>
#> $p_value
#> [1] 0.7219
#>
#> $interpretation
#> [1] "No significant spatial autocorrelation"
```

``` r

qc_spatial_autocorrelation(example_trial, "days_to_flower")
#> $statistic
#> [1] -0.0051
#>
#> $expected
#> [1] -0.0051
#>
#> $p_value
#> [1] 0.9998
#>
#> $interpretation
#> [1] "No significant spatial autocorrelation"
```

For both `yield` and `days_to_flower`, the observed Moran’s I is close
to its expectation and the p-value is large – no evidence of spatial
autocorrelation, matching the fact that neither trait was designed with
a field trend.

## Recommended workflow

1.  Run
    [`qc_spatial_autocorrelation()`](https://josh45-source.github.io/phenoQC/reference/qc_spatial_autocorrelation.md)
    per trait as a quick screening test.
2.  For traits with significant autocorrelation, follow up with
    [`qc_spatial_trend()`](https://josh45-source.github.io/phenoQC/reference/qc_spatial_trend.md)
    to quantify and visualise the trend, and consider whether it
    reflects real field variation that should be modelled (e.g. with a
    spatial mixed model) rather than treated as noise.
3.  Always run
    [`qc_outliers_spatial()`](https://josh45-source.github.io/phenoQC/reference/qc_outliers_spatial.md)
    alongside a statistical method –
    [`phenoqc()`](https://josh45-source.github.io/phenoQC/reference/phenoqc.md)
    does this by default via `outlier_methods = c("iqr", "spatial")` –
    so that local anomalies aren’t missed just because they look
    unremarkable at the whole-trial level.
