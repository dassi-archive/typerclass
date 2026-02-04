# Typerclass: Model Training and Evaluation Report

``` r
library(tidyverse)
#> ── Attaching core tidyverse packages ──────────────────────── tidyverse 2.0.0 ──
#> ✔ dplyr     1.2.0     ✔ readr     2.1.6
#> ✔ forcats   1.0.1     ✔ stringr   1.6.0
#> ✔ ggplot2   4.0.2     ✔ tibble    3.3.1
#> ✔ lubridate 1.9.5     ✔ tidyr     1.3.2
#> ✔ purrr     1.2.1     
#> ── Conflicts ────────────────────────────────────────── tidyverse_conflicts() ──
#> ✖ dplyr::filter() masks stats::filter()
#> ✖ dplyr::lag()    masks stats::lag()
#> ℹ Use the conflicted package (<http://conflicted.r-lib.org/>) to force all conflicts to become errors
library(tidymodels)
#> ── Attaching packages ────────────────────────────────────── tidymodels 1.4.1 ──
#> ✔ broom        1.0.12     ✔ rsample      1.3.2 
#> ✔ dials        1.4.2      ✔ tailor       0.1.0 
#> ✔ infer        1.1.0      ✔ tune         2.0.1 
#> ✔ modeldata    1.5.1      ✔ workflows    1.3.0 
#> ✔ parsnip      1.4.1      ✔ workflowsets 1.1.1 
#> ✔ recipes      1.3.1      ✔ yardstick    1.3.2 
#> ── Conflicts ───────────────────────────────────────── tidymodels_conflicts() ──
#> ✖ scales::discard() masks purrr::discard()
#> ✖ dplyr::filter()   masks stats::filter()
#> ✖ recipes::fixed()  masks stringr::fixed()
#> ✖ dplyr::lag()      masks stats::lag()
#> ✖ yardstick::spec() masks readr::spec()
#> ✖ recipes::step()   masks stats::step()
library(ranger)
library(gt)
library(vip)
#> 
#> Attaching package: 'vip'
#> 
#> The following object is masked from 'package:utils':
#> 
#>     vi
library(patchwork)
library(bundle)
library(xgboost)
library(here)
#> here() starts at /home/runner/work/typerclass/typerclass

knitr::opts_knit$set(root.dir = here::here())
```

## Introduction

This document presents the model training and evaluation process carried
out using Typerclass. The goal is to provide a clear overview of the
methodological choices and results of the modeling process.

## Key decisions in the modeling process

The model was trained following a few important choices regarding the
data and the algorithm.

### Dataset composition

Data from three surveys available at the Italian Istitute of Statistics
(ISTAT) were combined:

