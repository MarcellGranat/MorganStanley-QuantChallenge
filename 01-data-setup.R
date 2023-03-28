# Read raw files from OneDrive folder -------------------------

od <- Microsoft365R::get_business_onedrive("common")

# CSV files from minnesota_daily subfolder --------------------

daily_weather_df <- od$list_files(path = "MorganStanley-QuantChallenge/weather/minnesota_daily") |>
  pull(name) |>  # file names in the subfolder
  map_dfr(\(file_name) { # download to a temporary file, read and bind
    t <- tempfile(fileext = ".csv") 
    od$download_file(str_c("MorganStanley-QuantChallenge/weather/minnesota_daily/", file_name), dest = t)
    rio::import(t) |> 
      mutate(id = str_remove(file_name, ".csv"), .before = 1)
  }, .progress = TRUE) |> 
  set_names("station", "time", "avg_temp", "min_temp", "max_temp", "daily_prec") |> # colnames
  mutate(
    time = as.Date(time)
  ) |> 
  tibble()

# CSV files from prediction_targets_daily subfolder --------------------

prediction_targets_df <- od$list_files(path = "MorganStanley-QuantChallenge/weather/prediction_targets_daily") |>
  pull(name) |>  # file names in the subfolder
  setdiff("GqIUVenONyZikTIz.csv") |> # empty file
  map_dfr(\(file_name) { # download to a temporary file, read and bind
    t <- tempfile(fileext = ".csv") 
    od$download_file(str_c("MorganStanley-QuantChallenge/weather/prediction_targets_daily/", file_name), dest = t)
    rio::import(t) |> 
      mutate(id = str_remove(file_name, ".csv"), .before = 1)
  }, .progress = TRUE) |> 
  set_names("id", "time", "avg_temp", "min_temp", "max_temp", "daily_prec") # colnames

# Standalone files --------------------------------------------

od$download_file("MorganStanley-QuantChallenge/agri/minnesota_county_location.csv", dest = t, overwrite = TRUE)
minnesota_county_location_df <- read_csv(t) |> 
  select(- capital_name) |> # redundant information
  transmute(
    county = str_remove(county_name, " County"),
    latitude = county_latitude,
    longitude = county_longitude
  )

od$download_file("MorganStanley-QuantChallenge/agri/minnesota_county_yearly_agricultural_production.csv", dest = t, overwrite = TRUE)
minnesota_production_df <- read_csv(t) |> 
  janitor::clean_names() |> 
  rename_all(str_remove, pattern =  "_.*") |>  # keep only first word from the colnames
  mutate(
    county = str_to_title(county),
    acres = str_remove(acres, ","),
    acres = as.numeric(acres),
    production = str_remove(production, ","),
    production = as.numeric(production),
    yield = str_remove(yield, ","),
    yield = as.numeric(yield),
  )

  
od$download_file("MorganStanley-QuantChallenge/weather/Minnesota Station location list.csv", dest = t, overwrite = TRUE)
minnesota_station_location_df <- read_csv(t) |> 
  janitor::clean_names()


# Pin ---------------------------------------------------------
# Data and intermediate results are saved in to a private OneDrive folder. See: 00-board.R

.write(daily_weather_df, prediction_targets_df, minnesota_county_location_df, minnesota_production_df, minnesota_station_location_df)


