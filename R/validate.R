# ---- Trial Structure Validation ----
# Functions that check data integrity before statistical analysis.


#' Validate Trial Structure
#'
#' Runs all structure validation checks on a trial data frame and returns
#' a summary of issues found. This is the first step in any QC pipeline.
#'
#' @param data A data frame of trial data.
#' @param row_col Character. Name of the row position column. Default `"row"`.
#' @param col_col Character. Name of the column position column. Default `"col"`.
#' @param rep_col Character. Name of the replicate column. Default `"rep"`.
#' @param gen_col Character. Name of the genotype column. Default `"genotype"`.
#' @param trait_cols Character vector. Names of trait (numeric) columns to check.
#'
#' @return A tibble with columns: `check`, `status` (pass/warn/fail),
#'   `n_issues`, `details`.
#'
#' @examples
#' \dontrun{
#' data(example_trial)
#' qc_validate_structure(
#'   example_trial,
#'   trait_cols = c("yield", "plant_height", "days_to_flower")
#' )
#' }
#'
#' @export
qc_validate_structure <- function(data,
                                  row_col = "row",
                                  col_col = "col",
                                  rep_col = "rep",
                                  gen_col = "genotype",
                                  trait_cols = NULL) {
  results <- list()

  # Check duplicates, scoped within replicate by default so a field grid
  # reused across reps/environments isn't mistaken for one giant duplicate.
  dup_group_cols <- if (rep_col %in% names(data)) rep_col else NULL
  dups <- qc_check_duplicates(data, row_col, col_col, group_cols = dup_group_cols)
  n_dups <- nrow(dups)
  results[[length(results) + 1]] <- tibble(
    check = "Duplicate plot coordinates",
    status = if (n_dups == 0) "pass" else "fail",
    n_issues = n_dups,
    details = if (n_dups == 0) {
      "No duplicates found"
    } else {
      glue("{n_dups} duplicate position(s) detected")
    }
  )

  # Check missing plots
  missing_plots <- qc_check_missing_plots(data, row_col, col_col)
  n_missing <- nrow(missing_plots)
  results[[length(results) + 1]] <- tibble(
    check = "Missing plot positions",
    status = if (n_missing == 0) "pass" else "warn",
    n_issues = n_missing,
    details = if (n_missing == 0) {
      "Grid is complete"
    } else {
      glue("{n_missing} position(s) missing from grid")
    }
  )

  # Check trait types
  if (!is.null(trait_cols)) {
    types <- qc_check_trait_types(data, trait_cols)
    n_bad <- sum(types$n_non_numeric > 0)
    results[[length(results) + 1]] <- tibble(
      check = "Trait column types",
      status = if (n_bad == 0) "pass" else "fail",
      n_issues = n_bad,
      details = if (n_bad == 0) {
        "All trait columns are numeric"
      } else {
        glue("{n_bad} column(s) have non-numeric values")
      }
    )
  }

  # Check replication
  if (rep_col %in% names(data) && gen_col %in% names(data)) {
    rep_check <- qc_check_replication(data, gen_col, rep_col)
    n_unbalanced <- sum(rep_check$status != "balanced")
    results[[length(results) + 1]] <- tibble(
      check = "Replication balance",
      status = if (n_unbalanced == 0) "pass" else "warn",
      n_issues = n_unbalanced,
      details = if (n_unbalanced == 0) {
        "All genotypes equally replicated"
      } else {
        glue("{n_unbalanced} genotype(s) with unequal replication")
      }
    )
  }

  bind_rows(results)
}


#' Check for Duplicate Plot Coordinates
#'
#' Detects rows with identical (row, col) positions. In multi-environment
#' or multi-replicate trials the same physical grid is normally reused for
#' every environment/rep, so duplicates should be checked *within* those
#' groups rather than across the whole dataset.
#'
#' @param data A data frame.
#' @param row_col Character. Name of the row column.
#' @param col_col Character. Name of the column column.
#' @param group_cols Character vector or `NULL`. Columns that define separate
#'   trials/blocks (e.g. `c("env", "rep")`) within which `(row, col)` must be
#'   unique. If `NULL` (default), auto-detects any of `env`, `rep`,
#'   `location`, `site`, `trial`, `study` present in `data` (case
#'   insensitive) and uses those as the grouping columns. Pass
#'   `character(0)` to force a global (ungrouped) check.
#'
#' @return A tibble of duplicated positions with all columns from the
#'   original data.
#'
#' @export
qc_check_duplicates <- function(data, row_col = "row", col_col = "col",
                                group_cols = NULL) {
  check_col_exists(data, c(row_col, col_col))

  if (is.null(group_cols)) {
    candidates <- c("env", "rep", "location", "site", "trial", "study")
    group_cols <- names(data)[tolower(names(data)) %in% candidates]
    group_cols <- setdiff(group_cols, c(row_col, col_col))
  } else {
    check_col_exists(data, group_cols)
  }

  key_cols <- c(group_cols, row_col, col_col)

  data |>
    group_by(across(all_of(key_cols))) |>
    filter(n() > 1) |>
    ungroup() |>
    arrange(across(all_of(key_cols)))
}


