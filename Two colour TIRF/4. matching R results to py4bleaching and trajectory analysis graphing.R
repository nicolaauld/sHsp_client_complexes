library(tidyverse)
library(tidylog)

# This code follows on with the analysis including the results of py4bleaching. The py4bleaching module will generate
# a results folder called "python_results_647" for the AF647 molecules and equivalent ones for the other
# labelled proteins

# This code extracts that information and matches it back to the results with the colocalisation information. It also
# has some code to make a heatmap of the sizes of the different molecules

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

# Now loading up the paths for the py4bleaching molecule counts results

molecule_counts_488 <- read.csv(file = file.path("C:", "Nicola", "UNIVERSITY", "PhD", "SM", "Fluc", paste0(experiment_date, "_TWO_COLOUR"),"python_results-ATTO532", "calculate_molecule_size", "molecule_counts.csv"))

# now lets do this for the hsps

molecule_counts_647 <- read.csv(file = file.path("C:", "Nicola", "UNIVERSITY", "PhD", "SM", "Fluc", paste0(experiment_date, "_TWO_COLOUR"), "python_results-647", "calculate_molecule_size", "molecule_counts.csv"))

# AF488 molecules ---------------------------------------------------------

# Need to do separately for 488 and 647 because we ran py4bleaching separately for each fluorophore

all_clients_results <- read.csv(file = file.path(local_folder, "full_data", "all_clients_results.csv"))

all_hsp_results <- read.csv(file = file.path(local_folder, "full_data", "all_hsp_results.csv"))

all_clients_results <- all_clients_results %>% mutate(Traj_ID = paste(molecule_ID, X, Y, sep = "_"))
all_hsp_results <- all_hsp_results %>% mutate(Traj_ID = paste(molecule_ID, X, Y, sep = "_")) 

# now we are going to filter for this treatment (as there are some others here that are client only)

molecule_counts_488 <- molecule_counts_488 %>% 
  #filter(protein1 == "ATP") %>%
  mutate(X_Y = paste0(coordsX, "_", coordsY),
         Traj_ID = paste0(Contour_ID, "_", X_Y))

# we have both coloc and non-coloc here

all_clients_results <- all_clients_results %>% mutate(max_fluorescence = NA,
                                                      mol_count_all_small = NA,
                                                      mol_count_last_step = NA,
                                                      mol_count_single_step = NA)


for (i in 1:nrow(all_clients_results)){
  
  current_molecule_ID <- all_clients_results$Traj_ID[i]
  current_molecule_in_py4bleaching_result <- molecule_counts_488 %>% filter(Traj_ID == current_molecule_ID)
  
  if (nrow(current_molecule_in_py4bleaching_result) > 0){
    all_clients_results$max_fluorescence[i] <- current_molecule_in_py4bleaching_result$max_fluorescence
    all_clients_results$mol_count_all_small[i] <- current_molecule_in_py4bleaching_result$all_small_mol_count
    all_clients_results$mol_count_last_step[i] <- current_molecule_in_py4bleaching_result$last_step_mol_count
    all_clients_results$mol_count_single_step[i] <- current_molecule_in_py4bleaching_result$single_step_mol_count
  }
  
}

# doing some quick graphs

subunits <- ggplot(data = all_clients_results, aes(x = coloc, y = log10(mol_count_last_step + 1))) +
  geom_boxplot() +
  theme_minimal()
print(subunits)

histograms <- ggplot(data = all_clients_results, aes(x = mol_count_last_step)) +
  geom_histogram() +
  theme_minimal() +
  facet_wrap(~coloc)
print(histograms)

log_histograms <- ggplot(data = all_clients_results, aes(x = log10(mol_count_last_step+1))) +
  geom_histogram() +
  theme_minimal() +
  facet_wrap(~coloc, scales = "free_y")
print(log_histograms)


# AF647 molecules ---------------------------------------------------------

# now we are going to filter for this treatment (as there are some others here that are client only)

molecule_counts_647 <- molecule_counts_647 %>% 
  #filter(protein1 == "ATP") %>%
  mutate(X_Y = paste0(coordsX, "_", coordsY),
         Traj_ID = paste0(Contour_ID, "_", X_Y))

# we have both coloc and non-coloc here

all_hsp_results <- all_hsp_results %>% mutate(max_fluorescence = NA,
                                              mol_count_all_small = NA,
                                              mol_count_last_step = NA,
                                              mol_count_single_step = NA)

for (i in 1:nrow(all_hsp_results)){
  
  current_molecule_ID <- all_hsp_results$Traj_ID[i]
  current_molecule_in_py4bleaching_result <- molecule_counts_647 %>% filter(Traj_ID == current_molecule_ID)
  
  if (nrow(current_molecule_in_py4bleaching_result) > 0){
    all_hsp_results$max_fluorescence[i] <- current_molecule_in_py4bleaching_result$max_fluorescence
    all_hsp_results$mol_count_all_small[i] <- current_molecule_in_py4bleaching_result$all_small_mol_count
    all_hsp_results$mol_count_last_step[i] <- current_molecule_in_py4bleaching_result$last_step_mol_count
    all_hsp_results$mol_count_single_step[i] <- current_molecule_in_py4bleaching_result$single_step_mol_count
  }
  
}

