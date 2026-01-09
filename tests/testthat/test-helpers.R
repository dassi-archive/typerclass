test_that("select_metrics returns a character vector", {
  metrics <- select_metrics()
  expect_type(metrics, "character")
})


test_that("compute_var_metrics returns a named list", {
  metrics <- c("n_unique_values", "std_dev")

  results <- compute_var_metrics(var_numeric, "var_numeric", metrics)

  expect_type(results, "list")

  expect_equal(names(results), metrics)

  expect_true(all(!sapply(results, is.null)))
})


test_that("dataset_metrics returns correct structure", {
  var_test1 <- c(1, 2, 2, 3)
  var_test2 <- c(99, 1, 2, 98)

  df_example <- data.frame(
    var_test1 = var_test1,
    var_test2 = var_test2,
    stringsAsFactors = FALSE
  )

  df_metrics <- dataset_metrics(df_example)

  expect_s3_class(df_metrics, "data.frame")

  expect_true("variable" %in% names(df_metrics))

  expect_equal(nrow(df_metrics), ncol(df_example))

  expect_null(rownames(df_metrics))
})

test_that("predict_type returns correct structure", {
  # --- Example dataset with two numeric variables ---
  df_example <- data.frame(
    var1 = c(1, 2, 2, 3),
    var2 = c(4, 5, 5, 6)
  )

  # --- Call the predict_type function ---
  preds <- predict_type(df_example)

  # --- Check that the output is a tibble ---
  expect_s3_class(preds, "tbl_df")

  # --- Check that the 'variable' column exists ---
  expect_true("variable" %in% names(preds))

  # --- Check that predicted class column exists and is character ---
  expect_true(".pred_class" %in% names(preds))
  expect_s3_class(preds$.pred_class, "factor")

  # --- Check that probability columns exist and are numeric ---
  prob_cols <- c(".pred_N", ".pred_O", ".pred_S")
  expect_true(all(prob_cols %in% names(preds)))
  expect_true(all(sapply(preds[prob_cols], is.numeric)))

  # --- Check that the number of rows matches the number of input variables ---
  expect_equal(nrow(preds), ncol(df_example))

  # --- Check that the values in 'variable' column match the input dataset columns ---
  expect_equal(preds$variable, colnames(df_example))
})
