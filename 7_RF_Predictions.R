################################################################################
# CREATING RANDOM FOREST PREDICTIONS AND MAPPING

# This code was developed by Mario Guevara, Viviana Varón, Carlos E. Arroyo-Cruz

################################################################################
# Load relevant packages
library(tidyverse)
library(data.table)
library(caret)
library(quantregForest)
library(terra)
library(doParallel)

# Set working directory to where model is stored
setwd("C:/Users/spacella/OneDrive - Environmental Protection Agency (EPA)/SDR Blue Carbon/Dhond Files/Blue Carbon Modeling Project/TestTiles_241024")

# Load model
model <-readRDS("241028_rf_model.rds")

# Set working directory to Chesapeake tile folder
setwd("C:/Users/spacella/OneDrive - Environmental Protection Agency (EPA)/SDR Blue Carbon/Dhond Files/Blue Carbon Modeling Project/TestTiles_241024")

# Create list of subfolders
ds<-list.dirs(full.names =T, recursive =F)


for(d in ds[c(26)]){ ##[c(35,37,41,46,48)], watersheds in AOI
  
  f<-list.files(d, pattern = ".tif$", full.names = T)
  if( !file.exists(gsub(".tif","_SOCstock.tif",f[!grepl("_",f)])) ){
    cat( paste("\n",gsub(".tif","_SOCstock.tif",f[!grepl("_",f)])) )
    #s<-rast(f[-c(13:14,18)]) # Remove the  sentinel and unclipped DEM
    #s<-rast(f[-c(1,14,18)]) # Remove the  sentinel and unclipped DEM and new SOCstock.tif
    s<-rast(f[-c(1,14,18)]) # Remove the  sentinel and unclipped DEM and new SOCstock.tif
    tmp<-crop(rast(f[14]), rast(f[6])) #unclear what files we are using here (SRP thinks we are cropping Sentinel)
    
    domain<-c(s, tmp)
    
    names(domain)[grepl("_", names(domain))]<- sapply(names(domain)[grepl("_", names(domain))], function(x){ x<-strsplit(x,"_")[[1]][2]}) 
    
    domain<-domain[[model$finalModel$xNames]]
    
    # domain$LsFactor<-NULL
    # domain$Aspect<-NULL
    
    ## parallelization, chnage the "6" to a number that works for your PC. 
    cl <- makeCluster(detectCores()-6)
    registerDoParallel(cl)
    
    pred_quantiles <- terra::predict(domain, model = model$finalModel, na.rm=TRUE,  cores=cl,
                                     cpkgs="quantregForest", what=c(0.05, 0.5, 0.95))
    ###plot the mean the 95% prediction intervals. 
    #plot(pred_quantiles)
    stopCluster(cl)
    
    names(pred_quantiles)<-c("q05", "q50", "q95")
    
    #writeRaster(expm1(pred_quantiles), gsub(".tif","_SOCstock.tif",f[18]) )
    writeRaster(expm1(pred_quantiles),filename=gsub(".tif","_SOCstock.tif",f[!grepl("_",f)]))
    
    #writeRaster(pred_quantiles, gsub(".tif","_SOCstock_log.tif",f[18]) )
    writeRaster(pred_quantiles,filename=gsub(".tif","_SOCstock_log.tif",f[!grepl("_",f)]))
    
    rm(domain, pred_quantiles, tmp)
    gc()
    
  }
  
  
}

# Visualize SOC output
 test_image <- rast("./Severn/Severn_SOCstock_log.tif")
 print(test_image)
 plot(test_image)
 
 # Create zoomable map
 library(leaflet)
 leaflet() %>%
   addTiles() %>%
   addRasterImage(test_image, colors = terrain.colors(100), opacity = 0.8) %>%
   addLegend(pal = colorNumeric(palette = "viridis", domain = values(test_image)),
             values = values(test_image), title = "SOC Stocks", opacity = 0.7)
