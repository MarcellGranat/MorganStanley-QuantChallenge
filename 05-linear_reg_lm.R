load("model-setup.RData")

linear_reg_lm_spec <- linear_reg() |> 
  set_engine('lm')

tictoc::tic("linear_reg_lm")

linear_reg_lm_rs <- workflow(rec, linear_reg_lm_spec) |> 
  fit_resamples(
    resamples = training_folds,
    metrics = metric_set(rsq, rmse, msd, mape)
    )

linear_reg_lm <- list(
  spec = linear_reg_lm_spec,
  tuning_rs = linear_reg_lm_rs
)

stoc()

dir.create("tuning", showWarnings = FALSE)
write_rds(linear_reg_lm, file = "tuning/linear_reg_lm.rds")
