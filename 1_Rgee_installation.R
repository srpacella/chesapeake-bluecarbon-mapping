###############################################
# RGEE INSTALLATION

# This code was developed by Mario Guevara, Viviana Varón, Carlos E. Arroyo-Cruz
###############################################

#### Step 1: Install necessary dependencies/packages

install.packages("sf") # Simple features, for spatial vector data
install.packages("reticulate") # Interface to Python
install.packages("remotes") # Allows installation from remote repositories (not on CRAN)

#### Step 2: Install the rgee package from the r-spatial repository on GitHub

# The link to the GitHub repository is here: https://github.com/r-spatial/rgee

# Install package using remotes
remotes::install_github("r-spatial/rgee", force = TRUE)

#### Step 3: Load the required packages 
 
library(reticulate) # python interface
library(rgee) # rgee

#### Step 4: Check version of Python and install miniconda if necessary

# Because rgee is somewhat deprecated, we need to create a virtual python environment based on the version of python that works with rgee. The below steps create a virtual environment.
# We will likely need to play around/check many settings to see what versions we have for each program.

# Check version of python - it may or may not initialize a python connection based on if you have python installed on your computer.
py_discover_config()

# If asked, select the option "Y" to install miniconda

# If you DO NOT have miniconda and it does not give you a prompt to install it, you can install miniconda manually using the following code:
install_miniconda(path = miniconda_path(), update = TRUE, force = FALSE)

# Once miniconda has been installed, check the path
miniconda_path()

# Then, check the current path of the python installation.
import("sys")$executable

# Now we are going to create a virtual python environment with all rgee dependencies. Save the path to a notepad as we will use this for future code.
ee_install()

# When finished, enter "1" in the console to restart the R session.

#### Step 5: Restart computer and restart R.

# Remember to save the notepad with the path to the python environment

# For example, my path looks like "C:\\Users\\adhond\\AppData\\Local\\r-miniconda\\envs\\rgee/python.exe" or 
# "C:\Users\adhond\AppData\Local\r-miniconda\envs\rgee/python.exe"

################################################################################

#### Step 6: Open R and run these two lines.

# Once you have restarted your computer, open this R file and DO NOT LOAD ANYTHING ELSE. Just run the two lines one after the other

# First, select the version of python that we will use. The path should be the one within r-miniconda.
reticulate::use_python("C:\\Users\\spacella\\AppData\\Local\\r-miniconda\\envs\\rgee//python.exe",
                       required = TRUE) 
# Replace the example path above with the one you had in the notepad, note that the path, in windows, must be separated by "\\" or "/" 

# Then, initialize python
reticulate::py_config() 

# The steps above are taken to ensure that the correct version of python is loaded. Sometimes, if you load the "Reticulate" package first, it will select a different version of Python that we do not want.

#### Step 7: Attempt to load and connect to Google Earth Engine Servers

# load rgee
library(rgee)

# Clean user credentials to ensure there is nothing already loaded on your computer.
ee_clean_user_credentials("srpacella@gmail.com") # insert your own GEE account credentials

# # Initialize Google Earth Engine. This step will open a browser window, follow all instructions to obtain a token. Then copy and paste the token into R.
# ee_Initialize()

ee$Authenticate(auth_mode='notebook')
ee$Initialize(project='ee-srpacella')  # <-- EDIT THIS FOR YOUR PROJECT


# Print a simple message to the console to verify installation. 
ee$String('Hello World!')$getInfo()


#### TROUBLESHOOTING

# There might be some issues with loading RGEE based on your computer and python environment at Step 7. I found that the following code also works too.


# Step 7 (troubleshooting). Only run this part if step 7 above doesnt work.

# Import rgee.
library(rgee)

# Attempt to authenticate. If credentials are found, nothing will happen except a return of TRUE. If credentials are not found, it'll take you through an auth
# flow and save the credentials. If you want to force reauthentication, include
# `force=TRUE` in the call. This is generally a one-time setup step.
ee$Authenticate(auth_mode='notebook')

# Initialize - this will connect to a project. You should always call this
# before working with rgee. It is IMPORTANT THAT YOU SPECIFY A PROJECT using
# the project parameter. If you forget what project IDs you have access to, find them
# here: console.cloud.google.com/project
ee$Initialize(project='ee-srpacella')  # <-- EDIT THIS FOR YOUR PROJECT

# Optionally make a request to verify you are connected.
ee$String('Hello from the Earth Engine servers!')$getInfo()