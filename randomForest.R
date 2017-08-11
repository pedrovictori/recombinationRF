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

#print time and execution time for the randomForest to be made
cuTime = Sys.time() - startTime
print(paste("Random forest made. Current time: ", Sys.time(), ". Execution time: ", endTime, " seconds"))

#save the model as a RData file
save(fit,file = "randomForestBin.RData")
print(fit)

#make a variable importance plot and save it as a png file
png(filename= "varImpPlot.png")
varImpPlot(fit)
dev.off()

#validating model
validation = read_csv("validation.csv")
validation = subset(validation, select= -c(isHot)) #remove isHot column from validation data
prediction = predict(fit,validation)
subtest = data.frame(name = validation$name,isHot = prediction)

#print time and total execution time 
endTime = Sys.time() - startTime
print(paste("Script randomForest finished executing at: ", Sys.time(), "and took ", endTime, " seconds"))
