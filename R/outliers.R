# ---- Outlier Detection ----
# Statistical and spatial outlier detection for field trial data.


#' Detect Statistical Outliers
#'
#' Flags observations as outliers using IQR, z-score, or MAD methods.
#'
#' @param data A data frame.
#' @param trait_cols Character vector. Names of numeric trait columns.
#' @param method Character. One of `"iqr"`, `"zscore"`, or `"mad"`.
#' @param threshold Numeric. Multiplier for the outlier boundary.
#'   Default 1.5 for IQR, 3 for z-score/MAD.
#'
#' @return The input data frame with additional columns for each trait:
#'   `{trait}_outlier` (logical) and `{trait}_zscore` (numeric).
#'   An `"outlier_summary"` attribute is attached with per-trait counts.
#'
#' @examples
#' \dontrun{
#' data(example_trial)
#' result <- qc_outliers_statistical(example_trial, c("yield", "plant_height"))
#' attr(result, "outlier_summary")
#' }
#'
#' @export
qc_outliers_statistical <- function(data, trait_cols,
                                    method = "iqr",
                                    threshold = NULL) {
  check_col_exists(data, trait_cols)
  method <- match.arg(method, c("iqr", "zscore", "mad"))

  if (is.null(threshold)) {
    threshold <- switch(method,
      iqr = 1.5,
      zscore = 3,
      mad = 3
    )
  }

  summary_rows <- list()

  for (trait in trait_cols) {
    vals <- data[[trait]]
    if (!is.numeric(vals)) {
      cli_alert_warning("Skipping non-numeric column: {.field {trait}}")
      next
    }

    outlier_flag <- rep(FALSE, length(vals))
    z_scores <- rep(NA_real_, length(vals))

    non_na <- !is.na(vals)

    if (method == "iqr") {
      q1 <- quantile(vals, 0.25, na.rm = TRUE)
      q3 <- quantile(vals, 0.75, na.rm = TRUE)
      iqr_val <- IQR(vals, na.rm = TRUE)
      lower <- q1 - threshold * iqr_val
      upper <- q3 + threshold * iqr_val
      outlier_flag[non_na] <- vals[non_na] < lower | vals[non_na] > upper
      trait_mean <- mean(vals, na.rm = TRUE)
      trait_sd <- sd(vals, na.rm = TRUE)
      if (!is.na(trait_sd) && trait_sd > 0) {
        z_scores[non_na] <- (vals[non_na] - trait_mean) / trait_sd
      }
    } else if (method == "zscore") {
      trait_mean <- mean(vals, na.rm = TRUE)
      trait_sd <- sd(vals, na.rm = TRUE)
      if (!is.na(trait_sd) && trait_sd > 0) {
        z_scores[non_na] <- (vals[non_na] - trait_mean) / trait_sd
        outlier_flag[non_na] <- abs(z_scores[non_na]) > threshold
      }
    } else if (method == "mad") {
      trait_median <- median(vals, na.rm = TRUE)
      trait_mad <- mad(vals, na.rm = TRUE)
      if (!is.na(trait_mad) && trait_mad > 0) {
        z_scores[non_na] <- (vals[non_na] - trait_median) / trait_mad
        outlier_flag[non_na] <- abs(z_scores[non_na]) > threshold
      }
    }

    data[[paste0(trait, "_outlier")]] <- outlier_flag
    data[[paste0(trait, "_zscore")]] <- round(z_scores, 3)

    summary_rows[[trait]] <- tibble(
      trait = trait,
      method = method,
      threshold = threshold,
      n_total = sum(non_na),
      n_outliers = sum(outlier_flag, na.rm = TRUE),
      pct_outliers = round(100 * sum(outlier_flag, na.rm = TRUE) / sum(non_na), 1)
    )
  }

  attr(data, "outlier_summary") <- bind_rows(summary_rows)
  data
}


