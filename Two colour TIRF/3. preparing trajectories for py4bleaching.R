library(tidyverse)
library(tidylog)

# This code follows along from "1. compiling data and colocalisation analysis.R". We need to modify the trajectory data so that it
# is in an appropriate format to go into the py4bleaching analysis module. 

# This involves adding each molecule's unique identifier (that was made in the previous step of analysis) to the name of the 
# trajectory. Also it needs to have the molecule's X and Y co-ordinates to the name of the trajectory as well so that it can
# be further tracked.

# The trajectories need to be moved from the vorg (external network) folder to the local folder

# setting initial directories ---------------------------------------------

# experiment_date is how I would delineate the different independent experiments (as they were done on different days)

experiment_date <- "20260305"

# vorg_folder is the folder on an external drive that stored all of my raw images (where the ImageJ Fiji results files were also stored)

vorg_folder <- file.path("Z:", "Chaperone_subgroup", "NicolaA", "Fluc complexes", paste0(experiment_date))

vorg_folder

# I want to run the rest of the analysis on my actual computer hard-drive, hence the "local folder"

local_folder <- file.path("C:", "Nicola", "UNIVERSITY", "PhD", "SM", "Fluc", paste0(experiment_date, "_TWO_COLOUR"))
print(local_folder)
setwd(local_folder)

# Now we are loading up where the trajectory files live from "2. moving the trajectory files to local folder.R"
# this needs to be the folder ABOVE the folders that have "coloc" and "non-coloc" if that makes sense cause we are going to do each individually

# This path must also end in a /
path_to_files_client <- "C:/Nicola/UNIVERSITY/PhD/SM/Fluc/20260305_TWO_COLOUR/imagejresults-ATTO532/client/30min-complexes/"


path_to_files_hsp <- "C:/Nicola/UNIVERSITY/PhD/SM/Fluc/20260305_TWO_COLOUR/imagejresults-647/hsp/30min-complexes/"

# needs to be changed each time

# Loading up data from previous scripts -----------------------------------

all_clients_results <- read.csv(file = file.path(local_folder, "full_data", "all_clients_results.csv"))

all_hsp_results <- read.csv(file = file.path(local_folder, "full_data", "all_hsp_results.csv"))

# client molecules --------------------------------------------------------

# We are interested in the molecule ID and the coordinates of each molecule so here I am combining those two 
# pieces of information into something called the "Traj_ID" which will be the unique identifier for each trajectory

all_clients_results <- all_clients_results %>% 
  filter(Treatment_name =="30min_complexes") %>%
  mutate(Traj_ID = paste(molecule_ID, X, Y, sep = "_"))
all_hsp_results <- all_hsp_results %>% 
  filter(Treatment_name =="30min_complexes") %>%
  mutate(Traj_ID = paste(molecule_ID, X, Y, sep = "_")) 

vector_of_unique_image_treatments <- rep(unique(all_hsp_results$treatment_image),2)
print(vector_of_unique_image_treatments)


# Combine into a dataframe
extracted_info <- tibble(original = unique(vector_of_unique_image_treatments)) %>%
  separate(original, into = c("Treatment_name", "image_number"), sep = "-") %>%
  mutate(image_number = gsub("#", "", image_number)) %>%
  mutate(image_number = as.integer(image_number))

extracted_info_extended <- extracted_info %>%
  mutate(coloc = "coloc") %>%       # first copy with "coloc"
  bind_rows(
    extracted_info %>% mutate(coloc = "non-coloc")  # second copy with "non-coloc"
  )

print(extracted_info_extended)

# this needs to be whatever is before the numbered bit of the files
client_file_name <- "flucaBc3D_"

extracted_info_extended <- extracted_info_extended %>% mutate(full_name = paste0(client_file_name, coloc, image_number))

print(extracted_info_extended)



# for client files (488 labelled)

