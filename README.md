
# typerclass

<!-- badges: start -->
[![R-CMD-check](https://github.com/dassi-archive/typerclass/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/dassi-archive/typerclass/actions/workflows/R-CMD-check.yaml)
[![Codecov test coverage](https://codecov.io/gh/dassi-archive/typerclass/graph/badge.svg)](https://app.codecov.io/gh/dassi-archive/typerclass)
<!-- badges: end -->

The goal of Typerclass is to predict the type of variables (nominal, ordinal, or scale) based on their empirical distribution and observed values.


## Installation

You can install the development version of typerclass from [GitHub](https://github.com/) with:

``` r
# install.packages("typerclass")
pak::pak("dassi-archive/typerclass")
```

## Example

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
#      var .pred_class .pred_nominal .pred_ordinal .pred_scale
# 1  NCOMP       scale     0.1234567     0.2345678    0.6419755
# 2 ORDCOM     ordinal     0.2345678     0.5432109    0.2222215
# 3  POSIND     nominal     0.6543210     0 .1234567    0.2222223
# 4   RELPAR     ordinal     0.3456789     0.4567890    0.197532  
# 5    SEX     nominal     0.7654321     0.1234567    0.1111112

```