#' Detect Spatial Outliers
#'
#' Flags observations that are outliers relative to their spatial neighbors
#' in the field layout. Uses k-nearest-neighbor local means to compute
#' residuals, then flags observations with extreme residuals.
#'
#' @param data A data frame.
#' @param trait_cols Character vector. Names of numeric trait columns.
#' @param row_col Character. Name of the row position column. Default `"row"`.
#' @param col_col Character. Name of the column position column. Default `"col"`.
#' @param k Integer. Number of nearest neighbors to use. Default 8.
#' @param threshold Numeric. MAD multiplier for flagging. Default 3.
#'
#' @return The input data frame with `{trait}_spatial_outlier` (logical)
#'   and `{trait}_spatial_residual` (numeric) columns added.
#'
#' @export
qc_outliers_spatial <- function(data, trait_cols,
                                row_col = "row", col_col = "col",
                                k = 8L, threshold = 3) {
  check_col_exists(data, c(trait_cols, row_col, col_col))

  # Compute distance matrix from field coordinates
  coords <- cbind(data[[row_col]], data[[col_col]])
  dist_mat <- as.matrix(dist(coords))

  for (trait in trait_cols) {
    vals <- data[[trait]]
    if (!is.numeric(vals)) next

    n <- length(vals)
    local_means <- rep(NA_real_, n)
    residuals_spatial <- rep(NA_real_, n)
    outlier_flag <- rep(FALSE, n)

    for (i in seq_len(n)) {
      if (is.na(vals[i])) next

      # Find k nearest neighbors (excluding self)
      distances <- dist_mat[i, ]
      distances[i] <- Inf # exclude self
      neighbor_idx <- order(distances)[seq_len(min(k, n - 1))]

      # Only use neighbors with non-NA values
      neighbor_vals <- vals[neighbor_idx]
      neighbor_vals <- neighbor_vals[!is.na(neighbor_vals)]

      if (length(neighbor_vals) >= 2) {
        local_means[i] <- mean(neighbor_vals)
        residuals_spatial[i] <- vals[i] - local_means[i]
      }
    }

    # Flag based on MAD of residuals
    resid_mad <- mad(residuals_spatial, na.rm = TRUE)
    resid_median <- median(residuals_spatial, na.rm = TRUE)

    if (!is.na(resid_mad) && resid_mad > 0) {
      non_na_resid <- !is.na(residuals_spatial)
      outlier_flag[non_na_resid] <-
        abs(residuals_spatial[non_na_resid] - resid_median) > threshold * resid_mad
    }

    data[[paste0(trait, "_spatial_outlier")]] <- outlier_flag
    data[[paste0(trait, "_spatial_residual")]] <- round(residuals_spatial, 3)
  }

  data
}


#' Detect Outliers Within Groups
#'
#' Runs IQR outlier detection within each level of a grouping variable
#' (e.g. within each genotype or each replicate).
#'
#' @param data A data frame.
#' @param trait_cols Character vector. Names of numeric trait columns.
#' @param group_col Character. Name of the grouping column.
#' @param threshold Numeric. IQR multiplier. Default 1.5.
#'
#' @return The input data frame with `{trait}_group_outlier` columns.
#'
#' @export
qc_outliers_by_group <- function(data, trait_cols, group_col,
                                 threshold = 1.5) {
  check_col_exists(data, c(trait_cols, group_col))

  for (trait in trait_cols) {
    if (!is.numeric(data[[trait]])) next

    data <- data |>
      group_by(.data[[group_col]]) |>
      mutate(
        "{trait}_group_outlier" := {
          vals <- .data[[trait]]
          q1 <- quantile(vals, 0.25, na.rm = TRUE)
          q3 <- quantile(vals, 0.75, na.rm = TRUE)
          iqr_val <- IQR(vals, na.rm = TRUE)
          !is.na(vals) & (vals < q1 - threshold * iqr_val |
            vals > q3 + threshold * iqr_val)
        }
      ) |>
      ungroup()
  }

  data
}


