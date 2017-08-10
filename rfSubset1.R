setwd("/home/victori/randomForest")
library(randomForest)
library(readr)

startTime = Sys.time()
print(startTime)

coldspots <- read_csv("coldspots.csv")
hotspots <- read_csv("hotspots.csv")

#add column indicating if the row correspond to a hotspot and bind coldspots and hotspots in a new dataframe "data"
coldspots$isHot = 0
hotspots$isHot = 1
data = rbind(coldspots,hotspots[1:17547,])

#shuffle data row-wise
data = data[sample(nrow(data)),]

#split in two dataframes, 80% for training and 20% for testing
index80 = nrow(data) * .8
training = data[c(1:index80),]
testing = data[c((index80+1):(nrow(data)+1)),]

#split training in two other dataframes, 80% for training and 20% for validation
index80 = nrow(training) * .8
subTraining = training[c(1:index80),]
validation = training[c((index80+1):(nrow(training)+1)),]

#save subsets to binary
save(data, file="data.RData")
save(training, file="training.RData")
save(testing, file="testing.RData")
save(subTraining, file="subTraining.RData")
save(validation, file="validation.RData")

execTime = Sys.time() - startTime
print(paste("Script subsetting1 finished executing at: ", Sys.time(), "and took ",execTime, "seconds"))
