.read(design_df)

training_set <- design_df |> 
  filter(year < 2010)

# Recipe ------------------------------------------------------
# not preped recipe > avoid look-ahead bias

rec <- recipe(yield ~ ., data = training_set) |> 
  step_rm(county) |> 
  step_zv(all_predictors()) |> # remove with ZeroVariance
  step_corr(all_numeric_predictors(), threshold = .7) |> 
  step_normalize(all_numeric_predictors())


# Folds -------------------------------------------------------
# identical to `rolling_origin`, but for panel set + year refers to the year of assessment observations

training_folds <- training_set |> 
  group_by(year) |> 
  nest() |> 
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

save(rec, training_folds, file = "model-setup.RData")
