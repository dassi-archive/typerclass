# ------------------------------------------------------------------------------
# Missing value declaration
# ------------------------------------------------------------------------------

# set_missing() ---------------------------------------------------------------
#' Declare missing values for variable type prediction
#'
#' @description
#' `set_missing()` creates a specification of missing values that can be passed
#' to [predict_type()] via the `missing` argument. Values declared as missing
#' are converted to `NA` before computing the distributional metrics used for
#' type prediction, effectively excluding them from the analysis.
#'
#' @param all A numeric vector of global missing values to be applied to all
#'   numeric and factor variables in the dataset. Use this when the same codes
#'   (e.g. 98, 99) represent missing data across multiple variables.
#' @param ... Named numeric vectors specifying per-variable missing values.
#'   Each name must correspond to a column in the data passed to
#'   [predict_type()].
#'
#' @return An object of class `typerclass_missing`, which is a list with two
#'   components:
#'   \describe{
#'     \item{all}{The global missing value vector, or `NULL` if not set.}
#'     \item{per_variable}{A named list of per-variable missing value vectors.}
#'   }
#' @export
#'
#' @examples
#' # Global missing values applied to all eligible variables
#' set_missing(all = c(98, 99))
#'
#' # Per-variable missing values
#' set_missing(HWACTUAL = 99, STAPRO = c(9, 99))
#'
#' # Combined: global + variable-specific exceptions
#' set_missing(all = c(98, 99), HWACTUAL = 999)
set_missing <- function(all = NULL, ...) {
  per_variable <- list(...)

  if (!is.null(all)) {
    if (!is.numeric(all)) {
      cli_abort(
        "{.arg all} must be a numeric vector, not {.type {all}}.",
        class = "set_missing_all_not_numeric"
      )
    }
  }

  if (length(per_variable) > 0) {
    if (is.null(names(per_variable)) || any(names(per_variable) == "")) {
      cli_abort(
        "All per-variable missing values must be named.",
        class = "set_missing_unnamed"
      )
    }
    for (nm in names(per_variable)) {
      if (!is.numeric(per_variable[[nm]])) {
        cli_abort(
          "Missing values for {.val {nm}} must be numeric, not {.type {per_variable[[nm]]}}.",
          class = "set_missing_per_variable_not_numeric"
        )
      }
    }
  }

  structure(
    list(
      all = all,
      per_variable = per_variable
    ),
    class = "typerclass_missing"
  )
}
