.read(weekly_training_rset_75)
.read(weekly_training_no_wts_rset)

# linear regression does not have any hyperparameter > no need for tuning
# but we need a wf (and recipe) with and without case_wts

linear_reg_lm_spec <- linear_reg() %>%
  set_engine('lm')

weekly_recipe <- recipe(yield ~ ., data = analysis(weekly_training_rset_75$splits[[1]])) |> 
  step_rm(county) |> 
  step_zv(all_numeric_predictors(), - year) |>
  step_corr(all_numeric_predictors(), - year, threshold = .9) |> 
  step_normalize(all_numeric_predictors())

linear_reg_lm_wts_wf <- workflow() |> 
  add_recipe(weekly_recipe) |> 
  add_model(linear_reg_lm_spec) |> 
  add_case_weights(case_wts)

weekly_no_wts_recipe <- recipe(yield ~ ., data = analysis(weekly_training_no_wts_rset$splits[[1]])) |> 
  step_rm(county) |> 
  step_zv(all_numeric_predictors(), - year) |>
  step_corr(all_numeric_predictors(), - year, threshold = .9) |> 
  step_normalize(all_numeric_predictors())

linear_reg_lm_no_wts_wf <- workflow() |> 
  add_recipe(weekly_no_wts_recipe) |> 
  add_model(linear_reg_lm_spec)

.write(linear_reg_lm_wts_wf)
.write(linear_reg_lm_no_wts_wf)
