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
  id = training_folds |> 
    pull(id)
) |> 
  crossing(
    wf = wfs
  ) |> 
  mutate(
    analysis_pred = map2(analysis, wf, .progress = TRUE, ~ {
      predict(fit(.y, .x), .x) |> # build the model on the training data
        set_names(.y$fit$actions$model$spec$engine) # predict the training data
    }),
    assessment_pred = pmap(list(analysis, assessment, wf), .progress = TRUE, ~ {
      predict(fit(..3, ..1), ..2) |> # build the model on the training data
        set_names(..3$fit$actions$model$spec$engine) # predict the testing data!
    })
  ) |> 
  group_by(id) |> 
  reframe(
    analysis = bind_cols(analysis_pred) |> # colnames refer to the model which made the prediction
      mutate(
        county = analysis[[1]]$county,
        yield = analysis[[1]]$yield
        ) |> 
      list(),
    assessment = bind_cols(assessment_pred) |> 
      mutate(
        county = assessment[[1]]$county,
        yield = assessment[[1]]$yield
        ) |> 
      list()
  ) |> 
  mutate(splits = map2(analysis,  assessment, ~ make_splits(x = .x, assessment = .y))) %$%
  manual_rset(splits, as.character(id))

# Recipe ------------------------------------------------------
# not preped recipe > avoid look-ahead bias
# no need for cor filter and zv_remove again!

ensemble_rec <- recipe(yield ~ ., data = analysis(ensemble_folds$splits[[1]])) |> 
  step_rm(county) |> 
  step_normalize(all_numeric_predictors())

save(ensemble_rec, ensemble_folds, file = "ensemble-setup.RData")
