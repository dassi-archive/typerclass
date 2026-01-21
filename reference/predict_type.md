# Predict measurement types for dataset variables

Computes distributional metrics for numeric variables and uses a
pretrained random-forest model to classify each variable as nominal (N),
ordinal (O), or scale (S). Non-numeric variables are handled
deterministically: character/logical variables are marked as nominal,
date variables as ordinal, and unsupported types receive empty
predictions.

## Usage

``` r
predict_type(data)
```

## Arguments

- data:

  A data frame of variables to classify.

## Value

A tibble with one row per input variable and the following columns:

- variable:

  Original variable name.

- .pred_class:

  Predicted class (N, O, or S).

- .pred_N:

  Probability of nominal class.

- .pred_O:

  Probability of ordinal class.

- .pred_S:

  Probability of scale class.

Rows are returned in the same order as the columns of `data`. For
variables that are not processed by the model, probability columns are
`NA`.

## Details

Factors are coerced to numeric and included with other numeric
variables. The model object `rf_final_fit` is loaded with the package.

## Examples

``` r
if (FALSE) { # \dontrun{
df <- tibble(
  age = c(20, 30, 40),
  sex = c("M", "F", "F")
)
predict_type(df)
} # }
```
