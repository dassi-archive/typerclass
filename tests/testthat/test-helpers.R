# select_metrics() -------------------------------------------------------------
test_that("select_metrics returns a character vector", {
  metrics <- select_metrics()
  expect_type(metrics, "character")
})


# compute_var_metrics() --------------------------------------------------------
test_that("compute_var_metrics returns a named list", {
  metrics <- c("n_unique_values", "std_dev")

  results <- compute_var_metrics(var_numeric, "var_numeric", metrics)

  expect_type(results, "list")

  expect_equal(names(results), metrics)

  expect_true(all(!sapply(results, is.null)))

  expect_true(all(sapply(results, is.numeric)))
})


# dataset_metrics() ------------------------------------------------------------
test_that("dataset_metrics returns correct structure", {
  var_test1 <- c(1, 2, 2, 3)
  var_test2 <- c(99, 1, 2, 98)

  df_example <- tibble(
    var_test1 = var_test1,
    var_test2 = var_test2
  )

  df_metrics <- dataset_metrics(df_example)

  expect_s3_class(df_metrics, "data.frame")

  expect_true("variable" %in% names(df_metrics))

  expect_equal(nrow(df_metrics), ncol(df_example))

  expect_equal(rownames(df_metrics), c("1", "2"))
})

test_that("dataset_metrics throws error for non-numeric variables", {
  df_numeric <- tibble(
    x = c(1, 2, 3),
    y = c(4, 5, 6)
  )
  expect_silent(dataset_metrics(df_numeric))

  df_mixed <- tibble(
    x = c(1, 2, 3),
    y = c("a", "b", "c")
  )
  expect_error(
    dataset_metrics(df_mixed),
    class = "dataset_metrics_not_numeric"
  )

  df_factor <- tibble(
    x = c(1, 2, 3),
    y = factor(c("A", "B", "C"))
  )
  expect_error(
    dataset_metrics(df_factor),
    class = "dataset_metrics_not_numeric"
  )

  df_logical <- tibble(
    x = c(1, 2, 3),
    y = c(TRUE, FALSE, TRUE)
  )
  expect_error(
    dataset_metrics(df_logical),
    class = "dataset_metrics_not_numeric"
  )
})


# predict_type() ---------------------------------------------------------------
test_that("predict_type returns correct structure for multiple variable types", {
  # --- Example dataset with numeric, factor, character, logical, date, and other ---
  df_example <- tibble(
    num1 = c(1, 2, 3, 4),
    num2 = c(4, 5, 6, 7),
    fac1 = factor(c("A", "B", "A", "C")),
    char1 = c("x", "y", "z", "x"),
    log1 = c(TRUE, FALSE, TRUE, FALSE),
    date1 = as.Date(c("2023-01-01", "2023-01-02", "2023-01-03", "2023-01-04"))
  )

  preds <- predict_type(df_example)
  print(str(preds))
  expect_s3_class(preds, "tbl_df")
  expect_true("variable" %in% names(preds))
  expect_true(".pred_class" %in% names(preds))
  expect_type(preds$.pred_class, "character")

  prob_cols <- c(".pred_N", ".pred_O", ".pred_S")
  expect_true(all(prob_cols %in% names(preds)))
  expect_true(all(
    sapply(preds[prob_cols], is.numeric) |
      sapply(preds[prob_cols], function(x) all(is.na(x)))
  ))

  expect_equal(nrow(preds), ncol(df_example))

  expect_equal(preds$variable, colnames(df_example))

  numeric_vars <- c("num1", "num2", "fac1")
  expect_true(all(
    preds$variable[preds$variable %in% numeric_vars] %in% preds$variable
  ))

  char_log_date_vars <- c("char1", "log1", "date1")
  expect_true(all(
    preds$.pred_class[preds$variable %in% char_log_date_vars] %in% c("N", "O")
  ))
})

test_that("predict_type handles 'other' variables correctly", {
  df_example <- data.frame(
    num1 = c(1, 2, 3),
    fac1 = factor(c("A", "B", "C")),
    other1 = I(list(list(a = 1), list(b = 2), list(c = 3))) # using I() to keep as 'other' (list-column)
  )

  preds <- predict_type(df_example)

  # --- Check that 'other1' is included ---
  expect_true("other1" %in% preds$variable)

  # --- Check that its predicted class is empty string ---
  other_row <- preds[preds$variable == "other1", ]
  expect_equal(other_row$.pred_class, "")

  # --- Check that probability columns are NA ---
  expect_true(is.na(other_row$.pred_N))
  expect_true(is.na(other_row$.pred_O))
  expect_true(is.na(other_row$.pred_S))
})
