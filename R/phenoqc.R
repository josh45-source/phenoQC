# ---- Main QC Wrapper ----


#' Run Complete Phenotypic Quality Control
#'
#' The main entry point for phenoQC. Runs the full QC pipeline on a trial
#' data frame: structure validation, missing data summary, outlier detection,
#' and spatial trend diagnostics.
#'
#' @param data A data frame of trial data.
#' @param trait_cols Character vector. Names of numeric trait columns to QC.
#' @param row_col Character. Row position column. Default `"row"`.
#' @param col_col Character. Column position column. Default `"col"`.
#' @param gen_col Character. Genotype column. Default `"genotype"`.
#' @param rep_col Character. Replicate column. Default `"rep"`.
#' @param control_names Character vector or NULL. Known check/control names.
#' @param outlier_methods Character vector. Outlier methods to apply.
#'   Default `c("iqr", "spatial")`.
#' @param iqr_threshold Numeric. IQR multiplier for outlier detection.
#'   Default 1.5.
#' @param spatial_k Integer. Neighbors for spatial outlier detection.
#'   Default 8.
#' @param check_spatial_trend Logical. Whether to run spatial trend analysis.
#'   Default TRUE.
#' @param impute_missing Logical. Whether to impute missing values using
#'   spatial neighbors. Default FALSE.
#'
#' @return An S3 object of class `"phenoqc_result"` containing:
#' \describe{
#'   \item{data}{The original data with all QC flag columns added.}
#'   \item{validation}{Trial structure validation summary.}
#'   \item{outliers}{Outlier summary per trait.}
#'   \item{missing}{Missing data summary.}
#'   \item{spatial}{Spatial trend diagnostics (if run).}
#'   \item{cleaned_data}{Data with outliers set to NA.}
#'   \item{summary}{One-line-per-trait overview.}
#'   \item{params}{Parameters used for the QC run.}
#' }
#'
#' @examples
#' \dontrun{
#' data(example_trial)
#' result <- phenoqc(
#'   example_trial,
#'   trait_cols = c("yield", "plant_height", "days_to_flower")
#' )
#' result
#' summary(result)
#' }
#'
#' @export
phenoqc <- function(data,
                    trait_cols,
                    row_col = "row",
                    col_col = "col",
                    gen_col = "genotype",
                    rep_col = "rep",
                    control_names = NULL,
                    outlier_methods = c("iqr", "spatial"),
                    iqr_threshold = 1.5,
                    spatial_k = 8L,
                    check_spatial_trend = TRUE,
                    impute_missing = FALSE) {
  cli_h1("phenoQC: Phenotypic Data Quality Control")

  # ---- 1. Validate structure ----
  cli_h2("Step 1: Validating trial structure")
  validation <- qc_validate_structure(
    data, row_col, col_col, rep_col, gen_col, trait_cols
  )
  n_issues <- sum(validation$status != "pass")
  if (n_issues == 0) {
    cli_alert_success("All structure checks passed.")
  } else {
    cli_alert_warning("{n_issues} issue(s) found in trial structure.")
  }

  # ---- 2. Missing data ----
  cli_h2("Step 2: Analysing missing data")
  missing_summary <- qc_missing_summary(data, trait_cols)
  total_missing <- sum(missing_summary$n_missing)
  cli_alert_info("{total_missing} missing value(s) across {length(trait_cols)} trait(s).")

  # ---- 3. Outlier detection ----
  cli_h2("Step 3: Detecting outliers")
  qc_data <- qc_flag_outliers(
    data, trait_cols,
    methods = outlier_methods,
    row_col = row_col, col_col = col_col,
    iqr_threshold = iqr_threshold,
    spatial_k = spatial_k
  )
  outlier_summary <- attr(qc_data, "outlier_summary")
  if (is.null(outlier_summary)) {
    outlier_summary <- tibble(
      trait = trait_cols,
      n_outliers = 0L
    )
  }
  total_outliers <- sum(outlier_summary$n_outliers, na.rm = TRUE)
  cli_alert_info("{total_outliers} outlier(s) flagged.")

  # ---- 4. Spatial trends ----
  spatial_results <- NULL
  if (check_spatial_trend) {
    cli_h2("Step 4: Checking spatial trends")
    spatial_results <- list()
    for (trait in trait_cols) {
      qc_data <- qc_spatial_trend(qc_data, trait, row_col, col_col)
      diag <- attr(qc_data, "spatial_diagnostic")
      if (!is.null(diag)) spatial_results[[trait]] <- diag
    }
    spatial_results <- bind_rows(spatial_results)
    n_trends <- sum(spatial_results$has_trend, na.rm = TRUE)
    if (n_trends > 0) {
      cli_alert_warning("{n_trends} trait(s) show spatial trend.")
    } else {
      cli_alert_success("No significant spatial trends detected.")
    }
  }

  # ---- 5. Imputation ----
  if (impute_missing && total_missing > 0) {
    cli_h2("Step 5: Imputing missing values")
    for (trait in trait_cols) {
      if (sum(is.na(qc_data[[trait]])) > 0) {
        qc_data <- qc_impute_spatial(qc_data, trait, row_col, col_col)
      }
    }
  }

  # ---- 6. Create cleaned data ----
  cleaned <- qc_data
  for (trait in trait_cols) {
    flag_col <- paste0(trait, "_flagged")
    if (flag_col %in% names(cleaned)) {
      cleaned[[trait]][cleaned[[flag_col]] == TRUE] <- NA
    }
  }

  # ---- 7. Build summary ----
  trait_summary <- map_dfr(trait_cols, function(trait) {
    flag_col <- paste0(trait, "_flagged")
    n_flagged <- if (flag_col %in% names(qc_data)) {
      sum(qc_data[[flag_col]], na.rm = TRUE)
    } else {
      0L
    }
    n_miss <- sum(is.na(data[[trait]]))
    has_trend <- if (!is.null(spatial_results) && trait %in% spatial_results$trait) {
      spatial_results$has_trend[spatial_results$trait == trait]
    } else {
      NA
    }
    tibble(
      trait = trait,
      n_obs = sum(!is.na(data[[trait]])),
      n_missing = n_miss,
      n_outliers = n_flagged,
      spatial_trend = has_trend,
      mean_raw = round(mean(data[[trait]], na.rm = TRUE), 3),
      sd_raw = round(sd(data[[trait]], na.rm = TRUE), 3)
    )
  })

  # ---- Build result object ----
  result <- structure(
    list(
      data = qc_data,
      validation = validation,
      outliers = outlier_summary,
      missing = missing_summary,
      spatial = spatial_results,
      cleaned_data = cleaned,
      summary = trait_summary,
      params = list(
        trait_cols = trait_cols,
        row_col = row_col,
        col_col = col_col,
        gen_col = gen_col,
        rep_col = rep_col,
        outlier_methods = outlier_methods,
        iqr_threshold = iqr_threshold,
        spatial_k = spatial_k
      )
    ),
    class = "phenoqc_result"
  )

  cli_h2("QC Complete")
  cli_alert_success("Use {.fn summary} for an overview or {.fn qc_report} to generate an HTML report.")

  result
}


#' Print a phenoQC Result
#'
#' @param x A `phenoqc_result` object.
#' @param ... Ignored.
#' @return Invisibly returns `x`.
#' @export
print.phenoqc_result <- function(x, ...) {
  cli_h3("phenoQC Result")
  cli_ul(c(
    "Observations: {nrow(x$data)}",
    "Traits:       {paste(x$params$trait_cols, collapse = ', ')}",
    "Outliers:     {sum(x$summary$n_outliers)} total flagged",
    "Missing:      {sum(x$summary$n_missing)} total",
    "Spatial:      {sum(x$summary$spatial_trend, na.rm = TRUE)} trait(s) with trend"
  ))
  invisible(x)
}


#' Summarise a phenoQC Result
#'
#' @param object A `phenoqc_result` object.
#' @param ... Ignored.
#' @return The trait summary tibble (printed and returned invisibly).
#' @export
summary.phenoqc_result <- function(object, ...) {
  cli_h3("phenoQC Summary")
  print(object$summary)
  invisible(object$summary)
}
