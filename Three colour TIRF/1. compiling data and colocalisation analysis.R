# This code is used to compile the data from the ImageJ Fiji macro called "Three_colour_Client_Hsp_colocalisation_trajectories_w_scramble.ijm" from the images and quantifying the level of colocalisation

# It also gives each molecule a unique identifier that (along with its location) I can append to the trajectory name before I put it into py4bleaching

# For this we need to import for each treatment the compiled hsps, colocalised dataframes and then lastly the trajectories.

# The files from the ImageJ analysis should be generated and should follow a folder path like so:
# experiment_date/treatment/subfolder/AF647_photobleach

# File structure expected by this code:
#
# vorg_folder/
# └── <treatment>/                              (treatments[b])
#     └── <treat_directory_name>/                (per-replicate/experiment subfolder)
#         └── AF647 photobleach/
#             ├── client_results/
#             │   ├── *client_results.csv
#             │   ├── *client_colocalisation_sHsp.csv
#             │   ├── *client_colocalisation_Hsp70.csv
#             │   ├── *sHsp_scramble_colocalized.csv
#             │   └── *Hsp70_scramble_colocalized.csv    -> client_Hsp70_scramble_coloc
#             │
#             ├── sHsp_results/
#             │   ├── *sHsp_results.csv
#             │   ├── *sHsp_colocalisation_Hsp70_results.csv
#             │   └── *Hsp70_scramble_colocalized.csv    -> sHsp_Hsp70_coloc_scramble_files_all
#             │
#             └── Hsp70_results/
#                 └── *Hsp70_results.csv
#
# Note: Hsp70_scramble_colocalized.csv exists in both client_results/ and
# sHsp_results/ (client-channel vs. sHsp-channel colocalisation) and is
# read into two separate dataframes accordingly.
#
# process_dfs() extracts image number via "#\\d+" after truncating file_name
# to start at "Channel488" — raw filenames must contain Channel488...#<n>.

library(tidyverse)
library(tidylog)

# setting initial directories ---------------------------------------------

experiment_date <- "20260212_THREE_COLOUR"

# This is an external folder where I store the images and the results of the ImageJ analysis
# Insert your own folder where those things live here
vorg_folder <- file.path("Z:", "Chaperone_subgroup", "NicolaA", "Fluc complexes", paste0("20260212"))
print(vorg_folder)

# I do the rest of the analysis on my actual computer in this "local_folder"
local_folder <- file.path("C:", "Nicola", "UNIVERSITY", "PhD", "SM", "Fluc", experiment_date)
print(local_folder)
setwd(local_folder)

# Loading up complexes data -----------------------------------------------

# firstly defining some variables

all_items <- list.files(vorg_folder, full.names = TRUE) # List all items in the folder
directories <- all_items[file.info(all_items)$isdir] # Filter to keep only directories
directory_names <- basename(directories) # Get the names of the directories 
print(directory_names)

treatments <- rep(NA, length(directory_names))

yes <- "Y"
for (a in 1:length(directory_names)){
  current_treatment_name <- directory_names[a]
  console_prompt <- paste("Is ", current_treatment_name, "a treatment you want to include? Y or N (case senstitive)  ")
  include <- readline(console_prompt)
  if (setequal(yes,include) == TRUE){
    treatments[a] <- current_treatment_name
  }
}

# defining even more variables

treatments <- na.omit(treatments)
print(treatments)

all_clients_results_list = list()
all_clients_coloc_sHsp_list = list()
all_clients_coloc_Hsp70_list = list()
all_clients_coloc_sHsp_scramble_list = list()
all_clients_coloc_Hsp70_scramble_list = list()

all_sHsp_results_list = list()
all_sHsp_coloc_Hsp70_list = list()
all_sHsp_coloc_Hsp70_scramble_list = list()

all_Hsp70_results_list = list()

