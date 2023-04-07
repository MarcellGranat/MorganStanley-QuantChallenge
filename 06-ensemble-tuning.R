.read(weekly_training_rset_90)
.read(weekly_training_no_wts_rset)

.read(linear_reg_glmnet_90_wf)
.read(weekly_svm_linear_LiblineaR_wf)
.read(weekly_boost_tree_lightgbm_wf)
.read(rand_forest_ranger_no_wts_wf)
.read(mars_earth_no_wts_wf)

linear_reg_glmnet_pred <- fit_resamples(
  linear_reg_glmnet_90_wf,
  weekly_training_rset_90,
  control = control_resamples(save_pred = TRUE)
) |> 
  collect_predictions() |> 
  select(glmnet = .pred)

svm_linear_LiblineaR_pred <- fit_resamples(
  weekly_svm_linear_LiblineaR_wf,
  weekly_training_no_wts_rset,
  control = control_resamples(save_pred = TRUE)
) |> 
  collect_predictions() |> 
  select(LiblineaR = .pred)

boost_tree_lightgbm_wf_pred <- fit_resamples(
  weekly_boost_tree_lightgbm_wf,
  weekly_training_no_wts_rset,
  control = control_resamples(save_pred = TRUE)
) |> 
  collect_predictions() |> 
  select(lightgbm = .pred)

mars_earth_wf_pred <- fit_resamples(
  mars_earth_no_wts_wf,
  weekly_training_no_wts_rset,
  control = control_resamples(save_pred = TRUE)
) |> 
  collect_predictions() |> 
  select(earth = .pred)

rand_forest_ranger_pred <- fit_resamples(
  rand_forest_ranger_no_wts_wf,
  weekly_training_no_wts_rset,
  control = control_resamples(save_pred = TRUE)
) |> 
  collect_predictions() |> 
  select(ranger = .pred)

ensemble_training_rset <- weekly_training_no_wts_rset |> 
  transmute(
    id, data = map(splits, assessment)
  ) |> 
  unnest(data) |> 
  select(year, county, yield) |> 
  bind_cols(
    linear_reg_glmnet_pred,
    boost_tree_lightgbm_wf_pred,
    rand_forest_ranger_pred,
    svm_linear_LiblineaR_pred,
    mars_earth_wf_pred
  ) |> 
  group_by(year) |> 
  nest() |> 
  ungroup() |> 
  mutate(
    analysis = map(year, ~ {
      across(everything()) |> 
        filter(year < .) |> 
        pull(data) |> 
        bind_rows()
    })
  ) |> 
  tail(- 8) |> 
  mutate(
    splits = map2(analysis, data, make_splits)
  ) %$%
  manual_rset(splits, as.character(year))

linear_reg_glmnet_spec <- linear_reg(penalty = tune(), mixture = 1) %>%
  set_engine('glmnet')

linear_reg_lm_spec <- linear_reg() %>%
  set_engine('lm')

mars_earth_spec <- mars(prod_degree = tune()) %>%
  set_engine('earth') %>%
  set_mode('regression')

ensemble_wf <- workflow() |> 
  add_recipe(
    recipe = recipe(yield ~ glmnet + lightgbm + ranger + LiblineaR + earth, 
                    data = analysis(ensemble_training_rset$splits[[1]])) |> 
      step_normalize(all_predictors()) |> 
      step_zv(all_predictors())
  ) 

ensemble_dropSVM_wf <- workflow() |> 
  add_recipe(
    recipe = recipe(yield ~ glmnet + lightgbm + ranger, 
                    data = analysis(ensemble_training_rset$splits[[1]])) |> 
      step_normalize(all_predictors()) |> 
      step_zv(all_predictors())
  ) 

ensemble_linear_reg_glmnet_wf <- tune_grid(
  ensemble_wf |> 
    add_model(linear_reg_glmnet_spec),
  resamples = ensemble_training_rset,
  grid = 100
) |> 
  select_best("rmse") |> 
  finalize_workflow(
    x = ensemble_wf |> 
      add_model(linear_reg_glmnet_spec)
  )

ensemble_linear_reg_lm_wf <- ensemble_wf |> 
  add_model(linear_reg_lm_spec)

ensemble_mars_earth_wf <- tune_grid(
  ensemble_wf |> 
    add_model(mars_earth_spec),
  resamples = ensemble_training_rset,
  grid = 2
) |> 
  select_best("rmse") |> 
  finalize_workflow(
    x = ensemble_wf |> 
      add_model(mars_earth_spec)
  )


ensemble_dropSVM_linear_reg_glmnet_wf <- tune_grid(
  ensemble_dropSVM_wf |> 
    add_model(linear_reg_glmnet_spec),
  resamples = ensemble_training_rset,
  grid = 100
) |> 
  select_best("rmse") |> 
  finalize_workflow(
    x = ensemble_dropSVM_wf |> 
      add_model(linear_reg_glmnet_spec)
  )

ensemble_dropSVM_linear_reg_lm_wf <- ensemble_dropSVM_wf |> 
  add_model(linear_reg_lm_spec)

ensemble_dropSVM_mars_earth_wf <- tune_grid(
  ensemble_dropSVM_wf |> 
    add_model(mars_earth_spec),
  resamples = ensemble_training_rset,
  grid = 2
) |> 
  select_best("rmse") |> 
  finalize_workflow(
    x = ensemble_dropSVM_wf |> 
      add_model(mars_earth_spec)
  )

.write(ensemble_linear_reg_glmnet_wf, ensemble_linear_reg_lm_wf, ensemble_mars_earth_wf, 
       ensemble_dropSVM_linear_reg_glmnet_wf, 
       ensemble_dropSVM_linear_reg_lm_wf, ensemble_dropSVM_mars_earth_wf)




