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

# Try several seeds and layout options
for (s in c(42, 101, 7, 2026)) {
  set.seed(s)
  # Weight-influenced FR layout
  # For sharing webs, using log or sqrt weight prevents extreme compaction while keeping hubs central
  coords_fr <- layout_with_fr(g_plant, weights = E(g_plant)$weight^0.5, niter = 1000)
  
  # Normalize to -4 to 4 range
  coords_fr[,1] <- (coords_fr[,1] - mean(coords_fr[,1])) / sd(coords_fr[,1]) * 1.8
  coords_fr[,2] <- (coords_fr[,2] - mean(coords_fr[,2])) / sd(coords_fr[,2]) * 1.8
  
  rownames(coords_fr) <- V(g_plant)$name
  
  pn <- plant_nodes
  pn$x <- coords_fr[pn$Species, 1]
  pn$y <- coords_fr[pn$Species, 2]
  
  edges_plant <- igraph::as_data_frame(g_plant, what = "edges")
  edges_plant <- merge(edges_plant, pn[, c("Species", "x", "y", "Role")], by.x = "from", by.y = "Species")
  colnames(edges_plant)[4:6] <- c("x1", "y1", "role1")
  edges_plant <- merge(edges_plant, pn[, c("Species", "x", "y", "Role")], by.x = "to", by.y = "Species")
  colnames(edges_plant)[7:9] <- c("x2", "y2", "role2")
  
  edges_plant$EdgeType <- ifelse(edges_plant$role1 == "Core Plant" & edges_plant$role2 == "Core Plant", "Core-Core",
                          ifelse(edges_plant$role1 == "Core Plant" | edges_plant$role2 == "Core Plant", "Core-Spoke", "Spoke-Spoke"))
  
  edges_plot <- subset(edges_plant, EdgeType == "Core-Core" | (EdgeType == "Core-Spoke" & weight >= 3) | (EdgeType == "Spoke-Spoke" & weight >= 8))
  
  pn$Label <- ifelse(pn$Role == "Core Plant",
                     paste0(pn$Species, "\nk=", pn$Mean_k_round, ", Gc=", pn$Gc_round),
                     "")
  ex_periph <- c("Lathyrus pratensis", "Ranunculus flammula", "Cirsium palustre")
  pn$Label[pn$Species %in% ex_periph] <- paste0(pn$Species[pn$Species %in% ex_periph], "\nk=", pn$Mean_k_round[pn$Species %in% ex_periph], ", Gc=", pn$Gc_round[pn$Species %in% ex_periph])
  
  base_theme <- theme_void() +
    theme(
      plot.margin = margin(2, 2, 2, 2),
      panel.background = element_rect(fill = "#FAFAFA", color = "#CBD5E1", linewidth = 1)
    )
  
  p <- ggplot() +
    # Spoke edges
    geom_segment(data = subset(edges_plot, EdgeType != "Core-Core"),
                 aes(x = x1, y = y1, xend = x2, yend = y2),
                 color = "#93C5FD", alpha = 0.22, linewidth = 0.38) +
    # Core-Core backbone edges
    geom_segment(data = subset(edges_plot, EdgeType == "Core-Core"),
                 aes(x = x1, y = y1, xend = x2, yend = y2),
                 color = "#1D4ED8", alpha = 0.88, linewidth = 1.3) +
    # Peripheral plants
    geom_point(data = subset(pn, Role == "Peripheral Plant"),
               aes(x = x, y = y), color = "#F87171", alpha = 0.75, size = 2.8) +
    # Core plants
    geom_point(data = subset(pn, Role == "Core Plant"),
               aes(x = x, y = y), color = "#1E3A8A", size = 6.8, alpha = 0.95) +
    geom_point(data = subset(pn, Role == "Core Plant"),
               aes(x = x, y = y), color = "#FBBF24", size = 3.6) +
    # Labels
    geom_label_repel(data = subset(pn, Role == "Core Plant"),
                     aes(x = x, y = y, label = Label),
                     fontface = "bold.italic", size = 3.3, color = "#0F172A", fill = alpha("white", 0.92),
                     box.padding = 0.4, point.padding = 0.3, segment.color = "#1E3A8A", segment.size = 0.5) +
    geom_label_repel(data = subset(pn, Species %in% ex_periph),
                     aes(x = x, y = y, label = Label),
                     fontface = "italic", size = 3.0, color = "#B91C1C", fill = alpha("#FEF2F2", 0.95),
                     box.padding = 0.4, point.padding = 0.3, segment.color = "#DC2626", segment.size = 0.5) +
    coord_fixed(xlim = c(-4.8, 4.8), ylim = c(-4.8, 4.8)) +
    base_theme
    
  out_name <- paste0("test_layout_seed_", s, ".png")
  ggsave(out_name, p, width = 7.5, height = 6.4, dpi = 300)
  cat(paste("Saved", out_name, "\n"))
}
