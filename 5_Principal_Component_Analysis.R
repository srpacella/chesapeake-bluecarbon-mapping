################################################################################
# PRINCIPAL COMPONENT ANALYSIS AND ANALYSIS OF VARIANCE

# This code was developed by Mario Guevara, Viviana Varón, Carlos E. Arroyo-Cruz
################################################################################

#### Setup document ####
rm(list=ls()) # clear workspace

# set working directory
setwd("C:/Users/adhond/OneDrive - Environmental Protection Agency (EPA)/Dhond Files/Blue Carbon Modeling Project")

# Load libraries for multivariate analysis
library(FactoMineR)
library(FactoInvestigate)
library(randomForest)

# Load the dataset
dat <- read.csv('DataModel.csv')

# Remove unnecessary variables (SRP - is this correct????)
#df <- dat[c(19:46)]
df <- dat #SRP edit
# Remove variable with non assigned values (there were 0s here)
df$LsFactor <- NULL

#### Perform PCA Analysis ####

# Perform a PCA analysis, create the PCA
res.pca = PCA(df, quanti.sup = 1,  graph = TRUE)

# Generate an automated PCA interpretation
Investigate(res.pca, file = "PCA.Rmd", document = "html_document", time = "1000L", 
            parallel = FALSE)

#### Find NAs and temporarily make them equal to the dataset mean (SRP edit 10/28/2024)
na_find <- which(is.na(df))
na_new <- mean(na.omit(df$Aspect))
df[is.na(df)] <- na_new

#### Classification and Regression Training ####

# Load library for classifcation and regression training
library(caret)
library(doParallel)#for running in parallel

cl <- makePSOCKcluster(5)#n nodes
registerDoParallel(cl)#configure cluster

#perform random forests in a recursive feature evaluation framework
rfProfile <- rfe(df[-1], df$SurfaceCar,
                 sizes = c(2, 5, 10, 20),
                 rfeControl = rfeControl(functions = rfFuncs))


stopCluster(cl)

# summarize the results
print(rfProfile)
# list the chosen features
predictors(rfProfile)
# plot the results
plot(rfProfile, type=c("g", "o"))
