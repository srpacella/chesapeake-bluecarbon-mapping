################################################################################
# COVARIATE MATRIX CREATION

# This code was developed by Mario Guevara, Viviana Varón, Carlos E. Arroyo-Cruz
################################################################################


#### Step 0: Loading Rgee correctly
# If running this script for the first time, remember to load Rgee correctly using the specified miniconda virtual environment path. If it is already loaded you can skip this step.

# Load the correct python version
reticulate::use_python("C:\\Users\\adhond\\AppData\\Local\\r-miniconda\\envs\\rgee/python.exe",
                       required = TRUE) # Replace the example path above with your one
# Initialize python
reticulate::py_config()

#### Step 1: Load packages, set up directory, load Rgee and connect to Earth Engine

# Load packages
library(raster) # geospatial data
library(stars) # geospatial data
library(rgee) # rgee
library(terra) # geospatial data
library(sf) # geospatial data
library(tidyverse) # data manipulation
library(googledrive) # for interfacing with Google Drive
library(geojsonio)
library(future)

# Set directory
setwd("C:\\Users\\spacella\\OneDrive - Environmental Protection Agency (EPA)\\SDR Blue Carbon\\Dhond Files\\Blue Carbon Modeling Project") # change for your project

# Initialize earth engine
ee_Initialize(user = 'ee-srpacella', drive = TRUE)
#ee_Initialize(project='ee-srpacella')

#### Step 2: Create an area of interest (AOI) based on the Chesapeake Bay watershed shape file.

# This AOI needs to have the correct CRS that we are using (WGS84)

# Create a vector with the AOI extent
v <- vect("WBD_HU8_WGS84_export_Chesapeake.shp") #Edited 10/24/24 by SRP to use new shapefile created by Nate Lewis
v

# Project vector to target CRS (WGS84)
ex <- project( ext(v), from=crs(v), to="+proj=merc +a=6378137 +b=6356752.314245 +lat_ts=0 +lon_0=0 +x_0=0 +y_0=0 +k=1 +units=m +nadgrids=@null +wktext +no_defs")
ex

# Create a reference raster as a base reference for the spatial harmonization process. Ensure the correct CRS.
ref <- rast( crs=crs(ex), extent=ext(ex), resolution=30, vals=1)
crs(ref) <- "+proj=merc +a=6378137 +b=6356752.314245 +lat_ts=0 +lon_0=0 +x_0=0 +y_0=0 +k=1 +units=m +nadgrids=@null +wktext +no_defs"

# If you want to see what this raster looks like, use the following (not necessary:
#writeRaster(ref, "ref.tif")

#### Step 3: Create a loop to download the USGS DEM (will need to replace with CoNED) and the Sentinel-2 Data from GEE

