# ---- Spatial Trend Diagnostics ----


#' Detect and Extract Spatial Trends
#'
#' Fits a 2D loess surface to a trait using field coordinates and returns
#' the trend, residuals, and a diagnostic indicating whether a significant
#' spatial trend exists.
#'
#' @param data A data frame.
#' @param trait Character. Name of the trait column.
#' @param row_col Character. Row position column. Default `"row"`.
#' @param col_col Character. Column position column. Default `"col"`.
#' @param span Numeric. Smoothing parameter for loess. Default 0.5.
#'
#' @return The input data frame with `{trait}_trend` and `{trait}_residual`
#'   columns added. An attribute `"spatial_diagnostic"` contains a tibble
#'   with trend strength metrics.
#'
#' @export
qc_spatial_trend <- function(data, trait, row_col = "row", col_col = "col",
                             span = 0.5) {
  check_col_exists(data, c(trait, row_col, col_col))

  complete_idx <- complete.cases(data[, c(trait, row_col, col_col)])
  trend_vals <- rep(NA_real_, nrow(data))
  resid_vals <- rep(NA_real_, nrow(data))

  if (sum(complete_idx) < 10) {
    cli_alert_warning("Too few complete cases for spatial trend estimation.")
    data[[paste0(trait, "_trend")]] <- trend_vals
    data[[paste0(trait, "_residual")]] <- resid_vals
    return(data)
  }

  # Fit 2D loess
  fit <- tryCatch(
    loess(
      as.formula(paste(trait, "~", row_col, "*", col_col)),
      data = data[complete_idx, ],
      span = span
    ),
    error = function(e) NULL
  )

  if (is.null(fit)) {
    cli_alert_warning("Loess fitting failed for {.field {trait}}. Trying linear model.")
    fit <- lm(
      as.formula(paste(trait, "~", row_col, "+", col_col)),
      data = data[complete_idx, ]
    )
  }

  predicted <- predict(fit, newdata = data[complete_idx, ])
  trend_vals[complete_idx] <- round(predicted, 3)
  resid_vals[complete_idx] <- round(data[[trait]][complete_idx] - predicted, 3)

  data[[paste0(trait, "_trend")]] <- trend_vals
  data[[paste0(trait, "_residual")]] <- resid_vals

  # Diagnostic: proportion of variance explained by trend
  var_raw <- var(data[[trait]], na.rm = TRUE)
  var_trend <- var(predicted, na.rm = TRUE)
  var_ratio <- if (var_raw > 0) var_trend / var_raw else 0

  diagnostic <- tibble(
    trait = trait,
    var_raw = round(var_raw, 4),
    var_trend = round(var_trend, 4),
    var_ratio = round(var_ratio, 4),
    has_trend = var_ratio > 0.1,
    interpretation = dplyr::case_when(
      var_ratio > 0.3 ~ "Strong spatial trend detected",
      var_ratio > 0.1 ~ "Moderate spatial trend detected",
      TRUE ~ "No significant spatial trend"
    )
  )

  attr(data, "spatial_diagnostic") <- diagnostic
  data
}


