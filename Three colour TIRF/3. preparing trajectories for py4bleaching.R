# This code follows along from "1. compiling data and colocalisation analysis.R" and 
# "2. moving the trajectory files to local folder". We need to modify the trajectory data 
# so that it is in an appropriate format to go into the py4bleaching analysis module. 

# This involves adding each molecule's unique identifier (that was made in the previous step of analysis) to the name of the 
# trajectory. Also it needs to have the molecule's X and Y co-ordinates to the name of the trajectory as well so that it can
# be further tracked.

# The trajectories need to be moved from the vorg (external network) folder to the local folder

library(tidyverse)
library(tidylog)


# setting up initial directories -----------------------------------------

experiment_date <- "20260212_THREE_COLOUR"

# This is an external folder where I store the images and the results of the ImageJ analysis
# Insert your own folder where those things live here
vorg_folder <- file.path("Z:", "Chaperone_subgroup", "NicolaA", "Fluc complexes", paste0("20260212"))
print(vorg_folder)

# I do the rest of the analysis on my actual computer in this "local_folder"
local_folder <- file.path("C:", "Nicola", "UNIVERSITY", "PhD", "SM", "Fluc", experiment_date)
print(local_folder)
setwd(local_folder)

# THis is the path to the client files that we moved using "2. moving the trajectory files to local folder"
# This path must also end in a / and is hard coded into 
path_to_files_client <- "C:/Nicola/UNIVERSITY/PhD/SM/Fluc/20260212_THREE_COLOUR/imagejresults-555/555/"
# now we need to do the same thing for the sHsp files (647 labelled)
path_to_files_sHsp <- "C:/Nicola/UNIVERSITY/PhD/SM/Fluc/20260212_THREE_COLOUR/imagejresults-647/647/"
# now we need to do the Hsp70
path_to_files_Hsp70 <- "C:/Nicola/UNIVERSITY/PhD/SM/Fluc/20260212_THREE_COLOUR/imagejresults-488/488/"

# Loading up data from previous script ------------------------------------


all_clients_results <- read.csv(file = file.path(local_folder, "full_data","all_clients_results_coloc.csv"))

all_sHsp_results <- read.csv(file = file.path(local_folder, "full_data","all_sHsp_results_coloc.csv"))

all_Hsp70_results <- read.csv(file = file.path(local_folder, "full_data","all_Hsp70_results_coloc.csv"))


# Extracting relevant molecule information --------------------------------

# We are interested in the molecule ID and the coordinates of each molecule so here I am combining those two 
# pieces of information into something called the "Traj_ID" which will be the unique identifier for each trajectory

all_clients_results <- all_clients_results %>% mutate(Traj_ID = paste(molecule_ID, X, Y, sep = "_"))
all_sHsp_results <- all_sHsp_results %>% mutate(Traj_ID = paste(molecule_ID, X, Y, sep = "_")) 
all_Hsp70_results <- all_Hsp70_results %>% mutate(Traj_ID = paste(molecule_ID, X, Y, sep = "_")) 

vector_of_unique_image_treatments <- rep(unique(all_sHsp_results$treatment_image),2)
print(vector_of_unique_image_treatments)

# Combine into a dataframe
extracted_info <- tibble(original = unique(vector_of_unique_image_treatments)) %>%
  separate(original, into = c("Treatment_name", "image_number"), sep = "-") %>%
  mutate(image_number = gsub("#", "", image_number)) %>%
  mutate(image_number = as.integer(image_number))

extracted_info_extended <- extracted_info

print(extracted_info_extended)

# In order to find the files we need to make sure that we are matching up the proteins and their colours so that 
# we can give them the correct trajectory information

client_file_name <- "green3colour_all"
sHsp_file_name <- "red3colour_all"
Hsp70_file_name <- "blue3colour_all"

# Doing client first
extracted_info_extended <- extracted_info_extended %>% mutate(full_name = paste0(client_file_name, image_number))
print(extracted_info_extended)

# for client files (488 labelled)

