.read(design_df)

train <- design_df |> 
  filter(year < 2010)

rec <- recipe(yield ~ ., data = train) |> 
  step_rm(county) |> 
  step_impute_mean(all_predictors()) |> 
  step_zv(all_predictors()) |> 
  step_corr(all_numeric_predictors(), threshold = .5) |> 
  step_normalize(all_numeric_predictors()) |> 
  prep()

rec$template

train_folds <- train |> 
  group_by(year) |> 
  nest() |> 
  ungroup() |> 
  mutate( # identical to rolling_origin, but for panel set + year refers to the year of assessment observations
    data = map2(data, year, ~ mutate(.x, year = .y, .before = 1)),
    analysis = map(year, \(x) {
      cur_data_all() |> 
        filter(x < year, x >= year - 8) |> 
        pull(data) |> 
        bind_rows()
    })
  ) |> 
  rename(assessment = data) |> 
  tail(- 8)

linear_reg_lm_spec <- linear_reg() |> 
  set_engine('lm')

wf <- workflow(preprocessor = rec, spec = linear_reg_lm_spec)


train_folds |> 
  group_by(year) |> 
  group_map(~ .) |> 
  head() |> 
  # pluck(1) |>
  # pull(analysis)
  map(\(x, y) {
    fit(wf, bake(baker, new_data = x$analysis[[1]])) |> 
      augment(new_data = x$assessment[[1]]) |> 
      select(yield, .pred)
  }, .progress = TRUE)

o
