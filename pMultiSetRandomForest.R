library(RPushbullet)
library(randomForest)
library(readr)
library(foreach)
library(doParallel)

options(error = function() { 
  pbPost("note", "Error", geterrmessage())
})

startTime = Sys.time()
print(paste("Script pMultiSetRandomForest started executing at: ", startTime))

#folder containing the data
path = "./subsets"
file.sets = dir(path, pattern = "validation")
nFiles = length(file.sets)

#setup parallel backend
cores = detectCores()
nCores = cores[1]-1  #not to overload computer

if(nFiles<nCores){ #only need one core per iteration
  nCores = nFiles
}

cl <- makeCluster(nCores)

registerDoParallel(cl)
cat("\ncluster set")

perfData = foreach(i=1:nFiles, combine=data.frame,.packages = c('randomForest','readr')) %dopar% {
  #load file
  filename = paste("./subsets/subTraining", i, ".csv", sep = "")
  subTraining = read_csv(filename)
  
  #remove name column
  subTraining = subTraining[,-2]
  
  #extract isHot column and make it a factor
  y = subTraining$isHot
  y = as.factor(y)
  
  #create x, subTraining without isHot column
  x = subset(subTraining, select =-c(isHot))
  
  #random forest
  set.seed(42)
  fit = randomForest(x,y,
                     importance = TRUE,
                     ntree = 5000)
  
  #save the model as a RData file
  save(fit,file = paste("/fits/fit", i, ".RData", sep = ""))
}

#print time and total execution time, send Pushbullet notification 
endTime = Sys.time()
execTime = endTime - startTime
msg = paste("Script pMultiRandomForest finished executing at: ", endTime, "and took ", execTime, " seconds")
print(msg)
pbPost("note", "execution finished", msg)
