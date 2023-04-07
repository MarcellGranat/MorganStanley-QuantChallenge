.read(distance_df, daily_weather_df, prediction_targets_df, minnesota_county_location_df, minnesota_production_df, minnesota_station_location_df)
.read(design_df) # design for corn > imputed weather data

# design frame ------------------------------------------------

oats_kdd <- design_df |> 
  ungroup() |> 
  select(county, year, starts_with("avg_temp")) |> 
  pivot_longer(starts_with("avg_temp")) |> 
  pivot_wider(names_from = c(county, year)) |> 
  mutate_at(-1,
    ~ cumsum(max(. - 25, 0))
  ) |> 
  mutate(name = ((row_number() - 1) %/% 7) + 1) |>  # days into 7d groups
  rename(w = name) |> 
  group_by(w) |> 
  summarise_all(max) |> 
  pivot_longer(-1) |> 
  mutate(
    county = str_remove(name, "_\\d{4}"),
    year = str_extract(name, "\\d{4}") |> 
      as.numeric()
  ) |> 
  select(-name) |> 
  pivot_wider(names_from = w, names_prefix = "kdd_")

oats_gdd <- design_df |> 
  ungroup() |> 
  select(county, year, starts_with("avg_temp")) |> 
  pivot_longer(starts_with("avg_temp")) |> 
  pivot_wider(names_from = c(county, year)) |> 
  mutate_at(-1,
    ~ cumsum(max(. - 7, 0))
  ) |> 
  mutate(name = ((row_number() - 1) %/% 7) + 1) |>  # days into 7d groups
  rename(w = name) |> 
  group_by(w) |> 
  summarise_all(max) |> 
  pivot_longer(-1) |> 
  mutate(
    county = str_remove(name, "_\\d{4}"),
    year = str_extract(name, "\\d{4}") |> 
      as.numeric()
  ) |> 
  select(-name) |> 
  pivot_wider(names_from = w, names_prefix = "gdd_")

avg_temp <- design_df |> 
  ungroup() |> 
  select(county, year, starts_with("avg_temp")) |> 
  pivot_longer(starts_with("avg_temp")) |> 
  pivot_wider(names_from = c(county, year)) |> 
  mutate(name = ((row_number() - 1) %/% 7) + 1) |>  # days into 7d groups
  rename(w = name) |> 
  group_by(w) |> 
  summarise_all(mean) |> 
  pivot_longer(-1) |> 
  mutate(
    county = str_remove(name, "_\\d{4}"),
    year = str_extract(name, "\\d{4}") |> 
      as.numeric()
  ) |> 
  select(-name) |> 
  pivot_wider(names_from = w, names_prefix = "avg_temp_")

daily_prec <- design_df |> 
  ungroup() |> 
  select(county, year, starts_with("daily_prec")) |> 
  pivot_longer(starts_with("daily_prec")) |> 
  pivot_wider(names_from = c(county, year)) |> 
  mutate(name = ((row_number() - 1) %/% 7) + 1) |>  # days into 7d groups
  rename(w = name) |> 
  group_by(w) |> 
  summarise_all(mean) |> 
  pivot_longer(-1) |> 
  mutate(
    county = str_remove(name, "_\\d{4}"),
    year = str_extract(name, "\\d{4}") |> 
      as.numeric()
  ) |> 
  select(-name) |> 
  pivot_wider(names_from = w, names_prefix = "daily_prec_")

max_temp <- design_df |> 
  ungroup() |> 
  select(county, year, starts_with("max_temp")) |> 
  pivot_longer(starts_with("max_temp")) |> 
  pivot_wider(names_from = c(county, year)) |> 
  mutate(name = ((row_number() - 1) %/% 7) + 1) |>  # days into 7d groups
  rename(w = name) |> 
  group_by(w) |> 
  summarise_all(max) |> 
  pivot_longer(-1) |> 
  mutate(
    county = str_remove(name, "_\\d{4}"),
    year = str_extract(name, "\\d{4}") |> 
      as.numeric()
  ) |> 
  select(-name) |> 
  pivot_wider(names_from = w, names_prefix = "max_temp_")

min_temp <- design_df |> 
  ungroup() |> 
  select(county, year, starts_with("min_temp")) |> 
  pivot_longer(starts_with("min_temp")) |> 
  pivot_wider(names_from = c(county, year)) |> 
  mutate(name = ((row_number() - 1) %/% 7) + 1) |>  # days into 7d groups
  rename(w = name) |> 
  group_by(w) |> 
  summarise_all(max) |> 
  pivot_longer(-1) |> 
  mutate(
    county = str_remove(name, "_\\d{4}"),
    year = str_extract(name, "\\d{4}") |> 
      as.numeric()
  ) |> 
  select(-name) |> 
  pivot_wider(names_from = w, names_prefix = "min_temp_")

oats_design_df <- minnesota_production_df |> 
  filter(commodity == "OATS") |> 
  select(
    year, county, yield
  ) |> 
  left_join(
    bind_cols(
      oats_kdd,
      oats_gdd |> 
        select(- county, -year),
      avg_temp |> 
        select(- county, -year),
      min_temp |> 
        select(- county, -year),
      max_temp |> 
        select(- county, -year),
      daily_prec |> 
        select(- county, -year),
    )
  ) |> 
  filter(county != "Other (Combined) Counties")

