#!/usr/bin/env bash
if [ "$1" == "-h" ]; then
  echo "Usage: setup_exp.sh [experiment folder name] [training data file] [validation data file] [random forest script]"
  exit 0
fi
mkdir $1
mkdir $1/fits
mkdir $1/ACCplots
mkdir $1/ROCplots
mkdir $1/varImpPlots
cp parallelPredictionPerformance.R $1
cp .Renviron $1
cp .Rprofile $1
cp $2 $1
cp $3 $1
cp $4 $1

