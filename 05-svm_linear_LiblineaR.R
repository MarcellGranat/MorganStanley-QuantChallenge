load("model-setup.RData")

svm_linear_LiblineaR_spec <- svm_linear(cost = tune(), margin = tune()) |> 
  set_engine('LiblineaR') |> 
  set_mode('regression')

library(doParallel)
registerDoParallel(makePSOCKcluster(min(parallel::detectCores(logical = FALSE), 6)))

tictoc::tic("svm_linear_LiblineaR")

svm_linear_LiblineaR_rs <- workflow(rec, svm_linear_LiblineaR_spec) |> 
  tune_grid(
    resamples = training_folds,
    grid = 1000,
    metrics = metric_set(rsq, rmse, msd, mape)
  )

svm_linear_LiblineaR <- list(
  spec = svm_linear_LiblineaR_spec,
  tuning_rs = svm_linear_LiblineaR_rs
)

stoc()

dir.create("tuning", showWarnings = FALSE)
write_rds(svm_linear_LiblineaR, file = "tuning/svm_linear_LiblineaR.rds")
