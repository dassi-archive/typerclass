check_numeric <- function(var, var_name, metric_name) {
  if (is.null(var_name)) {
    var_name <- deparse(substitute(var))
    var_name <- sub(".*\\$", "", var_name)
  }

  if (!is.numeric(var)) {
    msg <- if (is.null(metric_name)) {
      paste0(
        "Error: cannot compute for '",
        var_name,
        "' because it is not numeric but is ",
        class(var)[1],
        "."
      )
    } else {
      paste0(
        "Error: the metric '",
        metric_name,
        "' cannot be computed for '",
        var_name,
        "' because it is not numeric but is ",
        class(var)[1],
        "."
      )
    }
    cli_abort(msg, .envir = parent.frame())
  }

  TRUE
}

get_datatype <- function(df) {
  stopifnot(is.data.frame(df))

  datatype_list <- list(
    numeric = character(),
    character = character(),
    factor = character(),
    logical = character(),
    date = character(),
    other = character()
  )

  for (var_name in names(df)) {
    var <- df[[var_name]]
    var_class <- class(var)[1]

    if (var_class %in% c("numeric", "integer")) {
      datatype_list$numeric <- c(datatype_list$numeric, var_name)
    } else if (var_class == "character") {
      datatype_list$character <- c(datatype_list$character, var_name)
    } else if (var_class == "factor") {
      datatype_list$factor <- c(datatype_list$factor, var_name)
    } else if (var_class == "logical") {
      datatype_list$logical <- c(datatype_list$logical, var_name)
    } else if (var_class %in% c("Date", "POSIXct", "POSIXt")) {
      datatype_list$date <- c(datatype_list$date, var_name)
    } else {
      datatype_list$other <- c(datatype_list$other, var_name)
    }
  }

  datatype_list
}
