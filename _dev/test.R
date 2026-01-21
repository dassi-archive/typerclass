devtools::load_all()

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