for (b in 1:length(treatments)){
  current_treat_folder <- file.path(vorg_folder, treatments[b])
  print(current_treat_folder)
  current_treatment <- treatments[b]
  all_items <- list.files(current_treat_folder, full.names = TRUE) 
  directories <- all_items[file.info(all_items)$isdir] 
  treat_directory_names <- basename(directories) 
  print(treat_directory_names)
  
  client_results_path <- file.path(current_treat_folder, treat_directory_names, "AF647 photobleach/client_results/")
  
  info <- fs::dir_info(
    path = client_results_path,
    regexp = "client_results.csv$"
  )

  files_to_use <- info %>%
        pull(path)
    print(files_to_use)
  
  client_results_files_all <- files_to_use |>
    rlang::set_names() |>
    purrr::map(readr::read_delim) |> 
    purrr::list_rbind(names_to = "file_name")

  info <- fs::dir_info(
    path = client_results_path,
    regexp = "client_colocalisation_sHsp.csv$"
  )

  files_to_use <- info %>%

    pull(path)
  print(files_to_use)

  client_sHsp_colocalisation_files_all <- files_to_use |>
    rlang::set_names() |>
    purrr::map(readr::read_delim) |> 
    purrr::list_rbind(names_to = "file_name")
  
  info <- fs::dir_info(
    path = client_results_path,
    regexp = "client_colocalisation_Hsp70.csv$"
  )

  files_to_use <- info %>%

    pull(path)
  print(files_to_use)
  
  client_Hsp70_colocalisation_files_all <- files_to_use |>
    rlang::set_names() |>
    purrr::map(readr::read_delim) |> 
    purrr::list_rbind(names_to = "file_name")
  
  info <- fs::dir_info(
    path = client_results_path,
    regexp = "sHsp_scramble_colocalized.csv$"
  )

  files_to_use <- info %>%
    pull(path)
  print(files_to_use)
  
  client_sHsp_scramble_coloc <- files_to_use |>
    rlang::set_names() |>
    purrr::map(readr::read_delim) |> 
    purrr::list_rbind(names_to = "file_name")
  

  info <- fs::dir_info(
    path = client_results_path,
    regexp = "Hsp70_scramble_colocalized.csv$"
  )

  files_to_use <- info %>%
    pull(path)
  print(files_to_use)
  
  client_Hsp70_scramble_coloc <- files_to_use |>
    rlang::set_names() |>
    purrr::map(readr::read_delim) |> 
    purrr::list_rbind(names_to = "file_name")
  
  sHsp_results_path <- file.path(current_treat_folder, treat_directory_names, "AF647 photobleach/sHsp_results/")
  
  info <- fs::dir_info(
    path = sHsp_results_path,
    regexp = "sHsp_results.csv$"
  )

  files_to_use <- info %>%
    pull(path)
  print(files_to_use)
  
  sHsp_results_files_all <- files_to_use |>
    rlang::set_names() |>
    purrr::map(readr::read_delim) |> 
    purrr::list_rbind(names_to = "file_name")
  
  info <- fs::dir_info(
    path = sHsp_results_path,
    regexp = "sHsp_colocalisation_Hsp70_results.csv$"
  )

    files_to_use <- info %>%
    pull(path)
  print(files_to_use)
  
  sHsp_Hsp70_coloc_files_all <- files_to_use |>
    rlang::set_names() |>
    purrr::map(readr::read_delim) |> 
    purrr::list_rbind(names_to = "file_name")

  info <- fs::dir_info(
    path = sHsp_results_path,
    regexp = "Hsp70_scramble_colocalized.csv$"
  )

  files_to_use <- info %>%
    pull(path)
  print(files_to_use)
  
  sHsp_Hsp70_coloc_scramble_files_all <- files_to_use |>
    rlang::set_names() |>
    purrr::map(readr::read_delim) |> 
    purrr::list_rbind(names_to = "file_name")
  
  Hsp70_results_path <- file.path(current_treat_folder, treat_directory_names, "AF647 photobleach/Hsp70_results/")
  

  info <- fs::dir_info(
    path = Hsp70_results_path,
    regexp = "Hsp70_results.csv$"
  )

  files_to_use <- info %>%
    pull(path)
  print(files_to_use)
  
  Hsp70_results_files_all <- files_to_use |>
    rlang::set_names() |>
    purrr::map(readr::read_delim) |> 
    purrr::list_rbind(names_to = "file_name")
  
  # this function adds information such as the experiment date and treatment and also extracts the image number
  
  process_dfs <- function(df){
    df %>% 
      mutate(file_name = sub(".*Channel488", "Channel488", file_name),
             just_image_number = str_extract(file_name, "#\\d+"),
             experiment_date = experiment_date,
             Treatment_name = current_treatment)}
    
   client_results_files_all <- process_dfs(client_results_files_all)
   client_sHsp_colocalisation_files_all <- process_dfs(client_sHsp_colocalisation_files_all)
   client_Hsp70_colocalisation_files_all <- process_dfs(client_Hsp70_colocalisation_files_all)
   client_sHsp_scramble_coloc <- process_dfs(client_sHsp_scramble_coloc)
   client_Hsp70_scramble_coloc <- process_dfs(client_Hsp70_scramble_coloc)
   sHsp_results_files_all <- process_dfs(sHsp_results_files_all)
   sHsp_Hsp70_coloc_files_all <- process_dfs(sHsp_Hsp70_coloc_files_all)
   sHsp_Hsp70_coloc_scramble_files_all <- process_dfs(sHsp_Hsp70_coloc_scramble_files_all)
   Hsp70_results_files_all <- process_dfs(Hsp70_results_files_all)
   
   all_clients_results_list[[b]] <- client_results_files_all
   all_clients_coloc_sHsp_list[[b]] <- client_sHsp_colocalisation_files_all
   all_clients_coloc_Hsp70_list[[b]] <- client_Hsp70_colocalisation_files_all
   all_clients_coloc_sHsp_scramble_list[[b]] <- client_sHsp_scramble_coloc
   all_clients_coloc_Hsp70_scramble_list[[b]] <- client_Hsp70_scramble_coloc
   
   all_sHsp_results_list[[b]] <- sHsp_results_files_all
   all_sHsp_coloc_Hsp70_list[[b]] <- sHsp_Hsp70_coloc_files_all
   all_sHsp_coloc_Hsp70_scramble_list[[b]] <- sHsp_Hsp70_coloc_scramble_files_all
   
   all_Hsp70_results_list[[b]] <- Hsp70_results_files_all
   
}

