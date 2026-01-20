test_that("compute_n_unique_values works", {
  expect_equal(
    compute_n_unique_values(var_numeric, var_name = "var_numeric"),
    4
  )

  expect_equal(
    compute_n_unique_values(
      var_numeric_with_na,
      var_name = "var_numeric_with_na"
    ),
    3
  )

  expect_equal(
    compute_n_unique_values(
      var_numeric_all_equal,
      var_name = "var_numeric_all_equal"
    ),
    1
  )

  expect_equal(
    compute_n_unique_values(
      var_numeric_only_na,
      var_name = "var_numeric_only_na"
    ),
    0
  )

  expect_error(
    compute_n_unique_values(var_char_simple, var_name = "var_char_simple"),
    class = "check_numeric_error"
  )
})


test_that("compute_std_dev works", {
  expect_equal(
    compute_std_dev(var_numeric, var_name = "var_numeric"),
    sd(c(1, 2, 2, 3, 4, 4, 4))
  )
  expect_equal(
    compute_std_dev(var_numeric_with_na, var_name = "var_numeric_with_na"),
    sd(c(1, 2, 2, 3))
  )
  expect_equal(
    compute_std_dev(var_numeric_all_equal, var_name = "var_numeric_all_equal"),
    0
  )
  expect_identical(compute_std_dev(c(5), var_name = "single_value"), NA_real_)
  expect_identical(
    compute_std_dev(var_numeric_only_na, var_name = "var_numeric_only_na"),
    NA_real_
  )

  expect_error(
    compute_std_dev(var_char_simple, var_name = "var_char_simple"),
    class = "check_numeric_error"
  )
})

test_that("compute_max_relative_frequency works", {
  expect_equal(
    compute_max_relative_frequency(var_numeric, var_name = "var_numeric"),
    3 / 7
  )

  expect_equal(
    compute_max_relative_frequency(
      var_numeric_with_na,
      var_name = "var_numeric_with_na"
    ),
    2 / 4
  )

  expect_equal(
    compute_max_relative_frequency(
      var_numeric_all_equal,
      var_name = "var_numeric_all_equal"
    ),
    1
  )

  expect_equal(
    compute_max_relative_frequency(c(5), var_name = "single_value"),
    1
  )

  expect_identical(
    compute_max_relative_frequency(
      var_numeric_only_na,
      var_name = "var_numeric_only_na"
    ),
    NA_real_
  )

  expect_error(
    compute_max_relative_frequency(var_logical, var_name = "var_logical"),
    class = "check_numeric_error"
  )
})

test_that("compute_norm_entropy works", {
  expect_equal(
    compute_norm_entropy(var_numeric, var_name = "var_numeric"),
    -sum(
      (table(var_numeric) / length(var_numeric)) *
        log(table(var_numeric) / length(var_numeric))
    ) /
      log(length(unique(var_numeric)))
  )

  expect_equal(
    compute_norm_entropy(var_numeric_with_na, var_name = "var_numeric_with_na"),
    -sum(
      (table(var_numeric_with_na[!is.na(var_numeric_with_na)]) / 4) *
        log(table(var_numeric_with_na[!is.na(var_numeric_with_na)]) / 4)
    ) /
      log(length(unique(var_numeric_with_na[!is.na(var_numeric_with_na)])))
  )

  expect_equal(
    compute_norm_entropy(
      var_numeric_all_equal,
      var_name = "var_numeric_all_equal"
    ),
    0
  )
  expect_equal(compute_norm_entropy(c(5), var_name = "single_value"), 0)
  expect_equal(
    compute_norm_entropy(var_numeric_only_na, var_name = "var_numeric_only_na"),
    0
  )

  expect_error(
    compute_norm_entropy(var_char_simple, var_name = "var_char_simple"),
    class = "check_numeric_error"
  )
})


test_that("compute_min_value works", {
  expect_equal(
    compute_min_value(var_numeric, var_name = "var_numeric"),
    min(var_numeric)
  )
  expect_equal(
    compute_min_value(var_numeric_with_na, var_name = "var_numeric_with_na"),
    min(var_numeric_with_na[!is.na(var_numeric_with_na)])
  )
  expect_equal(
    compute_min_value(
      var_numeric_all_equal,
      var_name = "var_numeric_all_equal"
    ),
    7
  )
  expect_equal(compute_min_value(c(5), var_name = "single_value"), 5)
  expect_identical(
    compute_min_value(var_numeric_only_na, var_name = "var_numeric_only_na"),
    NA_real_
  )

  expect_error(
    compute_min_value(var_char_simple, var_name = "var_char_simple"),
    class = "check_numeric_error"
  )
})

