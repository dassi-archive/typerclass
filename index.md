# TypeRClass

The goal of Typerclass is to predict the type of variables (nominal,
ordinal, or scale) based on their empirical distribution and observed
values.

Numeric variables are processed by the probabilistic prediction model.

For numeric inputs, `typerclass` analyzes the empirical distribution of
observed values and returns:

- a predicted measurement type (`.pred_class`)

- the estimated probabilities of each class:

  - `.pred_N` (Nominal)
  - `.pred_O` (Ordinal)
  - `.pred_S` (Scale)

The predicted class corresponds to the measurement level with the
highest estimated probability.

Variables of type `factor` are first converted to numeric and then
processed by the probabilistic prediction model.

Variables of type `logical`, `character`, and `date` are excluded from
the probabilistic prediction model.

These variables are deterministically classified as Nominal, since their
measurement level cannot be inferred from an empirical numeric
distribution.

For such variables:

- `.pred_class` is set to `N` (Nominal)
- `.pred_N`, `.pred_O`, and `.pred_S` are returned as `NA`

Variables of other types (e.g. complex, list) are not processed and
prediction results are returned as `NA` for all output fields.

## Installation

You can install the development version of typerclass from
[GitHub](https://github.com/dassi-archive/typerclass) with:

``` r
pak::pak("dassi-archive/typerclass")
```

## Example

### Basic example

This is a basic example which shows you how to solve a common problem:

``` r
library(typerclass)

# Example input
df <- data.frame(
  NCOMP = c(3,5,2),
  ORDCOM = c(1,2,1),
  POSIND = c(0,1,0),
  RELPAR = c(2,2,1),
  SEX = c("M","F","M")
)

predict_type(df)


# Example output
## A tibble: 5 × 5
#  variable .pred_class .pred_N .pred_O .pred_S
#  <chr>    <chr>         <dbl>   <dbl>   <dbl>
#1 NCOMP    N             0.502  0.442   0.0560
#2 ORDCOM   N             0.761  0.0323  0.207 
#3 POSIND   N             0.781  0.0280  0.191 
#4 RELPAR   N             0.761  0.0323  0.207 
#5 SEX      N            NA     NA      NA     
```

### Example with real dataset

Typerclass includes a sample of the Italian Labour Force Survey (2013)
dataset from
[Eurostat](https://ec.europa.eu/eurostat/web/microdata/european-union-labour-force-survey).

The data are provided in:

- `lfs_it_2013`: the dataset sample  
- `lfs_it_2013_labels`: variable labels

``` r
library(typerclass)

# Inspect the first rows
head(lfs_it_2013)

#  REFYEAR SEX AGE STAPRO HWACTUAL      COEFF
# 1    2013   1   7      9       99 0.06907368
# 2    2013   2  75      9       99 0.16291908
# 3    2013   2  75      9       99 0.18667223
# 4    2013   2  75      9       99 0.23400441
# 5    2013   1  65      9       99 0.23491220
# 6    2013   1  65      5       20 0.11992372

# Predict variable measurement types
type_predictions <- predict_type(lfs_it_2013)

# View results
type_predictions

# A tibble: 6 × 5
#  variable .pred_class .pred_N .pred_O .pred_S
#  <chr>    <fct>         <dbl>   <dbl>   <dbl>
# 1 REFYEAR  S             0.245 0        0.755 
# 2 SEX      N             0.998 0.00216  0     
# 3 AGE      S             0.151 0.0841   0.765 
# 4 STAPRO   N             0.644 0.272    0.0841
# 5 HWACTUAL S             0.121 0.0345   0.845 
# 6 COEFF    S             0.306 0.300    0.394 
```

You can also inspect the variable labels. The data frame structure
follows the DASSI convention and is as follows:

- `var`: variable name
- `value`: coded values (including the `>` marker that indicates the
  variable label)
- `label`: description of the value or the variable

In practice, for each variable you will see one row with `value == ">"`
(the variable label), followed by the rows for the possible codes.

``` r
# Inspect the labels
head(lfs_it_2013_labels, 11)

#    value      var                                                     label
# 1      >  REFYEAR                                            Reference year
# 2      >      SEX                                                       Sex
# 3      1      SEX                                                      Male
# 4      2      SEX                                                    Female
# 5      >      AGE                                                       Age
# 6      7      AGE                                                      0-14
# 7     20      AGE                                                     15-24
# 8     32      AGE                                                     25-39
# 9     47      AGE                                                     40-54
# 10    65      AGE                                                     55-74
# 11    75      AGE                                                       75+
```

The labels also help spot cases where the prediction fails: for
instance, `AGE` is predicted as Scale, but the labels show age groups
(0-14, 15-24, …).

### Notes on predictions

Variable labels are not required by `typerclass` to generate
predictions; they are included here only for illustrative purposes, to
clarify how variables are defined and coded in the dataset.

The variable type predictions returned by `typerclass` are probabilistic
and may not always be correct.  
They should be interpreted together with survey metadata and substantive
knowledge of the data. In practice, `typerclass` predictions should be
used as a **support tool**, not as a substitute for careful data
inspection and documentation.

The method implemented in `typerclass` has been tested on official
survey microdata, with good accuracy in most cases, but it is not a
guarantee: coding schemes, special values, and survey design can all
affect the output. Always validate predictions against metadata and
documentation before using them for analysis.
