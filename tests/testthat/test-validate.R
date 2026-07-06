# Helper: create a minimal test dataset
make_test_data <- function(n = 20) {
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

test_that("qc_check_duplicates finds duplicate coordinates", {
  d <- make_test_data()
  # Inject a duplicate
  d$row[2] <- d$row[1]
  d$col[2] <- d$col[1]

  dups <- qc_check_duplicates(d)
  expect_true(nrow(dups) >= 2)
})

test_that("qc_check_duplicates returns empty for clean data", {
  d <- make_test_data()
  dups <- qc_check_duplicates(d)
  expect_equal(nrow(dups), 0)
})

test_that("qc_check_duplicates does not flag a grid reused across environments", {
  # Same 5x4 physical layout repeated for two environments: row/col repeat
  # across env, but within each env every (row, col) is still unique.
  one_env <- make_test_data()
  d <- rbind(
    cbind(env = "env1", one_env),
    cbind(env = "env2", one_env)
  )

  dups <- qc_check_duplicates(d)
  expect_equal(nrow(dups), 0)
})

test_that("qc_check_duplicates still finds a true duplicate within one environment", {
  one_env <- make_test_data()
  d <- rbind(
    cbind(env = "env1", one_env),
    cbind(env = "env2", one_env)
  )
  # Inject a genuine duplicate within env1 only
  env1_idx <- which(d$env == "env1")
  d$row[env1_idx[2]] <- d$row[env1_idx[1]]
  d$col[env1_idx[2]] <- d$col[env1_idx[1]]

  dups <- qc_check_duplicates(d)
  expect_equal(nrow(dups), 2)
  expect_true(all(dups$env == "env1"))
})

test_that("qc_check_duplicates honours an explicit group_cols argument", {
  d <- make_test_data()
  # rep already distinguishes two blocks; injecting a duplicate that only
  # collides across reps should not be flagged when grouping by rep.
  d$row[11] <- d$row[1]
  d$col[11] <- d$col[1]

  dups <- qc_check_duplicates(d, group_cols = "rep")
  expect_equal(nrow(dups), 0)
})

test_that("qc_check_duplicates group_cols = character(0) forces a global check", {
  d <- make_test_data()
  d$row[2] <- d$row[1]
  d$col[2] <- d$col[1]

  dups <- qc_check_duplicates(d, group_cols = character(0))
  expect_true(nrow(dups) >= 2)
})

test_that("qc_check_missing_plots detects gaps", {
  d <- make_test_data()
  # Remove a row to create a gap
  d <- d[-5, ]

  missing <- qc_check_missing_plots(d)
  expect_true(nrow(missing) >= 1)
})

test_that("qc_check_trait_types identifies numeric columns", {
  d <- make_test_data()
  result <- qc_check_trait_types(d, c("yield", "plant_height"))
  expect_equal(nrow(result), 2)
  expect_true(all(result$is_numeric))
})

test_that("qc_check_trait_types flags non-numeric", {
  d <- make_test_data()
  d$yield <- as.character(d$yield)
  d$yield[1] <- "bad_value"

  result <- qc_check_trait_types(d, "yield")
  expect_false(result$is_numeric)
  expect_true(result$n_non_numeric >= 1)
})

test_that("qc_check_replication detects imbalance", {
  d <- make_test_data()
  # Remove one entry of G01
  g01_idx <- which(d$genotype == "G01")
  d <- d[-g01_idx[1], ]

  result <- qc_check_replication(d, "genotype", "rep")
  expect_true(any(result$status == "under-replicated"))
})

test_that("qc_validate_structure runs all checks", {
  d <- make_test_data()
  result <- qc_validate_structure(d, trait_cols = c("yield", "plant_height"))
  expect_s3_class(result, "tbl_df")
  expect_true("check" %in% names(result))
  expect_true("status" %in% names(result))
})

test_that("check_col_exists throws on missing columns", {
  d <- make_test_data()
  expect_error(check_col_exists(d, "nonexistent"), class = "phenoQC_missing_col")
})
