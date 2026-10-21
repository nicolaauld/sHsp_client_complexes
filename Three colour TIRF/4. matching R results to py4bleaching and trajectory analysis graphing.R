# This code follows on with the analysis including the results of py4bleaching. The py4bleaching module will generate
# a results folder called "python_results_647" for the AF647 molecules and equivalent ones for the other
# labelled proteins

# This code extracts that information and matches it back to the results with the colocalisation information. It also
# has some code to make a heatmap of the sizes of the different molecules

library(tidyverse)
library(tidylog)
library(hexbin)

# setting initial directories ---------------------------------------------

experiment_date <- "20260212_THREE_COLOUR"

vorg_folder <- file.path("Z:", "Chaperone_subgroup", "NicolaA", "Fluc complexes", paste0("20260212"))

vorg_folder

local_folder <- file.path("C:", "Nicola", "UNIVERSITY", "PhD", "SM", "Fluc", experiment_date)
print(local_folder)
setwd(local_folder)

# insert path here for the each fluorophore's molecule results from py4bleaching

molecule_counts_555 <- read.csv(file = file.path(local_folder, "python_results-555", "calculate_molecule_size", "molecule_counts.csv"))

molecule_counts_647 <- read.csv(file = file.path(local_folder,  "python_results-647", "calculate_molecule_size", "molecule_counts.csv"))

molecule_counts_488 <- read.csv(file = file.path(local_folder,  "python_results-488", "calculate_molecule_size", "molecule_counts.csv"))

all_clients_results <- read.csv(file = file.path(local_folder, "full_data", "all_clients_results_coloc.csv"))

all_sHsp_results <- read.csv(file = file.path(local_folder, "full_data", "all_sHsp_results_coloc.csv"))

all_Hsp70_results <- read.csv(file = file.path(local_folder, "full_data","all_Hsp70_results_coloc.csv"))

all_clients_results_coloc_traj_path <- file.path(local_folder, "full_data", "all_clients_results_coloc_traj.csv")

all_sHsp_results_coloc_traj_path <- file.path(local_folder, "full_data", "all_sHsp_results_coloc_traj.csv")

all_Hsp70_results_coloc_traj_path <- file.path(local_folder, "full_data", "all_Hsp70_results_coloc_traj.csv")

client_complexes_path <- file.path(local_folder, "full_data", "client_complexes.csv")

# updating the colocalisation results with trajectory information ---------

# Need to do separately for 488 and 647 because we ran py4bleaching separately for each fluorophore

all_clients_results <- all_clients_results %>% mutate(Traj_ID = paste(molecule_ID, X, Y, sep = "_"))
all_sHsp_results <- all_sHsp_results %>% mutate(Traj_ID = paste(molecule_ID, X, Y, sep = "_"))
all_Hsp70_results <- all_Hsp70_results %>% mutate(Traj_ID = paste(molecule_ID, X, Y, sep = "_")) 

# going to do the clients first which is 555

# now we are going to filter for this treatment (as there are some others here that are client only)

molecule_counts_555 <- molecule_counts_555 %>% 
  mutate(X_Y = paste0(coordsX, "_", coordsY),
         Traj_ID = paste0(Contour_ID, "_", X_Y))

# we have both coloc and non-coloc here

all_clients_results <- all_clients_results %>% mutate(max_fluorescence = NA,
                                                      mol_count_all_small = NA,
                                                      mol_count_last_step = NA,
                                                      mol_count_single_step = NA)


for (i in 1:nrow(all_clients_results)){
  
  current_molecule_ID <- all_clients_results$Traj_ID[i]
  current_molecule_in_py4bleaching_result <- molecule_counts_555 %>% filter(Traj_ID == current_molecule_ID)
  
  if (nrow(current_molecule_in_py4bleaching_result) > 0){
    all_clients_results$max_fluorescence[i] <- current_molecule_in_py4bleaching_result$max_fluorescence
    all_clients_results$mol_count_all_small[i] <- current_molecule_in_py4bleaching_result$all_small_mol_count
    all_clients_results$mol_count_last_step[i] <- current_molecule_in_py4bleaching_result$last_step_mol_count
    all_clients_results$mol_count_single_step[i] <- current_molecule_in_py4bleaching_result$single_step_mol_count
  }
  
}

