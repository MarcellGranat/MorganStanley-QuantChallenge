.read(design_df)

train <- design_df |> 
  filter(year < 2010)

rec <- recipe(yield ~ ., data = train) |> 
  step_zv(all_predictors()) |> 
  step_corr(all_numeric_predictors(), threshold = .2) |> 
  step_impute_bag(ends_with("_daily_prec")) |> 
  step_impute_mean(all_numeric_predictors()) |> 
  step_normalize(all_numeric_predictors()) |> 
  step_rm(county)

class(train_folds) <- class(vfold_cv(train))

train_folds <- train |> 
  group_by(year) |> 
  nest() |> 
  ungroup() |> 
  mutate( # identical to rolling_origin, but for panel set + year refers to the year of assessment observations
    data = map2(data, year, ~ mutate(.x, year = .y, .before = 1)),
    analysis = map(year, \(x) {
      cur_data_all() |> 
        filter(year < x, year >= (x - 8)) |> 
        pull(data) |> 
        bind_rows()
    })
  ) |> 
  tail(- 8) |> 
  mutate(
    splits = map2(analysis,  data, ~ make_splits(x = .x, assessment = .y)),
    id = as.character(row_number()),
    id = str_c("Fold", strrep("0", times = max(str_length(id))  - str_length(id)), id)
  ) %$%
  manual_rset(splits, as.character(year))

linear_reg_lm_spec <- linear_reg() |> 
  set_engine('lm')

wf <- workflow(preprocessor = rec, spec = linear_reg_lm_spec)

fit_resamples(wf, train_folds)
