test_that("compute_n_unique_values works", {
  var <- c(1, 2, 2, 3, 4, 4, 4)

  expect_equal(compute_n_unique_values(var), 4)
})
