.read(design_df)

training_set <- design_df |> 
  filter(year < 2010)

gamma <- seq(from = 0, to = 1, length.out = 3 + 2) |> 
  setdiff(c(0, 1)) |> 
  append(.9) # added 9 because .75 brought promising results

weighted_training_sets <- map(gamma, ~ {
  training_set |> 
    group_by(year) |> 
    mutate(n = n()) |> 
    ungroup() |> 
    mutate(
      case_wts = . ^ (max(year) - year) * min(n) / n, # Koyck weights + "undersampling"
      case_wts = importance_weights(case_wts)
    ) |> 
    select(-n)
}) |> 
  set_names(gamma)linear_reg_glmnet_spec <-
  linear_reg(penalty = tune(), mixture = tune()) %>%
  set_engine('glmnet')

linear_reg_lm_spec <-
  linear_reg() %>%
  set_engine('lm')

rand_forest_randomForest_spec <-
  rand_forest(mtry = tune(), min_n = tune()) %>%
  set_engine('randomForest') %>%
  set_mode('regression')

svm_linear_LiblineaR_spec <-
  svm_linear(cost = tune(), margin = tune()) %>%
  set_engine('LiblineaR') %>%
  set_mode('regression')




# Recipe ------------------------------------------------------
# not preped recipe > avoid look-ahead bias

rec <- recipe(yield ~ ., data = weighted_training_sets[[1]]) |> 
  step_rm(county) |> 
  step_zv(all_predictors()) |> # remove with ZeroVariance
  step_corr(all_numeric_predictors(), threshold = .7) |> 
  step_normalize(all_numeric_predictors())

weighted_wf <- workflow() |> 
  add_recipe(rec) |> 
  add_case_weights(case_wts)

# Folds -------------------------------------------------------
# identical to `rolling_origin`, but for panel set + year refers to the year of assessment observations

weighted_training_folds_l <- weighted_training_sets |> 
  map(~ {
    group_by(., year) |> 
      nest() |> 
      arrange(year) |> 
      ungroup() |> 
      mutate(
        data = map2(data, year, ~ mutate(.x, year = .y, .before = 1)),
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
  })

save(weighted_wf, weighted_training_folds_l, file = "weighted-setup.RData")
