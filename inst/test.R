devtools::load_all()

devtools::document()


df <- readr::read_csv("inst/SN217.csv")

devtools::load_all()
results <- compute_var_metrics(
  var = df$AMATR,
  var_name = "AMATR",
  metrics = select_metrics()
)

# Run tests

devtools::test()

covr::report()

devtools::check()

# predict_type function test

dataaa <- read.csv("inst/SN217.csv") %>%
  dplyr::select(
    -"IDNO",
    -"TITL",
    -"VERSION",
    -"RELEASE",
    -"CHIFIG2_8",
    -"CHIFIG2_9"
  )

dataaa <- dataaa %>% dplyr::select(1:30)

mio <- dataset_metrics(dataaa)

b <- predict_type(dataaa)
