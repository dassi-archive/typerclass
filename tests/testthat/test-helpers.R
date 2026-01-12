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

  expect_true(all(sapply(results, is.numeric)))
})


test_that("dataset_metrics returns correct structure", {
  var_test1 <- c(1, 2, 2, 3)
  var_test2 <- c(99, 1, 2, 98)

  df_example <- data.frame(
    var_test1 = var_test1,
    var_test2 = var_test2,
    stringsAsFactors = FALSE
  )

  labels_df <- data.frame(
    var = c("var_test1", "var_test2"),
    type = c("numeric_small", "numeric_large"),
    stringsAsFactors = FALSE
  )

  df_metrics <- dataset_metrics(df_example)

  expect_s3_class(df_metrics, "data.frame")

  expect_true("variable" %in% names(df_metrics))

  expect_equal(nrow(df_metrics), ncol(df_example))

  expect_null(rownames(df_metrics))

  df_metrics_labels <- dataset_metrics(df_example, labels_df = labels_df)

  expect_equal(
    df_metrics_labels$type[df_metrics_labels$variable == "var_test1"],
    "numeric_small"
  )
  expect_equal(
    df_metrics_labels$type[df_metrics_labels$variable == "var_test2"],
    "numeric_large"
  )
})

test_that("predict_type returns correct structure", {
  # --- Example dataset with two numeric variables ---
  df_example <- data.frame(
    var1 = c(1, 2, 2, 3),
    var2 = c(4, 5, 5, 6)
  )

  preds <- predict_type(df_example)

  expect_s3_class(preds, "tbl_df")

  expect_true("variable" %in% names(preds))

  expect_true(".pred_class" %in% names(preds))
  expect_s3_class(preds$.pred_class, "factor")

  prob_cols <- c(".pred_N", ".pred_O", ".pred_S")
  expect_true(all(prob_cols %in% names(preds)))
  expect_true(all(sapply(preds[prob_cols], is.numeric)))

  expect_equal(nrow(preds), ncol(df_example))

  expect_equal(preds$variable, colnames(df_example))
})
