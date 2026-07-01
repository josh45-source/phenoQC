# ---- Missing Data Analysis ----


#' Summarise Missing Data
#'
#' Provides a per-trait summary of missing values.
#'
#' @param data A data frame.
#' @param trait_cols Character vector. Names of trait columns to check.
#'
#' @return A tibble with columns: `trait`, `n_total`, `n_missing`,
#'   `pct_missing`.
#'
#' @examples
#' \dontrun{
#' data(example_trial)
#' qc_missing_summary(example_trial, c("yield", "plant_height", "days_to_flower"))
#' }
#'
#' @export
qc_missing_summary <- function(data, trait_cols) {
  check_col_exists(data, trait_cols)

  map_dfr(trait_cols, function(col) {
    vals <- data[[col]]
    n_total <- length(vals)
    n_missing <- sum(is.na(vals))
    tibble(
      trait = col,
      n_total = n_total,
      n_missing = n_missing,
      pct_missing = round(100 * n_missing / n_total, 1)
    )
  })
}


#' Visualise Missing Data Patterns
#'
#' Creates a ggplot showing missing data across traits, either as a
#' summary bar chart or a field layout showing where values are missing.
#'
#' @param data A data frame.
#' @param trait_cols Character vector. Names of trait columns.
#' @param type Character. Plot type: `"bar"` for summary or `"field"`
#'   for spatial layout (requires row/col columns).
#' @param row_col Character. Row column (used if `type = "field"`).
#' @param col_col Character. Column column (used if `type = "field"`).
#'
#' @return A ggplot object.
#'
#' @export
qc_missing_plot <- function(data, trait_cols, type = "bar",
                            row_col = "row", col_col = "col") {
  check_col_exists(data, trait_cols)
  type <- match.arg(type, c("bar", "field"))

  if (type == "bar") {
    summary_data <- qc_missing_summary(data, trait_cols)

    ggplot(summary_data, aes(
      x = stats::reorder(.data$trait, .data$pct_missing),
      y = .data$pct_missing
    )) +
      geom_col(fill = "#E63946", alpha = 0.8) +
      geom_text(aes(label = paste0(.data$n_missing, " (", .data$pct_missing, "%)")),
        hjust = -0.1, size = 3.5
      ) +
      coord_flip() +
      theme_minimal() +
      labs(
        title = "Missing data by trait",
        x = NULL, y = "% Missing"
      ) +
      theme(plot.title = element_text(face = "bold"))
  } else {
    check_col_exists(data, c(row_col, col_col))

    # Long format: which trait is missing at each position
    missing_long <- data |>
      select(all_of(c(row_col, col_col, trait_cols))) |>
      pivot_longer(
        cols = all_of(trait_cols),
        names_to = "trait",
        values_to = "value"
      ) |>
      mutate(is_missing = is.na(.data$value))

    ggplot(missing_long, aes(
      x = .data[[col_col]], y = .data[[row_col]],
      fill = .data$is_missing
    )) +
      geom_tile(colour = "grey80", linewidth = 0.3) +
      scale_fill_manual(
        values = c("FALSE" = "#457B9D", "TRUE" = "#E63946"),
        labels = c("Present", "Missing"),
        name = NULL
      ) +
      facet_wrap(~trait) +
      coord_fixed() +
      theme_minimal() +
      labs(title = "Missing data field layout", x = col_col, y = row_col) +
      theme(
        panel.grid = element_blank(),
        strip.text = element_text(face = "bold"),
        plot.title = element_text(face = "bold")
      )
  }
}


#' Impute Missing Values Using Spatial Neighbors
#'
#' Fills missing trait values using the k nearest non-missing neighbors
#' in the field layout.
#'
#' @param data A data frame.
#' @param trait Character. Name of the trait column to impute.
#' @param row_col Character. Row position column. Default `"row"`.
#' @param col_col Character. Column position column. Default `"col"`.
#' @param method Character. Imputation method: `"knn"` (weighted mean)
#'   or `"median"` (median of neighbors). Default `"knn"`.
#' @param k Integer. Number of nearest neighbors. Default 5.
#'
#' @return The data frame with imputed values in the trait column and a
#'   new `{trait}_imputed` logical column flagging which values were imputed.
#'
#' @export
qc_impute_spatial <- function(data, trait,
                              row_col = "row", col_col = "col",
                              method = "knn", k = 5L) {
  check_col_exists(data, c(trait, row_col, col_col))
  method <- match.arg(method, c("knn", "median"))

  vals <- data[[trait]]
  missing_idx <- which(is.na(vals))

  if (length(missing_idx) == 0) {
    cli_alert_info("No missing values in {.field {trait}} -- nothing to impute.")
    data[[paste0(trait, "_imputed")]] <- FALSE
    return(data)
  }

  coords <- cbind(data[[row_col]], data[[col_col]])
  dist_mat <- as.matrix(dist(coords))

  imputed_flag <- rep(FALSE, nrow(data))

  for (i in missing_idx) {
    distances <- dist_mat[i, ]
    distances[i] <- Inf

    # Find k nearest neighbors with non-NA values
    non_na_idx <- which(!is.na(vals))
    if (length(non_na_idx) == 0) next

    neighbor_dists <- distances[non_na_idx]
    top_k <- non_na_idx[order(neighbor_dists)[seq_len(min(k, length(non_na_idx)))]]

    if (method == "knn") {
      # Inverse-distance weighted mean
      d <- distances[top_k]
      d[d == 0] <- 0.001
      weights <- 1 / d
      vals[i] <- sum(weights * vals[top_k]) / sum(weights)
    } else {
      vals[i] <- median(vals[top_k], na.rm = TRUE)
    }

    imputed_flag[i] <- TRUE
  }

  data[[trait]] <- round(vals, 3)
  data[[paste0(trait, "_imputed")]] <- imputed_flag

  n_imputed <- sum(imputed_flag)
  cli_alert_success("Imputed {n_imputed} missing value(s) in {.field {trait}} using {method}.")

  data
}
