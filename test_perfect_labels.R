library(igraph)
library(ggplot2)
library(dplyr)

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

# Organic, natural core arrangement:
core_pos <- data.frame(
  Species = c("Centaurea jacea", "Succisa pratensis", "Achillea ptarmica", "Selinum carvifolia", "Pimpinella saxifraga", "Ranunculus acris"),
  x = c( 0.05,  1.40, -1.30,  0.15,  1.10, -0.95),
  y = c( 0.15, -0.35,  0.40, -1.35,  1.20, -0.85),
  lbl_x = c(-0.10,  2.55, -2.45,  0.15,  2.25, -2.15),
  lbl_y = c( 0.65, -0.35,  0.80, -2.05,  1.70, -1.35)
)

set.seed(2026)
periph_sp <- subset(plant_nodes, Role == "Peripheral Plant")$Species

coords <- matrix(0, nrow = nrow(plant_nodes), ncol = 2)
rownames(coords) <- plant_nodes$Species

for (i in 1:nrow(core_pos)) {
  coords[core_pos$Species[i], ] <- c(core_pos$x[i], core_pos$y[i])
}

# Dedicated positions for the 3 labeled peripheral plants so they represent peripheral spokes cleanly:
# Cirsium palustre: North periphery
coords["Cirsium palustre", ] <- c(0.2, 3.1)
# Lathyrus pratensis: South-West periphery
coords["Lathyrus pratensis", ] <- c(-2.7, -2.1)
# Ranunculus flammula: South-East periphery
coords["Ranunculus flammula", ] <- c(2.6, -2.2)

# Distribute remaining peripheral plants organically
remaining_periph <- setdiff(periph_sp, c("Cirsium palustre", "Lathyrus pratensis", "Ranunculus flammula"))

for (sp in remaining_periph) {
  weights <- plant_adj[sp, core_pos$Species]
  if (sum(weights) > 0) {
    w_norm <- weights / sum(weights)
    center_x <- sum(w_norm * core_pos$x)
    center_y <- sum(w_norm * core_pos$y)
  } else {
    center_x <- 0
    center_y <- 0
  }
  angle <- atan2(center_y + rnorm(1, 0, 0.4), center_x + rnorm(1, 0, 0.4))
  deg <- sum(plant_adj[sp, ])
  dist_factor <- 2.4 + 1.4 * (1 - min(deg, 25) / 25) + rnorm(1, 0, 0.25)
  coords[sp, 1] <- center_x + dist_factor * cos(angle)
  coords[sp, 2] <- center_y + dist_factor * sin(angle)
}

# 80 relaxation steps for smooth organic distribution
for (iter in 1:80) {
  for (i in 1:length(remaining_periph)) {
    sp1 <- remaining_periph[i]
    p1 <- coords[sp1, ]
    force_x <- 0
    force_y <- 0
    for (j in 1:nrow(coords)) {
      if (rownames(coords)[j] != sp1) {
        p2 <- coords[j, ]
        dx <- p1[1] - p2[1]
        dy <- p1[2] - p2[2]
        d <- sqrt(dx^2 + dy^2)
        if (d < 0.70 && d > 0.001) {
          repel <- (0.70 - d) / d
          force_x <- force_x + dx * repel * 0.18
          force_y <- force_y + dy * repel * 0.18
        }
      }
    }
    coords[sp1, 1] <- coords[sp1, 1] + force_x
    coords[sp1, 2] <- coords[sp1, 2] + force_y
  }
}

plant_nodes$x <- coords[plant_nodes$Species, 1]
plant_nodes$y <- coords[plant_nodes$Species, 2]

edges_plant <- igraph::as_data_frame(g_plant, what = "edges")
edges_plant <- merge(edges_plant, plant_nodes[, c("Species", "x", "y", "Role")], by.x = "from", by.y = "Species")
colnames(edges_plant)[4:6] <- c("x1", "y1", "role1")
edges_plant <- merge(edges_plant, plant_nodes[, c("Species", "x", "y", "Role")], by.x = "to", by.y = "Species")
colnames(edges_plant)[7:9] <- c("x2", "y2", "role2")

