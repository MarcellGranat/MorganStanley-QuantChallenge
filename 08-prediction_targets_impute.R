.read(prediction_targets_df)
.read(daily_weather_df)

binded_df <- prediction_targets_df |> 
  transmute(
    county, time = lubridate::year(time)
  ) |> 
  group_by(county) |> 
  (\(x) {
    bind_rows(
      summarise(x, time = min(time) - 1), # add the previous year
      x # years observed
    ) 
  }) () |> 
  ungroup() |> 
  crossing(
    day = seq.Date( # fastest solution after some attempt
      from = as.Date(paste0("2023", "-01-01")), # all days in a year
      to = as.Date(paste0("2023", "-12-31")), # 2023 > no 02-29 issue
      by = "days"
    ) |> 
      str_sub(start = 5) # remove the year
  ) |> 
  transmute(county, time = as.Date(str_c(time, day))) |> # combine w year
  left_join(prediction_targets_df, by = join_by(county, time)) |> 
  bind_rows(
    daily_weather_df |> # histrical weather data by stations
      rename(county = station)
  )

prediction_targets_imputed_df <- binded_df |>
  mice::mice(method = "rf", seed = 123) |> # missing data, specially `daily_prec` (there are known zeros in the data)
  mice::complete() |>
  mutate(
    avg_temp = binded_df$avg_temp, # avg of min & max is an appropriate estimation
    avg_temp = ifelse(is.na(avg_temp), (min_temp + max_temp) / 2, avg_temp),
    ) |> 
  head(- nrow(daily_weather_df)) # remove from the end

.write(prediction_targets_imputed_df)