all_clients_results = do.call(rbind, all_clients_results_list)
all_clients_coloc_sHsp = do.call(rbind, all_clients_coloc_sHsp_list)
all_clients_coloc_Hsp70 = do.call(rbind, all_clients_coloc_Hsp70_list)
all_clients_coloc_sHsp_scramble = do.call(rbind, all_clients_coloc_sHsp_scramble_list)
all_clients_coloc_Hsp70_scramble = do.call(rbind, all_clients_coloc_Hsp70_scramble_list)

all_sHsp_results = do.call(rbind, all_sHsp_results_list)
all_sHsp_coloc_Hsp70 = do.call(rbind, all_sHsp_coloc_Hsp70_list)
all_sHsp_coloc_Hsp70_scramble = do.call(rbind, all_sHsp_coloc_Hsp70_scramble_list)

all_Hsp70_results = do.call(rbind, all_Hsp70_results_list)


# Making unique identifier ------------------------------------------------

# Now that all of the data is loaded up I want to make a unique identifier for each molecule which will go along with its X and Y information to identify it at all stages of analysis

# The ID will just be a number but also a letter to denote if it is a client (C) or a sHsp (S) or a Hsp70 (H)

all_clients_results <- all_clients_results %>% mutate(molecule_ID = paste0("C", as.character(rownames(all_clients_results))))

all_sHsp_results <- all_sHsp_results %>% mutate(molecule_ID = paste0("S", as.character(rownames(all_sHsp_results))))

all_Hsp70_results <- all_Hsp70_results %>% mutate(molecule_ID = paste0("H", as.character(rownames(all_Hsp70_results))))

write.csv(all_clients_results, file = file.path("full_data","all_clients_results.csv"), row.names = F)

write.csv(all_sHsp_results, file = file.path("full_data","all_sHsp_results.csv"), row.names = F)

write.csv(all_Hsp70_results, file = file.path("full_data","all_Hsp70_results.csv"), row.names = F)

# # # # # # # # # # # # # # # # # # # # # 

write.csv(all_clients_coloc_sHsp, file = file.path("full_data","all_clients_coloc_sHsp.csv"), row.names = F)

write.csv(all_clients_coloc_Hsp70, file = file.path("full_data","all_clients_coloc_Hsp70.csv"), row.names = F)

write.csv(all_sHsp_coloc_Hsp70, file = file.path("full_data","all_sHsp_coloc_Hsp70.csv"), row.names = F)

# # # # # # # # # # # # # # # # # # # # # 

write.csv(all_clients_coloc_sHsp_scramble, file = file.path("full_data","all_clients_coloc_sHsp_scramble.csv"), row.names = F)

write.csv(all_clients_coloc_Hsp70_scramble, file = file.path("full_data","all_clients_coloc_Hsp70_scramble.csv"), row.names = F)

write.csv(all_sHsp_coloc_Hsp70_scramble, file = file.path("full_data","all_sHsp_coloc_Hsp70_scramble.csv"), row.names = F)

# If you want to read in the data from the local folder ------------------------------------

all_clients_results <- read.csv(file = file.path(local_folder, "full_data","all_clients_results.csv"))

all_sHsp_results <- read.csv(file = file.path(local_folder, "full_data","all_sHsp_results.csv"))

all_Hsp70_results <- read.csv(file = file.path(local_folder, "full_data","all_Hsp70_results.csv"))

# # # # # # # # # # # # # # # # # # # # # 

all_clients_coloc_sHsp <- read.csv(file = file.path(local_folder, "full_data", "all_clients_coloc_sHsp.csv"))

all_clients_coloc_Hsp70 <- read.csv(file = file.path(local_folder, "full_data", "all_clients_coloc_Hsp70.csv"))

all_sHsp_coloc_Hsp70 <- read.csv(file = file.path(local_folder, "full_data", "all_sHsp_coloc_Hsp70.csv"))

# # # # # # # # # # # # # # # # # # # # # 

all_clients_coloc_Hsp70 <- read.csv(file = file.path(local_folder, "full_data", "all_clients_coloc_Hsp70.csv"))

