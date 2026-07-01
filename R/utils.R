# ---- Internal Utilities ----


#' Check That Required Columns Exist
#'
#' @param data A data frame.
#' @param cols Character vector. Column names to check for.
#'
#' @return Invisible NULL. Throws an error if any column is missing.
#' @keywords internal
check_col_exists <- function(data, cols) {
  missing_cols <- setdiff(cols, names(data))
  if (length(missing_cols) > 0) {
    cli_abort(
      "Column(s) not found in data: {.field {missing_cols}}",
      class = "phenoQC_missing_col"
    )
  }
  invisible(NULL)
}


#' Auto-detect Numeric Trait Columns
#'
#' Returns the names of all numeric columns in a data frame, excluding
#' common non-trait columns like row, col, rep, block, and ID columns.
#'
#' @param data A data frame.
#' @param exclude Character vector. Additional column names to exclude.
#'
#' @return Character vector of numeric column names.
#'
#' @examples
#' \dontrun{
#' data(example_trial)
#' detect_trait_cols(example_trial)
#' # [1] "yield" "plant_height" "days_to_flower"
#' }
#'
#' @export
detect_trait_cols <- function(data, exclude = NULL) {
  # Common non-trait column patterns
  non_trait_patterns <- c(
    "^row$", "^col$", "^rep$", "^block$", "^genotype$", "^entry$",
    "^plot$", "^range$", "^pass$", "^id$", "^name$", "^check$",
    "^treatment$", "^trt$", "^loc$", "^location$", "^env$",
    "^year$", "^season$", "^trial$", "^study$"
  )

  numeric_cols <- names(data)[sapply(data, is.numeric)]

  # Remove non-trait columns
  pattern <- paste(non_trait_patterns, collapse = "|")
  trait_cols <- numeric_cols[!grepl(pattern, numeric_cols, ignore.case = TRUE)]

  # Remove user-specified exclusions
  if (!is.null(exclude)) {
    trait_cols <- setdiff(trait_cols, exclude)
  }

  trait_cols
}
