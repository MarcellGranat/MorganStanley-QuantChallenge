.read(weekly_training_rset_90)

rand_forest_ranger_spec <- rand_forest(mtry = tune(), min_n = tune()) %>%
  set_engine('ranger') %>%
  set_mode('regression')

weekly_recipe <- recipe(yield ~ ., data = analysis(weekly_training_rset_90$splits[[1]])) |> 
  step_rm(county) |> 
  step_zv(all_numeric_predictors(), - year) |>
  step_corr(all_numeric_predictors(), - year, threshold = .9) |> 
  step_normalize(all_numeric_predictors())

wf <- workflow() |> 
  add_recipe(weekly_recipe) |> 
  add_model(rand_forest_ranger_spec) |> 
  add_case_weights(case_wts)

library(doParallel)
registerDoParallel(makePSOCKcluster(min(parallel::detectCores(logical = FALSE), 9)))

gri <- tune_grid(
  wf, 
  resamples = weekly_training_rset_90,
  metrics = metric_set(rsq, rmse, msd, mape),
  grid = 90
)

rand_forest_ranger_90_wf <- wf |> 
  finalize_workflow(
    parameters = select_best(gri, "rmse")
  )

.write(rand_forest_ranger_90_wf)
