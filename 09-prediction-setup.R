.read(prediction_targets_imputed_df)
.read(prediction_targets_df)

# corn --------------------------------------------------------

weekly_corn_prediction_design_df <- prediction_targets_imputed_df |> 
  mutate(year = lubridate::year(time)) |> 
  group_by(county, year) |> 
  mutate(
    w = ((row_number() - 1) %/% 7) + 1, # days into 7d groups
    kdd = cumsum(max(avg_temp - 29, 0)),
    gdd = cumsum(max(avg_temp - 8, 0))
  ) |> 
  group_by(county, year, w) |> 
  summarise(
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

weekly_corn_prediction_p_design_df <- weekly_corn_prediction_design_df |> # previous year combined
  rename_at(- (1:2), ~ paste0("p_", .)) |> 
  mutate(year = year + 1) |> # the next years previous values
  inner_join(weekly_corn_prediction_design_df, join_by(county, year)) |> 
  left_join(
    x = prediction_targets_df |> 
      transmute(county, year = lubridate::year(time)),
    by = join_by(county, year)
  )

corn_prediction_target <- weekly_corn_prediction_p_design_df |> 
  select(county, year, 
         p_avg_temp_40:p_avg_temp_53, # previous year from November
         avg_temp_1:gdd_37, # until current year October
  ) |> 
  distinct(county, year, .keep_all = TRUE)

.write(corn_prediction_target)
  

# oats --------------------------------------------------------

weekly_oats_prediction_design_df <- prediction_targets_imputed_df |> 
  mutate(year = lubridate::year(time)) |> 
  group_by(county, year) |> 
  mutate(
    w = ((row_number() - 1) %/% 7) + 1, # days into 7d groups
    kdd = cumsum(max(avg_temp - 25, 0)),
    gdd = cumsum(max(avg_temp - 7, 0))
  ) |> 
  group_by(county, year, w) |> 
  summarise(
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

weekly_oats_prediction_p_design_df <- weekly_oats_prediction_design_df |> # previous year combined
  rename_at(- (1:2), ~ paste0("p_", .)) |> 
  mutate(year = year + 1) |> # the next years previous values
  inner_join(weekly_oats_prediction_design_df, join_by(county, year)) |> 
  left_join(
    x = corn_prediction_design|> 
      distinct(county, year),
    by = join_by(county, year)
  )

oats_prediction_target <- weekly_oats_prediction_p_design_df |> 
  select(county, year, 
         p_avg_temp_40:p_avg_temp_53, # previous year from November
         avg_temp_1:gdd_37, # until current year October
  ) |> 
  distinct(county, year, .keep_all = TRUE)


.write(oats_prediction_target)

# soybeans ----------------------------------------------------

weekly_soybean_prediction_design_df <- prediction_targets_imputed_df |> 
  mutate(year = lubridate::year(time)) |> 
  group_by(county, year) |> 
  mutate(
    w = ((row_number() - 1) %/% 7) + 1, # days into 7d groups
    kdd = cumsum(max(avg_temp - 30, 0)),
    gdd = cumsum(max(avg_temp - 12, 0))
  ) |> 
  group_by(county, year, w) |> 
  summarise(
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

weekly_soybean_prediction_p_design_df <- weekly_soybean_prediction_design_df |> # previous year combined
  rename_at(- (1:2), ~ paste0("p_", .)) |> 
  mutate(year = year + 1) |> # the next years previous values
  inner_join(weekly_soybean_prediction_design_df, join_by(county, year)) |> 
  left_join(
    x = corn_prediction_design|> 
      distinct(county, year),
    by = join_by(county, year)
  )

soybeans_prediction_target <- weekly_soybean_prediction_p_design_df |> 
  select(county, year, 
         p_avg_temp_40:p_avg_temp_53, # previous year from November
         avg_temp_1:gdd_37, # until current year October
  ) |> 
  distinct(county, year, .keep_all = TRUE)


.write(soybeans_prediction_target)

