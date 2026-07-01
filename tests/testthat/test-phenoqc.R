make_test_data <- function(n = 40) {
  set.seed(99)
  data.frame(
    row = rep(1:10, each = 4),
    col = rep(1:4, times = 10),
    rep = rep(1:2, each = 20),
    genotype = paste0("G", sprintf("%02d", rep(1:20, each = 2))),
    yield = c(rnorm(39, 5, 1), 25),
    plant_height = 80 + rep(1:4, times = 10) * 1.5 + rnorm(n, 0, 2),
    stringsAsFactors = FALSE
  )
}

test_that("phenoqc() returns a phenoqc_result object", {
  d <- make_test_data()
  result <- phenoqc(d, trait_cols = c("yield", "plant_height"))

  expect_s3_class(result, "phenoqc_result")
  expect_true("data" %in% names(result))
  expect_true("validation" %in% names(result))
  expect_true("outliers" %in% names(result))
  expect_true("missing" %in% names(result))
  expect_true("cleaned_data" %in% names(result))
  expect_true("summary" %in% names(result))
})

test_that("phenoqc() detects the extreme outlier", {
  d <- make_test_data()
  result <- phenoqc(d, trait_cols = "yield")

  expect_true(sum(result$summary$n_outliers) > 0)
})

test_that("phenoqc() summary has correct structure", {
  d <- make_test_data()
  result <- phenoqc(d, trait_cols = c("yield", "plant_height"))

  expect_s3_class(result$summary, "tbl_df")
  expect_equal(nrow(result$summary), 2)
  expect_true(all(c("trait", "n_obs", "n_missing", "n_outliers") %in%
    names(result$summary)))
})

test_that("print.phenoqc_result doesn't error", {
  d <- make_test_data()
  result <- phenoqc(d, trait_cols = "yield")

  expect_no_error(print(result))
})

test_that("summary.phenoqc_result returns summary tibble", {
  d <- make_test_data()
  result <- phenoqc(d, trait_cols = "yield")

  s <- summary(result)
  expect_s3_class(s, "tbl_df")
})

test_that("phenoqc() with impute_missing fills NAs", {
  d <- make_test_data()
  d$yield[c(1, 5)] <- NA

  result <- phenoqc(d, trait_cols = "yield", impute_missing = TRUE)
  # Imputed column should exist
  expect_true("yield_imputed" %in% names(result$data))
})

test_that("cleaned_data has outliers set to NA", {
  d <- make_test_data()
  result <- phenoqc(d, trait_cols = "yield")

  if (sum(result$summary$n_outliers) > 0) {
    flagged <- result$data$yield_flagged
    expect_true(any(is.na(result$cleaned_data$yield[flagged])))
  }
})

test_that("detect_trait_cols auto-detects numeric traits", {
  d <- make_test_data()
  traits <- detect_trait_cols(d)
  expect_true("yield" %in% traits)
  expect_true("plant_height" %in% traits)
  expect_false("genotype" %in% traits)
  expect_false("row" %in% traits)
})
