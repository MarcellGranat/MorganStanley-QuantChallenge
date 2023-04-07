.read(weekly_training_no_wts_rset)

svm_linear_LiblineaR_spec <- svm_linear(cost = tune(), margin = tune()) %>%
  set_engine('LiblineaR') %>%
  set_mode('regression')

weekly_recipe <- recipe(yield ~ ., data = analysis(weekly_training_no_wts_rset$splits[[1]])) |> 
  step_rm(county) |> 
  step_zv(all_numeric_predictors(), - year) |>
  step_corr(all_numeric_predictors(), - year, threshold = .9) |> 
  step_normalize(all_numeric_predictors())

library(doParallel)
registerDoParallel(makePSOCKcluster(min(parallel::detectCores(logical = FALSE), 9)))

wf <- workflow() |> 
  add_recipe(weekly_recipe) |> 
  add_model(svm_linear_LiblineaR_spec)

gri <- tune_grid(
  wf, 
  resamples = weekly_training_no_wts_rset,
  metrics = metric_set(rsq, rmse, msd, mape),
  grid = 900
)

svm_grid <- gri
.write(svm_grid)

svm_linear_LiblineaR_wf <- wf |> 
  finalize_workflow(
    parameters = select_best(gri, "rmse")
  )

.write(weekly_svm_linear_LiblineaR_wf)
