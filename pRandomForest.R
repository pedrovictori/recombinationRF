setwd("/home/victori/recombinationRF")
library(RPushbullet)

options(error = function() { 
  pbPost("note", "Error", geterrmessage())
})

#default variables
nIter = 100
sampleSize = .25
inputName = "subTraining.csv"

#keyword names
kiter = "-niter" 
ksample= "-samplesize" 
kinput = "-inputfile"
khelp = "-help"
keywords = c(kiter,ksample,kinput,khelp)

#parameters parsing
args = commandArgs(trailingOnly = TRUE)

if((length(args)%%2 == 0) && (length(args) <= 8)){
  if(length(args) != 0){
    cuArg = ""
    
    for(i in 1:length(args)){
      if(args[i] %in% keywords){ #if the current argument is a keyword
        cuArg = args[i]
      }
      
      else{ #not a keyword, either a value or a mistake
        if(cuArg==""){ #doesn't follow a keyword, so it's an error
          print("bad argument input, exiting")
          quit(save="no")
        }
        else{ # it's a value
          cat(cuArg,args[i])
          
          if(cuArg == kiter){
            nIter = as.numeric(args[i])
          }
          else if(cuArg == ksample){
            sampleSize = as.numeric(args[i])
          }
          else if(cuArg == kinput){
            inputName = args[i]
          }
        }
      }
    }
  }
} else{
  if(args[1] == khelp){
    cat("\nParameters for parallelRandomForest.R:\n",
        kiter, ": number of random forests to be run on random samples\n",
        ksample, ": fraction of the total data to randomly sample for a random forest\n",
        kinput, ": name of the csv file with the training data\n",
        khelp, ": prints this help\n")
  }
  else{
    print("bad argument input, exiting")
  }
  quit(save="no")
}

startTime = Sys.time()
print(paste("Script parallelRandomForest started executing at: ", startTime))

library(randomForest)
library(readr)
library(foreach)
library(doParallel)
library(RPushbullet)

#load data
subTraining = read_csv(inputName)

#Parallel loop
#setup parallel backend
cores = detectCores()
nCores = cores[1]-1 #all cores minus one, so not to overload the computer

if(nIter<nCores){ #only need one core per iteration
  nCores = nIter
}

cl <- makeCluster(nCores)
registerDoParallel(cl)
cat("\ncluster set.", nCores," cores, ",nIter, " iterations, ",sampleSize, " sample size.")

foreach(i=1:nIter, .packages = 'randomForest') %dopar% {
  #get random subsample 
  sub = subTraining[sample(nrow(subTraining)*sampleSize),]
  
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