all_clients_coloc_sHsp <- read.csv(file = file.path(local_folder, "full_data", "all_clients_coloc_sHsp.csv"))

all_sHsp_coloc_Hsp70 <- read.csv(file = file.path(local_folder, "full_data", "all_sHsp_coloc_Hsp70.csv"))

all_clients_coloc_sHsp_scramble <- read.csv(file = file.path(local_folder, "full_data", "all_clients_coloc_sHsp_scramble.csv"))

all_clients_coloc_Hsp70_scramble <- read.csv(file = file.path(local_folder, "full_data", "all_clients_coloc_Hsp70_scramble.csv"))

all_sHsp_coloc_Hsp70_scramble <- read.csv(file = file.path(local_folder, "full_data", "all_sHsp_coloc_Hsp70_scramble.csv"))


# Compiling colocalisation information ------------------------------------

# Updating each results with information about various colocalisations

# firstly we are making some empty columns to save this information into

all_clients_results <- all_clients_results %>% 
  mutate(treatment_image = paste(Treatment_name, just_image_number, sep = "-"),
         coloc_sHsp = NA,
         coloc_sHsp_molecule_ID = NA,
         coloc_sHsp_scramble = NA,
         coloc_Hsp70 = NA,
         coloc_Hsp70_molecule_ID = NA,
         coloc_Hsp70_scramble = NA)

all_sHsp_results <- all_sHsp_results %>% 
  mutate(treatment_image = paste(Treatment_name, just_image_number, sep = "-"),
         coloc_client = NA,
         coloc_client_molecule_ID = NA,
         coloc_client_scramble = NA,
         coloc_Hsp70 = NA,
         coloc_Hsp70_molecule_ID = NA,
         coloc_Hsp70_scramble = NA)

all_Hsp70_results <- all_Hsp70_results %>% 
  mutate(treatment_image = paste(Treatment_name, just_image_number, sep = "-"),
         coloc_client = NA,
         coloc_client_molecule_ID = NA,
         coloc_client_scramble = NA,
         coloc_sHsp = NA,
         coloc_sHsp_molecule_ID = NA,
         coloc_sHsp_scramble = NA)

all_clients_coloc_Hsp70 = all_clients_coloc_Hsp70 %>% 
  filter(distance > -1) %>%
  mutate(treatment_image = paste(Treatment_name, just_image_number, sep = "-"))

all_clients_coloc_sHsp = all_clients_coloc_sHsp %>% 
  filter(distance > -1) %>%
  mutate(treatment_image = paste(Treatment_name, just_image_number, sep = "-"))

all_clients_coloc_Hsp70_scramble <- all_clients_coloc_Hsp70_scramble %>%
  filter(distance > -1) %>%
  mutate(treatment_image = paste(Treatment_name, just_image_number, sep = "-"))

all_clients_coloc_sHsp_scramble <- all_clients_coloc_sHsp_scramble %>%
  filter(distance > -1) %>%
  mutate(treatment_image = paste(Treatment_name, just_image_number, sep = "-"))

all_sHsp_coloc_Hsp70 = all_sHsp_coloc_Hsp70 %>% 
  filter(distance > -1) %>%
  mutate(treatment_image = paste(Treatment_name, just_image_number, sep = "-"))

all_sHsp_coloc_Hsp70_scramble = all_sHsp_coloc_Hsp70_scramble %>% 
  filter(distance > -1) %>%
  mutate(treatment_image = paste(Treatment_name, just_image_number, sep = "-"))

# now we are going to check for client colocalisation in both normal and scrambled methods

