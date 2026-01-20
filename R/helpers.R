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
  if (!all(purrr::map_lgl(data, is.numeric))) {
    cli_abort("dataset_metrics() only works with numeric variables.")
  }

  metrics_list <- select_metrics()

  df_metrics <- map_dfr(unname(names(data)), function(var_name) {
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
  stopifnot(is.data.frame(data))

  # ---- Get datatypes from data ----
  dt_lst <- get_datatype(data)

  if (length(dt_lst$factor) != 0) {
    for (f_var in dt_lst$factor) {
      data[[f_var]] <- as.numeric(data[[f_var]])
      dt_lst$numeric <- c(dt_lst$numeric, f_var)
    }
  }

  # ---- Compute numeric variable-level metrics ----
  if (length(dt_lst$numeric) != 0) {
    # print(dt_lst$numeric)
    metrics <- dataset_metrics(data[, dt_lst$numeric])
    if (!"dataset" %in% names(metrics)) {
      metrics$dataset <- "dataset"
    }
    preds_class <- as_tibble(predict(rf_final_fit, metrics))

    # ---- Probability predictions ----
    preds_prob <- as_tibble(predict(rf_final_fit, metrics, type = "prob"))

    # ---- Combine numeric predictions ----
    out <- dplyr::bind_cols(
      tibble(variable = metrics$variable),
      preds_class,
      preds_prob
    )
  }

  # ---- Add character/logical variables ----
  if (length(dt_lst$character) != 0 | length(dt_lst$logical) != 0) {
    char_predict <- tibble(
      variable = c(dt_lst$character, dt_lst$logical),
      .pred_class = "N",
      .pred_N = NA,
      .pred_O = NA,
      .pred_S = NA
    )
    out <- dplyr::bind_rows(out, char_predict)
  }

  # ---- Add date variables ----
  if (length(dt_lst$date) != 0) {
    date_predict <- tibble(
      variable = dt_lst$date,
      .pred_class = "O",
      .pred_N = NA,
      .pred_O = NA,
      .pred_S = NA
    )
    out <- dplyr::bind_rows(out, date_predict)
  }

  # ---- Add date variables ----
  if (length(dt_lst$other) != 0) {
    other_predict <- tibble(
      variable = dt_lst$other,
      .pred_class = "",
      .pred_N = NA,
      .pred_O = NA,
      .pred_S = NA
    )
    out <- dplyr::bind_rows(out, other_predict)
  }

  #TODO: aggiungere test su questa parte (il numero di var deve essere quello del df iniziale)

  # ---- Ensure 'dataset' column exists (model requirement) ----
  if (!"dataset" %in% names(metrics)) {
    metrics$dataset <- "dataset"
  }

  # ---- Reorder to match original dataset ----
  out <- out[match(names(data), out$variable), ]

  return(out)
}
