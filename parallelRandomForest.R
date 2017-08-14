setwd("/home/victori/recombinationRF")
library(randomForest)
library(readr)
library(foreach)
library(doParallel)
library(RPushbullet)

startTime = Sys.time()
print(paste("Script parallelRandomForest started executing at: ", startTime))

subTraining = read_csv("subTraining.csv")

#Parallel loop
#setup parallel backend
cores = detectCores()
cl <- makeCluster(cores[1]-1) #not to overload computer
registerDoParallel(cl)

#folder for storing the random forest objects in binary form
#dir.create("fits")

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

#print time and total execution time, send Pushbullet notification 
endTime = Sys.time()
execTime = endTime - startTime
msg = paste("Script parallelRandomForest finished executing at: ", endTime, "and took ", execTime, " seconds")
print(msg)
pbPost("note", "execution finished", msg)