test_that("compute_max_value works", {
  expect_equal(
    compute_max_value(var_numeric, var_name = "var_numeric"),
    max(var_numeric)
  )
  expect_equal(
    compute_max_value(var_numeric_with_na, var_name = "var_numeric_with_na"),
    max(var_numeric_with_na[!is.na(var_numeric_with_na)])
  )
  expect_equal(
    compute_max_value(
      var_numeric_all_equal,
      var_name = "var_numeric_all_equal"
    ),
    7
  )
  expect_equal(compute_max_value(c(5), var_name = "single_value"), 5)
  expect_identical(
    compute_max_value(var_numeric_only_na, var_name = "var_numeric_only_na"),
    NA_real_
  )

  expect_error(
    compute_max_value(var_char_simple, var_name = "var_char_simple"),
    class = "check_numeric_error"
  )
})


test_that("compute_is_character works", {
  expect_true(compute_is_character(var_char_simple))
  expect_true(compute_is_character(var_char_with_na))
  expect_true(compute_is_character(var_char_empty))
  expect_false(compute_is_character(var_numeric))
  expect_false(compute_is_character(var_numeric_with_na))
  expect_false(compute_is_character(var_numeric_all_equal))
  expect_false(compute_is_character(var_numeric_only_na))
  expect_false(compute_is_character(var_logical))
})

test_that("compute_skewness_probs works", {
  expect_equal(compute_skewness_probs(var_numeric, var_name = "var_numeric"), {
    counts <- table(var_numeric)
    probs <- counts / sum(counts)
    m <- mean(probs)
    s <- sd(probs)
    z <- (probs - m) / s
    mean(z^3)
  })

  expect_equal(compute_skewness_probs(c(1), var_name = "single_value"), 0)
  expect_equal(compute_skewness_probs(c(1, 1), var_name = "two_values"), 0)
  expect_equal(
    compute_skewness_probs(
      var_numeric_only_na,
      var_name = "var_numeric_only_na"
    ),
    0
  )
  expect_error(
    compute_skewness_probs(var_char_simple, var_name = "var_char_simple"),
    class = "check_numeric_error"
  )
})

test_that("compute_kurtosis_probs works", {
  expect_equal(compute_kurtosis_probs(var_numeric, var_name = "var_numeric"), {
    counts <- table(var_numeric)
    probs <- counts / sum(counts)
    m <- mean(probs)
    s <- sd(probs)
    z <- (probs - m) / s
    mean(z^4) - 3
  })

  expect_equal(compute_kurtosis_probs(c(1), var_name = "single_value"), 0)
  expect_equal(compute_kurtosis_probs(c(1, 1), var_name = "two_values"), 0)
  expect_equal(
    compute_kurtosis_probs(
      var_numeric_only_na,
      var_name = "var_numeric_only_na"
    ),
    0
  )
  expect_error(
    compute_kurtosis_probs(var_char_simple, var_name = "var_char_simple"),
    class = "check_numeric_error"
  )

  expect_equal(
    compute_kurtosis_probs(
      var_numeric_all_equal,
      var_name = "var_numeric_all_equal"
    ),
    0
  )

  expect_equal(
    compute_kurtosis_probs(var_numeric_only_na, var_name = "all_na"),
    0
  )

  expect_equal(
    compute_kurtosis_probs(numeric(0), var_name = "empty"),
    0
  )
})

test_that("compute_dispersion_index works", {
  expect_equal(
    compute_dispersion_index(var_numeric, var_name = "var_numeric"),
    {
      counts <- table(var_numeric)
      probs <- counts / sum(counts)
      var(probs) / mean(probs)
    }
  )

  expect_identical(
    compute_dispersion_index(
      var_numeric_only_na,
      var_name = "var_numeric_only_na"
    ),
    NA_real_
  )
  expect_error(
    compute_dispersion_index(var_char_simple, var_name = "var_char_simple"),
    class = "check_numeric_error"
  )
})

