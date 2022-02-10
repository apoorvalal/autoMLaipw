# %% ####################################################
#' compute nuisance functions for causal effect estimation using h2o's automl
#' @param data [data.frame, matrix] data table (n x p)
#' @param y outcome name
#' @param w treatment name
#' @param x covariate names
#' @param runtime runtime for each model - defaults to 1 minute
#' @param diag boolean for whether model objects should be returned alongside predictions (default false)
#' @return data.table with predictions
#' @export
aipw_automl = function(data, y, w, x, runtime = 60, diag = F, seeD = 42){
  # automl needs treatment to be factor
  data[, treatment := as.factor(get(w))]
  ######################################################################
  # pscore
  ######################################################################
  d = ttsplit(data); train_h = as.h2o(d$train); test_h  = as.h2o(d$test)
  # fit pscore model
  aml_pscore = h2o.automl(x= x, y = 'treatment',
              training_frame = train_h, leaderboard_frame = test_h,
              max_models = 10, seed = 1, max_runtime_secs = runtime,
              seed = seeD, verbosity = NULL)
  ######################################################################
  # outcome models
  ######################################################################
  # mu1 - train/test on only treatment units
  d = ttsplit(data[treatment == 1]); train_h = as.h2o(d$train); test_h  = as.h2o(d$test)
  aml_m1 = h2o.automl(x = x, y = y,
              training_frame = train_h, leaderboard_frame = test_h,
              max_models = 10, seed = 1, max_runtime_secs = runtime,
              seed = seeD, verbosity = NULL)
  # mu0 - train/test only on control units
  d = ttsplit(data[treatment == 0]); train_h = as.h2o(d$train); test_h  = as.h2o(d$test)
  aml_m0 = h2o.automl(x = x, y = y,
              training_frame = train_h, leaderboard_frame = test_h,
              max_models = 10, seed = 1, max_runtime_secs = runtime,
              seed = seeD, verbosity = NULL)
  ######################################################################
  # collect into table
  ######################################################################
  # predict for all obs using best model (typically an ensemble)
  ehat   = h2o.predict(aml_pscore@leader, as.h2o(data)) %>% as.data.frame() %>% .$p1
  mu1hat = h2o.predict(aml_m1@leader, as.h2o(data)) %>% as.data.frame() %>% .$predict
  mu0hat = h2o.predict(aml_m0@leader, as.h2o(data)) %>% as.data.frame() %>% .$predict
  dd = data.table(ehat, mu1hat, mu0hat, w = data[[w]], y = data[[y]])
  if(!diag){
    return(dd)
  } else {
    list(fit = dd,
      # and return models for diagnostics
      psmod = aml_pscore, omod0 = aml_m0, omod1 = aml_m1)
  }
}

#' model diagnostics for automl
#' @export
modWeights = function(aml){
  lb = aml@leaderboard
  model_ids = aml@leaderboard$model_id %>% as.data.frame() %>% .[,1]
  stacked_ensemble = h2o.getModel(model_ids[1])
  metalearner = stacked_ensemble@model$metalearner_model
  h2o.varimp_plot(metalearner)
}

#' function to take output of aipw_automl and compute ATE using 3 estimators
#' @export
ate_estim = function(d){
  regadjust = with(outdat, mean(mu1hat - mu0hat))
  ipw = with(outdat, mean(
    (w * y)/(ehat) - ((1-w) * y)/(1-ehat)
  ))
  aipw = with(outdat,
      mean( (mu1hat + (w * (y - mu1hat) )/ehat) -
            (mu0hat + ((1 - w) * (y - mu0hat))/(1-ehat) )
    ))
  c(regadjust, ipw, aipw) |> round(3)
}