# This loop reads the shapefile, creates subfolders for each subwatershed (29 total), clips the DEM and Sentinel-2 data by that sub-watershed outline and then returns a raster .tif file for the DEM and a raster .tif file for the Sentinel data.
# There are 29 sub-watersheds 
for(i in 1:29){
  
  ee_roi <- st_read("WBD_HU8_WGS84_export_Chesapeake.shp")[i, ] ## read it separately to take the name for the folder - this is the Chesapeake Bay Watershed boundary
  
  # Results folder creation, change ChesTiles/ to your own working directory
  if( !dir.exists(paste0("TestTiles_241024/", ee_roi$name ) ) ){
    dir.create( paste0("TestTiles_241024/", ee_roi$name ) )
  }
  
  fn <- paste0("TestTiles_241024/", ee_roi$name, "/", ee_roi$name, ".tif") # file name template  
  
  if( !file.exists(fn) ){ ### if sentence to run only on missing sub watersheds
    cat("\nPROCESSING ", fn)
    
    ### create GEE geometry object
    ee_roi <- ee_roi %>%
      st_geometry() %>%
      sf_as_ee()
    
    
    ############################################################
    ############################## USGS DEM 
    ############################################################
    
    
    dataset = ee$Image('USGS/3DEP/10m')$clip(ee_roi)
    #dataset = ee$ImageCollection('USGS/3DEP/1m')$mean()$clip(ee_roi) ## it has holes
    
    ee_raster <- ee_as_rast(
      image = dataset, # image or image collection to extract data from
      #region = ee_roi, # el bbox of geometry/feature/featureCollection (not nedded in this case)
      #dsn = fn,
      scale = 30,
      maxPixels = 1e+13,
      via = "drive"
    )
    
    ############################################################
    ############################## sentinel
    ############################################################
    
    ## mcloud removing function 
    maskS2clouds <- function(image) {
      qa = image$select('QA60')
      
      #Both flags should be set to zero, indicating clear conditions.
      mask = qa$bitwiseAnd(1024)$eq(0)$And(qa$bitwiseAnd(2048)$eq(0)) 
      
      return( 
        image$updateMask(mask)$divide(10000)$select(c("B1","B2","B3","B4","B5","B6","B7","B8","B8A","B9","B11","B12"))
      )
      
    }
    
    dataset = ee$ImageCollection('COPERNICUS/S2_SR_HARMONIZED')$
      #filterDate('2023-01-01', '2023-12-31')$filter(ee$Filter$lt('CLOUDY_PIXEL_PERCENTAGE',20))$map(maskS2clouds)$mean()$clip(ee_roi)
      filterDate('2017-01-01', '2023-12-31')$filter(ee$Filter$lt('CLOUDY_PIXEL_PERCENTAGE',20))$map(maskS2clouds)$mean()$clip(ee_roi) #Expand this from 2015-Present
    
    senSR <- ee_as_rast(
      image = dataset, 
      #region = ee_roi, 
      #dsn = "Middle Potomac-Catoctin/Sentinel.tif",
      scale =30,
      via = "drive"
    )
    
    #project DEM to reference raster copying its properties (crs, resolution, extent)	
    res<-project(ee_raster, ref, method="cubic" )	
    writeRaster(res, fn )# save the results
    
    # project sentinel bands to harmonized DEM 
    res2<- project( senSR, res, method="cubic")
    #res2
    writeRaster(res2, gsub(".tif","_Sentinel.tif", fn) ) # save the results (we add the _Sentinel flag)
    
    #remove temp files from R memory 
    rm(ee_roi, ee_raster, senSR, res, res2)
    gc()
    
    # remove files from drive (need to work around this as we are unable to remove files this way.)
    # file.remove(list.files("yourDriveFolderWhereEverithingIsBeingSaved/rgee_backup", full.names=T))
    
    
  }else{#what to do if the watershed is already downloaded 
    cat("\n", fn, "ALREADY DONE")
  }
  
}## end for


#### Step 4: Clip the rasters to reduce file size (optional but recommended by Carlos)
###### to avoid any loss of information on the borders, I just play a little with the data type....
###### remember to do this before calculating the terrain properties 

# Set working directory
#setwd("/Users/CEAC/Library/CloudStorage/GoogleDrive-dreamwalker7777gm@gmail.com/Mi unidad/Colaboraciones/Chesapeack/Tiles2")
setwd("C:\\Users\\spacella\\OneDrive - Environmental Protection Agency (EPA)\\SDR Blue Carbon\\Dhond Files\\Blue Carbon Modeling Project\\TestTiles_241024")

# Select the files based on the tif format
f<-list.files(pattern = ".tif$", recursive=T, full.names = T) # select files
f<-f[!grepl("_Sentinel.tif", f)] # filter out the sentinel files
f # check files

# Create a for loop that takes the raster file, creates a raster dataframe, clips it, replaces it with the clipped version and saves as "_clip"
for(i in 1:length(f)){
  
  # r<-rast(f[i])
  # r<-as.data.frame(r, xy=T)
  # r<-rast(r, type="xyz")
  # writeRaster(r, gsub(".tif","_clip.tif", f[i]) )
  # rm(r)
  # gc()
  # Sys.sleep(30) #Pause 10 seconds before moving through the loop #Mario suggests try to remove everything
  # New suggested code from Carlos 7/24/24
  r<-rast(f[i])
  r<-trim(r)
  writeRaster(r, gsub(".tif","_clip.tif", f[i]) )
  rm(r)
  gc()
  
  
}