# doing some quick graphs

subunits <- ggplot(data = all_hsp_results, aes(x = coloc, y = log10(mol_count_last_step + 1))) +
  geom_boxplot() +
  theme_minimal()
print(subunits)

histograms <- ggplot(data = all_hsp_results, aes(x = mol_count_last_step)) +
  geom_histogram() +
  theme_minimal() +
  facet_wrap(~coloc, scales = "free_y")
print(histograms)

log_histograms <- ggplot(data = all_hsp_results, aes(x = log10(mol_count_last_step+1))) +
  geom_histogram() +
  theme_minimal() +
  facet_wrap(~coloc, scales = "free_y")
print(log_histograms)


# Combining results for both proteins -------------------------------------------------------

# want to now combine all of this into one big dataframe

# lets add the hsps to the clients dataframe


all_molecule_results <- all_clients_results

all_molecule_results <- all_molecule_results %>%
  rename(client_X = X,
         client_Y = Y,
         client_molecule_ID = molecule_ID,
         is_client_coloc = coloc,
         hsp_molecule_ID = coloc_molecule_ID,
         client_coloc_scramble = coloc_scramble,
         client_Traj_ID = Traj_ID,
         client_max_fluorescence = max_fluorescence,
         client_mol_count_all_small = mol_count_all_small,
         client_mol_count_last_step = mol_count_last_step,
         client_mol_count_single_step = mol_count_single_step)

all_molecule_results <- all_molecule_results %>% mutate(hsp_X = NA,
                                                        hsp_Y = NA,
                                                        hsp_Traj_ID = NA,
                                                        hsp_max_fluorescence = NA,
                                                        hsp_mol_count_all_small = NA,
                                                        hsp_mol_count_last_step = NA,
                                                        hsp_mol_count_single_step = NA)

# now we have to make a giant for loop to match up all of this data

for (i in 1:nrow(all_molecule_results)){
  current_client <- all_molecule_results$client_molecule_ID[i]
  current_hsp <- all_molecule_results$hsp_molecule_ID[i]
  
  # this checks if the hsp_molecule_ID is empty meaning that this client does not have a colocalised hsp
  if (any(is.na(current_hsp)) == F){
    hsp_in_hsp <- all_hsp_results %>% filter(molecule_ID == current_hsp)
    all_molecule_results$hsp_X[i] <- hsp_in_hsp$X
    all_molecule_results$hsp_Y[i] <- hsp_in_hsp$Y
    all_molecule_results$hsp_Traj_ID[i] <- hsp_in_hsp$Traj_ID
    all_molecule_results$hsp_max_fluorescence[i] <- hsp_in_hsp$max_fluorescence
    all_molecule_results$hsp_mol_count_all_small[i] <- hsp_in_hsp$mol_count_all_small
    all_molecule_results$hsp_mol_count_last_step[i] <- hsp_in_hsp$mol_count_last_step
    all_molecule_results$hsp_mol_count_single_step[i] <- hsp_in_hsp$mol_count_single_step
  } 
}

# now we need to fix up the non-coloc hsps so that we can add those into the all_molecule_results
colnames(all_molecule_results)

all_hsp_results_noncoloc <- all_hsp_results %>% filter(coloc == "No")

colnames(all_hsp_results_noncoloc)

all_hsp_results_noncoloc <- all_hsp_results_noncoloc %>%
  rename(hsp_X = X,
         hsp_Y = Y,
         hsp_molecule_ID = molecule_ID,
         is_hsp_coloc = coloc,
         hsp_Traj_ID = Traj_ID,
         hsp_max_fluorescence = max_fluorescence,
         hsp_mol_count_all_small = mol_count_all_small,
         hsp_mol_count_last_step = mol_count_last_step,
         hsp_mol_count_single_step = mol_count_single_step)

colnames(all_hsp_results_noncoloc)



all_hsp_results_noncoloc <- all_hsp_results_noncoloc %>% mutate(client_coloc_scramble = NA,
                                                                client_Traj_ID = NA,
                                                                client_X = NA,
                                                                client_Y = NA,
                                                                client_molecule_ID = NA,
                                                                is_client_coloc = NA,
                                                                client_max_fluorescence = NA,
                                                                client_mol_count_all_small = NA,
                                                                client_mol_count_last_step = NA,
                                                                client_mol_count_single_step = NA)
colnames(all_hsp_results_noncoloc)

all_molecule_results <- all_molecule_results %>%
  mutate(is_hsp_coloc = case_when(
    is_client_coloc == "Yes" ~ "Yes",
    TRUE ~ NA_character_))