for (i in 1:nrow(all_clients_results)){
  print(i)
  
  current_ID <- all_clients_results$molecule_ID[i]
  current_treatment_image <- all_clients_results$treatment_image[i]
  
  treatment_image_in_coloc_sHsp <- all_clients_coloc_sHsp %>% filter(distance > -1 & treatment_image == current_treatment_image)
  
  current_X <- all_clients_results$X[i]
  current_Y <- all_clients_results$Y[i]
  
  check_coloc_sHsp <- treatment_image_in_coloc_sHsp %>% filter(X == current_X & Y == current_Y)
  
  # If check coloc has at least one row (and it should only have one) then it is colocalised. The following if statement will extract the ID of the colocalised molecule and add it to the clients dataframe
  
  if(nrow(check_coloc_sHsp) == 1){
    print("coloc normal")
    all_clients_results$coloc_sHsp[i] <- "Yes"
    
    coloc_X <- check_coloc_sHsp$X2
    coloc_Y <- check_coloc_sHsp$Y2
    
    coloc_mol_sHsp <- all_sHsp_results %>% filter(treatment_image == current_treatment_image & X == coloc_X & Y == coloc_Y)
    
    all_clients_results$coloc_sHsp_molecule_ID[i] <- coloc_mol_sHsp$molecule_ID
    
  }
  
  # Now we are going to check if it is colocalised in the sHsp scrambled dataframe
  
  check_coloc_scramble <- all_clients_coloc_sHsp_scramble %>% filter(distance > -1 & treatment_image == current_treatment_image & X == current_X & Y == current_Y)
  
  if(nrow(check_coloc_scramble == 1)){
    print("coloc scramble")
    all_clients_results$coloc_sHsp_scramble[i] <- "Yes"
    
  } else{all_clients_results$coloc_sHsp_scramble[i] <- "No"}
  
  
  # Now we are going to do the same thing but to check if it is colocalised with Hsp70 
  
  check_coloc_Hsp70 <- all_clients_coloc_Hsp70 %>% filter(distance > -1 & treatment_image == current_treatment_image & X == current_X & Y == current_Y)
  
  # If check coloc has at least one row (and it should only have one) then it is colocalised. The following if statement will extract the ID of the colocalised molecule and add it to the clients dataframe
  
  if(nrow(check_coloc_Hsp70) == 1){
    print("coloc normal")
    all_clients_results$coloc_Hsp70[i] <- "Yes"
    
    coloc_X <- check_coloc_Hsp70$X2
    coloc_Y <- check_coloc_Hsp70$Y2
    
    coloc_mol_Hsp70 <- all_Hsp70_results %>% filter(treatment_image == current_treatment_image & X == coloc_X & Y == coloc_Y)
    
    all_clients_results$coloc_Hsp70_molecule_ID[i] <- coloc_mol_Hsp70$molecule_ID
    
  }
  
  # Now we are going to check if it is colocalised in the sHsp scrambled dataframe
  
  check_coloc_scramble <- all_clients_coloc_Hsp70_scramble %>% filter(distance > -1 & treatment_image == current_treatment_image & X == current_X & Y == current_Y)
  
  if(nrow(check_coloc_scramble == 1)){
    print("coloc scramble")
    all_clients_results$coloc_Hsp70_scramble[i] <- "Yes"
    
  } else{all_clients_results$coloc_Hsp70_scramble[i] <- "No"}
  
  
}

# converting the NA cells to say "No" meaning that the molecule was not colocalised as it could not be found in those specific 
# colocalisation results files

all_clients_results <- all_clients_results %>% mutate(coloc_sHsp_scramble = case_when(
  is.na(coloc_sHsp_scramble) ~ "No",
  TRUE ~ coloc_sHsp_scramble),
  coloc_Hsp70_scramble = case_when(is.na(coloc_Hsp70_scramble) ~ "No",
                          TRUE ~ coloc_Hsp70_scramble))

all_clients_results <- all_clients_results %>% mutate(coloc_sHsp = case_when(
  is.na(coloc_sHsp) ~ "No",
  TRUE ~ coloc_sHsp),
  coloc_Hsp70 = case_when(is.na(coloc_Hsp70) ~ "No",
                                   TRUE ~ coloc_Hsp70))

# saving these

write.csv(all_clients_results, file = file.path(local_folder, "full_data", "all_clients_results_coloc.csv"), row.names = F)

# If need to read in  then uncomment the next line:

#all_clients_results <- read.csv(file = file.path(local_folder, "full_data", "all_clients_results_coloc.csv"))

# Now doing the same thing but for the sHsps instead of the clients


for (i in 1:nrow(all_sHsp_results)){
  print(i)
  
  current_ID <- all_sHsp_results$molecule_ID[i]
  current_treatment_image <- all_sHsp_results$treatment_image[i]
  
  # as the information about colocalised sHsps for CLIENTS is in the all_clients_coloc_sHsp dataframe we will go to this one to get the X and Y information remembering that the sHsps are in the X2 and Y2 columns
  
  current_X <- all_sHsp_results$X[i]
  current_Y <- all_sHsp_results$Y[i]
  
  check_coloc_client <- all_clients_coloc_sHsp %>% filter(distance > -1 & treatment_image == current_treatment_image & X2 == current_X & Y2 == current_Y)
  
  # If check coloc has at least one row (and it should only have one) then it is colocalised. The following if statement will extract the ID of the colocalised molecule and add it to the clients dataframe
  
  if(nrow(check_coloc_client) == 1){
    print("coloc normal client")
    all_sHsp_results$coloc_client[i] <- "Yes"
    
    # we want the client molecule this time so X and Y instead of X2 and Y2
    coloc_client_X <- check_coloc_client$X
    coloc_client_Y <- check_coloc_client$Y
    
    coloc_client_mol <- all_clients_results %>% filter(treatment_image == current_treatment_image & X == coloc_client_X & Y == coloc_client_Y)
    
    all_sHsp_results$coloc_client_molecule_ID[i] <- coloc_client_mol$molecule_ID
    
  }

  # We can also have colocalisations between the sHsp and Hsp70 so now we need to check for that. In this case we had the sHsps as X and Y and the Hsp70 molecules as X2 and Y2
  
  check_coloc_Hsp70 <- all_sHsp_coloc_Hsp70 %>% filter(distance > -1 & treatment_image == current_treatment_image & X == current_X & Y == current_Y)
  
    if(nrow(check_coloc_Hsp70) == 1){
    print("coloc normal Hsp70")
    all_sHsp_results$coloc_Hsp70[i] <- "Yes"
    
    # we want the Hsp70 molecule this time so need X2 and Y2
    coloc_Hsp70_X <- check_coloc_Hsp70$X2
    coloc_Hsp70_Y <- check_coloc_Hsp70$Y2
    
    coloc_Hsp70_mol <- all_Hsp70_results %>% filter(treatment_image == current_treatment_image & X == coloc_Hsp70_X & Y == coloc_Hsp70_Y)
    
    all_sHsp_results$coloc_Hsp70_molecule_ID[i] <- coloc_Hsp70_mol$molecule_ID
    
  }
  
  # Now we do the same thing with the Hsp70 scrambled situation
  
  check_coloc_Hsp70_scramble <- all_sHsp_coloc_Hsp70_scramble %>% filter(distance > -1 & treatment_image == current_treatment_image & X == current_X & Y == current_Y)
  
  if(nrow(check_coloc_Hsp70_scramble == 1)){
    print("coloc scramble Hsp70")
    all_sHsp_results$coloc_Hsp70_scramble[i] <- "Yes"
    
  } else{all_sHsp_results$coloc_Hsp70_scramble[i] <- "No"}
  
}

