.read(weekly_testing_rset_95)

# baselearners ------------------------------------------------
# already tuned workflows

.read(rand_forest_ranger_95_wf)
.read(linear_reg_lm_wts_wf)
.read(linear_reg_glmnet_95_wf)

# evaluate the performance on the testing set -----------------

testing_rs_95 <- map_dfr(list(linear_reg_lm_wts_wf, rand_forest_ranger_95_wf, linear_reg_glmnet_95_wf), .progress = TRUE, ~ {
  fit_resamples( # walk-forward cross-validation
    .,
    weekly_testing_rset_95, # fit on the testing set, gamma = 0.95
    metrics = metric_set(rsq, rmse, msd, mape)
  ) |> 
    collect_metrics(summarize = FALSE) |> # to draw the trend of the performance
    mutate(
      gamma = 0.95, 
      type = "baselearner",
      engine = .$fit$actions$model$spec$engine
    )
})

.write(testing_rs_95)

