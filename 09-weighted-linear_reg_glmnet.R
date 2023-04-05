load("weighted-setup.RData")

linear_reg_glmnet_spec <- linear_reg(penalty = tune(), mixture = 1) %>%
  set_engine('glmnet')

library(doParallel)
registerDoParallel(makePSOCKcluster(min(parallel::detectCores(logical = FALSE), 9)))

tictoc::tic("w_linear_reg_glmnet")

w_linear_reg_glmnet_rs <- weighted_wf |> 
  add_model(linear_reg_glmnet_spec) |> 
  tune_grid(
    resamples = weighted_training_folds_l[["0.75"]],
    grid = 4500,
    metrics = metric_set(rsq, rmse, msd, mape)
  )

stoc()

dir.create("weighted", showWarnings = FALSE)
write_rds(w_linear_reg_glmnet_rs, file = "weighted/linear_reg_glmnet.rds")
