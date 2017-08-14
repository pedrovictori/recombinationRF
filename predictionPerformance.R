setwd("/home/victori/recombinationRF")
library(randomForest)
library(readr)
library(RPushbullet)

startTime = Sys.time()
cat("Script predictionPerformance started executing at: ", startTime)

#list for storing performance data
perfData = list()

#folder containing the Rdata files
path = paste(getwd(),"/fits",sep="")
file.fits = dir(path, pattern = ".RData")

for(i in 1:length(file.fits)){
  #load file
  filename = paste("./fits/fit", i, ".RData", sep = "")
  load(filename)
  
  #make a variable importance plot and save it as a png file
  png(filename= paste("varImpPlot",i,".png", sep = ""), width=1024, height = 955)
  varImpPlot(fit)
  dev.off()
  
  #validating model
  validation = read_csv("validation.csv")
  prediction = predict(fit,validation)
  subtest = data.frame(name = validation$name, isReallyHot = validation$isHot, isPredictedHot = prediction)
  
  #matches
  matches = sum(subtest$isReallyHot == subtest$isPredictedHot)
  matchesPercentage = matches*100/nrow(subtest)
  matchesPercentage = round(matchesPercentage,2)
  
  #false positives
  fp = sum((subtest$isReallyHot == 0) & (subtest$isPredictedHot ==1))
  
  #false negatives
  fn = sum((subtest$isReallyHot == 1) & (subtest$isPredictedHot ==0))
  
  #storing
  data = data.frame(matches = matches, matchesPer100 = matchesPercentage, falsePositives = fp, falseNegatives = fn)
  perfData[[i]] = data
}

#save results to csv
perfResults = do.call(rbind, perfData)
write_csv(perfResults, "perfResults.csv")

#print time and total execution time, send Pushbullet notification
endTime = Sys.time()
execTime = endTime - startTime
msg = paste("Script predictionPerformance finished executing at: ", endTime, "and took ", execTime, " seconds")
cat(msg)
pbPost("note", "execution finished", msg)

