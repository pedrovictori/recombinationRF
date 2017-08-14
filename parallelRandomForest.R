setwd("/home/victori/randomForest")
library(randomForest)
library(readr)
library(foreach)
library(doParallel)

startTime = Sys.time()
print(paste("Script ParallelRandomForest started executing at: ", startTime))

subTraining = read_csv("subTraining.csv")

#Parallel loop
#setup parallel backend
cores = detectCores()
cl <- makeCluster(cores[1]-1) #not to overload computer
registerDoParallel(cl)

#folder for storing the random forest objects in binary form
dir.create("fits")

foreach(i=1:100, .packages = 'randomForest') %dopar% {
  #get random 25% subsample 
  sub = subTraining[sample(nrow(subTraining)*.25),]
  
  #remove name column
  sub = sub[,-2]
  
  #extract isHot column and make it a factor
  y = sub$isHot
  y = as.factor(y)
  
  #create x, sub without isHot column
  x = subset(sub, select =-c(isHot))
  
  #random forest
  set.seed(42)
  fit = randomForest(x,y,
                     importance = TRUE,
                     ntree = 5000)
  
  #save the model as a RData file
  save(fit,file = paste(getwd(),"/fits/fit", i, ".RData", sep = ""))
}

#print time and total execution time 
endTime = Sys.time() - startTime
print(paste("Script ParallelRandomForest finished executing at: ", Sys.time(), "and took ", endTime, " seconds"))
