.read(weekly_training_no_wts_rset)

mars_earth_spec <- mars(prod_degree = tune()) %>%
  set_engine('earth') %>%
  set_mode('regression')

weekly_recipe <- recipe(yield ~ ., data = analysis(weekly_training_no_wts_rset$splits[[1]])) |> 
  step_rm(county) |> 
  step_zv(all_numeric_predictors(), - year) |>
  step_corr(all_numeric_predictors(), - year, threshold = .9) |> 
  step_normalize(all_numeric_predictors())

wf <- workflow() |> 
  add_recipe(weekly_recipe) |> 
  add_model(mars_earth_spec)

library(doParallel)
registerDoParallel(makePSOCKcluster(min(parallel::detectCores(logical = FALSE), 9)))

gri <- tune_grid(
  wf, 
  resamples = weekly_training_no_wts_rset,
  metrics = metric_set(rsq, rmse, msd, mape),
  grid = 2
)

mars_earth_no_wts_wf <- wf |> 
  finalize_workflow(
    parameters = select_best(gri, "rmse")
  )

.write(mars_earth_no_wts_wf)