test_that("compute_uniformity works", {
  h <- compute_shannon_entropy(var_numeric, var_name = "var_numeric")
  n_unique <- length(unique(var_numeric))
  expect_equal(
    compute_uniformity(var_numeric, var_name = "var_numeric"),
    h / log(n_unique)
  )

  expect_equal(compute_uniformity(c(5), var_name = "single_value"), 0)
  expect_equal(
    compute_uniformity(var_numeric_only_na, var_name = "var_numeric_only_na"),
    0
  )
  expect_error(
    compute_uniformity(var_char_simple, var_name = "var_char_simple"),
    class = "check_numeric_error"
  )
})


test_that("compute_range_value works", {
  expect_equal(
    compute_range_value(var_numeric, var_name = "var_numeric"),
    max(var_numeric) - min(var_numeric)
  )
  expect_equal(
    compute_range_value(var_numeric_with_na, var_name = "var_numeric_with_na"),
    max(var_numeric_with_na[!is.na(var_numeric_with_na)]) -
      min(var_numeric_with_na[!is.na(var_numeric_with_na)])
  )

  expect_identical(
    compute_range_value(c(5), var_name = "single_value"),
    NA_real_
  )
  expect_identical(
    compute_range_value(var_numeric_only_na, var_name = "var_numeric_only_na"),
    NA_real_
  )
  expect_error(
    compute_range_value(var_char_simple, var_name = "var_char_simple"),
    class = "check_numeric_error"
  )
})


test_that("compute_simpson_index works", {
  expect_equal(
    compute_simpson_index(var_numeric, var_name = "var_numeric"),
    1 - sum((table(var_numeric) / length(var_numeric))^2)
  )

  expect_equal(
    compute_simpson_index(
      var_numeric_with_na,
      var_name = "var_numeric_with_na"
    ),
    1 - sum((table(var_numeric_with_na[!is.na(var_numeric_with_na)]) / 4)^2)
  )

  expect_equal(
    compute_simpson_index(
      var_numeric_all_equal,
      var_name = "var_numeric_all_equal"
    ),
    0
  )

  expect_equal(
    compute_simpson_index(c(5), var_name = "single_value"),
    0
  )

  expect_identical(
    compute_simpson_index(
      var_numeric_only_na,
      var_name = "var_numeric_only_na"
    ),
    NA_real_
  )

  expect_error(
    compute_simpson_index(var_char_simple, var_name = "var_char_simple"),
    class = "check_numeric_error"
  )
})


test_that("compute_topk_ratio works", {
  expect_equal(
    compute_top2_ratio(var_numeric, var_name = "var_numeric"),
    setNames(
      sum(sort(table(var_numeric) / length(var_numeric), decreasing = TRUE)[
        1:2
      ]),
      "top2_ratio"
    )
  )

  expect_equal(
    compute_top3_ratio(var_numeric, var_name = "var_numeric"),
    setNames(
      sum(sort(table(var_numeric) / length(var_numeric), decreasing = TRUE)[
        1:3
      ]),
      "top3_ratio"
    )
  )

  expect_equal(
    compute_top2_ratio(var_numeric_with_na, var_name = "var_numeric_with_na"),
    setNames(
      sum(
        sort(
          table(var_numeric_with_na[!is.na(var_numeric_with_na)]) /
            length(var_numeric_with_na[!is.na(var_numeric_with_na)]),
          decreasing = TRUE
        )[1:2]
      ),
      "top2_ratio"
    )
  )

  expect_equal(
    compute_top2_ratio(c(5), var_name = "single_value"),
    setNames(1, "top2_ratio")
  )

  expect_equal(
    compute_top2_ratio(var_numeric_only_na, var_name = "var_numeric_only_na"),
    setNames(NA_real_, "top2_ratio")
  )

  expect_error(
    compute_top2_ratio(var_char_simple, var_name = "var_char_simple"),
    class = "check_numeric_error"
  )

  expect_error(
    compute_top3_ratio(var_char_simple, var_name = "var_char_simple"),
    class = "check_numeric_error"
  )
})

test_that("functions handle empty numeric vectors", {
  expect_equal(compute_n_unique_values(numeric_empty, "empty"), 0)
  expect_identical(compute_std_dev(numeric_empty, "empty"), NA_real_)
  expect_identical(compute_norm_entropy(numeric_empty, "empty"), 0)
  expect_identical(compute_skewness_probs(numeric_empty, "empty"), 0)
  expect_identical(compute_range_value(numeric_empty, "empty"), NA_real_)
  expect_identical(compute_dispersion_index(numeric_empty, "empty"), NA_real_)
})
