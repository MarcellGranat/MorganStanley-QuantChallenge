.read(weekly_testing_no_wts_rset)

# baselearners ------------------------------------------------
# already tuned workflows

.read(weekly_svm_linear_LiblineaR_wf)
.read(weekly_boost_tree_lightgbm_wf)
.read(rand_forest_ranger_no_wts_wf)
.read(linear_reg_lm_no_wts_wf)
.read(linear_reg_glmnet_no_wts_wf)
.read(mars_earth_no_wts_wf)

# evaluate the performance on the testing set -----------------

testing_rs_no_wts <- map_dfr(list(linear_reg_lm_no_wts_wf, rand_forest_ranger_no_wts_wf, weekly_svm_linear_LiblineaR_wf, weekly_boost_tree_lightgbm_wf, linear_reg_glmnet_no_wts_wf, mars_earth_no_wts_wf), .progress = TRUE, ~ {
  fit_resamples( # walk-forward cross-validation
    .,
    weekly_testing_no_wts_rset, # fit on the testing set, no weights
    metrics = metric_set(rsq, rmse, msd, mape)
  ) |> 
    collect_metrics(summarize = FALSE) |> # to draw the trend of the performance
    mutate(
      gamma = 1, # denoted with one, but also undersampling is ommitted here
      type = "baselearner",
      engine = .$fit$actions$model$spec$engine
    )
})

.write(testing_rs_no_wts)
