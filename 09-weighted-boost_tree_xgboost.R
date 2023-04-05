load("weighted-setup.RData")

boost_tree_xgboost_spec <- boost_tree(tree_depth = tune(), trees = tune(), learn_rate = tune(), min_n = tune(), loss_reduction = tune(), sample_size = tune(), stop_iter = tune()) %>%
  set_engine('xgboost') %>%
  set_mode('regression')

library(doParallel)
registerDoParallel(makePSOCKcluster(min(parallel::detectCores(logical = FALSE), 9)))

tictoc::tic("w_boost_tree_xgboost")

w_boost_tree_xgboost_rs <- weighted_wf |> 
  add_model(boost_tree_xgboost_spec)  |> 
  tune_grid(
    resamples = weighted_training_folds_l[["0.75"]],
    grid = 900,
    metrics = metric_set(rsq, rmse, msd, mape)
  )

stoc()

dir.create("weighted", showWarnings = FALSE)
write_rds(w_boost_tree_xgboost_rs, file = "weighted/boost_tree_xgboost.rds")
