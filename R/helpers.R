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
    "shannon_entropy",
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
  if (!all(map_lgl(data, is.numeric))) {
    cli_abort(
      "dataset_metrics() only works with numeric variables.",
      class = "dataset_metrics_not_numeric"
    )
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

    as_tibble(metrics_values)
  })

  df_metrics <- select(
    df_metrics,
    .data$variable,
    everything()
  )

  rownames(df_metrics) <- NULL

  df_metrics
}


# predict_type() ---------------------------------------------------------------
#' Predict measurement types for dataset variables
#'
#' Computes distributional metrics for numeric variables and uses a pretrained
#' random-forest model to classify each variable as nominal (N), ordinal (O),
#' or scale (S). Non-numeric variables are handled deterministically:
#' character/logical variables are marked as nominal, date variables as ordinal,
#' and unsupported types receive empty predictions.
#'
#' @param data A data frame of variables to classify.
#'
#' @return A tibble with one row per input variable and the following columns:
#' \describe{
#'   \item{variable}{Original variable name.}
#'   \item{.pred_class}{Predicted class (N, O, or S).}
#'   \item{.pred_N}{Probability of nominal class.}
#'   \item{.pred_O}{Probability of ordinal class.}
#'   \item{.pred_S}{Probability of scale class.}
#' }
#' Rows are returned in the same order as the columns of `data`. For variables
#' that are not processed by the model, probability columns are `NA`.
#'
#' @details
#' Factors are coerced to numeric and included with other numeric variables.
#' The model object `rf_final_fit` is loaded with the package.
#'
#' @examples
#' \dontrun{
#' df <- tibble(
#'   age = c(20, 30, 40),
#'   sex = c("M", "F", "F")
#' )
#' predict_type(df)
#' }
#' @export
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
    metrics <- dataset_metrics(data[, dt_lst$numeric])
    if (!"dataset" %in% names(metrics)) {
      metrics$dataset <- "dataset"
    }
    rf_final_fit <- get("rf_final_fit", envir = asNamespace("typerclass"))
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

  # ---- Ensure 'dataset' column exists (model requirement) ----
  if (!"dataset" %in% names(metrics)) {
    metrics$dataset <- "dataset"
  }

  # ---- Reorder to match original dataset ----
  out <- out[match(names(data), out$variable), ]

  return(out)
}
