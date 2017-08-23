library(readr)
features = read_delim("features.txt", "\t", escape_double = FALSE, trim_ws = TRUE)

selectedVars <- read_csv("selectedVars.csv")
features = data.frame(
  feature=paste(features$`Cell Type`,features$`TF/DNase/Histone`,features$Treatment,sep="|"),
  AUC = features$AUC)
features$feature = as.character(features$feature)
features$AUC = as.numeric(levels(features$AUC[features$AUC]))
colnames(selectedVars) = "feature"

selectedVars = merge(features,selectedVars,by = "feature",all.y = TRUE)
selectedVars = selectedVars[,-3]
colnames(selectedVars) = c("feature","AUC")

write_csv(selectedVars,"selectedVarsWithAUC.csv")
