setwd("/home/victori/recombinationRF")
library(randomForest)
library(readr)
library(foreach)
library(doParallel)
library(RPushbullet)
library(ROCR)

options(error = function() { 
  pbPost("note", "Error", geterrmessage())
})

startTime = Sys.time()
print(paste("Script parallelpredictionPerformance started executing at: ", startTime))

#folder containing the Rdata files
path = "./fits"
file.fits = dir(path, pattern = ".RData")
nFiles = length(file.fits)
#setup parallel backend
cores = detectCores()
nCores = cores[1]-1  #not to overload computer

if(nFiles<nCores){ #only need one core per iteration
  nCores = nFiles
}

cl <- makeCluster(nCores)

registerDoParallel(cl)
cat("\ncluster set")

perfData = foreach(i=1:nFiles, combine=data.frame,.packages = c('randomForest','readr','ROCR')) %dopar% {
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
  png(filename= paste("./ROCplots/ROCplot",i,".png", sep = ""))
  perf_ROC=performance(predictionROCR,"tpr","fpr") #plot the actual ROC curve
  plot(perf_ROC, main="ROC")
  text(0.5,0.5,paste("AUC = ",format(AUC, digits=5, scientific=FALSE)))
  abline(a=0,b=1)
  dev.off()
  
  #saving perf_ROC to a RData file to plot all curves together later.
  save(perf_ROC,file = paste("./ROCplots/RocObject", i, ".RData", sep = ""))
  
  
  #calculate ACC and save it to a RData file to plot all curves together later.
  perf_ACC = performance(predictionROCR, "acc")
  save(perf_ACC,file = paste("./ACCplots/AccObject", i, ".RData", sep = ""))
  
  #plot ACC
  png(filename= paste("./ACCplots/ACCplot",i,".png", sep = ""))
  plot(perf_ACC, main="ACC")
  dev.off()
  
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
png(filename= "./roc100.png")

#folder containing the Rdata files
load("./ROCplots/RocObject1.RData")
plot(perf_ROC)
abline(a=0,b=1)
path = "./ROCplots"
file.roc = dir(path, pattern = ".RData")

for(i in 2:length(file.roc)){
  #load file
  filename = paste("./ROCplots/RocObject", i, ".RData", sep = "")
  load(filename)# perf_ROC
  
  #plot ROC
  plot(perf_ROC,add=TRUE, main="ROC of 100 random forests")
}
dev.off()

#all ACC in one plot
png(filename= "./acc100.png")

#folder containing the Rdata files
load("./ACCplots/AccObject1.RData")
plot(perf_ACC)
path = "./ACCplots"
file.acc = dir(path, pattern = ".RData")

for(i in 2:length(file.acc)){
  #load file
  filename = paste("./ACCplots/AccObject", i, ".RData", sep = "")
  load(filename)# perf_ACC
  
  #plot ACC
  plot(perf_ACC,add=TRUE, main="ACC of 100 random forests")
}
dev.off()

#print time and total execution time, send Pushbullet notification
endTime = Sys.time()
execTime = endTime - startTime
msg = paste("Script parallelpredictionPerformance finished executing at: ", endTime, "and took ", execTime, " seconds")
print(msg)
pbPost("note", "execution finished", msg)

