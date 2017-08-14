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
print(paste("Random forest made. Current time: ", Sys.time(), ". Execution time: ", cuTime, " seconds"))

#save the model as a RData file
save(fit,file = "randomForestBin.RData")
print(fit)

#make a variable importance plot and save it as a png file
png(filename= "varImpPlot.png", width=1024, height = 955)
varImpPlot(fit)
dev.off()

#validating model
validation = read_csv("validation.csv")
validation = subset(validation, select= -c(isHot)) #remove isHot column from validation data
validation = validation[,-2] #remove name column
prediction = predict(fit,validation)
subtest = data.frame(name = validation$name, isReallyHot = validation$isHot, isPredictedHot = prediction)

#matches
matches = sum(subtest$isReallyHot == subtest$isPredictedHot)
matchesPercentage = matches*100/nrow(subtest)
matchesPercentage = round(matchesPercentage,2)
print(paste("Match count: ", matches, ". Match percentage: ", matchesPercentage, "%"))

#false positives
fp = sum((subtest$isReallyHot == 0) & (subtest$isPredictedHot ==1))
print(paste("False positives count: ", fp, "."))

#false negatives
fn = sum((subtest$isReallyHot == 1) & (subtest$isPredictedHot ==0))
print(paste("False negatives count: ", np, "."))

#print time and total execution time 
endTime = Sys.time()
execTime = endTime - startTime
print(paste("Script randomForest finished executing at: ", endTime, "and took ", execTime, " seconds"))
