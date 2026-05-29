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
    "variable",
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
#' @param missing An optional specification of missing values created by
#'   [set_missing()]. Values declared as missing are converted to `NA` before
#'   computing the distributional metrics, excluding them from the analysis.
#'   Can specify global missing values (applied to all numeric/factor variables)
#'   or per-variable missing values. Default is `NULL` (no additional missing
#'   values beyond standard `NA`).
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
#' When a `missing` specification is provided, the declared missing values are
#' converted to `NA` **before** the factor-to-numeric conversion and the metric
#' computation. This means that for factor variables, the values are matched
#' against the factor level labels (not the internal integer codes).
#'
#' @examples
#' \dontrun{
#' df <- tibble(
#'   age = c(20, 30, 40),
#'   sex = c("M", "F", "F")
#' )
#' predict_type(df)
#'
#' # Exclude survey missing codes
#' predict_type(df, missing = set_missing(all = c(98, 99)))
#' }
#' @export
predict_type <- function(data, missing = NULL) {
  stopifnot(is.data.frame(data))

  # ---- Validate missing object ----
  if (!is.null(missing)) {
    if (!inherits(missing, "typerclass_missing")) {
      cli_abort(
        "{.arg missing} must be a {.cls typerclass_missing} object created by {.fn set_missing}.",
        class = "predict_type_invalid_missing"
      )
    }
    if (length(missing$per_variable) > 0) {
      invalid_vars <- setdiff(names(missing$per_variable), names(data))
      if (length(invalid_vars) > 0) {
        cli_abort(
          "Variables not found in {.arg data}: {.val {invalid_vars}}.",
          class = "predict_type_missing_var_not_found"
        )
      }
    }
  }

  # ---- Get datatypes from data ----
  dt_lst <- get_datatype(data)

  # ---- Apply missing value conversion (before factor conversion) ----
  if (!is.null(missing)) {
    if (!is.null(missing$all)) {
      for (var in names(data)) {
        if (is.numeric(data[[var]]) || is.factor(data[[var]])) {
          data[[var]][data[[var]] %in% missing$all] <- NA
        }
      }
    }
    if (length(missing$per_variable) > 0) {
      for (var in names(missing$per_variable)) {
        if (is.numeric(data[[var]]) || is.factor(data[[var]])) {
          data[[var]][data[[var]] %in% missing$per_variable[[var]]] <- NA
        } else {
          cli_warn(
            "Variable {.val {var}} is not numeric or factor; missing value declaration will be ignored.",
            class = "predict_type_missing_non_numeric"
          )
        }
      }
    }
  }

  if (length(dt_lst$factor) != 0) {
    for (f_var in dt_lst$factor) {
      data[[f_var]] <- as.numeric(data[[f_var]])
      dt_lst$numeric <- c(dt_lst$numeric, f_var)
    }
  }

  # ---- Warn about variables with excessive missingness ----
  if (length(dt_lst$numeric) > 0) {
    na_frac <- sapply(dt_lst$numeric, function(var) mean(is.na(data[[var]])))
    high_na <- dt_lst$numeric[na_frac > 0.5]
    if (length(high_na) > 0) {
      n <- length(high_na)
      cli_warn(
        "{n} variable{?s} {?has/have} more than 50% missing values: {.val {high_na}}.",
        class = "predict_type_high_missingness"
      )
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