all_sHsp_results <- all_sHsp_results %>% mutate(coloc_client = case_when(
  is.na(coloc_client) ~ "No",
  TRUE ~ coloc_client),
  coloc_Hsp70 = case_when(is.na(coloc_Hsp70) ~ "No",
                          TRUE ~ coloc_Hsp70),
  coloc_client_scramble = case_when(is.na(coloc_client_scramble) ~ "No",
                          TRUE ~ coloc_client_scramble))

# saving these
write.csv(all_sHsp_results, file = file.path(local_folder, "full_data", "all_sHsp_results_coloc.csv"), row.names = F)

#all_sHsp_results <- read.csv(file = file.path(local_folder, "full_data", "all_sHsp_results_coloc.csv"))


# NOw doing the same thing but for the Hsp70s


for (i in 1:nrow(all_Hsp70_results)){
  print(i)
  
  current_ID <- all_Hsp70_results$molecule_ID[i]
  current_treatment_image <- all_Hsp70_results$treatment_image[i]
  
  # as the information about colocalised Hsp70s for CLIENTS is in the all_clients_coloc_Hsp70 dataframe we will go to this one to get the X and Y information remembering that the Hsp70s are in the X2 and Y2 columns
  
  current_X <- all_Hsp70_results$X[i]
  current_Y <- all_Hsp70_results$Y[i]
  
  check_coloc_client <- all_clients_coloc_Hsp70 %>% filter(distance > -1 & treatment_image == current_treatment_image & X2 == current_X & Y2 == current_Y)
  
  # If check coloc has at least one row (and it should only have one) then it is colocalised. The following if statement will extract the ID of the colocalised molecule and add it to the clients dataframe
  
  if(nrow(check_coloc_client) == 1){
    print("coloc normal client")
    all_Hsp70_results$coloc_client[i] <- "Yes"
    
    # we want the client molecule this time so X and Y instead of X2 and Y2
    coloc_client_X <- check_coloc_client$X
    coloc_client_Y <- check_coloc_client$Y
    
    coloc_client_mol <- all_clients_results %>% filter(treatment_image == current_treatment_image & X == coloc_client_X & Y == coloc_client_Y)
    
    all_Hsp70_results$coloc_client_molecule_ID[i] <- coloc_client_mol$molecule_ID
    
  }
  
  # Now we are going to check if it is colocalised in the client scrambled dataframe
  
  check_coloc_client_scramble <- all_clients_coloc_Hsp70_scramble %>% filter(distance > -1 & treatment_image == current_treatment_image & X2 == current_X & Y2 == current_Y)
  
  if(nrow(check_coloc_client_scramble == 1)){
    print("coloc scramble client")
    all_Hsp70_results$coloc_client_scramble[i] <- "Yes"
    
  } else{all_Hsp70_results$coloc_client_scramble[i] <- "No"}
  
  # We can also have colocalisations between the Hsp70 and sHsps so now we need to check for that. In this case we had the sHsps as X and Y and the Hsp70 molecules as X2 and Y2
  
  check_coloc_sHsp <- all_sHsp_coloc_Hsp70 %>% filter(distance > -1 & treatment_image == current_treatment_image & X2 == current_X & Y2 == current_Y)
  
  if(nrow(check_coloc_sHsp) == 1){
    print("coloc normal sHsp")
    all_Hsp70_results$coloc_sHsp[i] <- "Yes"
    
    # we want the sHsp molecule this time so need X and Y
    coloc_sHsp_X <- check_coloc_sHsp$X
    coloc_sHsp_Y <- check_coloc_sHsp$Y
    
    coloc_sHsp_mol <- all_sHsp_results %>% filter(treatment_image == current_treatment_image & X == coloc_sHsp_X & Y == coloc_sHsp_Y)
    
    all_Hsp70_results$coloc_sHsp_molecule_ID[i] <- coloc_sHsp_mol$molecule_ID
    
  }
  
  # Now we do the same thing with the Hsp70 scrambled situation
  
  check_coloc_sHsp_scramble <- all_sHsp_coloc_Hsp70_scramble %>% filter(distance > -1 & treatment_image == current_treatment_image & X2 == current_X & Y2 == current_Y)
  
  if(nrow(check_coloc_sHsp_scramble == 1)){
    print("coloc scramble sHsp")
    all_Hsp70_results$coloc_sHsp_scramble[i] <- "Yes"
    
  } else{all_Hsp70_results$coloc_sHsp_scramble[i] <- "No"}
  
}

