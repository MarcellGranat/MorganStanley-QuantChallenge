load("model-setup.RData")

model_specs <- list.files("tuning", full.names = TRUE) |> 
  setdiff("tuning/linear_reg_lm.rds") |> 
  map(read_rds) |> 
  map(1)

tuning_rs <- list.files("tuning", full.names = TRUE) |> 
  setdiff("tuning/linear_reg_lm.rds") |> 
  map(read_rds) |> 
  map(2) 

wfs <- map2(model_specs, tuning_rs, ~ { # models with the best hyperparameter set
  workflow() |> 
    add_recipe(rec) |> 
    add_model(.x) |> 
    finalize_workflow(select_best(.y, metric = "rmse")) # based on RMSE
})


# Folds -------------------------------------------------------
# identical to `rolling_origin`, but for panel set + year refers to the year of assessment observations
# predictors are the predictions from the single models!

ensemble_folds <- tibble(
  analysis = training_folds |> 
    pull(splits) |> 
    map(analysis),
  assessment = training_folds |> 
    pull(splits) |> 
    map(assessment),
  year = training_folds |> 
    pull(id) |> 
    as.numeric()
) |> 
  crossing(
    wf = wfs
  ) |> 
  mutate(
    baselearner_pred = pmap(list(analysis, assessment, wf), .progress = TRUE, ~ {
      predict(fit(..3, ..1), ..2) |> # build the model on the training data
        set_names(..3$fit$actions$model$spec$engine) # predict the testing data!
    })
  ) |> 
  group_by(year) |> 
  reframe(
    data = bind_cols(baselearner_pred) |> 
      mutate(
        county = assessment[[1]]$county,
        yield = assessment[[1]]$yield
        ) |> 
      list()
  ) |> 
  ungroup() |> 
  mutate(
    analysis = map(year, \(x) {
      cur_data_all() |> 
        filter(year < x, year >= (x - 8)) |> # previous 8 years
        pull(data) |> 
        bind_rows()
    })
  ) |> 
  tail(- 8) |>  # analysis set is not complete in the first 8 years
  mutate(splits = map2(analysis,  data, ~ make_splits(x = .x, assessment = .y))) %$%
  manual_rset(splits, as.character(year))

# Recipe ------------------------------------------------------
# not preped recipe > avoid look-ahead bias

ensemble_rec <- recipe(yield ~ ., data = analysis(ensemble_folds$splits[[1]])) |> 
  step_rm(county) |> 
  step_zv() |> 
  step_normalize(all_numeric_predictors())

save(ensemble_rec, ensemble_folds, file = "ensemble-setup.RData")