oats_design_df |> 
  count(county, year, sort = TRUE)

oats_pw_design_df <- oats_design_df |> # p:previous year combined, w:weights added
  rename_at(- (1:3), ~ paste0("p_", .)) |> 
  select(- yield) |> 
  mutate(year = year + 1) |> # the next years previous values
  inner_join(oats_design_df, join_by(county, year)) |> 
  arrange(year)

.read(corn_prediction_design)

oats_pw_selected_design_df <- oats_pw_design_df |> 
  select(yield, all_of(names(corn_prediction_design))) # keep it in the same str


# folds -------------------------------------------------------

oats_folds <- oats_pw_selected_design_df |> 
  drop_na() |> 
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

oats_prediction_design <- oats_pw_selected_design_df |> 
  filter(year >= 2006) |> 
  drop_na()

oats_training <- oats_folds |> 
  filter(year < 2010, row_number() > 8) |> 
  sample_n(10) |> 
  mutate(splits = map2(analysis, assessment, make_splits)) %$%
  manual_rset(splits, as.character(year))

oats_testing <- oats_folds |> 
  filter(year >= 2010) |> 
  mutate(splits = map2(analysis, assessment, make_splits)) %$%
  manual_rset(splits, as.character(year))

.write(oats_prediction_design, oats_training, oats_testing)


# soybeans ---------------------------------------------------------

# design frame ------------------------------------------------

soybeans_kdd <- design_df |> 
  ungroup() |> 
  select(county, year, starts_with("avg_temp")) |> 
  pivot_longer(starts_with("avg_temp")) |> 
  pivot_wider(names_from = c(county, year)) |> 
  mutate_at(-1,
            ~ cumsum(max(. - 30, 0))
  ) |> 
  mutate(name = ((row_number() - 1) %/% 7) + 1) |>  # days into 7d groups
  rename(w = name) |> 
  group_by(w) |> 
  summarise_all(max) |> 
  pivot_longer(-1) |> 
  mutate(
    county = str_remove(name, "_\\d{4}"),
    year = str_extract(name, "\\d{4}") |> 
      as.numeric()
  ) |> 
  select(-name) |> 
  pivot_wider(names_from = w, names_prefix = "kdd_")

soybeans_gdd <- design_df |> 
  ungroup() |> 
  select(county, year, starts_with("avg_temp")) |> 
  pivot_longer(starts_with("avg_temp")) |> 
  pivot_wider(names_from = c(county, year)) |> 
  mutate_at(-1,
            ~ cumsum(max(. - 12, 0))
  ) |> 
  mutate(name = ((row_number() - 1) %/% 7) + 1) |>  # days into 7d groups
  rename(w = name) |> 
  group_by(w) |> 
  summarise_all(max) |> 
  pivot_longer(-1) |> 
  mutate(
    county = str_remove(name, "_\\d{4}"),
    year = str_extract(name, "\\d{4}") |> 
      as.numeric()
  ) |> 
  select(-name) |> 
  pivot_wider(names_from = w, names_prefix = "gdd_")

soybeans_design_df <- minnesota_production_df |> 
  filter(commodity == "SOYBEANS") |> 
  select(
    year, county, yield
  ) |> 
  left_join(
    bind_cols(
      soybeans_kdd,
      soybeans_gdd |> 
        select(- county, -year),
      avg_temp |> 
        select(- county, -year),
      min_temp |> 
        select(- county, -year),
      max_temp |> 
        select(- county, -year),
      daily_prec |> 
        select(- county, -year),
    )
  ) |> 
  filter(county != "Other (Combined) Counties")


soybeans_pw_design_df <- soybeans_design_df |> # p:previous year combined, w:weights added
  rename_at(- (1:3), ~ paste0("p_", .)) |> 
  select(- yield) |> 
  mutate(year = year + 1) |> # the next years previous values
  inner_join(soybeans_design_df, join_by(county, year)) |> 
  arrange(year)

.read(corn_prediction_design)

soybeans_pw_selected_design_df <- soybeans_pw_design_df |> 
  select(yield, all_of(names(corn_prediction_design))) # keep it in the same str


# folds -------------------------------------------------------

soybeans_folds <- soybeans_pw_selected_design_df |> 
  drop_na() |> 
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
  tail(-4) |> # not enough observation in the analysis
  rename(assessment = data)

soybeans_prediction_design <- soybeans_pw_selected_design_df |> 
  filter(year >= 2006) |> 
  drop_na()

soybeans_training <- soybeans_folds |> 
  sample_n(10) |> 
  filter(year < 2010, row_number() > 8) |> 
  mutate(splits = map2(analysis, assessment, make_splits)) %$%
  manual_rset(splits, as.character(year))

soybeans_testing <- soybeans_folds |> 
  filter(year >= 2010) |> 
  mutate(splits = map2(analysis, assessment, make_splits)) %$%
  manual_rset(splits, as.character(year))

.write(soybeans_prediction_design, soybeans_training, soybeans_testing)