for (i in 1:nrow(extracted_info_extended)){
  
  # This is where you need to be careful about the paths of where the different trajectories are stored
  
  
  if (extracted_info_extended$coloc[i] == "coloc"){
    coloc_var <- "Yes"
  } else{coloc_var <- "No"}
  
  all_clients_current_treatment_image <- all_clients_results %>% filter(treatment_image == vector_of_unique_image_treatments[i] & coloc == coloc_var)
  
  
  csv_name <- paste0(path_to_files_client, extracted_info_extended$coloc[i], "/", extracted_info_extended$full_name[i], ".csv")
  print(csv_name)
  current_trajectories <- read.csv(csv_name)
  
  original_names <- colnames(current_trajectories)
  
  
  extra_info <- as.data.frame(all_clients_current_treatment_image$Traj_ID) 
  
  if (coloc_var == "Yes"){
    new_names <- original_names
    
    # Leave the first two names blank, then append info from extra_info to the remaining names
    new_names[1] <- ""
    #new_names[2] <- ""
    
    for (j in 2:length(original_names)) {
      new_names[j] <- paste0(original_names[j], "_", extra_info[j-1,1])
    }
    
    print(new_names)
    # Apply the new names to the dataframe
    colnames(current_trajectories) <- new_names
    
    # Check the new names to make sure it worked
    print(colnames(current_trajectories))
    
    write.csv(current_trajectories, file = csv_name, row.names = FALSE)
  }
  
  if (coloc_var == "No"){
    new_names <- original_names
    
    # Leave the first two names blank, then append info from extra_info to the remaining names
    new_names[1] <- ""
    #new_names[2] <- ""
    
    for (j in 2:length(original_names)) {
      new_names[j] <- paste0(original_names[j], "_", extra_info[j-1,1])
    }
    
    print(new_names)
    # Apply the new names to the dataframe
    colnames(current_trajectories) <- new_names
    
    # Check the new names to make sure it worked
    print(colnames(current_trajectories))
    
    write.csv(current_trajectories, file = csv_name, row.names = FALSE)
    
  }
  
}


# sHsp molecules ----------------------------------------------------------

# now we need to do the same thing for the hsp files (647 labelled)

# There is an additional issue here which is that the hsps are going to be out of order as they are read into the imageJ ROI in order of their colocalised client (if they are colocalised)

# BUT they are in order inside the "all_clients_results" dataframe so we can get the correct order from here and then reorder them to be correct

# There is no issue with the non-colocalised trajectories as they are already in the correct order


hsp_file_name <- "flucaBc3D_"

extracted_info_extended <- extracted_info_extended %>% mutate(full_name_hsp = paste0(hsp_file_name, coloc, image_number))

print(extracted_info_extended)

for (i in 1:nrow(extracted_info_extended)){
  
  # This is where you need to be careful about the paths of where the different trajectories are stored
  
  if (extracted_info_extended$coloc[i] == "coloc"){
    coloc_var <- "Yes"
  } else{coloc_var <- "No"}
  
  
  all_hsps_current_treatment_image <- all_hsp_results %>% filter(treatment_image == vector_of_unique_image_treatments[i] & coloc == coloc_var)
  
  csv_name <- paste0(path_to_files_hsp, extracted_info_extended$coloc[i], "/", extracted_info_extended$full_name_hsp[i], ".csv")
  print(csv_name)
  current_trajectories <- read.csv(csv_name)
  
  original_names <- colnames(current_trajectories)
  
  
  extra_info <- as.data.frame(all_hsps_current_treatment_image$Traj_ID)  
  
  if (coloc_var == "Yes"){
    
    all_hsps_from_client_coloc <- all_clients_results %>% filter(treatment_image == vector_of_unique_image_treatments[i] & coloc == coloc_var)
    
    mol_ID_correct_order <- all_hsps_from_client_coloc$coloc_molecule_ID
    print(mol_ID_correct_order)
    
    all_hsps_current_treatment_image_reordered <- all_hsps_current_treatment_image %>%
      mutate(molecule_ID = factor(molecule_ID, levels = mol_ID_correct_order)) %>%
      arrange(molecule_ID)
    
    extra_info_reordered <- as.data.frame(all_hsps_current_treatment_image_reordered$Traj_ID)
    
    new_names <- original_names
    
    # Leave the first two names blank, then append info from extra_info to the remaining names
    new_names[1] <- ""
    #new_names[2] <- ""
    
    for (j in 2:length(original_names)) {
      new_names[j] <- paste0(original_names[j], "_", extra_info_reordered[j-1,1])
    }
    
    print(new_names)
    # Apply the new names to the dataframe
    colnames(current_trajectories) <- new_names
    
    # Check the new names to make sure it worked
    print(colnames(current_trajectories))
    
    write.csv(current_trajectories, file = csv_name, row.names = FALSE)
  }
  
  if (coloc_var == "No"){
    new_names <- original_names
    
    # Leave the first two names blank, then append info from extra_info to the remaining names
    new_names[1] <- ""
    #new_names[2] <- ""
    
    for (j in 2:length(original_names)) {
      new_names[j] <- paste0(original_names[j], "_", extra_info[j-1,1])
    }
    
    print(new_names)
    # Apply the new names to the dataframe
    colnames(current_trajectories) <- new_names
    
    # Check the new names to make sure it worked
    print(colnames(current_trajectories))
    
    write.csv(current_trajectories, file = csv_name, row.names = FALSE)
  }
  
}


# End ---------------------------------------------------------------------

rm(list = ls()) #clears environment
dev.off()  # clears plots
cat("\014")  # ctrl+L clears console