# Generate an HTML Quality Control Report

Takes a
[`phenoqc()`](https://josh45-source.github.io/phenoQC/reference/phenoqc.md)
result and renders an HTML report with validation results, missing data
visualization, outlier summaries, field heatmaps, and spatial trend
diagnostics.

## Usage

``` r
qc_report(
  result,
  output_file = "qc_report.html",
  title = "Phenotypic QC Report",
  open = interactive()
)
```

## Arguments

- result:

  A `phenoqc_result` object from
  [`phenoqc()`](https://josh45-source.github.io/phenoQC/reference/phenoqc.md).

- output_file:

  Character. Path for the output HTML file. Default `"qc_report.html"`.

- title:

  Character. Report title. Default `"Phenotypic QC Report"`.

- open:

  Logical. Open the report in a browser after rendering? Default `TRUE`
  in interactive sessions.

## Value

The path to the generated report (invisibly).

## Examples

``` r
if (FALSE) { # \dontrun{
data(example_trial)
result <- phenoqc(example_trial,
  trait_cols = c("yield", "plant_height", "days_to_flower")
)
qc_report(result, "my_trial_qc.html")
} # }
```