# now lets do this for the sHsps

# now we are going to filter for this treatment (as there are some others here that are client only)

molecule_counts_647 <- molecule_counts_647 %>% 
  mutate(X_Y = paste0(coordsX, "_", coordsY),
         Traj_ID = paste0(Contour_ID, "_", X_Y))

# we have both coloc and non-coloc here

all_sHsp_results <- all_sHsp_results %>% mutate(max_fluorescence = NA,
                                                mol_count_all_small = NA,
                                                mol_count_last_step = NA,
                                                mol_count_single_step = NA)

for (i in 1:nrow(all_sHsp_results)){
  
  current_molecule_ID <- all_sHsp_results$Traj_ID[i]
  current_molecule_in_py4bleaching_result <- molecule_counts_647 %>% filter(Traj_ID == current_molecule_ID)
  
  if (nrow(current_molecule_in_py4bleaching_result) > 0){
    all_sHsp_results$max_fluorescence[i] <- current_molecule_in_py4bleaching_result$max_fluorescence
    all_sHsp_results$mol_count_all_small[i] <- current_molecule_in_py4bleaching_result$all_small_mol_count
    all_sHsp_results$mol_count_last_step[i] <- current_molecule_in_py4bleaching_result$last_step_mol_count
    all_sHsp_results$mol_count_single_step[i] <- current_molecule_in_py4bleaching_result$single_step_mol_count
  }
  
}


# finally lets do this for the sHsps

# now we are going to filter for this treatment (as there are some others here that are client only)

molecule_counts_488 <- molecule_counts_488 %>% 
  mutate(X_Y = paste0(coordsX, "_", coordsY),
         Traj_ID = paste0(Contour_ID, "_", X_Y))

# we have both coloc and non-coloc here

all_Hsp70_results <- all_Hsp70_results %>% mutate(max_fluorescence = NA,
                                                  mol_count_all_small = NA,
                                                  mol_count_last_step = NA,
                                                  mol_count_single_step = NA)

for (i in 1:nrow(all_Hsp70_results)){
  
  current_molecule_ID <- all_Hsp70_results$Traj_ID[i]
  current_molecule_in_py4bleaching_result <- molecule_counts_488 %>% filter(Traj_ID == current_molecule_ID)
  
  if (nrow(current_molecule_in_py4bleaching_result) > 0){
    all_Hsp70_results$max_fluorescence[i] <- current_molecule_in_py4bleaching_result$max_fluorescence
    all_Hsp70_results$mol_count_all_small[i] <- current_molecule_in_py4bleaching_result$all_small_mol_count
    all_Hsp70_results$mol_count_last_step[i] <- current_molecule_in_py4bleaching_result$last_step_mol_count
    all_Hsp70_results$mol_count_single_step[i] <- current_molecule_in_py4bleaching_result$single_step_mol_count
  }
  
}

write.csv(all_clients_results, file = file.path(local_folder, "full_data", "all_clients_results_coloc_traj.csv"), row.names = FALSE)

write.csv(all_sHsp_results, file = file.path(local_folder, "full_data", "all_sHsp_results_coloc_traj.csv"), row.names = FALSE)

write.csv(all_Hsp70_results, file = file.path(local_folder, "full_data", "all_Hsp70_results_coloc_traj.csv"), row.names = FALSE)

# Matching IDs to the other dataframes ------------------------------------

all_clients_results_coloc_traj <- read.csv(all_clients_results_coloc_traj_path)

all_sHsp_results_coloc_traj <- read.csv(all_sHsp_results_coloc_traj_path)

all_Hsp70_results_coloc_traj <- read.csv(all_Hsp70_results_coloc_traj_path)

