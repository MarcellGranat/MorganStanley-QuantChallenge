# in the final model we wont have information about in which county the weather belongs
# > use only aggregated yield and acres trend

.read(minnesota_production_df)

minnesota_production_df |> 
  filter(crop == "CORN, GRAIN", county != "OTHER (COMBINED) COUNTIES") |> 
  group_by(year) |> 
  summarise(
    yield = mean(yield),
    acres = sum(acres, na.rm = TRUE)
  )