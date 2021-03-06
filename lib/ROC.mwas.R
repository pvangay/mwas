"roc.mwas" <- function(x, model, predicted, response, is.plot=FALSE){
  # Receiver operating characteristic - using package 'pROC' or 'ROCR'
  # ----- input:
  #         x: feature vector
  #     model: trained model
  # predicted: predicted output using the trained model (if no model is specified as input)
  #   response: desired response 
  #
  # ----- output:
  #  rocobj:  ROC object
  #           $auc              class "auc" 
  #           $sensitivities    sensitivities defining the ROC curve
  #           $specificities    specificities defining the ROC curve         
  #           $response         response vector (desired)
  #           $predictor        the predictor vector converted to numeric as used to build the ROC curve
  #
  #
  
  if exists('model') predicted <- predict(model, x) # if model si
  
  if (length(levels(response)) == 2)  # binary classification
    rocobj <- roc(response, as.numeric(predicted), percent=TRUE, ci=TRUE, plot=is.plot)
  else    # multi-class classification
    rocobj <- multiclass.roc(response, as.numeric(predicted), percent=TRUE, ci=TRUE, plot=is.plot)
  
  return(rocobj)
}