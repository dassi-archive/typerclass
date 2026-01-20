# Setting and check
devtools::document()
devtools::check()
devtools::load_all()
devtools::test()
covr::report()

# Example run of compute_var_metrics
df <- readr::read_csv("inst/SN217.csv", guess_max = 1000000)

results <- compute_var_metrics(
  var = df$AMATR,
  var_name = "AMATR",
  metrics = select_metrics()
)


# example run of dataset_metrics and predict_type
df <- readr::read_csv("_dev/data/SN217.csv", guess_max = 1000000) |>
  dplyr::select(
    -"IDNO",
    -"TITL",
    -"VERSION",
    -"RELEASE",
    -"CHIFIG2_8",
    -"CHIFIG2_9"
  ) |>
  dplyr::select(1:30)

df_metrics <- dataset_metrics(df)
df_predict <- predict_type(df)

labels <- readr::read_csv("_dev/data/SN217_labels.csv") |>
  dplyr::filter(value == ">")

df_predict_w_type <- df_predict |>
  dplyr::left_join(
    labels |>
      dplyr::select(var, type),
    by = c("variable" = "var")
  ) |>
  dplyr::mutate(
    match = dplyr::if_else(.pred_class == type, TRUE, FALSE)
  )
