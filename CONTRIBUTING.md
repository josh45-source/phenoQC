# Contributing to phenoQC

Thank you for your interest in contributing!

## How to Contribute

1. Fork the repository on GitHub
2. Clone your fork locally
3. Create a branch for your feature or fix
4. Make your changes following the tidyverse style guide
5. Test with `devtools::check()`
6. Submit a pull request

## Adding a New QC Check

1. Add the function in the appropriate module file
2. Follow the pattern: `data` as first arg, return augmented data or tibble
3. Use `check_col_exists()` for input validation
4. Add roxygen2 docs with `@examples`
5. Write tests in `tests/testthat/`
6. Update `NEWS.md`

## Reporting Issues

Use the GitHub issue tracker with a reproducible example.