# getting the complexes that involve clients
clients_coloc <- all_clients_results_coloc_traj %>% filter(coloc_sHsp == "Yes" | coloc_Hsp70 == "Yes")

colnames(clients_coloc)

clients_coloc <- clients_coloc %>%
  mutate(sHsp_max_fluorescence = NA,
         sHsp_mol_count_all_small = NA,
         sHsp_mol_count_last_step = NA,
         sHsp_mol_count_single_step = NA,
         Hsp70_max_fluorescence = NA,
         Hsp70_mol_count_all_small = NA,
         Hsp70_mol_count_last_step = NA,
         Hsp70_mol_count_single_step = NA)

for (i in 1:nrow(clients_coloc)){
  
  current_client_mol <- clients_coloc$molecule_ID[i]
  
  is_coloc_sHsp <- clients_coloc$coloc_sHsp[i]
  
  if(is_coloc_sHsp == "Yes"){
    current_mol_in_sHsp <- all_sHsp_results_coloc_traj %>% filter(coloc_client_molecule_ID == current_client_mol)
    clients_coloc$sHsp_max_fluorescence[i] <- current_mol_in_sHsp$max_fluorescence
    clients_coloc$sHsp_mol_count_all_small[i] <- current_mol_in_sHsp$mol_count_all_small
    clients_coloc$sHsp_mol_count_last_step[i] <- current_mol_in_sHsp$mol_count_last_step 
    clients_coloc$sHsp_mol_count_single_step[i] <- current_mol_in_sHsp$mol_count_single_step
  }
  
  is_coloc_Hsp70 <- clients_coloc$coloc_Hsp70[i]
  
  if(is_coloc_Hsp70 == "Yes"){
    current_mol_in_Hsp70 <- all_Hsp70_results_coloc_traj %>% filter(coloc_client_molecule_ID == current_client_mol)
    clients_coloc$Hsp70_max_fluorescence[i] <- current_mol_in_Hsp70$max_fluorescence
    clients_coloc$Hsp70_mol_count_all_small[i] <- current_mol_in_Hsp70$mol_count_all_small
    clients_coloc$Hsp70_mol_count_last_step[i] <- current_mol_in_Hsp70$mol_count_last_step 
    clients_coloc$Hsp70_mol_count_single_step[i] <- current_mol_in_Hsp70$mol_count_single_step
  }
}

write.csv(clients_coloc, file = file.path(local_folder, "full_data", "client_complexes.csv"), row.names = F)

# now we just need to do the complexes that are between sHsps and Hsp70 molecules

sHsp_coloc <- all_sHsp_results_coloc_traj %>% filter(coloc_Hsp70 == "Yes")

colnames(sHsp_coloc)

sHsp_coloc <- sHsp_coloc %>%
  mutate(Hsp70_max_fluorescence = NA,
         Hsp70_mol_count_all_small = NA,
         Hsp70_mol_count_last_step = NA,
         Hsp70_mol_count_single_step = NA)


for (i in 1:nrow(sHsp_coloc)){
  
  current_sHsp_mol <- sHsp_coloc$molecule_ID[i]
  
  is_coloc_Hsp70 <- sHsp_coloc$coloc_Hsp70[i]
  
  if(is_coloc_Hsp70 == "Yes"){
    current_mol_in_Hsp70 <- all_Hsp70_results_coloc_traj %>% filter(coloc_sHsp_molecule_ID == current_sHsp_mol)
    sHsp_coloc$Hsp70_max_fluorescence[i] <- current_mol_in_Hsp70$max_fluorescence
    sHsp_coloc$Hsp70_mol_count_all_small[i] <- current_mol_in_Hsp70$mol_count_all_small
    sHsp_coloc$Hsp70_mol_count_last_step[i] <- current_mol_in_Hsp70$mol_count_last_step 
    sHsp_coloc$Hsp70_mol_count_single_step[i] <- current_mol_in_Hsp70$mol_count_single_step
  }
}

