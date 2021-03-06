calc_var <- function(X, model, correction = FALSE) {
  # Computes the variance estimation of predictions by X.
  #
  # Args:
  #   X: Covariates of interest
  #   model: Trained random forests model by library randomForest (set keep.inbag = TRUE)
  #   correction: Whether to apply bias correction for diagonal terms (variance)
  #
  # Returns:
  #   A list contains:
  #     y_pred: predictions generated by X using model
  #     var: covariance matrix
  #     zeta1_full: see paper for details
  #     zetan_full: see paper for details
  #   If classification, also returns:
  #     y_prob: probability generated by X using model
  #
  
  n_train <- length(model$predicted)
  ntree <- model$ntree
  sampsize <- sum(model$inbag[, 1])
  
  testall <- predict(model, X, predict.all = TRUE)
  y_pred <- testall$aggregate
  
  if (model$type == "regression") {
    cond_exp_full <- matrix(0, nrow = n_train, ncol = dim(X)[1])
    
    for (i in 1:n_train) {
      cond_exp_full[i, ] <- rowMeans(testall$individual[, model$inbag[i, ] == 1])
    }
    
    zeta1_full <- cov(cond_exp_full)
    zetan_full <- cov(t(testall$individual))
    
    var <- sampsize^2 / n_train * zeta1_full + (1 / ntree) * zetan_full
    
    if (correction == TRUE) {
      # refer to https://arxiv.org/abs/1912.01089
      zeta1_full_cor <- n_train * (n_train - 1) / (n_train - sampsize)^2 * (zeta1_full - 1 / ntree * (n_train - sampsize) / n_train * zetan_full)
      var <- sampsize^2 / n_train * zeta1_full_cor + (1 / ntree) * zetan_full
    }
    
    ans <- list("y_pred" = y_pred, "var" = var, "zeta1_full" = zeta1_full, "zetan_full" = zetan_full)
    
    return(ans)
  }
  
  if (model$type == "classification") {
    individual <- apply(testall$individual, 2, as.numeric)
    y_prob <- apply(individual, 1, mean)
    
    cond_exp_full <- matrix(0, nrow = n_train, ncol = dim(X)[1])
    
    for (i in 1:n_train) {
      cond_exp_full[i, ] <- rowMeans(individual[, model$inbag[i, ] == 1])
    }
    
    zeta1_full <- cov(cond_exp_full)
    zetan_full <- cov(t(individual))
    
    var <- sampsize^2 / n_train * zeta1_full + (1 / ntree) * zetan_full
    
    if (correction == TRUE) {
      # refer to https://arxiv.org/abs/1912.01089
      zeta1_full_cor <- n_train * (n_train - 1) / (n_train - sampsize)^2 * (zeta1_full - 1 / ntree * (n_train - sampsize) / n_train * zetan_full)
      var <- sampsize^2 / n_train * zeta1_full_cor + (1 / ntree) * zetan_full
    }
    
    ans <- list("y_pred" = y_pred, "y_prob" = y_prob, "var" = var, "zeta1_full" = zeta1_full, "zetan_full" = zetan_full)
    
    return(ans)
  }
}