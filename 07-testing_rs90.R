.read(weekly_testing_rset_90)

# baselearners ------------------------------------------------
# already tuned workflows

.read(rand_forest_ranger_90_wf)
.read(linear_reg_lm_wts_wf)
.read(linear_reg_glmnet_90_wf)

# evaluate the performance on the testing set -----------------

testing_rs_90 <- map_dfr(list(linear_reg_lm_wts_wf, rand_forest_ranger_90_wf, linear_reg_glmnet_90_wf), .progress = TRUE, ~ {
  fit_resamples( # walk-forward cross-validation
    .,
    weekly_testing_rset_90, # fit on the testing set, gamma = 0.90
    metrics = metric_set(rsq, rmse, msd, mape)
  ) |> 
    collect_metrics(summarize = FALSE) |> # to draw the trend of the performance
    mutate(
      gamma = 0.90, # gamma = .90 
      type = "baselearner",
      engine = .$fit$actions$model$spec$engine
    )
})

.write(testing_rs_90)

