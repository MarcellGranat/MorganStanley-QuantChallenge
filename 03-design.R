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
  ungroup()

.write(station_to_county)

daily_weather_mice <- mice::mice(daily_weather_df, method = "mean") |> # TODO rf
  mice::complete() |> 
  tibble()

daily_weather_imputed_df <- daily_weather_mice |> 
  mutate(
    avg_temp = daily_weather_df$avg_temp, # avg of min & max is an appropriate estimation
    avg_temp = ifelse(is.na(avg_temp), (min_temp + max_temp) / 2, avg_temp),
  )

design_df <- minnesota_production_df |> 
  left_join(station_to_county) |> 
  left_join(daily_weather_imputed_df, multiple = "all") |> 
  filter(crop == "CORN, GRAIN", county != "OTHER (COMBINED) COUNTIES") |> 
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
  pivot_wider(names_from = md, values_from = avg_temp:gdd)
  
  
  

weather_design_df <- daily_weather_mice |> 
  mutate(
    avg_temp = daily_weather_df$avg_temp, # avg of min & max is an appropriate estimation
    avg_temp = ifelse(is.na(avg_temp), (min_temp + max_temp) / 2, avg_temp),
    year = lubridate::year(time),
    md = str_c(lubridate::month(time), "-", lubridate::day(time)) # aggregate
  ) |> 
  pivot_longer(avg_temp:daily_prec) |> 
  select(-time) |> 
  unite("name", md, name) |> 
  pivot_wider() |> 
  rename(station = id)

design_df <- minnesota_production_df |> 
  left_join(station_to_county_df, by = join_by(county)) |> 
  left_join(weather_design_df, by = join_by(station, year)) |> 
  filter(crop == "CORN, GRAIN", county != "OTHER (COMBINED) COUNTIES") |> 
  select(- commodity, -station, - crop, - production, - acres, - distance)

prediction_design_df <- prediction_targets_df |> 
  mutate(
    avg_temp = ifelse(is.na(avg_temp), (min_temp + max_temp) / 2, avg_temp),
    year = lubridate::year(time),
    md = str_c(lubridate::month(time), "-", lubridate::day(time)) # aggregate
  ) |> 
  pivot_longer(avg_temp:daily_prec) |> 
  select(-time) |> 
  unite("name", md, name) |> 
  pivot_wider() |> 
  rename(county = id)

setdiff(names(design_df), names(prediction_design_df)) # only yield remains


.write(station_to_county_df, design_df, prediction_design_df)
