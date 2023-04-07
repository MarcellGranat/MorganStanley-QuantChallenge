.read(oats_boost_tree_lightgbm_wf)
.read(oats_testing)

fit_resamples(
  oats_boost_tree_lightgbm_wf,
  oats_testing
) |> 
  collect_metrics()

.read(soybeans_boost_tree_lightgbm_wf)
.read(soybeans_testing)

fit_resamples(
  soybeans_boost_tree_lightgbm_wf,
  soybeans_testing
) |> 
  collect_metrics()

