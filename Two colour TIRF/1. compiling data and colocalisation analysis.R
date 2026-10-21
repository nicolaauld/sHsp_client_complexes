# This code is used to compile the data from the ImageJ Fiji macro called "Client_Hsp_colocalisation_trajectories_w_scramble_annotated.ijm" from the images and quantifying the level of colocalisation

# It complies together all of the results .csv files that come from the ImageJ Fiji script and gives them a unique identifier.
# There is also some code at the end that generates a graph for this experiment of the colocalisations

# File structure expected by this code:
#
# vorg_folder/
# └── <treatment>/                              (user-selected via interactive prompt)
#     └── <treat_directory_name>/                (per-replicate/experiment subfolder)
#         └── AF647 photobleach/
#             ├── client_results/
#             │   ├── *client_results.csv
#             │   ├── *client_colocalisation.csv
#             │   ├── *client_non-colocalisation.csv
#             │   └── *scramble_colocalized.csv
#             │
#             └── hsp_results/
#                 ├── *Hsp_results.csv
#                 └── *hsp_non-colocalisation.csv
#
# Treatment folders are not hardcoded — at runtime, every top-level
# subfolder of vorg_folder is listed, and the user is prompted per folder
# (Y/N, case-sensitive "Y") to decide whether it's included as a treatment.
#
# process_dfs() extracts image number via "#\\d+" after truncating "file"
# to start at "Channel488" — raw filenames must contain Channel488...#<n>.


library(tidyverse)
library(tidylog)

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


# Loading up complexes data -----------------------------------------------

# This section is used to load up all of the data from the folders that the ImageJ Fiji scripts creates. Can do multiple treatments at one time (for example ATP and no ATP molecules)

all_items <- list.files(vorg_folder, full.names = TRUE) 
directories <- all_items[file.info(all_items)$isdir] # only want to look at directories
directory_names <- basename(directories) 
print(directory_names)

# using the next bit of code I can select the folders that contain the treatments that I want to analyse

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

treatments <- na.omit(treatments)
print(treatments)

# here we are going to make some empty lists that we can use to store the different data files in 

all_clients_results_list = list()
all_clients_coloc_list = list()
all_clients_noncoloc_list = list()
all_clients_coloc_scramble_list = list()
all_hsp_results_list = list()
all_hsp_noncoloc_list = list()

for (b in 1:length(treatments)){
  current_treat_folder <- file.path(vorg_folder, treatments[b])
  print(current_treat_folder)
  current_treatment <- treatments[b]
  all_items <- list.files(current_treat_folder, full.names = TRUE) 
  directories <- all_items[file.info(all_items)$isdir] 
  treat_directory_names <- basename(directories) 
  print(treat_directory_names)
  
  client_results_path <- file.path(current_treat_folder, treat_directory_names, "AF647 photobleach/client_results/")
  
  data_files <- list.files(path = client_results_path, pattern = "client_results.csv$", full.names = TRUE)
  print(data_files)
  client_results_files_all <- data_files |>
    rlang::set_names() |>
    purrr::map(readr::read_delim) |> 
    purrr::list_rbind(names_to = "file")
  
  data_files <- list.files(path = client_results_path, pattern = "client_colocalisation.csv$", full.names = TRUE)
  print(data_files)
  client_colocalisation_files_all <- data_files |>
    rlang::set_names() |>
    purrr::map(readr::read_delim) |> 
    purrr::list_rbind(names_to = "file")
  
  data_files <- list.files(path = client_results_path, pattern = "client_non-colocalisation.csv$", full.names = TRUE)
  print(data_files)
  client_noncoloc_files_all <- data_files |>
    rlang::set_names() |>
    purrr::map(readr::read_delim) |> 
    purrr::list_rbind(names_to = "file")
  
  data_files <- list.files(path = client_results_path, pattern = "scramble_colocalized.csv$", full.names = TRUE)
  print(data_files)
  client_scramble_coloc <- data_files |>
    rlang::set_names() |>
    purrr::map(readr::read_delim) |> 
    purrr::list_rbind(names_to = "file")
  
  hsp_results_path <- file.path(current_treat_folder, treat_directory_names, "AF647 photobleach/hsp_results/")
  
  data_files <- list.files(path = hsp_results_path, pattern = "Hsp_results.csv$", full.names = TRUE)
  print(data_files)
  hsp_results_files_all <- data_files |>
    rlang::set_names() |>
    purrr::map(readr::read_delim) |> 
    purrr::list_rbind(names_to = "file")
  
  data_files <- list.files(path = hsp_results_path, pattern = "hsp_non-colocalisation.csv$", full.names = TRUE)
  print(data_files)
  hsp_noncoloc_files_all <- data_files |>
    rlang::set_names() |>
    purrr::map(readr::read_delim) |> 
    purrr::list_rbind(names_to = "file")
  
  # this function adds information such as the experiment date and treatment and also extracts the image number
  
  process_dfs <- function(df){
    df %>% 
      mutate(file = sub(".*Channel488", "Channel488", file),
             just_image_number = str_extract(file, "#\\d+"),
             experiment_date = experiment_date,
             Treatment_name = current_treatment)
  }
    
   client_results_files_all <- process_dfs(client_results_files_all)
   client_colocalisation_files_all <- process_dfs(client_colocalisation_files_all)
   client_noncoloc_files_all <- process_dfs(client_noncoloc_files_all)
   client_scramble_coloc <- process_dfs(client_scramble_coloc)
   hsp_results_files_all <- process_dfs(hsp_results_files_all)
   hsp_noncoloc_files_all <- process_dfs(hsp_noncoloc_files_all)
   
   all_clients_results_list[[b]] <- client_results_files_all
   all_clients_coloc_list[[b]] <- client_colocalisation_files_all
   all_clients_noncoloc_list[[b]] <- client_noncoloc_files_all
   all_clients_coloc_scramble_list[[b]] <- client_scramble_coloc
   all_hsp_results_list[[b]] <- hsp_results_files_all
   all_hsp_noncoloc_list[[b]] = hsp_noncoloc_files_all
   
  
}

