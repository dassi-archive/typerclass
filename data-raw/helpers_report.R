# ------------------------------
# Wrapper: Compute All Metrics for a Single Variable (without label_coverage)
# ------------------------------
compute_selected_metrics <- function(var, var_name = NULL) {
  results <- list()

  # Default top-k values (used only for topk_ratios)
  topk <- c(2, 3)

  # --- List of all metrics to compute internally ---
  metrics <- c(
    "n_unique_values",
    "std_dev",
    "max_relative_frequency",
    "norm_entropy",
    "min_value",
    "max_value",
    "range_value",
    "is_character",
    "shannon_entropy",
    "simpson_index",
    "skewness_probs",
    "kurtosis_probs",
    "dispersion_index",
    "uniformity",
    "topk_ratios"
  )

  # --- Numeric / general metrics ---
  if ("n_unique_values" %in% metrics) {
    results$n_unique_values <- n_unique_values(var)
  }
  if ("std_dev" %in% metrics) {
    results$std_dev <- std_dev_var(var)
  }
  if ("max_relative_frequency" %in% metrics) {
    results$max_relative_frequency <- max_relative_freq(var)
  }
  if ("norm_entropy" %in% metrics) {
    results$norm_entropy <- norm_entropy_var(var)
  }
  if ("min_value" %in% metrics) {
    results$min_value <- min_value_var(var)
  }
  if ("max_value" %in% metrics) {
    results$max_value <- max_value_var(var)
  }
  if ("range_value" %in% metrics) {
    results$range_value <- range_value_var(var)
  }
  if ("is_character" %in% metrics) {
    results$is_character <- is_character_var(var)
  }

  # --- Frequency-based metrics ---
  if ("shannon_entropy" %in% metrics) {
    results$shannon_entropy <- shannon_entropy_var(var)
  }
  if ("simpson_index" %in% metrics) {
    results$simpson_index <- simpson_index_var(var)
  }
  if ("skewness_probs" %in% metrics) {
    results$skewness_probs <- skewness_probs_var(var)
  }
  if ("kurtosis_probs" %in% metrics) {
    results$kurtosis_probs <- kurtosis_probs_var(var)
  }
  if ("dispersion_index" %in% metrics) {
    results$dispersion_index <- dispersion_index_var(var)
  }
  if ("uniformity" %in% metrics) {
    results$uniformity <- uniformity_var(var)
  }

  # --- Top-k ratios ---
  if ("topk_ratios" %in% metrics) {
    topk_res <- topk_ratios_var(var, topk = topk)
    results <- c(results, topk_res)
  }

  return(as.list(results))
}
dataset_metrics <- function(data, labels_df = NULL) {
  df_metrics <- purrr::map_dfr(names(data), function(var_name) {
    # --- Compute all metrics for this variable (without label_coverage) ---
    metrics_list <- compute_selected_metrics(
      var = data[[var_name]],
      var_name = var_name
    )

    # --- Append variable name ---
    metrics_list$variable <- var_name

    # --- Append type only if labels_df is provided ---
    if (!is.null(labels_df) && "type" %in% names(labels_df)) {
      tmp <- labels_df$type[labels_df$var == var_name]
      if (length(tmp) > 0) metrics_list$type <- tmp[1]
    }

    # --- Convert to data frame ---
    as.data.frame(metrics_list)
  })

  return(df_metrics)
}
