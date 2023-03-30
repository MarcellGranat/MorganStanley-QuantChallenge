load("model-setup.RData")

linear_reg_glmnet_spec <- linear_reg(penalty = tune(), mixture = 1) %>%
  set_engine('glmnet')


library(doParallel)
registerDoParallel(makePSOCKcluster(min(parallel::detectCores(logical = FALSE), 6)))

tictoc::tic("linear_reg_glmnet")

linear_reg_glmnet_rs <- workflow(rec, linear_reg_glmnet_spec) |> 
  tune_grid(
    resamples = training_folds,
    grid = 5e3,
    metrics = metric_set(rsq, rmse, msd, mape)
  )

stoc()

linear_reg_glmnet <- list(
  spec = linear_reg_glmnet_spec,
  tuning_rs = linear_reg_glmnet_rs
)

dir.create("tuning", showWarnings = FALSE)
write_rds(linear_reg_glmnet, file = "tuning/linear_reg_glmnet.rds")