#' Plot Spatial Field Heatmap
#'
#' Creates a field layout heatmap showing raw values, fitted trend, or
#' residuals.
#'
#' @param data A data frame (with trend/residual columns from
#'   [qc_spatial_trend()]).
#' @param trait Character. Base trait name.
#' @param row_col Character. Row position column. Default `"row"`.
#' @param col_col Character. Column position column. Default `"col"`.
#' @param what Character vector. What to display: `"raw"`, `"trend"`,
#'   and/or `"residual"`. Default shows all three.
#'
#' @return A ggplot object (faceted if multiple `what` values).
#'
#' @export
qc_plot_spatial <- function(data, trait, row_col = "row", col_col = "col",
                            what = c("raw", "trend", "residual")) {
  check_col_exists(data, c(row_col, col_col))

  # Build long-format data for faceting
  plot_data <- list()

  if ("raw" %in% what && trait %in% names(data)) {
    plot_data[["Raw"]] <- data |>
      select(all_of(c(row_col, col_col, trait))) |>
      mutate(panel = "Raw", value = .data[[trait]])
  }

  trend_col <- paste0(trait, "_trend")
  if ("trend" %in% what && trend_col %in% names(data)) {
    plot_data[["Trend"]] <- data |>
      select(all_of(c(row_col, col_col, trend_col))) |>
      mutate(panel = "Trend", value = .data[[trend_col]])
  }

  resid_col <- paste0(trait, "_residual")
  if ("residual" %in% what && resid_col %in% names(data)) {
    plot_data[["Residual"]] <- data |>
      select(all_of(c(row_col, col_col, resid_col))) |>
      mutate(panel = "Residual", value = .data[[resid_col]])
  }

  if (length(plot_data) == 0) {
    cli_abort("No plottable columns found. Run {.fn qc_spatial_trend} first.")
  }

  combined <- bind_rows(plot_data)
  combined$panel <- factor(combined$panel, levels = c("Raw", "Trend", "Residual"))

  ggplot(combined, aes(x = .data[[col_col]], y = .data[[row_col]], fill = .data$value)) +
    geom_tile(colour = "grey80", linewidth = 0.3) +
    scale_fill_viridis_c(na.value = "grey90", name = trait) +
    facet_wrap(~panel, scales = "free") +
    coord_fixed() +
    theme_minimal() +
    labs(
      title = glue("Spatial diagnostics: {trait}"),
      x = col_col, y = row_col
    ) +
    theme(
      panel.grid = element_blank(),
      strip.text = element_text(face = "bold"),
      plot.title = element_text(face = "bold", size = 14)
    )
}


#' Test Spatial Autocorrelation (Moran's I)
#'
#' Calculates Moran's I statistic to test whether trait values are
#' spatially autocorrelated in the field layout.
#'
#' @param data A data frame.
#' @param trait Character. Name of the trait column.
#' @param row_col Character. Row position column. Default `"row"`.
#' @param col_col Character. Column position column. Default `"col"`.
#'
#' @return A list with components: `statistic` (Moran's I value),
#'   `expected` (expected I under null), `p_value`, `interpretation`.
#'
#' @export
qc_spatial_autocorrelation <- function(data, trait,
                                       row_col = "row", col_col = "col") {
  check_col_exists(data, c(trait, row_col, col_col))

  complete_idx <- complete.cases(data[, c(trait, row_col, col_col)])
  x <- data[[trait]][complete_idx]
  coords <- cbind(data[[row_col]][complete_idx], data[[col_col]][complete_idx])

  n <- length(x)
  if (n < 5) {
    return(list(
      statistic = NA_real_,
      expected = NA_real_,
      p_value = NA_real_,
      interpretation = "Too few observations"
    ))
  }

  # Inverse distance weight matrix
  d <- as.matrix(dist(coords))
  diag(d) <- Inf
  w <- 1 / d
  w[is.infinite(w)] <- 0

  # Normalize weights
  row_sums <- rowSums(w)
  row_sums[row_sums == 0] <- 1
  w <- w / row_sums

  # Moran's I
  x_bar <- mean(x)
  x_dev <- x - x_bar
  num <- sum(w * outer(x_dev, x_dev))
  denom <- sum(x_dev^2)

  moran_i <- if (denom > 0) (n / sum(w)) * (num / denom) else 0
  expected_i <- -1 / (n - 1)

  # Approximate p-value (normal approximation)
  s2 <- sum(x_dev^2) / n
  s_sq <- sum((w + t(w))^2) / 2
  var_i <- (n^2 * s_sq - n * sum(rowSums(w)^2 + colSums(w)^2) +
    3 * sum(w)^2) / ((n^2 - 1) * sum(w)^2)

  z <- (moran_i - expected_i) / sqrt(abs(var_i))
  p_value <- 2 * (1 - stats::pnorm(abs(z)))

  interpretation <- dplyr::case_when(
    p_value > 0.05 ~ "No significant spatial autocorrelation",
    moran_i > 0 ~ "Significant positive spatial autocorrelation (clustering)",
    TRUE ~ "Significant negative spatial autocorrelation (dispersion)"
  )

  list(
    statistic = round(moran_i, 4),
    expected = round(expected_i, 4),
    p_value = round(p_value, 4),
    interpretation = interpretation
  )
}
