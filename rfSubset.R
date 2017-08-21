library(readr)
library(RPushbullet)

startTime = Sys.time()
print(paste("Script rfSubset1 started executing at: ", startTime))

coldspots <- read_csv("coldspots.csv")
hotspots <- read_csv("hotspots.csv")

#add column indicating if the row correspond to a hotspot and bind coldspots and hotspots in a new dataframe "data"
coldspots$isHot = 0
hotspots$isHot = 1
data = rbind(coldspots,hotspots[1:17547,])

#shuffle data row-wise
data = as.data.frame(data)
data = data[sample(nrow(data)),]

#split in two dataframes, 80% for training and 20% for testing
get80 = floor(nrow(data) * .8)
get20 = nrow(data) - get80
training = data[sample(nrow(data), get80), ]
testing = data[sample(nrow(data), get20), ]

#split training in two other dataframes, 80% for training and 20% for validation
get80 = floor(nrow(training) * .8)
get20 = nrow(training) - get80
subTraining = training[sample(nrow(training), get80), ]
validation = training[sample(nrow(training), get20), ]

#save subsets to csv
write_csv(data, "data.csv")
write_csv(training, "training.csv")
write_csv(testing, "testing.csv")
write_csv(subTraining, "subTraining.csv")
write_csv(validation, "validation.csv")

#print time and total execution time, send Pushbullet notification
endTime = Sys.time()
execTime = endTime - startTime
msg = paste("Script rfSubset1 finished executing at: ", endTime, "and took ", execTime, " seconds")
print(msg)
pbPost("note", "execution finished", msg)

