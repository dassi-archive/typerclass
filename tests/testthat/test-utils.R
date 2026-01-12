test_that("check_numeric errors for character variables without metric_name (full message)", {
  expect_error(
    check_numeric(var_char_simple, "var_char_simple", NULL),
    "Error: cannot compute for 'var_char_simple' because it is not numeric but is character\\."
  )
})


test_that("check_numeric errors for character variables with metric_name (full message)", {
  expect_error(
    check_numeric(var_char_simple, "var_char_simple", "std_dev"),
    "Error: the metric 'std_dev' cannot be computed for 'var_char_simple' because it is not numeric but is character\\."
  )
})


test_that("check_numeric errors for logical variables (full message)", {
  expect_error(
    check_numeric(var_logical, "var_logical", "mean"),
    "Error: the metric 'mean' cannot be computed for 'var_logical' because it is not numeric but is logical\\."
  )
})


test_that("check_numeric errors for NA-only logical vector (full message)", {
  expect_error(
    check_numeric(var_na, "var_na", NULL),
    "Error: cannot compute for 'var_na' because it is not numeric but is logical\\."
  )
})


test_that("check_numeric infers variable name when var_name is NULL (full message)", {
  expect_error(
    check_numeric(var_char_simple, NULL, NULL),
    "Error: cannot compute for 'var_char_simple' because it is not numeric but is character\\."
  )
})
