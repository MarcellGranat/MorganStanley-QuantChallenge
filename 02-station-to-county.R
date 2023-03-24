distance_df <- bind_rows(
  minnesota_station_location_df,
  minnesota_county_location_df
) |> 
  select(longitude, latitude) |> 
  geosphere::distm() %>% # distance in m between all points
  .[1:nrow(minnesota_station_location_df), (nrow(minnesota_station_location_df) + 1):ncol(.)] |> # select only relevants
  data.frame() |> 
  mutate(
    station = minnesota_station_location_df$code, .before = 1
  ) |> 
  set_names(c("station", minnesota_county_location_df$county)) |> 
  pivot_longer(- station, names_to = "county", values_to = "distance") |> 
  mutate(distance = distance / 1e3) # convert to km

.write(distance_df)
