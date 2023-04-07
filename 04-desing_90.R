.read(design_df)

weekly_design_df <- design_df |> 
  pivot_longer(- (county:yield)) |> # convert to long format
  mutate(
    time = str_c(
      year,
      "-",
      str_extract(name, "\\d{1,2}-\\d{1,2}")
    ) |> 
      as.Date(),
    name = str_remove(name, "_\\d{1,2}-\\d{1,2}")
  ) |> 
  pivot_wider(names_from = name) |> 
  group_by(county, year) |> 
  mutate(
    w = ((row_number() - 1) %/% 7) + 1 # days into 7d groups
  ) |> 
  group_by(county, year, w) |> 
  summarise(
    yield = first(yield), # constant
    avg_temp = mean(avg_temp),
    min_temp = min(min_temp),
    max_temp = max(max_temp),
    daily_prec = mean(daily_prec),
    kdd = max(kdd), # equivalent with the last value in the week
    gdd = max(gdd)
  ) |> 
  pivot_longer(avg_temp:gdd) |>
  mutate(name = str_c(name, "_", w)) |> 
  select(- w) |> 
  pivot_wider()

weekly_pw_design_df <- weekly_design_df |> 
  rename_at(- (1:3), ~ paste0("p_", .)) |> 
  select(- yield) |> 
  mutate(year = year + 1) |> # the next years previous values
  inner_join(weekly_design_df, join_by(county, year)) |> 
  arrange(year) |> 
  group_by(year) |> 
  mutate(n = n()) |> 
  ungroup() |> 
  mutate(
    case_wts = .9 ^ (max(year) - year) * min(n) / n, # Koyck weights + "undersampling"
    case_wts = importance_weights(case_wts)
  ) |> 
  select(- n) |> 
  relocate(county, year, yield, case_wts)

weekly_pw_selected_design_df <- weekly_pw_design_df |> 
  select(county:case_wts, 
         p_avg_temp_40:p_avg_temp_53, # previous year from November
         avg_temp_1:gdd_37, # until current year October
  )

weekly_design_folds <- weekly_pw_selected_design_df |> 
  group_by(year) |> 
  nest() |> 
  arrange(year) |>
  ungroup() |> 
  mutate(
    data = map2(data, year, ~ mutate(.x, year = .y, .before = 1)),
    analysis = map(year, \(x) {
      across(everything()) |> 
        filter(year >= x - 8, year < x) |> 
        pull(data) |> 
        bind_rows()
    })
  ) |> 
  rename(assessment = data)

weekly_training_rset_90 <- weekly_design_folds |> 
  filter(year < 2010, row_number() > 8) |> 
  mutate(splits = map2(analysis, assessment, make_splits)) %$%
  manual_rset(splits, as.character(year))

weekly_testing_rset_90 <- weekly_design_folds |> 
  filter(year >= 2010) |> 
  mutate(splits = map2(analysis, assessment, make_splits)) %$%
  manual_rset(splits, as.character(year))

.write(weekly_training_rset_90, weekly_testing_rset_90)