#' Flag Outliers Using Multiple Methods
#'
#' Convenience wrapper that runs multiple outlier detection methods and
#' creates a combined flag for each trait.
#'
#' @param data A data frame.
#' @param trait_cols Character vector. Names of numeric trait columns.
#' @param methods Character vector. Methods to use: `"iqr"`, `"spatial"`,
#'   `"zscore"`, `"mad"`. Default `c("iqr", "spatial")`.
#' @param row_col Character. Row position column. Default `"row"`.
#' @param col_col Character. Column position column. Default `"col"`.
#' @param iqr_threshold Numeric. IQR multiplier. Default 1.5.
#' @param spatial_k Integer. Neighbors for spatial method. Default 8.
#'
#' @return The input data with `{trait}_flagged` (logical) and
#'   `flag_count` (integer) columns added.
#'
#' @export
qc_flag_outliers <- function(data, trait_cols,
                             methods = c("iqr", "spatial"),
                             row_col = "row", col_col = "col",
                             iqr_threshold = 1.5,
                             spatial_k = 8L) {
  # Run statistical methods
  stat_methods <- intersect(methods, c("iqr", "zscore", "mad"))
  for (m in stat_methods) {
    th <- if (m == "iqr") iqr_threshold else 3
    data <- qc_outliers_statistical(data, trait_cols, method = m, threshold = th)
  }

  # Run spatial if requested
  if ("spatial" %in% methods) {
    data <- qc_outliers_spatial(data, trait_cols,
      row_col = row_col, col_col = col_col,
      k = spatial_k
    )
  }

  # Create combined flag per trait
  for (trait in trait_cols) {
    flag_cols <- c()
    if ("iqr" %in% methods) flag_cols <- c(flag_cols, paste0(trait, "_outlier"))
    if ("zscore" %in% methods) flag_cols <- c(flag_cols, paste0(trait, "_outlier"))
    if ("mad" %in% methods) flag_cols <- c(flag_cols, paste0(trait, "_outlier"))
    if ("spatial" %in% methods) flag_cols <- c(flag_cols, paste0(trait, "_spatial_outlier"))

    flag_cols <- intersect(flag_cols, names(data))
    if (length(flag_cols) > 0) {
      data[[paste0(trait, "_flagged")]] <- apply(
        data[, flag_cols, drop = FALSE], 1, any,
        na.rm = TRUE
      )
    }
  }

  # Total flag count across all traits
  flagged_cols <- grep("_flagged$", names(data), value = TRUE)
  if (length(flagged_cols) > 0) {
    data$flag_count <- rowSums(data[, flagged_cols, drop = FALSE], na.rm = TRUE)
  }

  data
}


#' Plot Outliers on Field Layout
#'
#' Creates a field heatmap showing trait values with outliers highlighted.
#'
#' @param data A data frame (with outlier columns from `qc_flag_outliers`
#'   or `qc_outliers_statistical`).
#' @param trait Character. Name of the trait column to plot.
#' @param row_col Character. Row position column. Default `"row"`.
#' @param col_col Character. Column position column. Default `"col"`.
#'
#' @return A ggplot object.
#'
#' @export
qc_plot_outliers <- function(data, trait, row_col = "row", col_col = "col") {
  check_col_exists(data, c(trait, row_col, col_col))

  # Determine which outlier flag column to use
  flag_col <- paste0(trait, "_flagged")
  if (!flag_col %in% names(data)) {
    flag_col <- paste0(trait, "_outlier")
  }
  if (!flag_col %in% names(data)) {
    flag_col <- paste0(trait, "_spatial_outlier")
  }

  p <- ggplot(data, aes(x = .data[[col_col]], y = .data[[row_col]])) +
    geom_tile(aes(fill = .data[[trait]]), colour = "grey80", linewidth = 0.3) +
    scale_fill_viridis_c(na.value = "grey90", name = trait) +
    coord_fixed() +
    theme_minimal() +
    labs(
      title = glue("Field heatmap: {trait}"),
      x = col_col,
      y = row_col
    ) +
    theme(
      panel.grid = element_blank(),
      plot.title = element_text(face = "bold", size = 14)
    )

  # Overlay outlier markers if flag column exists
  if (flag_col %in% names(data)) {
    outlier_data <- data |> filter(.data[[flag_col]] == TRUE)
    if (nrow(outlier_data) > 0) {
      p <- p + geom_point(
        data = outlier_data,
        aes(x = .data[[col_col]], y = .data[[row_col]]),
        shape = 4, size = 4, colour = "red", stroke = 2
      )
    }
  }

  p
}
