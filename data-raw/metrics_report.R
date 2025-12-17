# ------------------------------
# Function: Number of Unique Values
# ------------------------------
n_unique_values <- function(var) {
  non_na <- var[!is.na(var)]
  length(unique(non_na))
}

# ------------------------------
# Function: Standard Deviation (numeric only)
# ------------------------------
std_dev_var <- function(var) {
  non_na <- var[!is.na(var)]
  if (is.numeric(non_na) && length(non_na) > 1) sd(non_na) else NA_real_
}


# ------------------------------
# Function: Maximum Relative Frequency
# ------------------------------
max_relative_freq <- function(var) {
  non_na <- var[!is.na(var)]
  if (length(non_na) == 0) {
    return(NA_real_)
  }
  counts <- table(non_na)
  max(counts) / length(non_na)
}


# ------------------------------
# Function: Normalized Entropy
# ------------------------------
norm_entropy_var <- function(var) {
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


# ------------------------------
# Function: Minimum Value
# ------------------------------
min_value_var <- function(var) {
  non_na <- var[!is.na(var)]
  if (is.numeric(non_na) && length(non_na) > 0) min(non_na) else NA
}

# ------------------------------
# Function: Maximum Value
# ------------------------------
max_value_var <- function(var) {
  non_na <- var[!is.na(var)]
  if (is.numeric(non_na) && length(non_na) > 0) max(non_na) else NA
}


# ------------------------------
# Function: Is Character Variable
# ------------------------------
is_character_var <- function(var) {
  is.character(var)
}

# ------------------------------
# Function: Label Coverage
# ------------------------------
label_coverage_var <- function(var, var_name = NULL, labels_df = NULL) {
  non_na <- var[!is.na(var)]
  if (is.null(labels_df) || is.null(var_name)) {
    return(NA_real_)
  }
  labels_var <- labels_df %>% dplyr::filter(var == var_name & value != ">")
  if (length(non_na) == 0) {
    return(NA_real_)
  }
  df_values <- data.frame(
    var = var_name,
    value = unique(non_na),
    stringsAsFactors = FALSE
  )
  merged <- merge(df_values, labels_var, by = c("var", "value"), all.x = TRUE)
  sum(!is.na(merged$label)) / nrow(merged)
}


# ------------------------------
# Function: Shannon Entropy (nats)
# ------------------------------
shannon_entropy_var <- function(var) {
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

# ------------------------------
# Function: Simpson Index (1 - sum p^2)
# ------------------------------
simpson_index_var <- function(var) {
  non_na <- var[!is.na(var)]
  counts <- table(non_na)
  probs <- if (sum(counts) > 0) counts / sum(counts) else numeric(0)
  if (length(probs) == 0) {
    return(NA_real_)
  }
  1 - sum(probs^2)
}


# ------------------------------
# Function: Skewness of probabilities
# ------------------------------
skewness_probs_var <- function(var) {
  non_na <- var[!is.na(var)]
  counts <- table(non_na)
  probs <- if (sum(counts) > 0) counts / sum(counts) else numeric(0)
  if (length(probs) <= 2) {
    return(0)
  }
  m <- mean(probs)
  s <- stats::sd(probs)
  if (!is.finite(s) || s == 0) {
    return(0)
  }
  z <- (probs - m) / s
  mean(z^3)
}

# ------------------------------
# Function: Kurtosis of probabilities (excess)
# ------------------------------
kurtosis_probs_var <- function(var) {
  non_na <- var[!is.na(var)]
  counts <- table(non_na)
  probs <- if (sum(counts) > 0) counts / sum(counts) else numeric(0)
  if (length(probs) <= 2) {
    return(0)
  }
  m <- mean(probs)
  s <- stats::sd(probs)
  if (!is.finite(s) || s == 0) {
    return(0)
  }
  z <- (probs - m) / s
  mean(z^4) - 3
}

# ------------------------------
# Function: Dispersion Index = Var / Mean
# ------------------------------
dispersion_index_var <- function(var) {
  non_na <- var[!is.na(var)]
  counts <- table(non_na)
  probs <- if (sum(counts) > 0) counts / sum(counts) else numeric(0)
  if (length(probs) == 0) {
    return(NA_real_)
  }
  stats::var(probs) / mean(probs)
}

# ------------------------------
# Function: Uniformity = Shannon / log(n_unique)
# ------------------------------
uniformity_var <- function(var) {
  H <- shannon_entropy_var(var)
  non_na <- var[!is.na(var)]
  n_unique_values <- length(unique(non_na))
  if (n_unique_values <= 1) {
    return(0)
  }
  H / log(n_unique_values)
}

# ------------------------------
# Function: Top-k Ratios
# ------------------------------
topk_ratios_var <- function(var, topk = c(2, 3)) {
  non_na <- var[!is.na(var)]
  counts <- table(non_na)
  probs <- if (sum(counts) > 0) counts / sum(counts) else numeric(0)
  if (length(probs) == 0) {
    return(setNames(rep(NA_real_, length(topk)), paste0("top", topk, "_ratio")))
  }
  p_sorted <- sort(probs, decreasing = TRUE)
  ratios <- vapply(
    topk,
    function(k) sum(p_sorted[seq_len(min(k, length(p_sorted)))]),
    numeric(1)
  )
  names(ratios) <- paste0("top", topk, "_ratio")
  ratios
}

range_value_var <- function(var) {
  non_na <- var[!is.na(var)]
  if (is.numeric(non_na) && length(non_na) > 1) {
    max(non_na) - min(non_na)
  } else {
    NA_real_
  }
}
