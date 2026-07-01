# Script to generate the example_trial dataset
# Run this script from the package root: source("data-raw/create_example_trial.R")

set.seed(42)

n_genotypes <- 48
n_reps <- 4
n_checks <- 2
n_rows <- 20
n_cols <- 10

# Base genotype list
genotypes <- c(paste0("G", sprintf("%03d", 1:n_genotypes)), "CHECK1", "CHECK2")

# Create basic trial layout
trial_rows <- list()
plot_id <- 1
for (r in 1:n_reps) {
  geno_order <- sample(genotypes)
  for (i in seq_along(geno_order)) {
    row_pos <- ((plot_id - 1) %/% n_cols) + 1
    col_pos <- ((plot_id - 1) %% n_cols) + 1
    trial_rows[[plot_id]] <- list(
      row = row_pos,
      col = col_pos,
      rep = r,
      block = ((i - 1) %/% 10) + 1 + (r - 1) * 2,
      genotype = geno_order[i]
    )
    plot_id <- plot_id + 1
  }
}

example_trial <- do.call(rbind, lapply(trial_rows, as.data.frame,
  stringsAsFactors = FALSE
))

# Generate trait values
n <- nrow(example_trial)

# Yield: mean ~5 t/ha with genotype and rep effects
geno_effects <- stats::setNames(rnorm(length(genotypes), 0, 0.8), genotypes)
rep_effects <- c(0.1, -0.1, 0.05, -0.05)

example_trial$yield <- round(5.0 +
  geno_effects[example_trial$genotype] +
  rep_effects[example_trial$rep] +
  rnorm(n, 0, 0.5), 2)

# Plant height: 80cm mean with spatial gradient (left to right)
example_trial$plant_height <- round(80 +
  example_trial$col * 1.5 +
  geno_effects[example_trial$genotype] * 5 +
  rnorm(n, 0, 3), 1)

# Days to flower: 65 days mean
example_trial$days_to_flower <- round(65 +
  geno_effects[example_trial$genotype] * 2 +
  rnorm(n, 0, 2))

# Inject quality issues

# 1. Duplicate plot coordinates (rows 5 and 6 get same coordinates)
example_trial$row[6] <- example_trial$row[5]
example_trial$col[6] <- example_trial$col[5]

# 2. Missing values in yield
example_trial$yield[c(15, 42, 98)] <- NA

# 3. Missing values in plant_height
example_trial$plant_height[c(33, 77)] <- NA

# 4. Extreme outlier in yield
example_trial$yield[50] <- 18.5

# 5. One genotype with only 1 rep (remove 3 of its 4 entries)
rare_geno <- "G048"
rare_idx <- which(example_trial$genotype == rare_geno)
if (length(rare_idx) > 1) {
  example_trial <- example_trial[-rare_idx[2:length(rare_idx)], ]
}

# Reset row names
rownames(example_trial) <- NULL

# Convert to proper types
example_trial$row <- as.integer(example_trial$row)
example_trial$col <- as.integer(example_trial$col)
example_trial$rep <- as.integer(example_trial$rep)
example_trial$block <- as.integer(example_trial$block)
example_trial$days_to_flower <- as.integer(example_trial$days_to_flower)

# Save
usethis::use_data(example_trial, overwrite = TRUE)
cat("example_trial saved to data/example_trial.rda\n")
cat("Dimensions:", nrow(example_trial), "x", ncol(example_trial), "\n")
