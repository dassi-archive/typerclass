# ------------------------------------------------------------------------------
# Helper funcions
# ------------------------------------------------------------------------------

# select_metrics() -------------------------------------------------------------
select_metrics <- function() {
  c(
    "n_unique_values",
    "std_dev",
    "max_relative_frequency",
    "norm_entropy",
    "min_value",
    "max_value",
    "range_value",
    "is_character",
    "shannon_entropy",
    #  "label_coverage",
    "simpson_index",
    "skewness_probs",
    "kurtosis_probs",
    "dispersion_index",
    "uniformity",
    "top2_ratio",
    "top3_ratio"
  )
}


# compute_var_metrics() --------------------------------------------------------
compute_var_metrics <- function(var, var_name, metrics) {
  results <- map(metrics, ~ get(sprintf("compute_%s", .x))(var, var_name))
  names(results) <- metrics

  results
}


# dataset_metrics() ------------------------------------------------------------
dataset_metrics <- function(data, labels_df = NULL) {
  # ---- Keep only numeric variables ----
  numeric_vars <- sapply(data, is.numeric)
  data_numeric <- data[, numeric_vars, drop = FALSE]

  metrics_list <- select_metrics()

  df_metrics <- map_dfr(unname(names(data_numeric)), function(var_name) {
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

  df_metrics <- dplyr::select(
    df_metrics,
    .data$variable,
    dplyr::everything()
  )

  rownames(df_metrics) <- NULL

  return(df_metrics)
}


# predict_type() ---------------------------------------------------------------
predict_type <- function(data) {
  # ---- Separate numeric and non-numeric variables ----
  numeric_vars <- sapply(data, is.numeric)
  non_numeric_vars <- names(data)[!numeric_vars]

  # ---- Subset data to numeric variables only ----
  numeric_data <- data[, numeric_vars, drop = FALSE]

  # ---- Compute variable-level metrics ----
  metrics <- dataset_metrics(numeric_data)

  #TODO: aggiungere test su questa parte (il numero di var deve essere quello del df iniziale)

  # ---- Ensure 'dataset' column exists (model requirement) ----
  if (!"dataset" %in% names(metrics)) {
    metrics$dataset <- "dataset"
  }

  # ---- Class predictions ----
  preds_class <- as_tibble(predict(rf_final_fit, metrics))

  # ---- Probability predictions ----
  preds_prob <- as_tibble(predict(rf_final_fit, metrics, type = "prob"))

  # ---- Combine numeric predictions ----
  numeric_out <- dplyr::bind_cols(
    tibble(variable = metrics$variable),
    preds_class,
    preds_prob
  )

  # ---- Handle non-numeric variables ----
  if (length(non_numeric_vars) > 0) {
    non_numeric_df <- tibble(
      variable = non_numeric_vars,
      .pred_class = "N",
      .pred_N = NA,
      .pred_O = NA,
      .pred_S = NA
    )
    # Merge numeric + non-numeric
    out <- dplyr::bind_rows(numeric_out, non_numeric_df)
  } else {
    out <- numeric_out
  }

  # ---- Reorder to match original dataset ----
  out <- out[match(names(data), out$variable), ]

  return(out)
}