all_Hsp70_results <- all_Hsp70_results %>% mutate(coloc_client = case_when(
  is.na(coloc_client) ~ "No",
  TRUE ~ coloc_client),
  coloc_sHsp = case_when(is.na(coloc_sHsp) ~ "No",
                         TRUE ~ coloc_sHsp))
# saving these
write.csv(all_Hsp70_results, file = file.path(local_folder, "full_data", "all_Hsp70_results_coloc.csv"), row.names = F)

#all_Hsp70_results <- read.csv(file = file.path(local_folder, "full_data", "all_Hsp70_results_coloc.csv"))



# Quick colocalisation graphing -------------------------------------------

# This is to make some graphs from this particular experiment about the percentage of colocalisations that are seen for all of the
# different colocalisation combinations

client_coloc_summary <- all_clients_results %>%
  group_by(Treatment_name) %>%
  reframe(n_total = n(),
          number_coloc_sHsp = sum(coloc_sHsp == "Yes"),
          number_coloc_sHsp_scrambled = sum(coloc_sHsp_scramble == "Yes"),
          number_coloc_Hsp70 = sum(coloc_Hsp70 == "Yes"),
          number_coloc_Hsp70_scrambled = sum(coloc_Hsp70_scramble == "Yes")) %>%
  mutate(percent_coloc_sHsp = 100 * number_coloc_sHsp/n_total,
         percent_coloc_sHsp_scrambled = 100 * number_coloc_sHsp_scrambled/n_total,
         percent_coloc_Hsp70 = 100 * number_coloc_Hsp70/n_total,
         percent_coloc_Hsp70_scrambled = 100 * number_coloc_Hsp70_scrambled/n_total,
         protein = "client")


sHsp_coloc_summary <- all_sHsp_results %>%
  group_by(Treatment_name) %>%
  reframe(n_total = n(),
          number_coloc_client = sum(coloc_client == "Yes"),
          number_coloc_client_scrambled = sum(coloc_client_scramble == "Yes"),
          number_coloc_Hsp70 = sum(coloc_Hsp70 == "Yes"),
          number_coloc_Hsp70_scrambled = sum(coloc_Hsp70_scramble == "Yes")) %>%
  mutate(percent_coloc_client = 100 * number_coloc_client/n_total,
         percent_coloc_client_scrambled = 100 * number_coloc_client_scrambled/n_total,
         percent_coloc_Hsp70 = 100 * number_coloc_Hsp70/n_total,
         percent_coloc_Hsp70_scrambled = 100 * number_coloc_Hsp70_scrambled/n_total,
         protein = "sHsp")

Hsp70_coloc_summary <- all_Hsp70_results %>%
  group_by(Treatment_name) %>%
  reframe(n_total = n(),
          number_coloc_client = sum(coloc_client == "Yes"),
          number_coloc_client_scrambled = sum(coloc_client_scramble == "Yes"),
          number_coloc_sHsp = sum(coloc_sHsp == "Yes"),
          number_coloc_sHsp_scrambled = sum(coloc_sHsp_scramble == "Yes")) %>%
  mutate(percent_coloc_client = 100 * number_coloc_client/n_total,
         percent_coloc_client_scrambled = 100 * number_coloc_client_scrambled/n_total,
         percent_coloc_sHsp = 100 * number_coloc_sHsp/n_total,
         percent_coloc_sHsp_scrambled = 100 * number_coloc_sHsp_scrambled/n_total,
         protein = "Hsp70")