for (i in 1:nrow(extracted_info_extended)){
  
  # This is where you need to be careful about the paths of where the different trajectories are stored
  
  all_clients_current_treatment_image <- all_clients_results %>% filter(treatment_image == vector_of_unique_image_treatments[i])
  
  csv_name <- paste0(path_to_files_client, extracted_info_extended$Treatment_name[i], "/client/", extracted_info_extended$full_name[i], ".csv")
  print(csv_name)
  current_trajectories <- read.csv(csv_name)
  
  original_names <- colnames(current_trajectories)
  
  extra_info <- as.data.frame(all_clients_current_treatment_image$Traj_ID) 
  
  new_names <- original_names
  
  # Leave the first two names blank, then append info from extra_info to the remaining names
  new_names[1] <- ""
  #new_names[2] <- ""
  
  for (j in 2:length(original_names)) {
    new_names[j] <- paste0(original_names[j], "_", extra_info[j-1,1])
  }
  
  #print(new_names)
  # Apply the new names to the dataframe
  colnames(current_trajectories) <- new_names
  
  # Check the new names to ensure the operation was successful
  print(colnames(current_trajectories))
  
  write.csv(current_trajectories, file = csv_name, row.names = FALSE)
  
}


# needs to be changed each time

sHsp_file_name <- "red3colour_all"

extracted_info_extended <- extracted_info_extended %>% mutate(full_name = paste0(sHsp_file_name, image_number))

print(extracted_info_extended)

for (i in 1:nrow(extracted_info_extended)){
  
  # This is where you need to be careful about the paths of where the different trajectories are stored
  
  all_sHsps_current_treatment_image <- all_sHsp_results %>% filter(treatment_image == vector_of_unique_image_treatments[i])
  
  #all_Hsps_current_treatment <- all_Hsps_df %>% filter(Image_treatment == extracted_info$original_entry[i])
  
  csv_name <- paste0(path_to_files_sHsp, extracted_info_extended$Treatment_name[i], "/sHsp/", extracted_info_extended$full_name[i], ".csv")
  print(csv_name)
  current_trajectories <- read.csv(csv_name)
  
  original_names <- colnames(current_trajectories)
  
  extra_info <- as.data.frame(all_sHsps_current_treatment_image$Traj_ID)  # Fill this with actual data
  
  new_names <- original_names
  
  # Leave the first two names blank, then append info from extra_info to the remaining names
  new_names[1] <- ""
  #new_names[2] <- ""
  
  for (j in 2:length(original_names)) {
    new_names[j] <- paste0(original_names[j], "_", extra_info[j-1,1])
  }
  
  #print(new_names)
  # Apply the new names to the dataframe
  colnames(current_trajectories) <- new_names
  
  # Check the new names to ensure the operation was successful
  print(colnames(current_trajectories))
  
  write.csv(current_trajectories, file = csv_name, row.names = FALSE)
  
}

# needs to be changed each time

Hsp70_file_name <- "blue3colour_all"

extracted_info_extended <- extracted_info_extended %>% mutate(full_name = paste0(Hsp70_file_name, image_number))

print(extracted_info_extended)

for (i in 1:nrow(extracted_info_extended)){
  
  # This is where you need to be careful about the paths of where the different trajectories are stored
  
  all_Hsp70s_current_treatment_image <- all_Hsp70_results %>% filter(treatment_image == vector_of_unique_image_treatments[i])
  
  #all_Hsps_current_treatment <- all_Hsps_df %>% filter(Image_treatment == extracted_info$original_entry[i])
  
  csv_name <- paste0(path_to_files_Hsp70, extracted_info_extended$Treatment_name[i], "/Hsp70/", extracted_info_extended$full_name[i], ".csv")
  print(csv_name)
  current_trajectories <- read.csv(csv_name)
  
  original_names <- colnames(current_trajectories)
  
  extra_info <- as.data.frame(all_Hsp70s_current_treatment_image$Traj_ID)  # Fill this with actual data
  
  new_names <- original_names
  
  # Leave the first two names blank, then append info from extra_info to the remaining names
  new_names[1] <- ""
  #new_names[2] <- ""
  
  for (j in 2:length(original_names)) {
    new_names[j] <- paste0(original_names[j], "_", extra_info[j-1,1])
  }
  
  #print(new_names)
  # Apply the new names to the dataframe
  colnames(current_trajectories) <- new_names
  
  # Check the new names to ensure the operation was successful
  print(colnames(current_trajectories))
  
  write.csv(current_trajectories, file = csv_name, row.names = FALSE)
  
}

# REMEMBER that you need to change the folder names to have no "_" before running in py4bleaching or it will ERROR
# You are now ready to run py4bleaching from the local_folder. 
# REMEMBER that py4bleaching must be run separately for each of the different fluorophores and separately on  
# different treatments if the laser power as different between them
