setwd("/home/victori/randomForest")
library(randomForest)
library(readr)

startTime = Sys.time()
print(paste("Script randomForest started executing at: ", startTime))

subTraining = read_csv("subTraining.csv")

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

save(fit,"randomForestBin.RData")
print(fit)

endTime = Sys.time() - startTime
print(paste("Script randomForest finished executing at: ", Sys.time(), "and took ", endTime, " seconds"))
