library(igraph)
library(ggplot2)
library(dplyr)
library(ggrepel)

load('/home/meow/ownCloud - Mgr Jakub Štenc Phd@owncloud.cesnet.cz/Psani_clanku/2025/Annual_dynamics_pollinator_sharing/local_packages/HanPolNet/data/interaction_data.rda')
core_def <- read.csv('/home/meow/ownCloud - Mgr Jakub Štenc Phd@owncloud.cesnet.cz/Psani_clanku/2025/Annual_dynamics_pollinator_sharing/outputs/Data_Prep/core_definition.csv')

valid_interactions <- subset(interaction_data, network_species != "not_network_species" & !is.na(plant_name) & plant_name != "")

bip_tab <- table(valid_interactions$plant_name, valid_interactions$network_species)
bip_mat <- as.matrix(bip_tab > 0) + 0

plant_adj <- bip_mat %*% t(bip_mat)
diag(plant_adj) <- 0

common_plants <- intersect(rownames(plant_adj), core_def$Plant_Species)
plant_adj <- plant_adj[common_plants, common_plants]

plant_nodes <- data.frame(Species = common_plants, stringsAsFactors = FALSE)
plant_nodes <- merge(plant_nodes, core_def[, c("Plant_Species", "Mean_k", "Obs_Mean_Gc", "Core_Status")], by.x = "Species", by.y = "Plant_Species")
plant_nodes$Role <- ifelse(plant_nodes$Core_Status == "Core", "Core Plant", "Peripheral Plant")
plant_nodes$Mean_k_round <- round(plant_nodes$Mean_k, 1)
plant_nodes$Gc_round <- round(plant_nodes$Obs_Mean_Gc, 2)

g_plant <- graph_from_adjacency_matrix(plant_adj, mode = "undirected", weighted = TRUE)

# Let's inspect layout with kamada-kawai and fruchterman-reingold with different parameters
set.seed(42)
l_kk <- layout_with_kk(g_plant)
set.seed(42)
l_fr <- layout_with_fr(g_plant, niter = 2000, start.temp = 5, weights = E(g_plant)$weight^0.3)

# Let's print positions of core plants in both
core_sp <- subset(plant_nodes, Role == "Core Plant")$Species
cat("Core plants in KK:\n")
rownames(l_kk) <- V(g_plant)$name
print(l_kk[core_sp, ])

cat("Core plants in FR:\n")
rownames(l_fr) <- V(g_plant)$name
print(l_fr[core_sp, ])
