check_numeric <- function(var, var_name, metric_name) {
  if (is.null(var_name)) {
    var_name <- deparse(substitute(var)) %>%
     sub(".*\\$", "", x = .)
  }

  if (!is.numeric(var)) {
    msg <- if (is.null(metric_name)) {
      paste0("Error: cannot compute for '", var_name,
       "' because it is not numeric but is ", class(var)[1], ".")
    } else {
      paste0("Error: the metric '", metric_name, "' cannot be computed for '",
       var_name,"' because it is not numeric but is ", class(var)[1], ".")
    }
    cli::cli_abort(msg, .envir = parent.frame())
  }

  TRUE
}
