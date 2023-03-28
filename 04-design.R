.read(distance_df, daily_weather_df, prediction_targets_df, minnesota_county_location_df, minnesota_production_df, minnesota_station_location_df)

station_to_county_df <- distance_df |> 
  group_by(county) |> 
  slice_min(distance)

weather_design_df <- daily_weather_df |> 
  mutate(
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
  