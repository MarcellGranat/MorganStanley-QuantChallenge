.read(weekly_training_rset)

boost_tree_xgboost_spec <- boost_tree(tree_depth = tune(), trees = tune(), learn_rate = tune(), min_n = tune(), loss_reduction = tune(), sample_size = tune(), stop_iter = tune()) %>%
  set_engine('xgboost', validation = .2) %>%
  set_mode('regression')

weekly_recipe <- recipe(yield ~ ., data = analysis(weekly_training_rset$splits[[1]])) |> 
  step_rm(county) |> 
  step_zv(all_numeric_predictors(), - year) |>
  step_corr(all_numeric_predictors(), - year, threshold = .9) |> 
  step_normalize(all_numeric_predictors()) |> 
  step_rm(year)

wf <- workflow() |> 
  add_recipe(weekly_recipe) |> 
  add_model(boost_tree_xgboost_spec) |> 
  add_case_weights(case_wts)

library(doParallel)
registerDoParallel(makePSOCKcluster(min(parallel::detectCores(logical = FALSE), 9)))

gri <- tune_grid(
  wf, 
  resamples = weekly_training_rset,
  metrics = metric_set(rsq, rmse, msd, mape),
  grid = 5
)

boost_tree_xgboost_wf <- wf |> 
  finalize_workflow(
    parameters = select_best(gri, "rmse")
  )

.write(boost_tree_xgboost_wf)