- [Family, social subjects and life
  cycle](https://www.istat.it/en/microdata/multipurpose-survey-on-households-families-social-subjects-and-life-cycle-public-use-micro-stat-files/)
- [Labour Force
  Survey](https://www.istat.it/en/microdata/labour-force-survey-cross-sectional-quarterly-data-2/)
- [Aspects of daily
  life](https://www.istat.it/en/microdata/aspects-of-daily-life/)

The final dataset included 400 instances of class “Nominal”, 200 of
class “Ordinal”, and 125 of class “Scale” (mapped in the code as N, O,
and S, respectively).

## Indicators

The following indicators are used in the model, along with a brief
description of each:

- **n_unique_values** – Number of unique values in the variable
  (excluding missing values).  
- **std_dev** – Standard deviation; measures how spread out the values
  are.  
- **max_relative_frequency** – Proportion of the most frequent value
  relative to the total number of observations.  
- **norm_entropy** – Normalized entropy; measures how evenly the values
  are  
  distributed.
- **min_value** – Minimum observed value.  
- **max_value** – Maximum observed value.  
- **range_value** – Difference between the maximum and minimum values.
- **shannon_entropy** – Shannon entropy; a measure of uncertainty or
  information  
  content.
- **simpson_index** – Simpson diversity index; indicates how
  concentrated the values are.  
- **skewness_probs** – Skewness of the value-probability distribution;
  measures  
  asymmetry.
- **kurtosis_probs** – Excess kurtosis of the value distribution;
  indicates tail  
  heaviness.
- **dispersion_index** – Variance-to-mean ratio of value probabilities;
  measures  
  dispersion.
- **uniformity** – Shannon entropy normalized by `log(n_unique_values)`;
  measures distributional evenness.  
- **top2_ratio** – Sum of the probabilities of the two most frequent
  values.  
- **top3_ratio** – Sum of the probabilities of the three most frequent
  values.

The table provides an overview of all indicators used in the model. Most
indicators have no missing values, ensuring reliable inputs for
training. The only exception is `dispersion_index`, which contains 128
missing values. The `ranger` package can handle missing values by
default; preliminary tests also showed that imputation did not improve
model performance.

``` r
# Data import & preparation

# Import dataset
data <- read_csv("./vignettes/model_data.csv")
#> Rows: 1167 Columns: 18
#> ── Column specification ────────────────────────────────────────────────────────
#> Delimiter: ","
#> chr  (3): variable, dataset, type
#> dbl (15): n_unique_values, std_dev, max_relative_frequency, norm_entropy, mi...
#> 
#> ℹ Use `spec()` to retrieve the full column specification for this data.
#> ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.

# Balanced sample
set.seed(123)

data_N <- data %>%
  filter(type == "N") %>%
  sample_n(400)

data_O <- data %>%
  filter(type == "O") %>%
  sample_n(200)

data_S <- data %>%
  filter(type == "S")

data <- bind_rows(data_N, data_O, data_S)


# Split into training (80%) and test (20%) sets, stratified by 'type'
set.seed(123)
data_split <- initial_split(data, prop = 0.8, strata = type)
train_data <- training(data_split)
test_data <- testing(data_split)

# Fix consistent class level ordering for the whole script
class_order <- c("N", "O", "S")

indicators <- train_data %>%
  select(-dataset, -variable, -type) %>%
  colnames()

df_indicators <- tibble(indicator = indicators)


# --- NA count per indicator

na_table <- train_data %>%
  select(all_of(indicators)) %>%
  summarise(across(everything(), ~ sum(is.na(.)))) %>%
  pivot_longer(everything(), names_to = "indicator", values_to = "na_count") %>%
  arrange(desc(na_count))

na_table %>%
  gt() %>%
  tab_header(
    title = "Overview of Indicators and Missing Values"
  ) %>%
  cols_label(
    indicator = "Indicator",
    na_count = "NAs"
  )
```

| Overview of Indicators and Missing Values |     |
|-------------------------------------------|-----|
| Indicator                                 | NAs |
| dispersion_index                          | 128 |
| n_unique_values                           | 0   |
| std_dev                                   | 0   |
| max_relative_frequency                    | 0   |
| norm_entropy                              | 0   |
| min_value                                 | 0   |
| max_value                                 | 0   |
| range_value                               | 0   |
| shannon_entropy                           | 0   |
| simpson_index                             | 0   |
| skewness_probs                            | 0   |
| kurtosis_probs                            | 0   |
| uniformity                                | 0   |
| top2_ratio                                | 0   |
| top3_ratio                                | 0   |

## Indicator Distributions

This section shows the distributions of all indicators, highlighting
variability and potential outliers. Several indicators display heavy
tails and numerous outliers, while others (e.g., proportion-based
measures) are more tightly concentrated; overall, the plots suggest
substantial heterogeneity across predictors.

To improve readability, a log transformation (log10 with +1) was applied
to a subset of indicators with very different scales or heavy tails. The
remaining panels are shown on the original scale so that comparably
scaled indicators can be interpreted directly.

``` r

data %>%
  select(-variable, -dataset, -type) %>%
  pivot_longer(
    cols = everything(),
    names_to = "variable",
    values_to = "value"
  ) %>%
  mutate(
    value_plot = ifelse(is.na(value), NA_real_, value),
    value_plot = case_when(
      variable %in%
        c(
          "max_value",
          "min_value",
          "range_value",
          "std_dev",
          "n_unique_values",
          "kurtosis_probs",
          "skewness_probs",
          "shannon_entropy"
        ) &
        !is.na(value_plot) &
        value_plot >= 0 ~ log10(value_plot + 1),
      TRUE ~ value_plot
    )
  ) %>%
  ggplot(aes(x = variable, y = value_plot)) +
  geom_boxplot(outlier.colour = "red", outlier.shape = 1) +
  theme_minimal() +
  labs(
    title = "Boxplot of Metrics (log10 for selected indicators)",
    x = "Variable",
    y = "Value (log10 for selected indicators)",
    caption = "Outliers in red"
  ) +
  facet_wrap(~variable, scales = "free_y", ncol = 3) +
  theme(axis.text.x = element_blank())
#> Warning: There was 1 warning in `mutate()`.
#> ℹ In argument: `value_plot = case_when(...)`.
#> Caused by warning:
#> ! NaNs produced
#> Warning: Removed 160 rows containing non-finite outside the scale range
#> (`stat_boxplot()`).
```

![](model_training_files/figure-html/indicator-boxplots-1.png)

## Correlation matrix

The correlation matrix displays pairwise relationships between all model
indicators. Several predictors show high correlations, but they were
retained in the dataset because Random Forest — one of the algorithms
selected for this study — is robust to multicollinearity. In fact,
including correlated indicators can still improve model performance by
providing additional predictive information.

``` r

numeric_data <- train_data %>%
  select(all_of(indicators)) %>%
  select(where(is.numeric))

# Compute correlation matrix
cor_matrix <- cor(numeric_data, use = "pairwise.complete.obs")

# Convert to long format for conditional formatting
cor_df <- as.data.frame(cor_matrix) %>%
  rownames_to_column(var = "indicator")

# Build GT table: format numbers + highlight abs(cor) > 0.6
gt(cor_df) %>%
  fmt_number(
    columns = -indicator,
    decimals = 1
  ) %>%
  data_color(
    columns = -indicator,
    fn = function(x) {
      ifelse(abs(x) > 0.6 & abs(x) != 1, "#ff9999", "white")
    }
  ) %>%
  tab_header(
    title = "Correlation Matrix of Indicators"
  )
```

| Correlation Matrix of Indicators |                 |         |                        |              |           |           |             |                 |               |                |                |                  |            |            |            |
|----------------------------------|-----------------|---------|------------------------|--------------|-----------|-----------|-------------|-----------------|---------------|----------------|----------------|------------------|------------|------------|------------|
| indicator                        | n_unique_values | std_dev | max_relative_frequency | norm_entropy | min_value | max_value | range_value | shannon_entropy | simpson_index | skewness_probs | kurtosis_probs | dispersion_index | uniformity | top2_ratio | top3_ratio |
| n_unique_values                  | 1.0             | 0.3     | −0.2                   | 0.1          | 0.3       | 0.3       | 0.3         | 0.7             | 0.2           | 0.3            | 0.3            | −0.1             | 0.1        | −0.3       | −0.4       |
| std_dev                          | 0.3             | 1.0     | −0.1                   | 0.1          | 1.0       | 1.0       | 1.0         | 0.3             | 0.1           | 0.8            | 1.0            | 0.0              | 0.1        | −0.1       | −0.2       |
| max_relative_frequency           | −0.2            | −0.1    | 1.0                    | −0.9         | −0.1      | −0.1      | −0.1        | −0.8            | −1.0          | −0.3           | −0.1           | 0.9              | −0.9       | 0.9        | 0.8        |
| norm_entropy                     | 0.1             | 0.1     | −0.9                   | 1.0          | 0.1       | 0.1       | 0.1         | 0.6             | 0.9           | 0.1            | 0.0            | −1.0             | 1.0        | −0.6       | −0.5       |
| min_value                        | 0.3             | 1.0     | −0.1                   | 0.1          | 1.0       | 1.0       | 1.0         | 0.3             | 0.1           | 0.8            | 1.0            | −0.1             | 0.1        | −0.1       | −0.2       |
| max_value                        | 0.3             | 1.0     | −0.1                   | 0.1          | 1.0       | 1.0       | 1.0         | 0.3             | 0.1           | 0.8            | 1.0            | 0.0              | 0.1        | −0.1       | −0.2       |
| range_value                      | 0.3             | 1.0     | −0.1                   | 0.1          | 1.0       | 1.0       | 1.0         | 0.3             | 0.1           | 0.8            | 1.0            | 0.0              | 0.1        | −0.1       | −0.2       |
| shannon_entropy                  | 0.7             | 0.3     | −0.8                   | 0.6          | 0.3       | 0.3       | 0.3         | 1.0             | 0.8           | 0.5            | 0.3            | −0.5             | 0.6        | −0.9       | −0.9       |
| simpson_index                    | 0.2             | 0.1     | −1.0                   | 0.9          | 0.1       | 0.1       | 0.1         | 0.8             | 1.0           | 0.3            | 0.1            | −0.9             | 0.9        | −0.8       | −0.7       |
| skewness_probs                   | 0.3             | 0.8     | −0.3                   | 0.1          | 0.8       | 0.8       | 0.8         | 0.5             | 0.3           | 1.0            | 0.8            | −0.1             | 0.1        | −0.4       | −0.4       |
| kurtosis_probs                   | 0.3             | 1.0     | −0.1                   | 0.0          | 1.0       | 1.0       | 1.0         | 0.3             | 0.1           | 0.8            | 1.0            | −0.1             | 0.0        | −0.2       | −0.2       |
| dispersion_index                 | −0.1            | 0.0     | 0.9                    | −1.0         | −0.1      | 0.0       | 0.0         | −0.5            | −0.9          | −0.1           | −0.1           | 1.0              | −1.0       | 0.6        | 0.5        |
| uniformity                       | 0.1             | 0.1     | −0.9                   | 1.0          | 0.1       | 0.1       | 0.1         | 0.6             | 0.9           | 0.1            | 0.0            | −1.0             | 1.0        | −0.6       | −0.5       |
| top2_ratio                       | −0.3            | −0.1    | 0.9                    | −0.6         | −0.1      | −0.1      | −0.1        | −0.9            | −0.8          | −0.4           | −0.2           | 0.6              | −0.6       | 1.0        | 1.0        |
| top3_ratio                       | −0.4            | −0.2    | 0.8                    | −0.5         | −0.2      | −0.2      | −0.2        | −0.9            | −0.7          | −0.4           | −0.2           | 0.5              | −0.5       | 1.0        | 1.0        |

## Model Selection

### Preprocessing Recipe

We tested a preprocessing approach using median imputation for all
numeric predictors. However, preliminary tests showed no improvement in
model performance, so we decided to proceed with a recipe without any
imputation.

``` r

# Define Preprocessing Recipes

# (A) Recipe with no imputation
rec_none <- recipe(type ~ ., data = train_data) %>%
  update_role(dataset, variable, new_role = "info")
```

Random Forest and XGBoost were both selected and evaluated with
hyperparameter tuning.

### Model Specification: Random Forest

``` r
# Model Specifications

# ---- Random Forest ----
rf_spec <- rand_forest(
  trees = tune(),
  mtry = tune(),
  min_n = tune()
) %>%
  set_engine("ranger", importance = "permutation") %>%
  set_mode("classification")
```

### Hyperparameter Tuning for Random Forest

We selected the `mtry` range using the classic rule-of-thumb centered on
`sqrt(p)`, where `p` is the number of predictors, and expanded it by
±50% to allow slightly simpler or more complex splits.

``` r
# Create workflow combining recipe + model
rf_tune_wf <- workflow() %>%
  add_recipe(rec_none) %>% # change rec_median here for imputation
  add_model(rf_spec)

# 5-fold cross-validation (stratified)
set.seed(123)
cv_folds <- vfold_cv(train_data, v = 5, strata = type)

# Define regular grid for RF tuning
p <- ncol(train_data %>% select(-dataset, -variable, -type))
mtry_center <- floor(sqrt(p))
mtry_low <- max(1L, floor(mtry_center * 0.5))
mtry_high <- min(p, ceiling(mtry_center * 1.5))

rf_grid <- grid_space_filling(
  trees(range = c(300L, 1000L)),
  mtry(range = c(mtry_low, mtry_high)),
  min_n(range = c(2L, 20L)),
  size = 20
)

# Run grid search for RF
rf_tune_res <- tune_grid(
  rf_tune_wf,
  resamples = cv_folds,
  grid = rf_grid,
  metrics = metric_set(accuracy)
)


# Select best parameters based on accuracy
best_rf_params <- select_best(rf_tune_res, metric = "accuracy")
best_rf_params %>%
  gt() %>%
  tab_header(
    title = "Best Random Forest Hyperparameters"
  ) %>%
  fmt_number(
    columns = everything(),
    decimals = 2
  )
```

| Best Random Forest Hyperparameters |        |       |                  |
|------------------------------------|--------|-------|------------------|
| mtry                               | trees  | min_n | .config          |
| 2.00                               | 410.00 | 4.00  | pre0_mod06_post0 |

``` r

# Finalize model with best parameters
rf_final_spec <- finalize_model(rf_spec, best_rf_params)

rf_final_wf <- workflow() %>%
  add_recipe(rec_none) %>%
  add_model(rf_final_spec)

# Fit the tuned RF on the full training data
rf_final_fit <- rf_final_wf %>%
  fit(data = train_data)
```

### Model Specification: XGBoost

XGBoost was specified using a gradient-boosted tree model with tunable
hyperparameters. We used the `xgboost` engine and set the model to
classification mode to predict the three classes.

``` r
# ---- XGBoost ----
xgb_spec <- boost_tree(
  trees = tune(),
  tree_depth = tune(),
  learn_rate = tune(),
  loss_reduction = tune(),
  min_n = tune(),
  sample_size = tune(),
  mtry = tune()
) %>%
  set_engine("xgboost") %>%
  set_mode("classification")
```

### Hyperparameter Tuning for XGBoost

We tuned XGBoost using the same cross-validation folds as Random Forest.
The `mtry` range follows the same rule-of-thumb (centered on `sqrt(p)`),
while the other hyperparameters use typical ranges for boosted trees.

``` r
# Create workflow combining recipe + model
xgb_tune_wf <- workflow() %>%
  add_recipe(rec_none) %>%
  add_model(xgb_spec)

# Define regular grid for XGBoost tuning
p <- ncol(train_data %>% select(-dataset, -variable, -type))
mtry_center <- floor(sqrt(p))
mtry_low <- max(1L, floor(mtry_center * 0.5))
mtry_high <- min(p, ceiling(mtry_center * 1.5))

xgb_params <- extract_parameter_set_dials(xgb_spec) %>%
  update(
    trees = trees(range = c(300L, 1000L)),
    tree_depth = tree_depth(range = c(2L, 10L)),
    learn_rate = learn_rate(range = c(0.01, 0.3)),
    loss_reduction = loss_reduction(range = c(0.0, 5.0)),
    min_n = min_n(range = c(2L, 20L)),
    sample_size = sample_prop(range = c(0.5, 1.0)),
    mtry = mtry(range = c(mtry_low, mtry_high))
  )

xgb_grid <- grid_space_filling(
  xgb_params,
  size = 20
)

# Run grid search for XGBoost
xgb_tune_res <- tune_grid(
  xgb_tune_wf,
  resamples = cv_folds,
  grid = xgb_grid,
  metrics = metric_set(accuracy)
)


# Select best parameters based on accuracy
best_xgb_params <- select_best(xgb_tune_res, metric = "accuracy")
best_xgb_params %>%
  gt() %>%
  tab_header(
    title = "Best XGBoost Hyperparameters"
  ) %>%
  fmt_number(
    columns = everything(),
    decimals = 3
  )
```

| Best XGBoost Hyperparameters |         |       |            |            |                |             |                  |
|------------------------------|---------|-------|------------|------------|----------------|-------------|------------------|
| mtry                         | trees   | min_n | tree_depth | learn_rate | loss_reduction | sample_size | .config          |
| 3.000                        | 889.000 | 2.000 | 6.000      | 1.674      | 3.360          | 0.921       | pre0_mod12_post0 |

``` r

# Finalize model with best parameters
xgb_final_spec <- finalize_model(xgb_spec, best_xgb_params)

xgb_final_wf <- workflow() %>%
  add_recipe(rec_none) %>%
  add_model(xgb_final_spec)

# Fit the tuned XGBoost on the full training data
xgb_final_fit <- xgb_final_wf %>%
  fit(data = train_data)
```

## Evaluation

### Confusion matrix

We compare Random Forest and XGBoost on the same held-out test set. The
confusion matrices are normalized by row (true class), so values
represent per-class recall.

``` r
cm_compare %>%
  gt() %>%
  tab_header(title = "Summary of Confusion Matrix (Per-Class Recall, %)") %>%
  cols_label(
    truthN_predN = "True N → Pred N",
    truthN_predO = "True N → Pred O",
    truthN_predS = "True N → Pred S",
    truthO_predN = "True O → Pred N",
    truthO_predO = "True O → Pred O",
    truthO_predS = "True O → Pred S",
    truthS_predN = "True S → Pred N",
    truthS_predO = "True S → Pred O",
    truthS_predS = "True S → Pred S",
    model = "Model"
  ) %>%
  fmt_number(
    columns = everything()[-ncol(cm_compare)],
    decimals = 1
  )
```

| Summary of Confusion Matrix (Per-Class Recall, %) |                 |                 |                 |                 |                 |                 |                 |                 |                 |
|---------------------------------------------------|-----------------|-----------------|-----------------|-----------------|-----------------|-----------------|-----------------|-----------------|-----------------|
| Model                                             | True N → Pred N | True N → Pred O | True N → Pred S | True O → Pred N | True O → Pred O | True O → Pred S | True S → Pred N | True S → Pred O | True S → Pred S |
| RF_tuned                                          | 91.1            | 15.6            | 4.3             | 5.1             | 73.3            | 13.0            | 3.8             | 11.1            | 82.60870        |
| XGB_tuned                                         | 87.8            | 14.3            | 8.7             | 7.3             | 71.4            | 17.4            | 4.9             | 14.3            | 73.91304        |

### Performance metrics

The table below compares Random Forest and XGBoost on the same test set
using a consistent set of metrics (accuracy, balanced accuracy, macro
F1, Cohen’s Kappa, and macro ROC AUC). Hyperparameters were selected
using accuracy for simplicity; we report additional metrics to assess
class‑balanced performance.

| Model Comparison Metrics |          |              |          |          |          |
|--------------------------|----------|--------------|----------|----------|----------|
| model                    | accuracy | bal_accuracy | f_meas   | kap      | roc_auc  |
| RF_tuned                 | 0.84     | 0.86         | 0.81     | 0.74     | 0.93     |
| XGB_tuned                | 0.81     | 0.83         | 0.77     | 0.68     | 0.90     |
| Winner                   | RF_tuned | RF_tuned     | RF_tuned | RF_tuned | RF_tuned |

Accuracy is the overall proportion of correct predictions, while
balanced accuracy averages recall across classes to reduce
class-imbalance effects. Macro F1 gives equal weight to each class,
Cohen’s Kappa adjusts for chance agreement, and macro ROC AUC summarizes
discriminative ability across classes. Based on the average of these
metrics, the best overall model is **RF_tuned**.

### Misclassification Analysis

Misclassifications are inspected on the held-out test set to avoid
optimistic bias. The tables below summarize the misclassification
patterns for each model.

| Misclassification Summary (Test Set) — RF |                 |       |     |
|:------------------------------------------|:----------------|:------|:----|
| True class                                | Predicted class | Count |     |
| N                                         | O               | 7     |     |
| N                                         | S               | 1     |     |
| O                                         | N               | 4     |     |
| O                                         | S               | 3     |     |
| S                                         | N               | 3     |     |
| S                                         | O               | 5     |     |

| Misclassification Summary (Test Set) — XGBoost |                 |       |
|:-----------------------------------------------|:----------------|:------|
| True class                                     | Predicted class | Count |
| N                                              | O               | 6     |
| N                                              | S               | 2     |
| O                                              | N               | 6     |
| O                                              | S               | 4     |
| S                                              | N               | 4     |
| S                                              | O               | 6     |

For RF, the most frequent error is N → O (7 cases, 23 total
misclassifications). For XGBoost, the top confusion is N → O (6 cases,
28 total). These summaries highlight whether errors cluster between
adjacent classes or are more diffuse; fewer and more concentrated errors
generally indicate a more reliable model.

**Consistent with the overall performance metrics, Random Forest remains
the best-performing model and will be used for the final classifier.**

### Variable importance scores

This plot reports permutation importance for the Random Forest model.
For each indicator, its values are randomly permuted and the resulting
drop in model performance is measured; larger drops indicate more
important predictors. Because several indicators are correlated (as
shown in the correlation section), importance can be shared across
related features, so the plot should be read as a relative ranking
rather than an absolute measure of effect.

![](model_training_files/figure-html/rf-variable-importance-1.png)

### Distribution of Predictor Variables by True Class (N, O, S)

The final figure shows the distribution of predictor variables by their
true class (N, O, S) on the test set, highlighting how indicator values
vary across classes.

``` r

pred_vars <- test_data %>%
  select(-dataset, -variable, -type) %>%
  select(where(is.numeric)) %>%
  names()

plot_by_class <- function(data, vars, class_col = "type") {
  plots <- lapply(vars, function(var) {
    vals <- data[[var]]
    y_min <- quantile(vals, 0.05, na.rm = TRUE)
    y_max <- quantile(vals, 0.95, na.rm = TRUE)

    ggplot(data, aes_string(x = class_col, y = var, fill = class_col)) +
      geom_boxplot(alpha = 0.7) +
      coord_cartesian(ylim = c(y_min, y_max)) +
      labs(
        title = paste("Distribution of", var, "by", class_col),
        x = class_col,
        y = var
      ) +
      theme_minimal() +
      theme(legend.position = "none")
  })

  wrap_plots(plots, ncol = 3)
}

plot_by_class(test_data, pred_vars, class_col = "type")
#> Warning: `aes_string()` was deprecated in ggplot2 3.0.0.
#> ℹ Please use tidy evaluation idioms with `aes()`.
#> ℹ See also `vignette("ggplot2-in-packages")` for more information.
#> Warning: Removed 32 rows containing non-finite outside the scale range
#> (`stat_boxplot()`).
```

![](model_training_files/figure-html/predictor-distributions-1.png)

``` r
# Save final Random Forest workflow with fitted model
# Avoid writing during R CMD check (vignette build runs in a temp, read-only dir)
if (interactive() || identical(Sys.getenv("NOT_CRAN"), "true")) {
  dir.create("data-raw", showWarnings = FALSE, recursive = TRUE)
  if (!file.exists("./data-raw/rf_final_fit.rds")) {
    # rf_final_fit_bundled <- bundle(rf_final_fit)
    saveRDS(rf_final_fit, "./data-raw/rf_final_fit.rds")
  }
}

# rf_final_fit_bundled <- bundle(rf_final_fit)

# usethis::use_data(rf_final_fit, overwrite = TRUE, internal = TRUE)
```