client_coloc_long <- client_coloc_summary %>%
  pivot_longer(
    cols = matches("number_coloc_|percent_coloc_"),
    names_to = "col",
    values_to = "value"
  ) %>%
  mutate(
    analysis_method = if_else(str_detect(col, "_scrambled"), "scrambled", "normal"),
    protein = case_when(
      str_detect(col, "sHsp") ~ "sHsp",
      str_detect(col, "Hsp70") ~ "Hsp70"
    ),
    measure = case_when(
      str_detect(col, "^number_coloc") ~ "number_coloc",
      str_detect(col, "^percent_coloc") ~ "percent_coloc"
    )
  ) %>%
  select(-col) %>%
  pivot_wider(
    names_from = measure,
    values_from = value
  )

colnames(client_coloc_long)[3] <- "coloc_protein"

client_coloc_long <- client_coloc_long %>% mutate(protein = "client")

desired_order <- c("0mins_bleach", "15mins_bleach", "60mins_bleach", "120mins_bleach")
client_coloc_long <- client_coloc_long %>%
  mutate(Treatment_name = factor(Treatment_name, levels = desired_order)) %>%
  arrange(Treatment_name)

graph_client <- ggplot(data = client_coloc_long, aes(x = Treatment_name, y = percent_coloc, fill = analysis_method)) +
  geom_col(position = position_dodge()) +
  facet_wrap(~coloc_protein) +
  theme_minimal()
print(graph_client)

write.csv(client_coloc_long, file = file.path(local_folder,  "analysis_outputs", "percent_coloc_summary_client.csv"), row.names = F)


sHsp_coloc_long <- sHsp_coloc_summary %>%
  pivot_longer(
    cols = matches("number_coloc_|percent_coloc_"),
    names_to = "col",
    values_to = "value"
  ) %>%
  mutate(
    analysis_method = if_else(str_detect(col, "_scrambled"), "scrambled", "normal"),
    protein = case_when(
      str_detect(col, "client") ~ "client",
      str_detect(col, "Hsp70") ~ "Hsp70"
    ),
    measure = case_when(
      str_detect(col, "^number_coloc") ~ "number_coloc",
      str_detect(col, "^percent_coloc") ~ "percent_coloc"
    )
  ) %>%
  select(-col) %>%
  pivot_wider(
    names_from = measure,
    values_from = value
  )

colnames(sHsp_coloc_long)[3] <- "coloc_protein"
#colnames(client_coloc_long)[4] <- "coloc_protein"
sHsp_coloc_long <- sHsp_coloc_long %>% mutate(protein = "sHsp")

#desired_order <- c("0min_5pM", "15min_5pM", "60min_5pM", "120min_5pM")
sHsp_coloc_long <- sHsp_coloc_long %>%
  mutate(Treatment_name = factor(Treatment_name, levels = desired_order)) %>%
  arrange(Treatment_name)

graph_sHsp <- ggplot(data = sHsp_coloc_long, aes(x = Treatment_name, y = percent_coloc, fill = analysis_method)) +
  geom_col(position = position_dodge()) +
  facet_wrap(~coloc_protein) +
  theme_minimal()
print(graph_sHsp)


Hsp70_coloc_long <- Hsp70_coloc_summary %>%
  pivot_longer(
    cols = matches("number_coloc_|percent_coloc_"),
    names_to = "col",
    values_to = "value"
  ) %>%
  mutate(
    analysis_method = if_else(str_detect(col, "_scrambled"), "scrambled", "normal"),
    protein = case_when(
      str_detect(col, "client") ~ "client",
      str_detect(col, "sHsp") ~ "sHsp"
    ),
    measure = case_when(
      str_detect(col, "^number_coloc") ~ "number_coloc",
      str_detect(col, "^percent_coloc") ~ "percent_coloc"
    )
  ) %>%
  select(-col) %>%
  pivot_wider(
    names_from = measure,
    values_from = value
  )

colnames(Hsp70_coloc_long)[3] <- "coloc_protein"
#colnames(client_coloc_long)[4] <- "coloc_protein"
Hsp70_coloc_long <- Hsp70_coloc_long %>% mutate(protein = "Hsp70")

#desired_order <- c("0min_5pM", "15min_5pM", "60min_5pM", "120min_5pM")
Hsp70_coloc_long <- Hsp70_coloc_long %>%
  mutate(Treatment_name = factor(Treatment_name, levels = desired_order)) %>%
  arrange(Treatment_name)

graph_Hsp70 <- ggplot(data = Hsp70_coloc_long, aes(x = Treatment_name, y = percent_coloc, fill = analysis_method)) +
  geom_col(position = position_dodge()) +
  facet_wrap(~coloc_protein) +
  theme_minimal()
print(graph_Hsp70)

coloc_summary_all <- rbind(client_coloc_long, sHsp_coloc_long, Hsp70_coloc_long)

write.csv(coloc_summary_all, file = file.path(local_folder,  "analysis_outputs", "coloc_summary_all_proteins.csv"), row.names = F)