edges_plant$EdgeType <- ifelse(edges_plant$role1 == "Core Plant" & edges_plant$role2 == "Core Plant", "Core-Core",
                        ifelse(edges_plant$role1 == "Core Plant" | edges_plant$role2 == "Core Plant", "Core-Spoke", "Spoke-Spoke"))

edges_plot <- subset(edges_plant, EdgeType == "Core-Core" | (EdgeType == "Core-Spoke" & weight >= 3) | (EdgeType == "Spoke-Spoke" & weight >= 8))

# Labeled data frames
labels_core <- subset(plant_nodes, Role == "Core Plant")
labels_core <- merge(labels_core, core_pos[, c("Species", "lbl_x", "lbl_y")], by = "Species")
labels_core$LabelText <- paste0(labels_core$Species, "\nk=", labels_core$Mean_k_round, ", Gc=", labels_core$Gc_round)

ex_periph_df <- subset(plant_nodes, Species %in% c("Cirsium palustre", "Lathyrus pratensis", "Ranunculus flammula"))
ex_periph_df$LabelText <- paste0(ex_periph_df$Species, "\nk=", ex_periph_df$Mean_k_round, ", Gc=", ex_periph_df$Gc_round)
# Offsets for peripheral labels
ex_periph_df$lbl_x <- c(0.2, -2.7, 2.6)
ex_periph_df$lbl_y <- c(3.7, -2.7, -2.8)

base_theme <- theme_void() +
  theme(
    plot.margin = margin(2, 2, 2, 2),
    panel.background = element_rect(fill = "#FAFAFA", color = "#CBD5E1", linewidth = 1)
  )

p <- ggplot() +
  # Spoke routes
  geom_segment(data = subset(edges_plot, EdgeType != "Core-Core"),
               aes(x = x1, y = y1, xend = x2, yend = y2),
               color = "#93C5FD", alpha = 0.28, linewidth = 0.4) +
  # Core-Core backbone routes
  geom_segment(data = subset(edges_plot, EdgeType == "Core-Core"),
               aes(x = x1, y = y1, xend = x2, yend = y2),
               color = "#1D4ED8", alpha = 0.88, linewidth = 1.2) +
  # Peripheral plants
  geom_point(data = subset(plant_nodes, Role == "Peripheral Plant"),
             aes(x = x, y = y), color = "#F87171", alpha = 0.75, size = 2.8) +
  # Core plants
  geom_point(data = subset(plant_nodes, Role == "Core Plant"),
             aes(x = x, y = y), color = "#1E3A8A", size = 6.8, alpha = 0.95) +
  geom_point(data = subset(plant_nodes, Role == "Core Plant"),
             aes(x = x, y = y), color = "#FBBF24", size = 3.6) +
  # Callout lines for core labels
  geom_segment(data = labels_core, aes(x = x, y = y, xend = lbl_x, yend = lbl_y),
               color = "#1E3A8A", alpha = 0.6, linewidth = 0.5) +
  # Callout lines for peripheral labels
  geom_segment(data = ex_periph_df, aes(x = x, y = y, xend = lbl_x, yend = lbl_y),
               color = "#DC2626", alpha = 0.6, linewidth = 0.5) +
  # Core labels
  geom_label(data = labels_core, aes(x = lbl_x, y = lbl_y, label = LabelText),
             fontface = "bold.italic", size = 3.3, color = "#0F172A", fill = alpha("white", 0.95),
             label.padding = unit(0.25, "lines"), label.r = unit(0.2, "lines")) +
  # Peripheral labels
  geom_label(data = ex_periph_df, aes(x = lbl_x, y = lbl_y, label = LabelText),
             fontface = "italic", size = 3.0, color = "#B91C1C", fill = alpha("#FEF2F2", 0.96),
             label.padding = unit(0.25, "lines"), label.r = unit(0.2, "lines")) +
  coord_fixed(xlim = c(-4.6, 4.6), ylim = c(-4.6, 4.6)) +
  base_theme

ggsave("test_perfect_labels.png", p, width = 7.5, height = 6.4, dpi = 300)
cat("Saved test_perfect_labels.png\n")
