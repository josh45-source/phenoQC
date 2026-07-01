# phenoQC (development version)

## phenoQC 0.1.0

### New features

* **Validation module**: `qc_validate_structure()`, `qc_check_duplicates()`,
  `qc_check_missing_plots()`, `qc_check_trait_types()`,
  `qc_check_replication()`, `qc_check_controls()`.
* **Outlier detection**: `qc_outliers_statistical()` (IQR, z-score, MAD),
  `qc_outliers_spatial()` (k-NN residuals), `qc_outliers_by_group()`,
  `qc_flag_outliers()` (combined), `qc_plot_outliers()`.
* **Spatial diagnostics**: `qc_spatial_trend()` (loess surface),
  `qc_plot_spatial()`, `qc_spatial_autocorrelation()` (Moran's I).
* **Missing data**: `qc_missing_summary()`, `qc_missing_plot()`,
  `qc_impute_spatial()` (k-NN / median neighbor imputation).
* **Main wrapper**: `phenoqc()` runs the full QC pipeline and returns
  a `phenoqc_result` object with data, validation, outlier, missing,
  spatial, and cleaned data components.
* **Reporting**: `qc_report()` generates an HTML QC report.
* **Utilities**: `detect_trait_cols()` for auto-detection of numeric traits.
* Built-in `example_trial` dataset with deliberate QC issues.
