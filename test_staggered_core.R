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

# Core positions: Staggered natural layout (like Frankfurt in the center, Paris/London/Munich/Amsterdam around it)
core_pos <- data.frame(
  Species = c("Centaurea jacea", "Succisa pratensis", "Achillea ptarmica", "Selinum carvifolia", "Pimpinella saxifraga", "Ranunculus acris"),
  x = c(0.15,  1.25, -1.15,  0.20,  0.95, -0.90),
  y = c(0.10, -0.45,  0.35, -1.25,  1.10, -0.85)
)

set.seed(101)
periph_sp <- subset(plant_nodes, Role == "Peripheral Plant")$Species

coords <- matrix(0, nrow = nrow(plant_nodes), ncol = 2)
rownames(coords) <- plant_nodes$Species

for (i in 1:nrow(core_pos)) {
  coords[core_pos$Species[i], ] <- c(core_pos$x[i], core_pos$y[i])
}

for (sp in periph_sp) {
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
  dist_factor <- 2.2 + 1.8 * (1 - min(deg, 30) / 30) + rnorm(1, 0, 0.25)
  coords[sp, 1] <- center_x + dist_factor * cos(angle)
  coords[sp, 2] <- center_y + dist_factor * sin(angle)
}

# Relaxation
for (iter in 1:60) {
  for (i in 1:length(periph_sp)) {
    sp1 <- periph_sp[i]
    p1 <- coords[sp1, ]
    force_x <- 0
    force_y <- 0
    for (j in 1:nrow(coords)) {
      if (rownames(coords)[j] != sp1) {
        p2 <- coords[j, ]
        dx <- p1[1] - p2[1]
        dy <- p1[2] - p2[2]
        d <- sqrt(dx^2 + dy^2)
        if (d < 0.65 && d > 0.001) {
          repel <- (0.65 - d) / d
          force_x <- force_x + dx * repel * 0.15
          force_y <- force_y + dy * repel * 0.15
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

# Match line styling of airport network:
# On airport network, flight routes are thin blue lines (#60A5FA / #3B82F6),
# and core-core routes are weighted or clean blue lines:
edges_plot <- subset(edges_plant, EdgeType == "Core-Core" | (EdgeType == "Core-Spoke" & weight >= 3) | (EdgeType == "Spoke-Spoke" & weight >= 8))

plant_nodes$Label <- ifelse(plant_nodes$Role == "Core Plant",
                           paste0(plant_nodes$Species, "\nk=", plant_nodes$Mean_k_round, ", Gc=", plant_nodes$Gc_round),
                           "")
ex_periph <- c("Lathyrus pratensis", "Ranunculus flammula", "Cirsium palustre")
plant_nodes$Label[plant_nodes$Species %in% ex_periph] <- paste0(plant_nodes$Species[plant_nodes$Species %in% ex_periph], "\nk=", plant_nodes$Mean_k_round[plant_nodes$Species %in% ex_periph], ", Gc=", plant_nodes$Gc_round[plant_nodes$Species %in% ex_periph])

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
               color = "#1D4ED8", alpha = 0.85, linewidth = 1.1) +
  # Peripheral plants
  geom_point(data = subset(plant_nodes, Role == "Peripheral Plant"),
             aes(x = x, y = y), color = "#F87171", alpha = 0.75, size = 2.8) +
  # Core plants
  geom_point(data = subset(plant_nodes, Role == "Core Plant"),
             aes(x = x, y = y), color = "#1E3A8A", size = 6.8, alpha = 0.95) +
  geom_point(data = subset(plant_nodes, Role == "Core Plant"),
             aes(x = x, y = y), color = "#FBBF24", size = 3.6) +
  # Labels with explicit direction nudging to keep them totally legible
  geom_label_repel(data = subset(plant_nodes, Role == "Core Plant"),
                   aes(x = x, y = y, label = Label),
                   fontface = "bold.italic", size = 3.3, color = "#0F172A", fill = alpha("white", 0.93),
                   box.padding = 0.5, point.padding = 0.35, segment.color = "#1E3A8A", segment.size = 0.5) +
  geom_label_repel(data = subset(plant_nodes, Species %in% ex_periph),
                   aes(x = x, y = y, label = Label),
                   fontface = "italic", size = 3.0, color = "#B91C1C", fill = alpha("#FEF2F2", 0.95),
                   box.padding = 0.45, point.padding = 0.35, segment.color = "#DC2626", segment.size = 0.5) +
  coord_fixed(xlim = c(-4.5, 4.5), ylim = c(-4.5, 4.5)) +
  base_theme

ggsave("test_staggered_core.png", p, width = 7.5, height = 6.4, dpi = 300)
cat("Saved test_staggered_core.png\n")
