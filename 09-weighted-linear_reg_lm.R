load("weighted-setup.RData")

linear_reg_lm_spec <- linear_reg() |> 
  set_engine('lm')

tictoc::tic("w_linear_reg_lm")

w_linear_reg_lm_rs_l <- weighted_training_folds_l |> 
  map(~ {
    weighted_wf |> 
      add_model(linear_reg_lm_spec) |> 
      fit_resamples(
        resamples = .,
        metrics = metric_set(rsq, rmse, msd, mape)
      )
  })

stoc()

dir.create("weighted", showWarnings = FALSE)
write_rds(w_linear_reg_lm_rs_l, file = "weighted/linear_reg_lm.rds")