# ok now turning those populated lists into dataframes so that they are nice to work with

all_clients_results = do.call(rbind, all_clients_results_list)
all_clients_coloc = do.call(rbind, all_clients_coloc_list)
all_clients_noncoloc = do.call(rbind, all_clients_noncoloc_list)
all_clients_coloc_scramble = do.call(rbind, all_clients_coloc_scramble_list)
all_hsp_results = do.call(rbind, all_hsp_results_list)
all_hsp_noncoloc = do.call(rbind, all_hsp_noncoloc_list)


# Making unique identifier ------------------------------------------------

# Now that all of the data is loaded up I want to make a unique identifier for each molecule which will go along with its X and Y information to identify it at all stages of analysis

# The ID will just be a number but also a letter to denote if it is a client (C) or a Hsp (H)

all_clients_results <- all_clients_results %>% mutate(molecule_ID = paste0("C", as.character(rownames(all_clients_results))))
all_hsp_results <- all_hsp_results %>% mutate(molecule_ID = paste0("H", as.character(rownames(all_hsp_results))))


# Compiling colocalisation information ------------------------------------

# So instead of having several dataframes with the colocalised clients and hsps and then the non-colocalised ones in a separate dataframe I am going to try to put all of that information into the all_clients_results and the all_hsp_results

# firstly we are making some empty columns to save this information into

all_clients_results <- all_clients_results %>% 
  mutate(coloc = NA,
         coloc_molecule_ID = NA,
         treatment_image = paste(Treatment_name, just_image_number, sep = "-"),
         coloc_scramble = NA)

all_hsp_results <- all_hsp_results %>% 
  mutate(coloc = NA,
         coloc_molecule_ID = NA,
         treatment_image = paste(Treatment_name, just_image_number, sep = "-"),
         coloc_scramble = NA)

all_clients_coloc = all_clients_coloc %>% 
  mutate(treatment_image = paste(Treatment_name, just_image_number, sep = "-"))

all_clients_noncoloc = all_clients_noncoloc %>% 
  mutate(treatment_image = paste(Treatment_name, just_image_number, sep = "-"))

all_hsp_noncoloc = all_hsp_noncoloc %>% 
  mutate(treatment_image = paste(Treatment_name, just_image_number, sep = "-"))

all_clients_coloc_scramble = all_clients_coloc_scramble %>% 
  mutate(treatment_image = paste(Treatment_name, just_image_number, sep = "-"))


# now we are going to check for client colocalisation in both normal and scrambled methods

# this loop is going through every row in "all_clients_results" and updates it with the colocalisation information