write.csv(sHsp_coloc, file = file.path(local_folder, "full_data", "sHsp_Hsp70_complexes.csv"), row.names = FALSE)

# Graphing heat maps for client complexes with sHsp -------------------------------------------------------

# we want only the colocalised molecules here I think so that we can have client on x axis and sHsp on y or vice versa

complexes <- read.csv(client_complexes_path)

# firstly we want to look at the complexes between clients and sHsps

client_sHsp_complexes_only <- complexes %>% filter(coloc_sHsp == "Yes")

# now we want to remove the rows that have NA in the trajectory columns for either the CLIENT or the sHsp
client_sHsp_complexes_only <- client_sHsp_complexes_only[!is.na(client_sHsp_complexes_only$mol_count_last_step), ]
client_sHsp_complexes_only <- client_sHsp_complexes_only[!is.na(client_sHsp_complexes_only$sHsp_mol_count_last_step), ]

client_sHsp_heatmap <- ggplot(data = client_sHsp_complexes_only, aes(x = mol_count_last_step, y = sHsp_mol_count_last_step))+
  geom_hex(colour = "black", linewidth= 0.5)+
  scale_fill_viridis_b() +
  scale_x_continuous(breaks = seq(floor(min(complexes$mol_count_last_step, na.rm=TRUE)),
                                  ceiling(max(complexes$mol_count_last_step, na.rm=TRUE)), 
                                  by = 1)) +
  scale_y_continuous(breaks = seq(floor(min(complexes$sHsp_mol_count_last_step, na.rm=TRUE)),
                                  ceiling(max(complexes$sHsp_mol_count_last_step, na.rm=TRUE)), 
                                  by = 1)) +
  labs(x = "Client mol count (last step)",
       y = "sHsp mol count (last step)",
       fill = "Count") +
  facet_wrap(~Treatment_name) +
  theme_minimal()
print(client_sHsp_heatmap)

png(filename = file.path(local_folder, "analysis_outputs", "heatmap_traj_client_sHsp.png"), units="px", width=2000, height=1600, res=300)
print(client_sHsp_heatmap)
dev.off()

# Graphing heat maps for client complexes with Hsp70 -------------------------------------------------------

# now let's look at the complexes between clients and Hsp70

client_Hsp70_complexes_only <- complexes %>% filter(coloc_Hsp70 == "Yes")

# now we want to remove the rows that have NA in the trajectory columns for either the CLIENT or the Hsp70
client_Hsp70_complexes_only <- client_Hsp70_complexes_only[!is.na(client_Hsp70_complexes_only$mol_count_last_step), ]
client_Hsp70_complexes_only <- client_Hsp70_complexes_only[!is.na(client_Hsp70_complexes_only$Hsp70_mol_count_last_step), ]

client_Hsp70_heatmap <- ggplot(data = client_Hsp70_complexes_only, aes(x = mol_count_last_step, y = Hsp70_mol_count_last_step))+
  geom_hex(colour = "black", linewidth= 0.5)+
  scale_fill_viridis_b() +
  scale_x_continuous(breaks = seq(floor(min(complexes$mol_count_last_step, na.rm=TRUE)),
                                  ceiling(max(complexes$mol_count_last_step, na.rm=TRUE)), 
                                  by = 1)) +
  scale_y_continuous(breaks = seq(floor(min(complexes$Hsp70_mol_count_last_step, na.rm=TRUE)),
                                  ceiling(max(complexes$Hsp70_mol_count_last_step, na.rm=TRUE)), 
                                  by = 1)) +
  labs(x = "Client mol count (last step)",
       y = "Hsp70 mol count (last step)",
       fill = "Count") +
  theme_minimal() +
  facet_wrap(~Treatment_name)
print(client_Hsp70_heatmap)


png(filename = file.path(local_folder, "analysis_outputs", "heatmap_traj_client_hsp70.png"), units="px", width=2000, height=1600, res=300)
print(client_Hsp70_heatmap)
dev.off()

