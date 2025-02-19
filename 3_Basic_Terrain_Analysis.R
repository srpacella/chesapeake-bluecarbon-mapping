###############################################################################
# BASIC TERRAIN ANALYSIS USING R SAGA


# This code was developed by Mario Guevara, Viviana Varón, Carlos E. Arroyo-Cruz
########################################################

#### Step 1: Load packages and set working directory

# Load packages
library(raster) # geospatial data
library(RSAGA) # R saga interface
library(terra) # geospatial data

# Set working directory (set to where the sub-watershed folders are located, change for your own directory)
setwd("C:/Users/spacella/OneDrive - Environmental Protection Agency (EPA)/SDR Blue Carbon/Dhond Files/Blue Carbon Modeling Project/TestTiles_241024")

#### Step 2: Select the DEM Files to undergo terrain analysis

# Set up the SAGA environment and ensure that SAGA is installed
envi = rsaga.env(path = "C:/Program Files/SAGA") # pointing to where saga is installed
rsaga.get.version(env = envi) # checking the saga version that is installed

# # Read in the DEMs. This code uses the clipped version, but if there is a different file name structure replace the "_clip" to match it.
files<-list.files(pattern=".tif$", recursive=T, full.names=T) # create a list of files with the .tif ending
files<-files[grepl("_clip", files)] # subset these files to only select the "clipped" version
files # take a look at the files

# #If you don't clip you can use the following code to do it:
# ## read DEMS
# files<-list.files(pattern=".tif$", recursive=T, full.names=T)
# ## only choose the tifs and exclude the sentinel ones (We only want DEM files here)
# files <- files[!grepl("_Sentinel.tif$", files)]
# files

#useful functions to find a tools and to know how to use them
rsaga.get.libraries()
rsaga.get.modules("ta_compound")
rsaga.get.usage("ta_compound", 0)

#### Step 3: Create a for loop that iterates through each subwatershed folder and calculates terrain parameters.

# In this case, we are calculating the following 14 terrain parameters from the DEM:
# Slope, Aspect, Curvature, Multiresolution index of valley bottom flatness (MRVBF), Multiresolution index of the ridge top flatness (MRRTF),
# Catchment area, catchment slope, module catchment area, topographic wetness index (TWI), Ls factor, channel base, channel distance, valley depth, and relative slope position.

# Create the loop. Iterate through all of the subwatershed files. For each file calculate the terrain parameter and save it as a new file with the
# file name structure as "_parameter.tif". 
# Once this code is finished running, there should be 14 new files with the terrain parameters in each sub-watershed folder
for(i in 1:length(files)){
  
  
  # # Fill raster (USGS DEM is a very weird one it gets all messed up when I try to filled it, need more thought/research) 
  # rsaga.geoprocessor("ta_preprocessor", 3, list(
  #   DEM= files[i],
  #   RESULT= gsub("_clip.tif","_Fill.tif",files[i]) )
  # )
  # 
  
  # basic morphometry
  rsaga.geoprocessor("ta_morphometry", 0, list(
    ELEVATION= files[i], # gsub(".tif","_Fill.tif",files[i]),
    SLOPE=gsub("_clip.tif","_Slope.tif",files[i]),
    ASPECT=gsub("_clip.tif","_Aspect.tif",files[i]),
    C_GENE=gsub("_clip.tif","_Curv.tif",files[i]),
    METHOD=8,
    UNIT_SLOPE="degree",
    UNIT_ASPECT="degree"
    
  )
  )
  
  # morphometry indexes
  rsaga.geoprocessor("ta_morphometry", 8, list(
    DEM= files[i], 
    MRVBF=gsub("_clip.tif","_MRVBF.tif",files[i]),
    MRRTF=gsub("_clip.tif","_MRRTF.tif",files[i])
    
  )
  )
  
  
  # basic hydrology
  rsaga.geoprocessor("ta_hydrology", 15, list(
    DEM= files[i], 
    AREA=gsub("_clip.tif","_CatchArea.tif",files[i]),
    SLOPE=gsub("_clip.tif","_CatchSlope.tif",files[i]),
    AREA_MOD=gsub("_clip.tif","_ModCatchArea.tif",files[i]),
    TWI=gsub("_clip.tif","_TWI.tif",files[i])
    
  )
  )
  
  
  # basic hydrology part 2
  rsaga.geoprocessor("ta_hydrology", 22, list(
    SLOPE= gsub("_clip.tif","_Slope.tif",files[i]), 
    AREA=gsub("_clip.tif","_CatchArea.tif",files[i]),
    LS=gsub("_clip.tif","_LsFactor.tif",files[i]) ### ls factor creates holes we decide later if we will use it or not... 
    
  )
  )
  
  
  # extra properties
  rsaga.geoprocessor("ta_compound", 0, list(
    ELEVATION= files[i],
    CHNL_BASE= gsub("_clip.tif","_ChNetBaseLev.tif",files[i]),    	   
    CHNL_DIST= gsub("_clip.tif","_ChNetDist.tif",files[i]),  	  
    VALL_DEPTH= gsub("_clip.tif","_ValleyDepth.tif",files[i]),   
    RSP= gsub("_clip.tif","_RelSlopePos.tif",files[i]) 	  
    
  ))
  
  
  
  
}## end for loop


