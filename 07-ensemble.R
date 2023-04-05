load("ensemble-setup.RData")

wf <- workflow() |> 
  add_recipe(ensemble_rec)

linear_reg_lm_wf <- wf |> 
  add_model(
    spec = linear_reg() |>
      set_engine('lm')
  )

decision_tree_rpart_wf <- wf |> 
  add_model(
    spec = decision_tree(tree_depth = tune(), min_n = tune(), cost_complexity = tune()) |> 
      set_engine('rpart') |>
      set_mode('regression')
  )

linear_reg_glmnet_wf <- wf |> 
  add_model(
    spec = linear_reg(penalty = tune(), mixture = 1) |>
      set_engine('glmnet')
  )

mars_earth_wf <- wf |> 
  add_model(
    spec = mars_earth_spec <- mars(prod_degree = tune()) |> 
      set_engine('earth') |> 
      set_mode('regression')
  )

linear_reg_lm_rs <- fit_resamples(
  linear_reg_lm_wf,
  resamples = ensemble_folds,
  metrics = metric_set(rsq, rmse, msd, mape)
)

decision_tree_rpart_grid <- tune_grid(
  decision_tree_rpart_wf,
  resamples = ensemble_folds,
  metrics = metric_set(rsq, rmse, msd, mape),
  grid = 100
)

decision_tree_rpart_wf <- decision_tree_rpart_wf |> 
  finalize_workflow(select_best(decision_tree_rpart_grid, "rmse"))

linear_reg_glmnet_grid <- tune_grid(
  linear_reg_glmnet_wf,
  resamples = ensemble_folds,
  metrics = metric_set(rsq, rmse, msd, mape),
  grid = 100 # default in glmnet
)

linear_reg_glmnet_wf <- linear_reg_glmnet_wf |> 
  finalize_workflow(select_best(linear_reg_glmnet_grid, "rmse"))

mars_earth_grid <- tune_grid(
  mars_earth_wf,
  resamples = ensemble_folds,
  metrics = metric_set(rsq, rmse, msd, mape),
  grid = 2 # can be only 1 or 2
)

mars_earth_wf <- mars_earth_wf |> 
  finalize_workflow(select_best(mars_earth_grid, "rmse"))

write_rds(list(linear_reg_lm_rs, decision_tree_rpart_grid, linear_reg_glmnet_grid, mars_earth_grid), file = "ensemble_grids.rds")
write_rds(list(linear_reg_lm_wf, decision_tree_rpart_wf, linear_reg_glmnet_wf, mars_earth_wf), file = "ensemble_grids.rds")


