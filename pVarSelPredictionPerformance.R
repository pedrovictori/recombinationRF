library(randomForest)
library(readr)
library(foreach)
library(doParallel)
library(RPushbullet)
library(ROCR)
library(varSelRF)

options(error = function() { 
  pbPost("note", "Error", geterrmessage())
})

startTime = Sys.time()
print(paste("Script pVarSelPredictionPerformance started executing at: ", startTime))

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
  load(filename)#load fitVS, a VarSelRF object
  
  #storing selection history as csv
  history = fitVS$selec.history
  write_csv(history, "history.csv")
  
  #storing selected variables as csv
  selectedVars = fitVS$selected.model
  write_csv(selectedVars, "selectedVars.csv")
  
  firstRF = fitVS$firstForest #forest without feature selection
  selectedRF = fitVS$rf.model #the selected forest
  
  #make a variable importance plot and save it as a png file
  png(filename= paste("./varImpPlots/firstVarImpPlot",i,".png", sep = ""), width=1024, height = 955)
  varImpPlot(firstRF)
  dev.off()
  
  png(filename= paste("./varImpPlots/selectedVarImpPlot",i,".png", sep = ""), width=1024, height = 955)
  varImpPlot(selectedRF)
  dev.off()
  
  #making model
  validation = read_csv("validation.csv")
  predictionFirst = predict(firstRF,validation)
  testFirst = data.frame(name = validation$name, isReallyHot = validation$isHot, isPredictedHot = predictionFirst)
  
  predictionSelected = predict(selectedRF,validation)
  testSelected = data.frame(name = validation$name, isReallyHot = validation$isHot, isPredictedHot = predictionSelected)
  
  #for ROC operations
  predictionObjectFirst = predict(firstRF,validation, type = "prob")
  predictionROCRFirst = prediction(predictionObjectFirst[,2], validation$isHot)
  
  predictionObjectSelected = predict(selectedRF,validation, type = "prob")
  predictionROCRSelected = prediction(predictionObjectSelected[,2], validation$isHot)
  
  #calculate AUC
  perf_AUCFirst = performance(predictionROCRFirst,"auc") #Calculate the AUC value
  AUCFirst = perf_AUCFirst@y.values[[1]]
  
  perf_AUCSelected = performance(predictionROCRSelected,"auc") #Calculate the AUC value
  AUCSelected = perf_AUCSelected@y.values[[1]]
  
  #plot ROC
  png(filename= paste("./ROCplots/firstROCplot",i,".png", sep = ""))
  perf_ROCFirst=performance(predictionROCRFirst,"tpr","fpr") #plot the actual ROC curve
  plot(perf_ROCFirst, main="ROC")
  text(0.8,0.2,paste("AUC = ",format(AUCFirst, digits=5, scientific=FALSE)))
  abline(a=0,b=1)
  dev.off()
  
  png(filename= paste("./ROCplots/selectedROCplot",i,".png", sep = ""))
  perf_ROCSelected=performance(predictionROCRSelected,"tpr","fpr") #plot the actual ROC curve
  plot(perf_ROCSelected, main="ROC")
  text(0.8,0.2,paste("AUC = ",format(AUCSelected, digits=5, scientific=FALSE)))
  abline(a=0,b=1)
  dev.off()
  
  #plot ROC for both forests together
  png(filename= paste("./ROCplots/bothForestsROCplot",i,".png", sep = ""))
  plot(perf_ROCFirst, main="ROC",col='red')
  plot(perf_ROCSelected,add=TRUE,col= 'blue')
  text(0.8,0.2,paste("First forest AUC = ",format(AUCFirst, digits=5, scientific=FALSE)),col = 'red')
  text(0.8,0.3,paste("Selected forest AUC = ",format(AUCSelected, digits=5, scientific=FALSE)),col = 'blue')
  abline(a=0,b=1)
  dev.off()
  
  #saving perf_ROC to a RData file to plot all curves together later.
  if(nFiles > 1){
    save(perf_ROCFirst,file = paste("./ROCplots/FirstRocObject", i, ".RData", sep = ""))
    save(perf_ROCSelected,file = paste("./ROCplots/SelectedRocObject", i, ".RData", sep = ""))
  }
  
  #calculate ACC and save it to a RData file to plot all curves together later.
  perf_ACCFirst = performance(predictionROCRFirst, "acc")
  perf_ACCSelected = performance(predictionROCRSelected, "acc")
  if(nFiles > 1){
    save(perf_ACCFirst,file = paste("./ACCplots/firstAccObject", i, ".RData", sep = ""))
    save(perf_ACCSelected,file = paste("./ACCplots/selectedAccObject", i, ".RData", sep = ""))
  }
  
  #plot ACC
  png(filename= paste("./ACCplots/firstACCplot",i,".png", sep = ""))
  plot(perf_ACCFirst, main="ACC")
  dev.off()
  
  png(filename= paste("./ACCplots/selectedACCplot",i,".png", sep = ""))
  plot(perf_ACCSelected, main="ACC")
  dev.off()
  
  #matches
  matchesFirst = sum(testFirst$isReallyHot == testFirst$isPredictedHot)
  matchesPercentageFirst = matches*100/nrow(testFirst)
  matchesPercentageFirst = round(matchesPercentageFirst,2)
  
  matchesSelected = sum(testSelected$isReallyHot == testSelected$isPredictedHot)
  matchesPercentageSelected = matches*100/nrow(testSelected)
  matchesPercentageSelected = round(matchesPercentageSelected,2)
  
  #false positives
  fpFirst = sum((testFirst$isReallyHot == 0) & (testFirst$isPredictedHot ==1))
  fpSelected = sum((testSelected$isReallyHot == 0) & (testSelected$isPredictedHot ==1))
  
  #false negatives
  fnFirst = sum((testFirst$isReallyHot == 1) & (testFirst$isPredictedHot ==0))
  fnSelected = sum((testSelected$isReallyHot == 1) & (testSelected$isPredictedHot ==0))
  
  #return object
  data.frame(treeID = i, 
             AUCf = AUCFirst, matchesf = matchesFirst, matchesPer100f = matchesPercentageFirst, falsePositivesf = fpFirst, falseNegativesf = fnFirst,
             AUCs = AUCSelected, matches_s = matchesSelected, matchesPer100s = matchesPercentageSelected, falsePositives_s = fpSelected, falseNegatives_s = fnSelected)
}