a <- colnames(all_molecule_results)
b <- colnames(all_hsp_results_noncoloc)

setdiff(b, a)

all_hsp_results_noncoloc <- all_hsp_results_noncoloc %>% select(-c(coloc_molecule_ID, coloc_scramble))

full_molecule_results <- rbind(all_molecule_results, all_hsp_results_noncoloc)

write.csv(full_molecule_results, file = file.path(local_folder, "analysis_outputs", "full_molecule_results.csv"), row.names = F)


# Graphing heat map -------------------------------------------------------

# we want only the colocalised molecules here I think so that we can have client on x axis and hsp on y or vice versa

full_molecule_results <- read.csv(file = file.path(local_folder, "analysis_outputs", "full_molecule_results.csv"))

complexes <- full_molecule_results %>% filter(is_client_coloc == "Yes")

# we also want to remove the NAs i.e. the ones that we don't have trajectory information for because their trajectories were bad

complexes_traj <- na.omit(complexes)

#install.packages("hexbin")
library(hexbin)

heatmap_test <- ggplot(data = complexes_traj, aes(x = client_mol_count_last_step, y = hsp_mol_count_last_step))+
  geom_hex(colour = "black", linewidth= 0.5)+
  scale_fill_viridis_b() +
  scale_x_continuous(breaks = seq(floor(min(complexes_traj$client_mol_count_last_step, na.rm=TRUE)),
                                  ceiling(max(complexes_traj$client_mol_count_last_step, na.rm=TRUE)), 
                                  by = 1)) +
  scale_y_continuous(breaks = seq(floor(min(complexes_traj$hsp_mol_count_last_step, na.rm=TRUE)),
                                  ceiling(max(complexes_traj$hsp_mol_count_last_step, na.rm=TRUE)), 
                                  by = 1)) +
  labs(x = "Client mol count (last step)",
       y = "HSP mol count (last step)",
       fill = "Count") +
  theme_minimal()
print(heatmap_test)

# now lets do histograms of the non-colocalised ones

hsp_non_coloc <- full_molecule_results %>% 
  filter(is_hsp_coloc == "No") %>%
  select(hsp_Traj_ID, hsp_max_fluorescence, hsp_mol_count_all_small, hsp_mol_count_last_step, hsp_mol_count_single_step)

hsp_non_coloc <- na.omit(hsp_non_coloc)

hsp_non_coloc_histograms <- ggplot(data = hsp_non_coloc, aes(x = hsp_mol_count_last_step)) +
  geom_histogram() +
  theme_minimal()
print(hsp_non_coloc_histograms)

hsp_non_coloc_histograms <- ggplot(data = hsp_non_coloc, aes(x = log10(hsp_mol_count_last_step))) +
  geom_histogram() +
  theme_minimal()
print(hsp_non_coloc_histograms)

client_non_coloc <- full_molecule_results %>% 
  filter(is_client_coloc == "No") %>%
  select(client_Traj_ID, client_max_fluorescence, client_mol_count_all_small, client_mol_count_last_step, client_mol_count_single_step)

client_non_coloc <- na.omit(client_non_coloc)

client_non_coloc_histograms <- ggplot(data = client_non_coloc, aes(x = client_mol_count_last_step)) +
  geom_histogram() +
  theme_minimal()
print(client_non_coloc_histograms)


# ok now we need to do coloc vs non_coloc

client <- full_molecule_results %>% filter(!is.na(client_molecule_ID))

client_histograms <- ggplot(data = na.omit(client[,c(9, 13:17)]), aes(x = client_mol_count_last_step)) +
  geom_histogram() +
  facet_wrap(~is_client_coloc) +
  theme_minimal()
print(client_histograms)

client_histograms <- ggplot(data = na.omit(client[,c(9, 13:17)]), aes(x = log10(client_mol_count_last_step+1))) +
  geom_histogram() +
  facet_wrap(~is_client_coloc, scales = "free_y") +
  theme_minimal()
print(client_histograms)


hsp <- full_molecule_results %>% filter(!is.na(hsp_molecule_ID))

hsp_histograms <- ggplot(data = na.omit(hsp[,c(25, 21:24)]), aes(x = hsp_mol_count_last_step, y = after_stat(count / sum(count) * 100))) +
  geom_histogram() +
  facet_wrap(~is_hsp_coloc, scales = "free_y") +
  theme_minimal()
print(hsp_histograms)

hsp_histograms <- ggplot(data = na.omit(hsp[,c(25, 21:24)]), aes(x = log10(hsp_mol_count_last_step+1))) +
  geom_histogram() +
  facet_wrap(~is_hsp_coloc, scales = "free_y") +
  theme_minimal()
print(hsp_histograms)

# ENd ---------------------------------------------------------------------

rm(list = ls()) #clears environment
dev.off()  # clears plots
cat("\014")  # ctrl+L clears console