make_test_data <- function(n = 20) {
  set.seed(123)
  data.frame(
    row = rep(1:5, each = 4),
    col = rep(1:4, times = 5),
    rep = rep(1:2, each = 10),
    genotype = paste0("G", sprintf("%02d", rep(1:10, each = 2))),
    yield = rnorm(n, 5, 1),
    plant_height = rnorm(n, 80, 5),
    stringsAsFactors = FALSE
  )
}

test_that("qc_outliers_statistical detects extreme values with IQR", {
  d <- make_test_data()
  d$yield[1] <- 50 # extreme outlier

  result <- qc_outliers_statistical(d, "yield", method = "iqr")
  expect_true("yield_outlier" %in% names(result))
  expect_true(result$yield_outlier[1])
  expect_true("yield_zscore" %in% names(result))
})

test_that("qc_outliers_statistical works with zscore method", {
  d <- make_test_data()
  d$yield[1] <- 50

  result <- qc_outliers_statistical(d, "yield", method = "zscore")
  expect_true(result$yield_outlier[1])
})

test_that("qc_outliers_statistical works with mad method", {
  d <- make_test_data()
  d$yield[1] <- 50

  result <- qc_outliers_statistical(d, "yield", method = "mad")
  expect_true(result$yield_outlier[1])
})

test_that("qc_outliers_statistical attaches summary attribute", {
  d <- make_test_data()
  result <- qc_outliers_statistical(d, c("yield", "plant_height"))
  summary <- attr(result, "outlier_summary")
  expect_s3_class(summary, "tbl_df")
  expect_equal(nrow(summary), 2)
})

test_that("qc_outliers_statistical handles all-NA column", {
  d <- make_test_data()
  d$yield <- NA_real_
  result <- qc_outliers_statistical(d, "yield")
  expect_true("yield_outlier" %in% names(result))
  expect_true(all(!result$yield_outlier))
})

test_that("qc_outliers_spatial detects spatially anomalous values", {
  d <- make_test_data()
  # Make one plot very different from neighbors
  d$yield[10] <- 50

  result <- qc_outliers_spatial(d, "yield")
  expect_true("yield_spatial_outlier" %in% names(result))
  expect_true("yield_spatial_residual" %in% names(result))
})

test_that("qc_flag_outliers creates combined flags", {
  d <- make_test_data()
  d$yield[1] <- 50

  result <- qc_flag_outliers(d, "yield", methods = c("iqr", "spatial"))
  expect_true("yield_flagged" %in% names(result))
  expect_true("flag_count" %in% names(result))
  expect_true(result$yield_flagged[1])
})

test_that("qc_plot_outliers returns a ggplot", {
  d <- make_test_data()
  d <- qc_flag_outliers(d, "yield")

  p <- qc_plot_outliers(d, "yield")
  expect_s3_class(p, "ggplot")
})
