#' Example Field Trial Dataset
#'
#' A simulated field trial dataset with 200 observations for testing
#' phenoQC functions. The trial has 50 genotypes in 4 reps laid out
#' in a 10-column x 20-row grid. Includes deliberate quality issues:
#' duplicate plot coordinates, missing values, a non-numeric entry in
#' yield, and an unreplicated genotype.
#'
#' @format A data frame with 200 rows and 8 columns:
#' \describe{
#'   \item{row}{Integer. Row position in the field (1-20).}
#'   \item{col}{Integer. Column position in the field (1-10).}
#'   \item{rep}{Integer. Replicate number (1-4).}
#'   \item{block}{Integer. Incomplete block within rep (1-8).}
#'   \item{genotype}{Character. Genotype identifier (G001-G050 plus checks).}
#'   \item{yield}{Numeric. Grain yield in t/ha. Contains outliers and
#'     missing values.}
#'   \item{plant_height}{Numeric. Plant height in cm. Contains spatial trend.}
#'   \item{days_to_flower}{Numeric. Days from planting to 50% flowering.}
#' }
#'
#' @details
#' Known quality issues embedded in this dataset:
#' - 2 duplicate plot coordinates (same row+col)
#' - 3 missing values in yield
#' - 2 missing values in plant_height
#' - 1 extreme yield outlier (value > 15 t/ha)
#' - 1 genotype with only 1 rep instead of 4
#' - Spatial gradient in plant_height (increases from left to right)
#'
#' @examples
#' data(example_trial)
#' head(example_trial)
#' dim(example_trial)
#'
#' @source Simulated data for package testing.
"example_trial"
