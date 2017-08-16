setwd("/home/victori/recombinationRF")
library(randomForest)
library(readr)
library(foreach)
library(doParallel)
library(RPushbullet)
library(ROCR)

startTime = Sys.time()
print(paste("Script parallelpredictionPerformance started executing at: ", startTime))

#setup parallel backend
cores = detectCores()
cl <- makeCluster(cores[1]-1) #not to overload computer
registerDoParallel(cl)
cat("\ncluster set")

#folder containing the Rdata files
path = "./fits"
file.fits = dir(path, pattern = ".RData")

perfData = foreach(i=1:length(file.fits), combine=data.frame,.packages = c('randomForest','readr','ROCR')) %dopar% {
  #load file
  filename = paste("./fits/fit", i, ".RData", sep = "")
  load(filename)
  
  #make a variable importance plot and save it as a png file
  png(filename= paste("./varImpPlots/varImpPlot",i,".png", sep = ""), width=1024, height = 955)
  varImpPlot(fit)
  dev.off()
  
  #making model
  validation = read_csv("validation.csv")
  prediction = predict(fit,validation)
  subtest = data.frame(name = validation$name, isReallyHot = validation$isHot, isPredictedHot = prediction)
  
  #for ROC operations
  prediction = predict(fit,validation, type = "prob")
  predictionROCR = prediction(prediction[,2], validation$isHot)
  
  #calculate AUC
  perf_AUC=performance(predictionROCR,"auc") #Calculate the AUC value
  AUC=perf_AUC@y.values[[1]]
  
  #plot ROC
  png(filename= paste("./ROCplots/ROcplot",i,".png", sep = ""))
  perf_ROC=performance(predictionROCR,"tpr","fpr") #plot the actual ROC curve
  plot(perf_ROC, main="ROC plot")
  text(0.5,0.5,paste("AUC = ",format(AUC, digits=5, scientific=FALSE)))
  dev.off()
  
  #saving perf_ROC to a RData file to plot all curves together later.
  save(perf_ROC,file = paste("./ROCplots/RocObject", i, ".RData", sep = ""))
  
  #matches
  matches = sum(subtest$isReallyHot == subtest$isPredictedHot)
  matchesPercentage = matches*100/nrow(subtest)
  matchesPercentage = round(matchesPercentage,2)
  
  #false positives
  fp = sum((subtest$isReallyHot == 0) & (subtest$isPredictedHot ==1))
  
  #false negatives
  fn = sum((subtest$isReallyHot == 1) & (subtest$isPredictedHot ==0))

  #return object
  data.frame(treeID = i, AUC = AUC, matches = matches, matchesPer100 = matchesPercentage, falsePositives = fp, falseNegatives = fn)
}

#save results to csv
perfResults = do.call(rbind, perfData)
write_csv(perfResults, "perfResults.csv")

#all ROC in one plot
#folder containing the Rdata files
load("./ROCplots/RocObject1.RData")
plot(perf_ROC)
path = "./ROCplots"
file.roc = dir(path, pattern = ".RData")

for(i in 2:length(file.roc)){
  #load file
  filename = paste("./ROCplots/RocObject", i, ".RData", sep = "")
  load(filename)# perf_ROC
  
  #plot ROC
  png(filename= "./roc100.png")
  plot(perf_ROC,add=TRUE, main="ROC of 100 random forests")
  dev.off()
}

#print time and total execution time, send Pushbullet notification
endTime = Sys.time()
execTime = endTime - startTime
msg = paste("Script parallelpredictionPerformance finished executing at: ", endTime, "and took ", execTime, " seconds")
print(msg)
pbPost("note", "execution finished", msg)

