.read(oats_training)

boost_tree_lightgbm_spec <- boost_tree(tree_depth = tune(), trees = tune(), 
                                       learn_rate = tune(), min_n = tune(), 
                                       loss_reduction = tune(), 
                                       sample_size = tune(), 
                                       stop_iter = tune()) %>%
  set_engine('lightgbm') %>%
  set_mode('regression')

weekly_recipe <- recipe(yield ~ ., data = analysis(oats_training$splits[[1]])) |> 
  step_rm(county) |> 
  step_zv(all_numeric_predictors(), - year) |>
  step_corr(all_numeric_predictors(), - year, threshold = .9) |> 
  step_normalize(all_numeric_predictors())

library(doParallel)
registerDoParallel(makePSOCKcluster(min(parallel::detectCores(logical = FALSE), 9)))

wf <- workflow() |> 
  add_recipe(weekly_recipe) |> 
  add_model(boost_tree_lightgbm_spec)

gri <- tune_grid(
  wf, 
  resamples = oats_training,
  metrics = metric_set(rsq, rmse, msd, mape),
  grid = 3
)

oats_boost_tree_lightgbm_wf <- wf |> 
  finalize_workflow(
    parameters = select_best(gri, "rmse")
  )

.write(oats_boost_tree_lightgbm_wf)
