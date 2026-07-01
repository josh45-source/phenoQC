# ---- QC Report Generation ----


#' Generate an HTML Quality Control Report
#'
#' Takes a [phenoqc()] result and renders an HTML report with
#' validation results, missing data visualization, outlier summaries,
#' field heatmaps, and spatial trend diagnostics.
#'
#' @param result A `phenoqc_result` object from [phenoqc()].
#' @param output_file Character. Path for the output HTML file.
#'   Default `"qc_report.html"`.
#' @param title Character. Report title. Default
#'   `"Phenotypic QC Report"`.
#' @param open Logical. Open the report in a browser after rendering?
#'   Default `TRUE` in interactive sessions.
#'
#' @return The path to the generated report (invisibly).
#'
#' @examples
#' \dontrun{
#' data(example_trial)
#' result <- phenoqc(example_trial,
#'   trait_cols = c("yield", "plant_height", "days_to_flower")
#' )
#' qc_report(result, "my_trial_qc.html")
#' }
#'
#' @export
qc_report <- function(result,
                      output_file = "qc_report.html",
                      title = "Phenotypic QC Report",
                      open = interactive()) {
  if (!inherits(result, "phenoqc_result")) {
    cli_abort("{.arg result} must be a {.cls phenoqc_result} from {.fn phenoqc}.")
  }

  if (!requireNamespace("rmarkdown", quietly = TRUE)) {
    cli_abort("Install {.pkg rmarkdown} to generate QC reports.")
  }

  if (!requireNamespace("knitr", quietly = TRUE)) {
    cli_abort("Install {.pkg knitr} to generate QC reports.")
  }

  # Find the template
  template <- system.file("templates", "qc_report.Rmd", package = "phenoQC")
  if (template == "") {
    cli_abort("Report template not found. Reinstall phenoQC.")
  }

  # Render
  output_file <- normalizePath(output_file, mustWork = FALSE)

  cli_alert_info("Rendering QC report to {.path {output_file}}...")

  output <- rmarkdown::render(
    input = template,
    output_file = output_file,
    params = list(
      result = result,
      title = title
    ),
    envir = new.env(parent = globalenv()),
    quiet = TRUE
  )

  cli_alert_success("Report saved to {.path {output}}")

  if (open) {
    utils::browseURL(output)
  }

  invisible(output)
}
