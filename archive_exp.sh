#!/usr/bin/env bash
rm fits/*.RData
mkdir $1
mkdir $1/ACCplots
mkdir $1/ROCplots
mkdir $1/varImpPlots
mv ACCplots/*.png $1/ACCplots/
mv ROCplots/*.png $1/ROCplots/
mv varImpPlots/*.png $1/varImpPlots/
mv accAll.png $1/
mv perfResults.csv $1/
mv rocAll.png $1/
