.read(weekly_testing_rset_90)
.read(weekly_testing_no_wts_rset)

.read(linear_reg_glmnet_90_wf)
.read(weekly_svm_linear_LiblineaR_wf)
.read(weekly_boost_tree_lightgbm_wf)
.read(rand_forest_ranger_no_wts_wf)

.read(ensemble_linear_reg_glmnet_wf, ensemble_linear_reg_lm_wf, ensemble_mars_earth_wf, 
      ensemble_dropSVM_linear_reg_glmnet_wf, 
      ensemble_dropSVM_linear_reg_lm_wf, ensemble_dropSVM_mars_earth_wf)

w <- linear_reg_glmnet_90_wf
rset <- weekly_testing_rset_90

baselearner_test_prediction <- function(w, testing_set) {
  map(testing_set$splits, \(s) {
    m <- fit(w, analysis(s)) # build on analysis
    list(
      analysis = predict(m, analysis(s)) |>  # prediction on the analysis
        set_names(w$fit$actions$model$spec$engine),
      assessment = predict(m, assessment(s)) |>  # prediction on the assessment
        set_names(w$fit$actions$model$spec$engine)
    )
  }) |> 
    transpose()
}

bt <- map2(
  list(
    linear_reg_glmnet_90_wf,
    weekly_svm_linear_LiblineaR_wf,
    weekly_boost_tree_lightgbm_wf,
    rand_forest_ranger_no_wts_wf,
    mars_earth_no_wts_wf
  ),
  list(
    weekly_testing_rset_90,
    weekly_testing_no_wts_rset,
    weekly_testing_no_wts_rset,
    weekly_testing_no_wts_rset,
    weekly_testing_no_wts_rset
  ),
  .f = baselearner_test_prediction
)

ensemble_testing_rset <- tibble(
  id = weekly_testing_no_wts_rset$id,
  analysis = map(bt, 1) |> 
    transpose() |> 
    map(bind_cols),
  assessment = map(bt, 2) |> 
    transpose() |> 
    map(bind_cols)
) |> 
  mutate(
    analysis= map2(analysis, weekly_testing_no_wts_rset$splits, ~ {
      bind_cols(.x, analysis(.y)["yield"])
    }),
    assessment = map2(assessment, weekly_testing_no_wts_rset$splits, ~ {
      bind_cols(.x, assessment(.y)["yield"])
    }),
    splits = map2(analysis, assessment, make_splits)
  ) %$%
  manual_rset(splits, id)

ensemble_svm_rs <- map_dfr(list(ensemble_linear_reg_glmnet_wf, ensemble_linear_reg_lm_wf, ensemble_mars_earth_wf), .progress = TRUE, ~ {
  fit_resamples( # walk-forward cross-validation
    .,
    ensemble_testing_rset, # fit on the testing set, gamma = 0.90
    metrics = metric_set(rsq, rmse, msd, mape)
  ) |> 
    collect_metrics(summarize = FALSE) |> # to draw the trend of the performance
    mutate(
      svm = TRUE,
      type = "ensemble",
      engine = .$fit$actions$model$spec$engine
    )
})

ensemble_dropsvm_rs <- map_dfr(list(ensemble_dropSVM_linear_reg_glmnet_wf, ensemble_dropSVM_linear_reg_lm_wf, ensemble_dropSVM_mars_earth_wf), .progress = TRUE, ~ {
  fit_resamples( # walk-forward cross-validation
    .,
    ensemble_testing_rset, # fit on the testing set, gamma = 0.90
    metrics = metric_set(rsq, rmse, msd, mape)
  ) |> 
    collect_metrics(summarize = FALSE) |> # to draw the trend of the performance
    mutate(
      svm = FALSE,
      type = "ensemble",
      engine = .$fit$actions$model$spec$engine
    )
})

.write(ensemble_svm_rs, ensemble_dropsvm_rs)