for (i in 1:nrow(all_clients_results)){
  print(i)
  
  # firstly we are getting some information about the relevant molecule of the row
  
  current_ID <- all_clients_results$molecule_ID[i]
  current_treatment_image <- all_clients_results$treatment_image[i]
  
  # now we are looking for this molecule in the "coloc" dataframe that contains only the colocalised molecules
  
  treatment_image_in_coloc <- all_clients_coloc %>% filter(distance > -1 & treatment_image == current_treatment_image)
  
  current_X <- all_clients_results$X[i]
  current_Y <- all_clients_results$Y[i]
  
  check_coloc <- treatment_image_in_coloc %>% filter(X == current_X & Y == current_Y)
  
  # If check coloc has at least one row (and it should only have one) then it is colocalised. The following if statement will extract the ID of the colocalised molecule and add it to the clients dataframe
  
  if(nrow(check_coloc) == 1){
    print("coloc normal")
    all_clients_results$coloc[i] <- "Yes"
    
    coloc_X <- check_coloc$X2
    coloc_Y <- check_coloc$Y2
    
    coloc_mol <- all_hsp_results %>% filter(treatment_image == current_treatment_image & X == coloc_X & Y == coloc_Y)
    
    all_clients_results$coloc_molecule_ID[i] <- coloc_mol$molecule_ID
    
  }
  
  # Now we are going to check if it is colocalised in the scrambled dataframe
  
  check_coloc_scramble <- all_clients_coloc_scramble %>% filter(distance > -1 & treatment_image == current_treatment_image & X == current_X & Y == current_Y)
  
  if(nrow(check_coloc_scramble == 1)){
    print("coloc scramble")
    all_clients_results$coloc_scramble[i] <- "Yes"
    
  } else{all_clients_results$coloc_scramble[i] <- "No"}
  
  # Now if it is NOT in the colocalised dataframe then it must be in the non-colocalised one in which case we want to actually check that is is in there to confirm
  
  if (is.na(all_clients_results$coloc[i])) {
    print("checking in non-coloc...")
    
    noncoloc_mol <- all_clients_noncoloc %>% filter(treatment_image == current_treatment_image & X == current_X & Y == current_Y)
    
  if(nrow(noncoloc_mol) == 1){
    all_clients_results$coloc[i] <- "No"
  }
  
  
  }
}

# saving these
write.csv(all_clients_results, file = file.path(local_folder, "full_data", "all_clients_results.csv"), row.names = F)

# If need to read in :

all_clients_results <- read.csv(file = file.path(local_folder,"full_data", "all_clients_results.csv"))

# NOw doing the same thing but for the Hsps instead of the clients

for (i in 1:nrow(all_hsp_results)){
  print(i)
  
  current_ID <- all_hsp_results$molecule_ID[i]
  current_treatment_image <- all_hsp_results$treatment_image[i]
  
  # as we do not have an all_hsps_coloc dataframe (since the colocalised hsps are also present in the client colocalised dataframe) we will go to this one to get the X and Y information remembering that the Hsps are in the X2 and Y2 columns
  
  treatment_image_in_coloc <- all_clients_coloc %>% filter(distance > -1 & treatment_image == current_treatment_image)
  
  current_X <- all_hsp_results$X[i]
  current_Y <- all_hsp_results$Y[i]
  
  check_coloc <- treatment_image_in_coloc %>% filter(X2 == current_X & Y2 == current_Y)
  
  # If check coloc has at least one row (and it should only have one) then it is colocalised. The following if statement will extract the ID of the colocalised molecule and add it to the clients dataframe
  
  if(nrow(check_coloc) == 1){
    print("coloc normal")
    all_hsp_results$coloc[i] <- "Yes"
    
    # we want the client molecule this time so X and Y instead of X2 and Y2
    coloc_X <- check_coloc$X
    coloc_Y <- check_coloc$Y
    
    coloc_mol <- all_clients_results %>% filter(treatment_image == current_treatment_image & X == coloc_X & Y == coloc_Y)
    
    all_hsp_results$coloc_molecule_ID[i] <- coloc_mol$molecule_ID
    
  }
  
  # Now we are going to check if it is colocalised in the scrambled dataframe
  
  check_coloc_scramble <- all_clients_coloc_scramble %>% filter(distance > -1 & treatment_image == current_treatment_image & X2 == current_X & Y2 == current_Y)
  
  if(nrow(check_coloc_scramble == 1)){
    print("coloc scramble")
    all_hsp_results$coloc_scramble[i] <- "Yes"
    
  } else{all_hsp_results$coloc_scramble[i] <- "No"}
  
  # Now if it is NOT in the colocalised dataframe then it must be in the non-colocalised one in which case we want to actually check that is is in there to confirm
  
  if (is.na(all_hsp_results$coloc[i])) {
    print("checking in non-coloc...")
    
    noncoloc_mol <- all_hsp_noncoloc %>% filter(treatment_image == current_treatment_image & X == current_X & Y == current_Y)
    
    if(nrow(noncoloc_mol) == 1){
      all_hsp_results$coloc[i] <- "No"
    }
    
    
  }
}

all_hsp_results2 <- all_hsp_results %>% filter(coloc %in% c("Yes", "No"))

all_hsp_results_problematic <- all_hsp_results %>% filter(is.na(coloc))

# saving these
write.csv(all_hsp_results2, file = file.path(local_folder, "full_data", "all_hsp_results.csv"), row.names = F)

