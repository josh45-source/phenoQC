# Changelog

## phenoQC (development version)

### phenoQC 0.1.0

#### New features

- **Validation module**:
  [`qc_validate_structure()`](https://josh45-source.github.io/phenoQC/reference/qc_validate_structure.md),
  [`qc_check_duplicates()`](https://josh45-source.github.io/phenoQC/reference/qc_check_duplicates.md),
  [`qc_check_missing_plots()`](https://josh45-source.github.io/phenoQC/reference/qc_check_missing_plots.md),
  [`qc_check_trait_types()`](https://josh45-source.github.io/phenoQC/reference/qc_check_trait_types.md),
  [`qc_check_replication()`](https://josh45-source.github.io/phenoQC/reference/qc_check_replication.md),
  [`qc_check_controls()`](https://josh45-source.github.io/phenoQC/reference/qc_check_controls.md).
- **Outlier detection**:
  [`qc_outliers_statistical()`](https://josh45-source.github.io/phenoQC/reference/qc_outliers_statistical.md)
  (IQR, z-score, MAD),
  [`qc_outliers_spatial()`](https://josh45-source.github.io/phenoQC/reference/qc_outliers_spatial.md)
  (k-NN residuals),
  [`qc_outliers_by_group()`](https://josh45-source.github.io/phenoQC/reference/qc_outliers_by_group.md),
  [`qc_flag_outliers()`](https://josh45-source.github.io/phenoQC/reference/qc_flag_outliers.md)
  (combined),
  [`qc_plot_outliers()`](https://josh45-source.github.io/phenoQC/reference/qc_plot_outliers.md).
- **Spatial diagnostics**:
  [`qc_spatial_trend()`](https://josh45-source.github.io/phenoQC/reference/qc_spatial_trend.md)
  (loess surface),
  [`qc_plot_spatial()`](https://josh45-source.github.io/phenoQC/reference/qc_plot_spatial.md),
  [`qc_spatial_autocorrelation()`](https://josh45-source.github.io/phenoQC/reference/qc_spatial_autocorrelation.md)
  (Moran’s I).
- **Missing data**:
  [`qc_missing_summary()`](https://josh45-source.github.io/phenoQC/reference/qc_missing_summary.md),
  [`qc_missing_plot()`](https://josh45-source.github.io/phenoQC/reference/qc_missing_plot.md),
  [`qc_impute_spatial()`](https://josh45-source.github.io/phenoQC/reference/qc_impute_spatial.md)
  (k-NN / median neighbor imputation).
- **Main wrapper**:
  [`phenoqc()`](https://josh45-source.github.io/phenoQC/reference/phenoqc.md)
  runs the full QC pipeline and returns a `phenoqc_result` object with
  data, validation, outlier, missing, spatial, and cleaned data
  components.
- **Reporting**:
  [`qc_report()`](https://josh45-source.github.io/phenoQC/reference/qc_report.md)
  generates an HTML QC report.
- **Utilities**:
  [`detect_trait_cols()`](https://josh45-source.github.io/phenoQC/reference/detect_trait_cols.md)
  for auto-detection of numeric traits.
- Built-in `example_trial` dataset with deliberate QC issues.
