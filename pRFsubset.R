library(readr)
library(foreach)
library(doParallel)
library(RPushbullet)

options(error = function() { 
  pbPost("note", "Error", geterrmessage())
})

#default
nIter = 20


#parameter parsing
args = commandArgs(trailingOnly = TRUE)
if(length(args)!=0){
  if(length(args)==1){
    nIter = as.numeric(args[1])
  } else{
    print("bad argument input, exiting")
    quit(save="no")
  }
}


startTime = Sys.time()
print(paste("Script pRFsubset started executing at: ", startTime))

training <- read_csv("training.csv")

#folder for storing the subsets 
path = "./subsets"

#setup parallel backend
cores = detectCores()
nCores = cores[1]-1  #not to overload computer

if(nFiles<nCores){ #only need one core per iteration
  nCores = nFiles
}

cl <- makeCluster(nCores)

registerDoParallel(cl)
cat("\ncluster set")

foreach(i=1:nIter,.packages = 'randomForest') %dopar% {
  #split training in two other dataframes, 80% for training and 20% for validation
  get80 = floor(nrow(training) * .8)
  get20 = nrow(training) - get80
  subTraining = training[sample(nrow(training), get80), ]
  validation = training[sample(nrow(training), get20), ]
  
  #write csv
  write_csv(subTraining, paste(path,"/subTraining", i, ".csv",sep=""))
  write_csv(validation, paste(path,"/validation", i, ".csv",sep=""))
}

#print time and total execution time, send Pushbullet notification
endTime = Sys.time()
execTime = endTime - startTime
msg = paste("Script rfSubset1 finished executing at: ", endTime, "and took ", execTime, " seconds")
print(msg)
pbPost("note", "execution finished", msg)