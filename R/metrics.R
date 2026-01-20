# ------------------------------------------------------------------------------
# Metrics funcions
# ------------------------------------------------------------------------------

# Number of Unique Values ------------------------------------------------------
compute_n_unique_values <- function(var, var_name) {
  check_numeric(
    var = var,
    var_name = var_name,
    metric_name = "n_unique_values"
  )

  non_na <- var[!is.na(var)]
  length(unique(non_na))
}

# Standard Deviation -----------------------------------------------------------
compute_std_dev <- function(var, var_name) {
  check_numeric(
    var = var,
    var_name = var_name,
    metric_name = "std_dev"
  )

  non_na <- var[!is.na(var)]
  if (length(non_na) <= 1) {
    return(NA_real_)
  }
  sd(non_na)
}

# Maximum Relative Frequency --------------------------------------------------
compute_max_relative_frequency <- function(var, var_name) {
  check_numeric(
    var = var,
    var_name = var_name,
    metric_name = "max_relative_frequency"
  )

  non_na <- var[!is.na(var)]

  if (length(non_na) == 0) {
    return(NA_real_)
  }

  counts <- table(non_na)
  max(counts) / length(non_na)
}
# Normalized Entropy ---------------------------------------------------------
compute_norm_entropy <- function(var, var_name) {
  check_numeric(
    var = var,
    var_name = var_name,
    metric_name = "norm_entropy"
  )

  safe_log <- function(z) {
    z[z <= 0] <- 1e-12
    log(z)
  }

  non_na <- var[!is.na(var)]
  counts <- table(non_na)
  probs <- if (sum(counts) > 0) counts / sum(counts) else numeric(0)

  if (length(probs) <= 1) {
    return(0)
  }

  -sum(probs * safe_log(probs)) / log(length(probs))
}


# Minimum Value --------------------------------------------------------------
compute_min_value <- function(var, var_name) {
  check_numeric(
    var = var,
    var_name = var_name,
    metric_name = "min_value"
  )

  non_na <- var[!is.na(var)]
  if (length(non_na) == 0) {
    return(NA_real_)
  }

  min(non_na)
}


# Maximum Value --------------------------------------------------------------
compute_max_value <- function(var, var_name) {
  check_numeric(
    var = var,
    var_name = var_name,
    metric_name = "max_value"
  )

  non_na <- var[!is.na(var)]
  if (length(non_na) == 0) {
    return(NA_real_)
  }

  max(non_na)
}

# Is Character Variable ------------------------------------------------------
compute_is_character <- function(var, var_name) {
  is.character(var)
}


# Shannon Entropy ------------------------------------------------------------
compute_shannon_entropy <- function(var, var_name) {
  check_numeric(
    var = var,
    var_name = var_name,
    metric_name = "shannon_entropy"
  )

  safe_log <- function(z) {
    z[z <= 0] <- 1e-12
    log(z)
  }

  non_na <- var[!is.na(var)]
  counts <- table(non_na)
  probs <- if (sum(counts) > 0) counts / sum(counts) else numeric(0)

  if (length(probs) == 0) {
    return(NA_real_)
  }

  -sum(probs * safe_log(probs))
}


# Simpson Index --------------------------------------------------------------
compute_simpson_index <- function(var, var_name) {
  check_numeric(
    var = var,
    var_name = var_name,
    metric_name = "simpson_index"
  )

  non_na <- var[!is.na(var)]
  counts <- table(non_na)
  probs <- if (sum(counts) > 0) counts / sum(counts) else numeric(0)

  if (length(probs) == 0) {
    return(NA_real_)
  }

  1 - sum(probs^2)
}


# Skewness of probabilities --------------------------------------------------
compute_skewness_probs <- function(var, var_name) {
  check_numeric(
    var = var,
    var_name = var_name,
    metric_name = "skewness_probs"
  )

  non_na <- var[!is.na(var)]
  counts <- table(non_na)
  probs <- if (sum(counts) > 0) counts / sum(counts) else numeric(0)

  if (length(probs) <= 2) {
    return(0)
  }

  m <- mean(probs)
  s <- sd(probs)

  if (!is.finite(s) || s == 0) {
    return(0)
  }

  z <- (probs - m) / s
  mean(z^3)
}


# Kurtosis of probabilities (excess) -----------------------------------------
compute_kurtosis_probs <- function(var, var_name) {
  check_numeric(
    var = var,
    var_name = var_name,
    metric_name = "kurtosis_probs"
  )

  non_na <- var[!is.na(var)]
  counts <- table(non_na)
  probs <- if (sum(counts) > 0) counts / sum(counts) else numeric(0)

  if (length(probs) <= 2) {
    return(0)
  }

  m <- mean(probs)
  s <- sd(probs)

  if (!is.finite(s) || s == 0) {
    return(0)
  }

  z <- (probs - m) / s
  mean(z^4) - 3
}


# Dispersion Index = Var / Mean ----------------------------------------------
compute_dispersion_index <- function(var, var_name) {
  check_numeric(
    var = var,
    var_name = var_name,
    metric_name = "dispersion_index"
  )

  non_na <- var[!is.na(var)]
  counts <- table(non_na)
  probs <- if (sum(counts) > 0) counts / sum(counts) else numeric(0)

  if (length(probs) == 0) {
    return(NA_real_)
  }

  var(probs) / mean(probs)
}


# Uniformity = Shannon / log(n_unique_values) ---------------------------------------
compute_uniformity <- function(var, var_name) {
  check_numeric(
    var = var,
    var_name = var_name,
    metric_name = "uniformity"
  )

  h <- compute_shannon_entropy(var, var_name)

  non_na <- var[!is.na(var)]
  n_unique_values <- length(unique(non_na))

  if (n_unique_values <= 1) {
    return(0)
  }

  h / log(n_unique_values)
}


# Top-k Ratios -----------------------------------------------------------------
compute_topk_ratio <- function(var, topk, var_name) {
  check_numeric(
    var = var,
    var_name = var_name,
    metric_name = "topk_ratio"
  )

  non_na <- var[!is.na(var)]
  counts <- table(non_na)
  probs <- if (sum(counts) > 0) counts / sum(counts) else numeric(0)

  out_name <- paste0("top", topk, "_ratio")

  if (length(probs) == 0) {
    return(setNames(NA_real_, out_name))
  }

  p_sorted <- sort(probs, decreasing = TRUE)
  ratio <- sum(p_sorted[seq_len(min(topk, length(p_sorted)))])

  setNames(ratio, out_name)
}

compute_top2_ratio <- function(var, var_name) {
  compute_topk_ratio(var, topk = 2, var_name = var_name)
}

compute_top3_ratio <- function(var, var_name) {
  compute_topk_ratio(var, topk = 3, var_name = var_name)
}


# Range Value ----------------------------------------------------------------
compute_range_value <- function(var, var_name) {
  check_numeric(
    var = var,
    var_name = var_name,
    metric_name = "range_value"
  )

  non_na <- var[!is.na(var)]

  if (length(non_na) <= 1) {
    return(NA_real_)
  }

  max(non_na) - min(non_na)
}
