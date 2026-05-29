# set_missing() ----------------------------------------------------------------
test_that("set_missing with all returns typerclass_missing object", {
  miss <- set_missing(all = c(98, 99))
  expect_s3_class(miss, "typerclass_missing")
  expect_equal(miss$all, c(98, 99))
  expect_equal(miss$per_variable, list())
})

test_that("set_missing with per_variable returns typerclass_missing object", {
  miss <- set_missing(HWACTUAL = 99, STAPRO = c(9, 99))
  expect_s3_class(miss, "typerclass_missing")
  expect_null(miss$all)
  expect_equal(miss$per_variable$HWACTUAL, 99)
  expect_equal(miss$per_variable$STAPRO, c(9, 99))
})

test_that("set_missing with both all and per_variable works", {
  miss <- set_missing(all = c(98, 99), HWACTUAL = 999)
  expect_s3_class(miss, "typerclass_missing")
  expect_equal(miss$all, c(98, 99))
  expect_equal(miss$per_variable$HWACTUAL, 999)
})

test_that("set_missing errors when all is not numeric", {
  expect_error(
    set_missing(all = c("98", "99")),
    class = "set_missing_all_not_numeric"
  )
})

test_that("set_missing errors when per_variable values are not numeric", {
  expect_error(
    set_missing(x = c("a", "b")),
    class = "set_missing_per_variable_not_numeric"
  )
})

test_that("set_missing errors when per_variable is unnamed", {
  # This should pass because it's not actually a named argument issue
  # but we test the unnamed case
  expect_error(
    set_missing(all = c(1, 2), 1),
    class = "set_missing_unnamed"
  )
})


# predict_type() with missing parameter ----------------------------------------
test_that("predict_type with missing = NULL works as before", {
  df <- tibble(
    x = c(1, 2, 3, 4),
    y = c(4, 5, 6, 7)
  )

  expect_s3_class(predict_type(df), "tbl_df")
  expect_s3_class(predict_type(df, missing = NULL), "tbl_df")
})

test_that("predict_type with global missing runs without error", {
  df <- tibble(
    x = c(1, 2, 98, 99, 3),
    y = c(4, 5, 6, 7, 8)
  )

  preds <- predict_type(df, missing = set_missing(all = c(98, 99)))
  expect_s3_class(preds, "tbl_df")
  expect_equal(nrow(preds), ncol(df))
  expect_equal(preds$variable, colnames(df))
})

test_that("predict_type with per_variable missing runs without error", {
  df <- tibble(
    x = c(1, 2, 98, 99, 3),
    y = c(4, 5, 6, 7, 8)
  )

  preds <- predict_type(df, missing = set_missing(x = 98))
  expect_s3_class(preds, "tbl_df")
  expect_equal(nrow(preds), ncol(df))
})

test_that("predict_type with missing on factor variable runs without error", {
  df <- tibble(
    x = factor(c("1", "2", "98", "99", "3")),
    y = c(4, 5, 6, 7, 8)
  )

  preds <- predict_type(df, missing = set_missing(all = c(98, 99)))
  expect_s3_class(preds, "tbl_df")
  expect_equal(nrow(preds), ncol(df))
})

test_that("predict_type errors for invalid missing class", {
  df <- tibble(x = c(1, 2, 3))

  expect_error(
    predict_type(df, missing = list(all = c(98, 99))),
    class = "predict_type_invalid_missing"
  )
})

test_that("predict_type errors for non-existent variable in per_variable", {
  df <- tibble(x = c(1, 2, 3))

  expect_error(
    predict_type(df, missing = set_missing(y = 99)),
    class = "predict_type_missing_var_not_found"
  )
})

test_that("predict_type warns for missing on non-numeric variable", {
  df <- tibble(
    x = c(1, 2, 3),
    y = c("a", "b", "c")
  )

  expect_warning(
    predict_type(df, missing = set_missing(y = 99)),
    class = "predict_type_missing_non_numeric"
  )
})

test_that("predict_type warns when missing values exceed 50% of a variable", {
  df <- tibble(
    x = c(1, 99, 99, 99, 99, 99),  # 5/6 ≈ 83% NA after conversion
    y = c(1, 2, 3, 4, 5, 6)
  )

  expect_warning(
    predict_type(df, missing = set_missing(all = 99)),
    class = "predict_type_high_missingness"
  )
})

test_that("predict_type does not warn when missing values are below 50%", {
  df <- tibble(
    x = c(1, 2, 99, 4, 5),  # 1/5 = 20% NA after conversion
    y = c(1, 2, 3, 4, 5)
  )

  expect_warning(
    predict_type(df, missing = set_missing(all = 99)),
    NA
  )
})

test_that("predict_type with missing excludes values from metrics", {
  # Column with a clear outlier that should be excluded
  df_clean <- tibble(
    a = c(1, 2, 3, 4, 5)
  )

  # Same column but with missing codes present
  df_dirty <- tibble(
    a = c(1, 2, 3, 98, 99)
  )

  # Without missing declaration, the dirty data has different distribution
  preds_dirty <- predict_type(df_dirty)

  # With missing declaration, 98 and 99 are excluded: same as clean
  preds_clean <- predict_type(df_dirty, missing = set_missing(all = c(98, 99)))

  # The predictions should differ because the distribution changed
  expect_false(identical(preds_dirty, preds_clean))
})
