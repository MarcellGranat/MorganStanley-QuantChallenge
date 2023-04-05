.read(distance_df, daily_weather_df, prediction_targets_df, minnesota_county_location_df, minnesota_production_df, minnesota_station_location_df)

station_to_county <- minnesota_production_df |> 
  select(year, county) |> 
  distinct() |> 
  left_join(
    distance_df,
    by = join_by(county)
  ) |> 
  mutate(
    time = map(year, ~ seq.Date(from = as.Date(paste0(., "-01-01")), to = as.Date(paste0(., "-12-31")), by = "days"))
  ) |> 
  unnest(time) |> 
  semi_join(
    daily_weather_df, 
    by = join_by(station, time)
  ) |> 
  group_by(county, time) |> 
  slice_min(distance, n = 3) |> 
  ungroup() |> 
  arrange(time, county)

.write(station_to_county)


# design frame ------------------------------------------------

daily_weather_imputed_df <- daily_weather_df |> 
  mice::mice(method = "rf", seed = 123) |> # missing data, specially `daily_prec` (there are known zeros in the data)
  mice::complete() |> 
  mutate(
    avg_temp = daily_weather_df$avg_temp, # avg of min & max is an appropriate estimation
    avg_temp = ifelse(is.na(avg_temp), (min_temp + max_temp) / 2, avg_temp),
  )

design_df <- minnesota_production_df |> 
  left_join(station_to_county, by = join_by(year, county)) |> 
  left_join(daily_weather_imputed_df, multiple = "all", by = join_by(station, time)) |> 
  filter(crop == "CORN, GRAIN", county != "OTHER (COMBINED) COUNTIES") |> 
  arrange(time, county) |> 
  group_by(county, time) |> 
  summarise(
    across(c(year, yield), first),
    across(avg_temp:daily_prec, ~ weighted.mean(., w = 1 / distance, na.rm = TRUE))
  ) |> 
  group_by(county, year) |>
  mutate(
    kdd = cumsum(max(avg_temp - 29, 0)),
    gdd = cumsum(max(avg_temp - 8, 0)),
    md = str_c(lubridate::month(time), "-", lubridate::day(time))
  ) |> 
  select(-time) |> 
  drop_na() |> 
  pivot_wider(names_from = md, values_from = avg_temp:gdd) |> 
  select(- ends_with("_2-29")) |> 
  arrange(year, county)

.write(design_df)

# prediction_targets > design ---------------------------------

extended_prediction_targets_df <- prediction_targets_df |> 
  mutate(county, year = lubridate::year(time)) |> 
  distinct(county, year) |> 
  mutate(
    time = map(year, ~ seq.Date(from = as.Date(paste0(., "-01-01")), to = as.Date(paste0(., "-12-31")), by = "days"))
  ) |> 
  unnest(time) |> 
  left_join(prediction_targets_df, by = join_by(county, time))

prediction_design_df <- extended_prediction_targets_df |> 
  mice::mice(method = "rf", seed = 123) |>
  mice::complete() |> 
  mutate(
    avg_temp = extended_prediction_targets_df$avg_temp,
    avg_temp = ifelse(is.na(avg_temp), (min_temp + max_temp) / 2, avg_temp)
  ) |> 
  mutate(
    year = lubridate::year(time),
    md = str_c(lubridate::month(time), "-", lubridate::day(time)),
    .before = 1
  ) |> 
  group_by(county, year) |> 
  mutate(
    kdd = cumsum(max(avg_temp - 29, 0)),
    gdd = cumsum(max(avg_temp - 8, 0))
  ) |> 
  ungroup() |> 
  pivot_longer(avg_temp:gdd) |> 
  select(-time) |> 
  unite("name", md, name) |> 
  pivot_wider() |> 
  rename_at(- (1:2), \(x) {
    str_remove(x, "\\d{1,2}-\\d{1,2}_") |> 
      str_c("_", str_extract(x, "\\d{1,2}-\\d{1,2}"))
  }) |> 
  select(- ends_with("_2-29")) |> 
  arrange(year, county)

.write(prediction_design_df)

setdiff(names(design_df), names(prediction_design_df)) # only yield remains