#save results to csv
perfResults = do.call(rbind, perfData)
#separate in two dataframes, for first forest and selected forest

firstForestResults = perfResults[,c(1,2,3,4,5)]
selectedForestResults = perfResults[,c(1,6,7,8,9)]
write_csv(firstForestResults, "firstForestResults.csv")
write_csv(selectedForestResults, "selectedForestResults.csv")

if(nFiles > 1){
  #all ROC in one plot
  png(filename= "./firstRocAll.png")
  abline(a=0,b=1)
  #folder containing the Rdata files
  path = "./ROCplots"
  file.roc = dir(path, pattern = "firstRocObject")
  
  for(i in 2:length(file.roc)){
    #load file
    filename = paste("./ROCplots/firstRocObject", i, ".RData", sep = "")
    load(filename)# perf_ROCFirst
    
    #plot ROC
    plot(perf_ROCFirst,add=(i!=1), main="ROC of all first forests")
  }
  averageAUCFirst = mean(firstForestResults$AUCf)
  text(0.8,0.2,paste("average AUC = ",format(averageAUCFirst, digits=5, scientific=FALSE)))
  dev.off()
  
  png(filename= "./selectedRocAll.png")
  abline(a=0,b=1)
  #folder containing the Rdata files
  path = "./ROCplots"
  file.roc = dir(path, pattern = "selectedRocObject")
  
  for(i in 1:length(file.roc)){
    #load file
    filename = paste("./ROCplots/selectedRocObject", i, ".RData", sep = "")
    load(filename)# perf_ROCSelected
    
    #plot ROC
    plot(perf_ROCSelected,add=(i!=1), main="ROC of all selected forests")
  }
  averageAUCSelected = mean(selectedForestResults$AUCs)
  text(0.8,0.2,paste("average AUC = ",format(averageAUCSelected, digits=5, scientific=FALSE)))
  dev.off()
  
  #all ROC of first and selected forests in one plot
  png(filename= "./allROC.png")
  abline(a=0,b=1)
  #folder containing the Rdata files
  path = "./ROCplots"
  file.roc = dir(path, pattern = "selectedRocObject")
  
  for(i in 1:length(file.roc)){
    #load file
    filename = paste("./ROCplots/firstRocObject", i, ".RData", sep = "")
    load(filename)# perf_ROCFirst
    filename = paste("./ROCplots/selectedRocObject", i, ".RData", sep = "")
    load(filename)# perf_ROCSelected
    
    #plot ROC
    plot(perf_ROCSelected,add=(i!=1), main="ROC of all forests",col='blue')
    plot(perf_ROCFirst,add=TRUE, main="ROC of all forests",col='red')
  }
  
  averageAUCFirst = mean(firstForestResults$AUCf)
  text(0.8,0.2,paste("average AUC = ",format(averageAUCFirst, digits=5, scientific=FALSE)),col='red')
  averageAUCSelected = mean(selectedForestResults$AUCs)
  text(0.8,0.3,paste("average AUC = ",format(averageAUCSelected, digits=5, scientific=FALSE)),col = 'blue')
  dev.off()
  
  #all ACC in one plot
  png(filename= "./firstAccAll.png")
  
  #folder containing the Rdata files
  path = "./ACCplots"
  file.acc = dir(path, pattern = "firstAccObject")
  
  for(i in 1:length(file.acc)){
    #load file
    filename = paste("./ACCplots/firstAccObject", i, ".RData", sep = "")
    load(filename)# perf_ACC
    
    #plot ACC
    plot(perf_ACCFirst,add=i!=1, main="ACC of all first forests")
  }
  dev.off()
  
  png(filename= "./selectedAccAll.png")
  
  #folder containing the Rdata files
  path = "./ACCplots"
  file.acc = dir(path, pattern = "selectedAccObject")
  
  for(i in 1:length(file.acc)){
    #load file
    filename = paste("./ACCplots/selectedAccObject", i, ".RData", sep = "")
    load(filename)# perf_ACC
    
    #plot ACC
    plot(perf_ACCSelected,add=i!=1, main="ACC of all selected forests")
  }
  dev.off()
}

#print time and total execution time, send Pushbullet notification
endTime = Sys.time()
execTime = endTime - startTime
msg = paste("Script pVarSelPredictionPerformance finished executing at: ", endTime, "and took ", execTime, " seconds")
print(msg)
pbPost("note", "execution finished", msg)

