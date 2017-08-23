#!/usr/bin/env bash
rm fits/*.RData
mkdir $1
mkdir $1/ACCplots
mkdir $1/ROCplots
mkdir $1/varImpPlots
mv ACCplots/*.png $1/ACCplots/
mv ROCplots/*.png $1/ROCplots/
mv varImpPlots/*.png $1/varImpPlots/

mv firstRocAll.png $1/
mv selectedRocAll.png $1/
mv allROC.png $1/
mv firstAccAll.png $1/
mv selectedAccAll.png $1/
mv firstForestResults.csv $1/
mv selectedForestResults.csv $1/
mv history.csv $1/
mv selectedVars.csv $1/
