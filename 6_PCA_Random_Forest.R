################################################################################

# PRINCIPAL COMPONENT ANALYSIS AND RANDOM FOREST

# This code was developed by Mario Guevara, Viviana Varón, Carlos E. Arroyo-Cruz
################################################################################

#### Setup document ####

# Clear workspace
rm(list=ls())

# set working directory
setwd("C:/Users/spacella/OneDrive - Environmental Protection Agency (EPA)/SDR Blue Carbon/Dhond Files/Blue Carbon Modeling Project")

# Load relevant libraries for multivariate analysis
library(FactoMineR)
library(FactoInvestigate)
library(openair)

# Load the covariate matrix  
dat <- read.csv('DataModel.csv') # update with new data when covariates are loaded

# Remove unnecesary variables
df <- dat[c(19:46)]

# Remove variables with non assigned values
df$LsFactor <- NULL

# Perform a PCA analysis
res.pca = PCA(df, quanti.sup = 1,  graph = TRUE)

# Generate an automated PCA interpretation
Investigate(res.pca, file = "PCA.Rmd", document = "html_document", time = "1000L",
            parallel = FALSE)

# Load library for classification and regression training
library(caret)
library(doParallel)# for running in parallel

# Configure parallel processing 
cl <- makePSOCKcluster(5)#n nodes
registerDoParallel(cl)#configure cluster

# Perform random forests in a recursive feature evaluation framework
rfProfile <- rfe(df[-1:-2], df$Soil_C_sto,
                 sizes = c(2, 5, 10, 20),
                 rfeControl = rfeControl(functions = rfFuncs))



stopCluster(cl) #used to stop the parallel processing fork

# summarize the results
print(rfProfile)

# list the chosen features
predictors(rfProfile)

# plot the results
plot(rfProfile, type=c("g", "o"))

# Save covariates 
opt_covs <- predictors(rfProfile)
# Save log_soil carbon as a formula
fm <- as.formula(paste("log1p(Soil_C_sto) ~", paste0(opt_covs, collapse = "+") ) )


#### Random Forest Model ####
cl <- makeCluster(detectCores()-1)
registerDoParallel(cl)
#registerDoParallel(cores=25)

## 3.2 - Set training parameters -----------------------------------------------
fitControl <- trainControl(method = "repeatedcv",
                           number = 10,         ## 10 -fold CV
                           repeats = 3,        ## repeated 3 times
                           savePredictions = TRUE)
# These values may give warnings when running the code but that is mainly due to the parameterization of the model

# Tune mtry hyperparameters
mtry <- round(length(opt_covs)/3)
tuneGrid <-  expand.grid(mtry = c(mtry-5, mtry, mtry+5))

## 3.3 - Calibrate the QRF model -----------------------------------------------
model <- caret::train(fm,
                      data = df,
                      method = "qrf",
                      trControl = fitControl,
                      verbose = TRUE,
                      tuneGrid = tuneGrid,
                      keep.inbag = T,
                      importance = TRUE)

stopCluster(cl)
#stopImplicitCluster()

# Save the observations and predictions in one dataframe
ob <- model$pred$obs # observations
pr <- model$pred$pred # predictions
DF <- data.frame(ob,pr) # combine

# 
openair::modStats(DF, mod="pr", obs="ob")
#plot(DF)
openair::scatterPlot(DF, x = "pr", y = "ob", linear=TRUE)
##

randomForest::varImpPlot(model$finalModel,
                         sort=TRUE, 
                         main="Variable Importance Plot")
###
library(terra)
domain <- rast('stack_Tangier2.tif')
#cl <- makeCluster(10)
#registerDoParallel(cl)
#stopCluster(cl)
pred_quantiles <- terra::predict(domain, model = model$finalModel, na.rm=TRUE,  #cores=cl,
                                 cpkgs="quantregForest", what=c(0.05, 0.5, 0.95))
###plot the mean the 95% prediction intervals. 1 realization
plot(pred_quantiles)
#names(s)[grepl("_", names(s))]<- sapply(names(s)[grepl("_", names(s))], function(x){ x<-strsplit(x,"_")[[1]][2]}) 

# Save the model to an RDS file
saveRDS(model, file = "250212_rf_model.rds")

