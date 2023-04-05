load("model-setup.RData")

rand_forest_randomForest_spec <- rand_forest(mtry = tune(), min_n = tune()) |> 
  set_engine('ranger') |> 
  set_mode('regression')

library(doParallel)
registerDoParallel(makePSOCKcluster(min(parallel::detectCores(logical = FALSE), 9)))

tictoc::tic("rand_forest_randomForest")

rand_forest_randomForest_rs <- workflow(rec, rand_forest_randomForest_spec) |> 
  tune_grid(
    resamples = training_folds,
    grid = 90,
    metrics = metric_set(rsq, rmse, msd, mape)
  )

rand_forest_randomForest <- list(
  spec = rand_forest_randomForest_spec,
  tuning_rs = rand_forest_randomForest_rs
)

stoc()

dir.create("tuning", showWarnings = FALSE)
write_rds(rand_forest_randomForest, file = "tuning/rand_forest_randomForest.rds")
