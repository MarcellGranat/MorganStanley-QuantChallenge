.read(weekly_training_rset_90)

linear_reg_glmnet_spec <- linear_reg(penalty = tune(), mixture = 1) %>%
  set_engine('glmnet')

weekly_recipe <- recipe(yield ~ ., data = analysis(weekly_training_rset_90$splits[[1]])) |> 
  step_rm(county) |> 
  step_zv(all_numeric_predictors(), - year) |>
  step_corr(all_numeric_predictors(), - year, threshold = .9) |> 
  step_normalize(all_numeric_predictors())

wf <- workflow() |> 
  add_recipe(weekly_recipe) |> 
  add_model(linear_reg_glmnet_spec) |> 
  add_case_weights(case_wts)


library(doParallel)
registerDoParallel(makePSOCKcluster(min(parallel::detectCores(logical = FALSE), 9)))

gri <- tune_grid(
  wf, 
  resamples = weekly_training_rset_90,
  metrics = metric_set(rsq, rmse, msd, mape),
  grid = 1000
)

linear_reg_glmnet_90_wf <- wf |> 
  finalize_workflow(
    parameters = select_best(gri, "rmse")
  )

.write(linear_reg_glmnet_90_wf)