#' Check for Missing Plot Positions
#'
#' Compares the observed (row, col) grid against a complete rectangular
#' grid and identifies gaps.
#'
#' @param data A data frame.
#' @param row_col Character. Name of the row column.
#' @param col_col Character. Name of the column column.
#'
#' @return A tibble of (row, col) positions that are missing from the data.
#'
#' @export
qc_check_missing_plots <- function(data, row_col = "row", col_col = "col") {
  check_col_exists(data, c(row_col, col_col))

  rows <- data[[row_col]]
  cols <- data[[col_col]]

  full_grid <- tidyr::expand_grid(
    !!row_col := seq(min(rows, na.rm = TRUE), max(rows, na.rm = TRUE)),
    !!col_col := seq(min(cols, na.rm = TRUE), max(cols, na.rm = TRUE))
  )

  observed <- data |>
    select(all_of(c(row_col, col_col))) |>
    distinct()

  dplyr::anti_join(full_grid, observed, by = c(row_col, col_col))
}


#' Check Trait Column Types
#'
#' Verifies that trait columns are numeric. Reports columns with
#' non-numeric values and provides examples.
#'
#' @param data A data frame.
#' @param trait_cols Character vector. Names of trait columns to check.
#'
#' @return A tibble with columns: `trait`, `is_numeric`, `n_non_numeric`,
#'   `example_values`.
#'
#' @export
qc_check_trait_types <- function(data, trait_cols) {
  check_col_exists(data, trait_cols)

  map_dfr(trait_cols, function(col) {
    vals <- data[[col]]
    if (is.numeric(vals)) {
      tibble(
        trait = col,
        is_numeric = TRUE,
        n_non_numeric = 0L,
        example_values = NA_character_
      )
    } else {
      # Try to coerce and see what fails
      numeric_vals <- suppressWarnings(as.numeric(vals))
      bad_idx <- which(is.na(numeric_vals) & !is.na(vals))
      tibble(
        trait = col,
        is_numeric = FALSE,
        n_non_numeric = length(bad_idx),
        example_values = paste(head(vals[bad_idx], 3), collapse = ", ")
      )
    }
  })
}


#' Check Replication Balance
#'
#' Checks whether each genotype has the expected number of replicates.
#'
#' @param data A data frame.
#' @param gen_col Character. Name of the genotype column.
#' @param rep_col Character. Name of the replicate column.
#'
#' @return A tibble with columns: `genotype`, `expected_reps`, `actual_reps`,
#'   `status` ("balanced", "under-replicated", "over-replicated").
#'
#' @export
qc_check_replication <- function(data, gen_col = "genotype", rep_col = "rep") {
  check_col_exists(data, c(gen_col, rep_col))

  rep_counts <- data |>
    group_by(.data[[gen_col]]) |>
    summarise(actual_reps = n(), .groups = "drop")

  # Expected = mode of rep counts
  expected <- as.integer(names(sort(table(rep_counts$actual_reps),
    decreasing = TRUE
  ))[1])

  rep_counts |>
    mutate(
      expected_reps = expected,
      status = dplyr::case_when(
        actual_reps == expected ~ "balanced",
        actual_reps < expected ~ "under-replicated",
        actual_reps > expected ~ "over-replicated"
      )
    ) |>
    rename(genotype = !!gen_col) |>
    arrange(.data$status, .data$actual_reps)
}


#' Check Control/Check Genotype Distribution
#'
#' Verifies that control genotypes appear in every replicate or block.
#'
#' @param data A data frame.
#' @param gen_col Character. Name of the genotype column.
#' @param rep_col Character. Name of the replicate column.
#' @param control_names Character vector or NULL. Names of known controls.
#'   If NULL, auto-detects genotypes appearing in all reps.
#'
#' @return A tibble with control names and their rep/block coverage.
#'
#' @export
qc_check_controls <- function(data, gen_col = "genotype", rep_col = "rep",
                              control_names = NULL) {
  check_col_exists(data, c(gen_col, rep_col))

  n_reps <- length(unique(data[[rep_col]]))

  if (is.null(control_names)) {
    # Auto-detect: genotypes in all reps
    controls <- data |>
      group_by(.data[[gen_col]]) |>
      summarise(
        reps_present = length(unique(.data[[rep_col]])),
        total_plots = n(),
        .groups = "drop"
      ) |>
      filter(.data$reps_present == n_reps & .data$total_plots > n_reps)

    cli_alert_info("Auto-detected {nrow(controls)} potential control(s).")
  } else {
    controls <- data |>
      filter(.data[[gen_col]] %in% control_names) |>
      group_by(.data[[gen_col]]) |>
      summarise(
        reps_present = length(unique(.data[[rep_col]])),
        total_plots = n(),
        .groups = "drop"
      )
  }

  controls |>
    mutate(
      total_reps = n_reps,
      complete = .data$reps_present == n_reps
    ) |>
    rename(genotype = !!gen_col)
}
