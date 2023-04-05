load("weighted-setup.RData")

rand_forest_ranger_spec <- rand_forest(mtry = tune(), min_n = tune()) %>%
  set_engine('ranger') %>%
  set_mode('regression')

library(doParallel)
registerDoParallel(makePSOCKcluster(min(parallel::detectCores(logical = FALSE), 6)))

tictoc::tic("w_rand_forest_ranger")

w_rand_forest_ranger_rs <- weighted_wf |> 
  add_model(rand_forest_ranger_spec)  |> 
  tune_grid(
    resamples = weighted_training_folds_l[["0.75"]],
    grid = 90,
    metrics = metric_set(rsq, rmse, msd, mape)
  )

stoc()

dir.create("weighted", showWarnings = FALSE)
write_rds(w_rand_forest_ranger_rs, file = "weighted/rand_forest_ranger.rds")