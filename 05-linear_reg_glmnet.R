load("model-setup.RData")

linear_reg_glmnet_spec <- linear_reg(penalty = tune(), mixture = tune()) %>%
  set_engine('glmnet')

linear_reg_glmnet_grid <- grid_regular(
  penalty(), mixture(),
  levels = 3
)

linear_reg_glmnet_rs <- workflow(rec, linear_reg_glmnet_spec) |> 
  tune_grid(
    resamples = training_folds,
    grid = linear_reg_glmnet_grid
  )
