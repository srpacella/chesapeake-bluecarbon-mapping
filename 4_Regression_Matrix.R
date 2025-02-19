################################################################################
# REGRESSION MATRIX GENERATION

# This code was developed by Mario Guevara, Viviana Varón, Carlos E. Arroyo-Cruz
################################################################################


#### Step 1: Install packages, set working directory, set up data

# Install packages
library(terra) # geospatial data

# Set working directory to the folder of the sub watersheds
#setwd("C:/Users/adhond/OneDrive - Environmental Protection Agency (EPA)/Profile/Desktop/EPA ORISE WORK/3_Blue Carbon Modeling/ChesTiles")
setwd("C:/Users/spacella/OneDrive - Environmental Protection Agency (EPA)/SDR Blue Carbon/Dhond Files/Blue Carbon Modeling Project/TestTiles_241024")

# Load carbon stock points that have been projected to web Mercator (auxiliary sphere)
#samples <- vect("cb_latlong_pts_wgs_webmerc.shp") # load and save shape file; This needs to be updated with locations of cores from database
#samples <- vect("072524_CBLatLong_SoilModel1.shp") # load and save shape file; This needs to be updated with locations of cores from database
samples <- vect("7-31-24_SOC_WebMer.shp") # load and save shape file; This needs to be updated with locations of cores from database
samples$ID<-1:dim(samples)[1]
samples<-samples[, c("ID", "SurfaceCar")]
plot(samples) # plot it
crs(samples) # check Coordinate Reference system

####### Need to project the points
samples <- project(samples,"+proj=merc +a=6378137 +b=6356752.314245 +lat_ts=0 +lon_0=0 +x_0=0 +y_0=0 +k=1 +units=m +nadgrids=@null +wktext +no_defs")


# Create an empty data frame to store results
result<- data.frame() 
result

# Save the entire watersheds folder
dirs <- list.dirs(full.names = F, recursive = F)

#### Step 2: Create a for loop that iterates through the sub watersheds folders.
# set all the CRS the same, remove unused variables, stack all rasters on top of one another, combine into a dataframe

# Create the for loop
for(i in 1:length(dirs)){
#for(i in 49)){
  
  # Create a temporary object to use as a template for the extraction.
  result.tmp <- samples
  #result.tmp
  
  # Select rasters saved in the ith folder (rasters in a single sub watershed folder)
  f <- list.files(dirs[i], pattern=".tif$", recursive=T, full.names=T)
  #f
  
  # Remove layers with no matching extent (remove the original DEM file and the Sentinel file)
  #s<-rast(f[-c(13, 17)]) ### change this if the file structure is different/if we decide not to use some of the covariates we extracted.
  s<-rast(f[-c(1, 14)]) ### change this if the file structure is different/if we decide not to use some of the covariates we extracted.
  #s
  
  # Ensure the CRS is the same
  crs(s)<-crs(samples)
  
  # Remove the name of the watershed from the band name 
  names(s)[grepl( "_", names(s) ) ]<- sapply(names(s)[grepl( "_", names(s) ) ], function(x){ x=strsplit(x, "_")[[1]][2]   })
  #plot(s)
  
  # Extract information from the stack to the samples
  ov<-terra::extract(s, result.tmp, ID=F)
  #str(ov)
  
  # Combine the columns together and remove NAs
  tmp<-cbind(result.tmp, ov)
  tmp <-tmp[!is.na(tmp$elevation),] ## remove NA data using the DEM as mandatory property
  #str(tmp)
  
  ## check is there is any data on the extracted data frame	
  if(  dim(tmp)[1]>=1  ){
    
    r<-rast(f[14])## sentinel SR
    r
    
    ov<-terra::extract(r, tmp, ID=F) # extract sentinel to resulting samples
    str(ov)
    tmp<-cbind(tmp, ov)
    
    
    result<-rbind(result, values(tmp)) ## combine and save rows of sub watershed extraction on the result data frame 
    
  }
  
  
  rm(tmp, result.tmp, s, f, ov)# remove temp objects
  
}# end for

#### Step 3: Check the results and save them

# Check and order results (does not work for SRP - error in the sort)
summary(result)
#result <- result[order(result$field_1),] # ordering results
head(result)

# Save results as a CSV file to disk
#save results to disk 
write.table(result, "C:/Users/spacella/OneDrive - Environmental Protection Agency (EPA)/SDR Blue Carbon/Dhond Files/Blue Carbon Modeling Project/TestTiles_241024/DataModel.csv", 
            sep=",", col.names=T, row.names=F) # change for your own directory
