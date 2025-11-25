# ------------------------------------------------------------------------------
# Helper funcions
# ------------------------------------------------------------------------------


# select_metrics() -------------------------------------------------------------
select_metrics <- function() {
  c(
  #   "compute_n_unique_values",
    "compute_std_dev"
  #   "compute_max_relative_frequency",
  #   "compute_norm_entropy",
  #   "compute_min_value",
  #   "compute_max_value",
  #   "compute_range_value",
  #   "compute_is_character",
  #   "compute_shannon_entropy",
  # #  "compute_label_coverage",
  #   "compute_simpson_index",
  #   "compute_skewness_probs",
  #   "compute_kurtosis_probs",
  #   "compute_dispersion_index",
  #   "compute_uniformity",
  #   "compute_top2_ratio",
  #   "compute_top3_ratio",
  #   "compute_range_value"
  )
}


# compute_var_metrics() --------------------------------------------------------
compute_var_metrics <- function(var, var_name, metrics) {
  results <- purrr::map(metrics, ~ get(.x)(var, var_name))
  names(results) <- metrics

  results
}


# ------------------------------
# Wrapper: Compute All Metrics for a Single Variable (without label_coverage)
# ------------------------------
# compute_selected_metrics <- function(var, var_name = NULL) {
  
#   results <- purrr::map(metrics, ~ get(.x)(var))
#   names(results) <- metrics

#   results
# }
  # --- List of all metrics to compute internally ---

  
  # --- Numeric / general metrics ---
  # if ("n_unique" %in% metrics) results$n_unique <- n_unique_values(var)
  # if ("std_dev" %in% metrics) results$std_dev <- std_dev_var(var)
  # if ("max_relative_frequency" %in% metrics) results$max_relative_frequency <- max_relative_freq(var)
  # if ("norm_entropy" %in% metrics) results$norm_entropy <- norm_entropy_var(var)
  # if ("min_value" %in% metrics) results$min_value <- min_value_var(var)
  # if ("max_value" %in% metrics) results$max_value <- max_value_var(var)
  # if ("range_value" %in% metrics) results$range_value <- range_value_var(var)
  # if ("is_character" %in% metrics) results$is_character <- is_character_var(var)
  
  # # --- Frequency-based metrics ---
  # if ("shannon_entropy" %in% metrics) results$shannon_entropy <- shannon_entropy_var(var)
  # if ("simpson_index" %in% metrics) results$simpson_index <- simpson_index_var(var)
  # if ("skewness_probs" %in% metrics) results$skewness_probs <- skewness_probs_var(var)
  # if ("kurtosis_probs" %in% metrics) results$kurtosis_probs <- kurtosis_probs_var(var)
  # if ("dispersion_index" %in% metrics) results$dispersion_index <- dispersion_index_var(var)
  # if ("uniformity" %in% metrics) results$uniformity <- uniformity_var(var)
  
  # # --- Top-k ratios ---
  # if ("topk_ratios" %in% metrics) {
  #   topk_res <- topk_ratios_var(var, topk = topk)
  #   results <- c(results, topk_res)
  # }
  
  # return(as.list(results))
# }
  
dataset_metrics <- function(data, labels_df = NULL) {
  
  metrics_list <- select_metrics()  # lista delle metriche

  df_metrics <- purrr::map_dfr(names(data), function(var_name) {
    
    # --- Compute all metrics for this variable ---
    metrics_values <- compute_var_metrics(
      var = data[[var_name]],
      var_name = var_name,
      metrics = metrics_list
    )
    
    # --- Append variable name ---
    metrics_values$variable <- var_name
    
    # --- Append type only if labels_df is provided ---
    if (!is.null(labels_df) && "type" %in% names(labels_df)) {
      tmp <- labels_df$type[labels_df$var == var_name]
      if (length(tmp) > 0) metrics_values$type <- tmp[1]
    }
    
    as.data.frame(metrics_values)
  })
  
  return(df_metrics)
}


# ------------------------------
# Function: Predict variable types for new data and return JSON
# ------------------------------
predict_new_data_json <- function(model_fit, data) {
  
  # ---- Compute dataset-level metrics (all metrics except label_coverage) ----
  metrics <- dataset_metrics(data)
  
  # ---- Ensure 'dataset' column exists (required by the model) ----
  if (!"dataset" %in% names(metrics)) {
    metrics$dataset <- "dataset"
  }
  
  # ---- Variable names from metrics ----
  vars <- metrics$variable
  
  # ---- Predictions using metrics as input ----
  preds_class <- as_tibble(predict(model_fit, metrics))
  if (!".pred_class" %in% names(preds_class)) {
    preds_class <- tibble(.pred_class = preds_class[[1]])
  }
  
  preds_prob <- as_tibble(predict(model_fit, metrics, type = "prob"))
  
  # ---- Combine predictions into a single tibble ----
  preds_df <- bind_cols(tibble(var = vars), preds_class, preds_prob)
  
  # ---- Convert each row into a list for JSON output ----
  preds_list <- pmap(preds_df, function(var, .pred_class, .pred_N, .pred_O, .pred_S) {
    prob_pred_type <- switch(
      as.character(.pred_class),
      N = .pred_N,
      O = .pred_O,
      S = .pred_S
    )
    
    var_obj <- list(
      "variable" = var,
      "predicted_type" = .pred_class,
      "prob_predicted_type" = prob_pred_type,
      "prob_N" = .pred_N,
      "prob_O" = .pred_O,
      "prob_S" = .pred_S
    )
    
    setNames(list(var_obj), var)
  })
  
  # ---- Convert to JSON ----
  jsonlite::toJSON(preds_list, pretty = TRUE, auto_unbox = TRUE, na = "null")
}




