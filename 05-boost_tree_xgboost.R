load("model-setup.RData")

boost_tree_xgboost_spec <- boost_tree(tree_depth = tune(), trees = tune(), learn_rate = tune(), min_n = tune(), loss_reduction = tune(), sample_size = tune(), stop_iter = tune()) %>%
  set_engine('xgboost') %>%
  set_mode('regression')

library(doParallel)
registerDoParallel(makePSOCKcluster(min(parallel::detectCores(logical = FALSE), 6)))

tictoc::tic("boost_tree_xgboost")

boost_tree_xgboost_rs <- workflow(rec, boost_tree_xgboost_spec) |> 
  tune_grid(
    resamples = training_folds,
    grid = 100,
    metrics = metric_set(rsq, rmse, msd, mape)
  )

boost_tree_xgboost <- list(
  spec = boost_tree_xgboost_spec,
  tuning_rs = boost_tree_xgboost_rs
)

stoc()

dir.create("tuning", showWarnings = FALSE)
write_rds(boost_tree_xgboost, file = "tuning/boost_tree_xgboost.rds")
