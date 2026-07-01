make_test_data <- function(n = 20) {
  set.seed(42)
  data.frame(
    row = rep(1:5, each = 4),
    col = rep(1:4, times = 5),
    rep = rep(1:2, each = 10),
    genotype = paste0("G", sprintf("%02d", rep(1:10, each = 2))),
    yield = rnorm(n, 5, 1),
    plant_height = 80 + rep(1:4, times = 5) * 2 + rnorm(n, 0, 1),
    stringsAsFactors = FALSE
  )
}

# ---- Spatial tests ----

test_that("qc_spatial_trend fits and returns trend columns", {
  d <- make_test_data()
  result <- qc_spatial_trend(d, "plant_height")

  expect_true("plant_height_trend" %in% names(result))
  expect_true("plant_height_residual" %in% names(result))
})

test_that("qc_spatial_trend attaches diagnostic attribute", {
  d <- make_test_data()
  result <- qc_spatial_trend(d, "plant_height")
  diag <- attr(result, "spatial_diagnostic")

  expect_s3_class(diag, "tbl_df")
  expect_true("var_ratio" %in% names(diag))
  expect_true("has_trend" %in% names(diag))
})

test_that("qc_plot_spatial returns ggplot", {
  d <- make_test_data()
  d <- qc_spatial_trend(d, "plant_height")

  p <- qc_plot_spatial(d, "plant_height")
  expect_s3_class(p, "ggplot")
})

test_that("qc_spatial_autocorrelation returns expected structure", {
  d <- make_test_data()
  result <- qc_spatial_autocorrelation(d, "plant_height")

  expect_type(result, "list")
  expect_true("statistic" %in% names(result))
  expect_true("p_value" %in% names(result))
  expect_true("interpretation" %in% names(result))
})

# ---- Missing data tests ----

test_that("qc_missing_summary counts correctly", {
  d <- make_test_data()
  d$yield[c(1, 5, 10)] <- NA

  result <- qc_missing_summary(d, c("yield", "plant_height"))
  expect_equal(result$n_missing[result$trait == "yield"], 3)
  expect_equal(result$n_missing[result$trait == "plant_height"], 0)
})

test_that("qc_missing_plot bar returns ggplot", {
  d <- make_test_data()
  d$yield[1] <- NA

  p <- qc_missing_plot(d, c("yield", "plant_height"), type = "bar")
  expect_s3_class(p, "ggplot")
})

test_that("qc_missing_plot field returns ggplot", {
  d <- make_test_data()
  d$yield[1] <- NA

  p <- qc_missing_plot(d, c("yield", "plant_height"), type = "field")
  expect_s3_class(p, "ggplot")
})

test_that("qc_impute_spatial fills missing values", {
  d <- make_test_data()
  d$yield[5] <- NA

  result <- qc_impute_spatial(d, "yield")
  expect_false(is.na(result$yield[5]))
  expect_true(result$yield_imputed[5])
  expect_false(result$yield_imputed[1])
})

test_that("qc_impute_spatial with no missing does nothing", {
  d <- make_test_data()
  result <- qc_impute_spatial(d, "yield")
  expect_true(all(!result$yield_imputed))
})
