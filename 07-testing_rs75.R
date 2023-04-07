.read(weekly_testing_rset_75)

# baselearners ------------------------------------------------
# already tuned workflows

.read(linear_reg_lm_wts_wf)
.read(weekly_linear_reg_glmnet_wf)
.read(weekly_rand_forest_ranger_wf)

# evaluate the performance on the testing set -----------------

testing_rs_75 <- map_dfr(list(linear_reg_lm_wts_wf, weekly_linear_reg_glmnet_wf, weekly_rand_forest_ranger_wf), .progress = TRUE, ~ {
  fit_resamples( # walk-forward cross-validation
    .,
    weekly_testing_rset_75, # fit on the testing set, gamma = 0.75
    metrics = metric_set(rsq, rmse, msd, mape)
  ) |> 
    collect_metrics(summarize = FALSE) |> # to draw the trend of the performance
    mutate(
      gamma = 0.75,
      type = "baselearner",
      engine = .$fit$actions$model$spec$engine
    )
})

.write(testing_rs_75)