all_hsp_results <- read.csv(file = file.path(local_folder, "full_data", "all_hsp_results.csv"))

# Matching IDs to the other dataframes ------------------------------------

all_clients_coloc <- all_clients_coloc %>%
  filter(distance > -1) %>%
  mutate(client_molecule_ID = NA,
         hsp_molecule_ID = NA)

for (i in 1:nrow(all_clients_coloc)){
  print(i)
  current_treatment_image <- all_clients_coloc$treatment_image[i]
  current_client_X <- all_clients_coloc$X[i]
  current_client_Y <- all_clients_coloc$Y[i]
  
  current_client_in_all <- all_clients_results %>% filter(treatment_image == current_treatment_image & X == current_client_X & Y == current_client_Y)
  
  all_clients_coloc$client_molecule_ID[i] <- current_client_in_all$molecule_ID
  all_clients_coloc$hsp_molecule_ID[i] <- current_client_in_all$coloc_molecule_ID
  
}

write.csv(all_clients_coloc, file = file.path(local_folder, "full_data", "client_and_hsp_colocalisation_results.csv"))


all_clients_noncoloc <- all_clients_noncoloc %>%
  mutate(molecule_ID = NA)

for (i in 1:nrow(all_clients_noncoloc)){
  print(i)
  current_treatment_image <- all_clients_noncoloc$treatment_image[i]
  current_client_X <- all_clients_noncoloc$X[i]
  current_client_Y <- all_clients_noncoloc$Y[i]
  
  current_client_in_all <- all_clients_results %>% filter(treatment_image == current_treatment_image & X == current_client_X & Y == current_client_Y)
  
  all_clients_noncoloc$molecule_ID[i] <- current_client_in_all$molecule_ID
  
}

write.csv(all_clients_noncoloc, file = file.path(local_folder, "full_data", "client_non-colocal_results.csv"))


all_hsp_noncoloc <- all_hsp_noncoloc %>%
  mutate(molecule_ID = NA)

for (i in 1:nrow(all_hsp_noncoloc)){
  print(i)
  current_treatment_image <- all_hsp_noncoloc$treatment_image[i]
  current_hsp_X <- all_hsp_noncoloc$X[i]
  current_hsp_Y <- all_hsp_noncoloc$Y[i]
  
  current_hsp_in_all <- all_hsp_results %>% filter(treatment_image == current_treatment_image & X == current_hsp_X & Y == current_hsp_Y)
  
  all_hsp_noncoloc$molecule_ID[i] <- current_hsp_in_all$molecule_ID
  
}

write.csv(all_hsp_noncoloc, file = file.path(local_folder,"full_data", "hsp_non-colocal_results.csv"))


# Quick colocalisation graphing -------------------------------------------

# Now we are going to check the colocalisation of the client molecules

client_coloc_summary <- all_clients_results %>%
  group_by(Treatment_name, just_image_number) %>%
  reframe(n_total = n(),
          number_coloc = sum(coloc == "Yes"),
          number_coloc_scrambled = sum(coloc_scramble == "Yes")) %>%
  mutate(percent_coloc = 100 * number_coloc/n_total,
         percent_coloc_scrambled = 100 * number_coloc_scrambled/n_total,
         protein = "client")

# as well as the colocalisation of the hsps

all_hsp_results <- all_hsp_results %>% filter(!is.na(coloc))

hsp_coloc_summary <- all_hsp_results %>%
  group_by(Treatment_name, just_image_number) %>%
  reframe(n_total = n(),
          number_coloc = sum(coloc == "Yes"),
          number_coloc_scrambled = sum(coloc_scramble == "Yes")) %>%
  mutate(percent_coloc = 100 * number_coloc/n_total,
         percent_coloc_scrambled = 100 * number_coloc_scrambled/n_total,
         protein = "hsp")

full_summary <- rbind(client_coloc_summary, hsp_coloc_summary)
full_summary_melted <- gather(full_summary, key = "analysis_method", value = percent_coloc, 6:7)

graph <- ggplot(data = full_summary_melted, aes(x = just_image_number, y = percent_coloc, fill = analysis_method)) +
  geom_col(position = position_dodge()) +
  facet_wrap(~protein + Treatment_name) +
  theme_minimal()
print(graph)

write.csv(full_summary, file = file.path(local_folder, "analysis_outputs", "percent_coloc_summary.csv"), row.names = F)

graph_overall <- ggplot(data = full_summary_melted, aes(x = protein, y = percent_coloc, fill = analysis_method)) +
  geom_col(position = position_dodge()) +
  facet_wrap(~Treatment_name) +
  theme_minimal()
print(graph_overall)