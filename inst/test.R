devtools::load_all()

df <- readr::read_csv("inst/SN217.csv")

results <- compute_var_metrics(
  var = df$AMATR,
  var_name = "AMATR",
  metrics = select_metrics()
)

# Run tests
devtools::test()
