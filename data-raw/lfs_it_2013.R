library(tidyverse)


# LFS Italy 2013 from Eurostat
tmp <- tempfile()
download.file(
  "https://ec.europa.eu/eurostat/cache/microdata/lfs/IT_2013_LFS.zip",
  tmp
)

unzip(tmp, files = c("IT_LFS_2013_Y.csv"), exdir = tempdir())

lfs_it_2013 <- read_csv(file.path(tempdir(), "IT_LFS_2013_Y.csv")) %>%
  select(REFYEAR, SEX, AGE, STAPRO, HWACTUAL, COEFF) %>%
  sample_n(size = 1000, weight = .data$COEFF)


write_csv(lfs_it_2013, "data-raw/lfs_it_2013.csv")
usethis::use_data(lfs_it_2013, overwrite = TRUE, compress = "gzip")


# Labels for LFS Italy 2013
# REFYEAR
refyear <- tibble(
  value   = ">",
  var     = "REFYEAR",
  label   = "Reference year",
  lang    = "en",
  type    = "S",
  weight  = FALSE,
  missing = NA
)

# SEX
sex <- tibble(
  value   = c(">", "1", "2"),
  var     = "SEX",
  label   = c("Sex", "Male", "Female"),
  lang    = "en",
  type    = "N",
  weight  = c(FALSE, NA, NA),
  missing = c(NA, FALSE, FALSE)
)

# AGE
age <- tibble(
  value   = c(">", "7", "20", "32", "47", "65", "75"),
  var     = "AGE",
  label   = c("Age", "0-14", "15-24", "25-39", "40-54", "55-74", "75+"),
  lang    = "en",
  type    = "O",
  weight  = c(FALSE, NA, NA, NA, NA, NA, NA),
  missing = c(NA, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE)
)

# STAPRO
stapro <- tibble(
  value = c(">", "0", "5", "9"),
  var = "STAPRO",
  label = c(
    "Professional status",
    "Self-employed with or without employees",
    "Employee or family worker",
    "Not applicable"
  ),
  lang = "en",
  type = "N",
  weight = c(FALSE, NA, NA, NA),
  missing = c(NA, FALSE, FALSE, TRUE)
)

# HWACTUAL
hwactual <- tibble(
  value = c(">", "0", "99"),
  var = "HWACTUAL",
  label = c(
    "Number of hours actually worked during the reference week in main job",
    paste(
      "Persons having a job or business and not having worked at all in",
      "the main activity during the reference week"
    ),
    "Not applicable"
  ),
  lang = "en",
  type = "N",
  weight = c(FALSE, NA, NA),
  missing = c(NA, FALSE, TRUE)
)

# COEFF
coeff <- tibble(
  value   = ">",
  var     = "COEFF",
  label   = "Weighting factor",
  lang    = "en",
  type    = "S",
  weight  = TRUE,
  missing = NA
)

lfs_it_2013_labels <- bind_rows(
  refyear,
  sex,
  age,
  stapro,
  hwactual,
  coeff
)

write_csv(lfs_it_2013_labels, "data-raw/lfs_it_2013_labels.csv")
usethis::use_data(lfs_it_2013_labels, overwrite = TRUE, compress = "gzip")
