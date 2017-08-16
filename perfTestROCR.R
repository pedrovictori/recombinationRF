library(ROCR)
library(randomForest)
library(readr)

load("fit1.RData")
validation = read_csv("validation.csv")

prediction = predict(fit,validation, type = "prob")
predictionROCR = prediction(prediction[,2], validation$isHot)


perf_AUC=performance(predictionROCR,"auc") #Calculate the AUC value
AUC=perf_AUC@y.values[[1]]

perf_ROC=performance(predictionROCR,"tpr","fpr") #plot the actual ROC curve
plot(perf_ROC, main="ROC plot")
text(0.5,0.5,paste("AUC = ",format(AUC, digits=5, scientific=FALSE)))
