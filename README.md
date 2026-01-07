# typerclass

<!-- badges: start -->

[![R-CMD-check](https://github.com/dassi-archive/typerclass/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/dassi-archive/typerclass/actions/workflows/R-CMD-check.yaml) [![Codecov test coverage](https://codecov.io/gh/dassi-archive/typerclass/graph/badge.svg)](https://app.codecov.io/gh/dassi-archive/typerclass)

<!-- badges: end -->

The goal of Typerclass is to predict the type of variables (nominal, ordinal, or scale) based on their empirical distribution and observed values.

## Installation

You can install the development version of typerclass from [GitHub](https://github.com/) with: link

<!-- #TODO: update link github -->

```
# install.packages("typerclass")
pak::pak("dassi-archive/typerclass")
```

## Example

This is a basic example which shows you how to solve a common problem:

```r
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
# NCOMP        scale     0.1234567     0.2345678    0.6419755
# ORDCOM     ordinal     0.2345678     0.5432109    0.2222215
# POSIND     nominal     0.6543210     0.1234567   0.2222223
# RELPAR     ordinal     0.3456789     0.4567890    0.197532  
# SEX        nominal     0.7654321     0.1234567    0.1111112
```

# Example with real dataset

Typerclass includes a sample of the Italian Labour Force Survey (2013) dataset from Eurostat.

The data are provided in:
- `data-raw/lfs_it_2013.csv`: the dataset sample  
- `data-raw/lfs_it_2013_labels.csv`: variable labels

```r
library(typerclass)

# Load the sample dataset
lfs <- read.csv("data-raw/lfs_it_2013.csv")

# Inspect the first rows
head(lfs)

#  REFYEAR SEX AGE STAPRO HWACTUAL      COEFF
# 1    2013   1   7      9       99 0.06907368
# 2    2013   2  75      9       99 0.16291908
# 3    2013   2  75      9       99 0.18667223
# 4    2013   2  75      9       99 0.23400441
# 5    2013   1  65      9       99 0.23491220
# 6    2013   1  65      5       20 0.11992372

# Load variable labels
labels <- read.csv("data-raw/lfs_it_2013_labels.csv")

> labels <- labels %>%
  dplyr::select(-missing ,- weight, -lang)

# DISCUSS: togliamo missing lang e weight per semplicità?
# DISCUSS: visto che così stamparla è impossibile perchè etichetta di hwactual è lunghissima, togliamo quella variabile per fare più pulito? 




# Predict variable measurement types
type_predictions <- predict_type(lfs)

# View results
head(type_predictions)

# A tibble: 6 × 5
#  variable .pred_class .pred_N .pred_O .pred_S
#  <chr>    <fct>         <dbl>   <dbl>   <dbl>
# 1 REFYEAR  S             0.245 0        0.755 
# 2 SEX      N             0.998 0.00216  0     
# 3 AGE      S             0.151 0.0841   0.765 
# 4 STAPRO   N             0.644 0.272    0.0841
# 5 HWACTUAL S             0.121 0.0345   0.845 
# 6 COEFF    S             0.306 0.300    0.394 

#TODO: vogliamo aggiungere di matrice confusione?

# Join the tables using the correct column names
comparison <- type_predictions %>%
  dplyr::left_join(
    labels %>% dplyr::select(var, type),
    by = c("variable" = "var")
  ) %>%
  dplyr::rename(
    original_type = type,
    predicted_type = .pred_class
  )

# Display the row-by-row comparison
comparison

# A tibble: 19 × 6
#   variable predicted_type .pred_N .pred_O .pred_S original_type
#   <chr>    <fct>            <dbl>   <dbl>   <dbl> <chr>        
# 1 REFYEAR  S                0.245 0        0.755  S            
# 2 SEX      N                0.998 0.00216  0      N            
# 3 SEX      N                0.998 0.00216  0      N            
# 4 SEX      N                0.998 0.00216  0      N            
# 5 AGE      S                0.151 0.0841   0.765  O            
# 6 AGE      S                0.151 0.0841   0.765  O            
#7 AGE      S                0.151 0.0841   0.765  O            
# 8 AGE      S                0.151 0.0841   0.765  O            
# 9 AGE      S                0.151 0.0841   0.765  O            
#10 AGE      S                0.151 0.0841   0.765  O            
#11 AGE      S                0.151 0.0841   0.765  O            
#12 STAPRO   N                0.644 0.272    0.0841 N            
#13 STAPRO   N                0.644 0.272    0.0841 N            
#14 STAPRO   N                0.644 0.272    0.0841 N            
#15 STAPRO   N                0.644 0.272    0.0841 N            
#16 HWACTUAL S                0.121 0.0345   0.845  N            
#17 HWACTUAL S                0.121 0.0345   0.845  N            
#18 HWACTUAL S                0.121 0.0345   0.845  N            
#19 COEFF    S                0.306 0.300    0.394  S  

# Create the confusion matrix
conf_matrix <- table(
  comparison$original_type,
  comparison$predicted_type
)

# Display the confusion matrix

#  N O S
#  N 7 0 3
#  O 0 0 7
#  S 0 0 2

  ```

