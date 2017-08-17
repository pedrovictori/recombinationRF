#!/usr/bin/env bash

mkdir $1
mkdir $1/fits
mkdir $1/ACCplots
mkdir $1/ROCplots
mkdir $1/varImpPlots
cp parallelPredictionPerformance.R $1
cp parallelRandomForest.R $1
cp .Renviron $1
cp .Rprofile $1
cp $2 $1
cp $3 $1

