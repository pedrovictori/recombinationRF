library(readr)
firstForestResults <- read_csv("./firstForestResults.csv")
selectedForestResults <- read_csv("./selectedForestResults.csv")

#comparing AUC and getting number of final selected variables
firstSelectedComparison = data.frame(datasetID = firstForestResults$treeID, firstForestAUC = firstForestResults$AUCf,
                                     selectedForestAUC = selectedForestResults$AUCs)

filename = paste("./varSelHistory/selectedVars", 1, ".csv", sep = "")
selectedVars = read_csv(filename)
colnames(selectedVars) = "variables"
firstSelectedComparison$selectedVariables[1] = nrow(selectedVars)

#create new dataframe to store all variables and count repetitions later
allVariables = selectedVars

for(i in 2:nrow(firstSelectedComparison)){
  #load file
  filename = paste("./varSelHistory/selectedVars", i, ".csv", sep = "")
  selectedVars = read_csv(filename)
  colnames(selectedVars) = "variables"
  firstSelectedComparison$selectedVariables[i] = nrow(selectedVars)
  allVariables = rbind(allVariables, selectedVars)
}

write_csv(firstSelectedComparison, "firstVSselectedComparison.csv")

#counting repetition of variables
tableVars = table(allVariables)
countDF = as.data.frame(tableVars)

write_csv(countDF,"selectedVariablesFrequency.csv")
