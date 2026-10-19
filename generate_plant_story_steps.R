library(igraph)
library(ggplot2)
library(dplyr)
library(ggrepel)

cat("Step 1: Processing Handrkov pollinator sharing network...\n")
load('/home/meow/ownCloud - Mgr Jakub Štenc Phd@owncloud.cesnet.cz/Psani_clanku/2025/Annual_dynamics_pollinator_sharing/local_packages/HanPolNet/data/interaction_data.rda')
core_def <- read.csv('/home/meow/ownCloud - Mgr Jakub Štenc Phd@owncloud.cesnet.cz/Psani_clanku/2025/Annual_dynamics_pollinator_sharing/outputs/Data_Prep/core_definition.csv')

valid_interactions <- subset(interaction_data, network_species != "not_network_species" & !is.na(plant_name) & plant_name != "")

bip_tab <- table(valid_interactions$plant_name, valid_interactions$network_species)
bip_mat <- as.matrix(bip_tab > 0) + 0

# Plant-plant shared pollinator count
plant_adj <- bip_mat %*% t(bip_mat)
diag(plant_adj) <- 0

common_plants <- intersect(rownames(plant_adj), core_def$Plant_Species)
plant_adj <- plant_adj[common_plants, common_plants]

plant_nodes <- data.frame(
  Species = common_plants,
  stringsAsFactors = FALSE
)
plant_nodes <- merge(plant_nodes, core_def[, c("Plant_Species", "Mean_k", "Obs_Mean_Gc", "Core_Status")], by.x = "Species", by.y = "Plant_Species")
plant_nodes$Role <- ifelse(plant_nodes$Core_Status == "Core", "Core Plant", "Peripheral Plant")
plant_nodes$Mean_k_round <- round(plant_nodes$Mean_k, 1)
plant_nodes$Gc_round <- round(plant_nodes$Obs_Mean_Gc, 2)

# Concentric layout
core_sp <- subset(plant_nodes, Role == "Core Plant")$Species
periph_sp <- subset(plant_nodes, Role == "Peripheral Plant")$Species

n_core <- length(core_sp)
n_periph <- length(periph_sp)

set.seed(42)
# Arrange core species in inner circle
theta_core <- seq(0, 2 * pi, length.out = n_core + 1)[1:n_core]
r_core <- 1.45

# Arrange peripheral species in outer ring with slight organic dispersion
theta_periph <- seq(0, 2 * pi, length.out = n_periph + 1)[1:n_periph]
r_periph <- 3.85 + rnorm(n_periph, 0, 0.2)

coords <- matrix(0, nrow = nrow(plant_nodes), ncol = 2)
rownames(coords) <- plant_nodes$Species

coords[core_sp, 1] <- r_core * cos(theta_core)
coords[core_sp, 2] <- r_core * sin(theta_core)

coords[periph_sp, 1] <- r_periph * cos(theta_periph)
coords[periph_sp, 2] <- r_periph * sin(theta_periph)

plant_nodes$x <- coords[plant_nodes$Species, 1]
plant_nodes$y <- coords[plant_nodes$Species, 2]

# Edge filtering: keep significant sharing connections
g_plant <- graph_from_adjacency_matrix(plant_adj, mode = "undirected", weighted = TRUE)
edges_plant <- igraph::as_data_frame(g_plant, what = "edges")
edges_plant <- merge(edges_plant, plant_nodes[, c("Species", "x", "y", "Role")], by.x = "from", by.y = "Species")
colnames(edges_plant)[4:6] <- c("x1", "y1", "role1")
edges_plant <- merge(edges_plant, plant_nodes[, c("Species", "x", "y", "Role")], by.x = "to", by.y = "Species")
colnames(edges_plant)[7:9] <- c("x2", "y2", "role2")

edges_plant$EdgeType <- ifelse(edges_plant$role1 == "Core Plant" & edges_plant$role2 == "Core Plant", "Core-Core",
                        ifelse(edges_plant$role1 == "Core Plant" | edges_plant$role2 == "Core Plant", "Core-Spoke", "Spoke-Spoke"))

# Filter weak spoke-spoke edges to highlight hub routing
edges_plot <- subset(edges_plant, EdgeType == "Core-Core" | (EdgeType == "Core-Spoke" & weight >= 3) | (EdgeType == "Spoke-Spoke" & weight >= 8))

plant_nodes$Label <- ifelse(plant_nodes$Role == "Core Plant",
                           paste0(plant_nodes$Species, "\nk=", plant_nodes$Mean_k_round, ", Gc=", plant_nodes$Gc_round),
                           "")

ex_periph <- c("Lathyrus pratensis", "Ranunculus flammula", "Cirsium palustre")
plant_nodes$Label[plant_nodes$Species %in% ex_periph] <- paste0(plant_nodes$Species[plant_nodes$Species %in% ex_periph], "\nk=", plant_nodes$Mean_k_round[plant_nodes$Species %in% ex_periph], ", Gc=", plant_nodes$Gc_round[plant_nodes$Species %in% ex_periph])

# Circular boundary circle for stage 1
t_seq <- seq(0, 2 * pi, length.out = 100)
outer_circle <- data.frame(x = 4.3 * cos(t_seq), y = 4.3 * sin(t_seq))
inner_circle <- data.frame(x = 1.45 * cos(t_seq), y = 1.45 * sin(t_seq))

base_theme <- theme_void() +
  theme(
    plot.margin = margin(2, 2, 2, 2),
    panel.background = element_rect(fill = "#FAFAFA", color = "#CBD5E1", linewidth = 1)
  )

# --- Stage 1: Empty Meadow boundary / canvas ---
p1 <- ggplot() +
  geom_path(data = outer_circle, aes(x = x, y = y), color = "#CBD5E1", linetype = "dashed", linewidth = 0.7) +
  coord_fixed(xlim = c(-4.6, 4.6), ylim = c(-4.6, 4.6)) +
  base_theme

ggsave("images/plant_step1_meadow.png", p1, width = 7.5, height = 6.4, dpi = 300)
cat("Saved plant_step1_meadow.png\n")

# --- Stage 2: Plant species as uniform dots ---
p2 <- ggplot() +
  geom_path(data = outer_circle, aes(x = x, y = y), color = "#CBD5E1", linetype = "dashed", linewidth = 0.7) +
  geom_point(data = plant_nodes, aes(x = x, y = y), color = "#475569", alpha = 0.8, size = 2.8) +
  coord_fixed(xlim = c(-4.6, 4.6), ylim = c(-4.6, 4.6)) +
  base_theme

ggsave("images/plant_step2_plants.png", p2, width = 7.5, height = 6.4, dpi = 300)
cat("Saved plant_step2_plants.png\n")

# --- Stage 3: Shared pollinator routes connecting plants ---
p3 <- ggplot() +
  geom_path(data = outer_circle, aes(x = x, y = y), color = "#CBD5E1", linetype = "dashed", linewidth = 0.7) +
  geom_segment(data = edges_plot, aes(x = x1, y = y1, xend = x2, yend = y2),
               color = "#60A5FA", alpha = 0.28, linewidth = 0.45) +
  geom_point(data = plant_nodes, aes(x = x, y = y), color = "#334155", alpha = 0.8, size = 2.8) +
  coord_fixed(xlim = c(-4.6, 4.6), ylim = c(-4.6, 4.6)) +
  base_theme

ggsave("images/plant_step3_routes.png", p3, width = 7.5, height = 6.4, dpi = 300)
cat("Saved plant_step3_routes.png\n")

# --- Stage 4: Coreness highlighted (Core Plant hubs pop out) ---
p4 <- ggplot() +
  geom_path(data = outer_circle, aes(x = x, y = y), color = "#E2E8F0", linetype = "dashed", linewidth = 0.5) +
  geom_path(data = inner_circle, aes(x = x, y = y), color = "#DBEAFE", linetype = "dotted", linewidth = 0.5) +
  # Spoke edges
  geom_segment(data = subset(edges_plot, EdgeType != "Core-Core"),
               aes(x = x1, y = y1, xend = x2, yend = y2),
               color = "#93C5FD", alpha = 0.25, linewidth = 0.4) +
  # Core-Core backbone edges
  geom_segment(data = subset(edges_plot, EdgeType == "Core-Core"),
               aes(x = x1, y = y1, xend = x2, yend = y2),
               color = "#1D4ED8", alpha = 0.88, linewidth = 1.3) +
  # Peripheral plants
  geom_point(data = subset(plant_nodes, Role == "Peripheral Plant"),
             aes(x = x, y = y), color = "#F87171", alpha = 0.7, size = 2.8) +
  # Core plants
  geom_point(data = subset(plant_nodes, Role == "Core Plant"),
             aes(x = x, y = y), color = "#1E3A8A", size = 6.8, alpha = 0.95) +
  geom_point(data = subset(plant_nodes, Role == "Core Plant"),
             aes(x = x, y = y), color = "#FBBF24", size = 3.6) +
  # Labels
  geom_label_repel(data = subset(plant_nodes, Role == "Core Plant"),
                   aes(x = x, y = y, label = Label),
                   fontface = "bold.italic", size = 3.6, color = "#0F172A", fill = alpha("white", 0.92),
                   box.padding = 0.5, point.padding = 0.4, segment.color = "#1E3A8A", segment.size = 0.5) +
  geom_label_repel(data = subset(plant_nodes, Species %in% ex_periph),
                   aes(x = x, y = y, label = Label),
                   fontface = "italic", size = 3.2, color = "#B91C1C", fill = alpha("#FEF2F2", 0.95),
                   box.padding = 0.45, point.padding = 0.35, segment.color = "#DC2626", segment.size = 0.5) +
  coord_fixed(xlim = c(-4.6, 4.6), ylim = c(-4.6, 4.6)) +
  base_theme

ggsave("images/plant_step4_coreness.png", p4, width = 7.5, height = 6.4, dpi = 300)
cat("Saved plant_step4_coreness.png\n")

# --- Stage 5: Spoke Loss (Peripheral species like Lathyrus knocked out) ---
p5 <- ggplot() +
  geom_path(data = outer_circle, aes(x = x, y = y), color = "#E2E8F0", linetype = "dashed", linewidth = 0.5) +
  geom_path(data = inner_circle, aes(x = x, y = y), color = "#DBEAFE", linetype = "dotted", linewidth = 0.5) +
  # Spoke edges
  geom_segment(data = subset(edges_plot, EdgeType != "Core-Core"),
               aes(x = x1, y = y1, xend = x2, yend = y2),
               color = "#93C5FD", alpha = 0.25, linewidth = 0.4) +
  # Core-Core backbone edges
  geom_segment(data = subset(edges_plot, EdgeType == "Core-Core"),
               aes(x = x1, y = y1, xend = x2, yend = y2),
               color = "#1D4ED8", alpha = 0.88, linewidth = 1.3) +
  # Peripheral plants surviving
  geom_point(data = subset(plant_nodes, Role == "Peripheral Plant" & !(Species %in% ex_periph[1:2])),
             aes(x = x, y = y), color = "#F87171", alpha = 0.7, size = 2.8) +
  # Core plants intact
  geom_point(data = subset(plant_nodes, Role == "Core Plant"),
             aes(x = x, y = y), color = "#1E3A8A", size = 6.8, alpha = 0.95) +
  geom_point(data = subset(plant_nodes, Role == "Core Plant"),
             aes(x = x, y = y), color = "#FBBF24", size = 3.6) +
  # Knocked out peripheral plants (Red X)
  geom_point(data = subset(plant_nodes, Species %in% ex_periph[1:2]),
             aes(x = x, y = y), color = "#DC2626", size = 6.5, shape = 4, stroke = 2.8) +
  # Labels
  geom_label_repel(data = subset(plant_nodes, Role == "Core Plant"),
                   aes(x = x, y = y, label = Label),
                   fontface = "bold.italic", size = 3.4, color = "#0F172A", fill = alpha("white", 0.92),
                   box.padding = 0.5, point.padding = 0.4, segment.color = "#1E3A8A", segment.size = 0.5) +
  geom_label_repel(data = subset(plant_nodes, Species %in% ex_periph[1:2]),
                   aes(x = x, y = y, label = paste0("❌ ", Species, "\nSPOKE FAILED")),
                   fontface = "italic", size = 3.2, color = "#B91C1C", fill = alpha("#FEF2F2", 0.95),
                   box.padding = 0.45, point.padding = 0.35, segment.color = "#DC2626", segment.size = 0.5) +
  # Top banner
  annotate("label", x = 0, y = 4.8, label = "🟢 SPOKE LOSS: Meadow Web Absorbs Shock (Core intact)",
           fill = "#F0FDF4", color = "#15803D", fontface = "bold", size = 3.8, label.r = unit(0.2, "lines")) +
  coord_fixed(xlim = c(-4.6, 4.6), ylim = c(-4.6, 5.1)) +
  base_theme

ggsave("images/plant_step5_spoke.png", p5, width = 7.5, height = 6.4, dpi = 300)
cat("Saved plant_step5_spoke.png\n")

# --- Stage 6: Hub Loss (Centaurea & Core Perennials knocked out) ---
edges_spoke_only <- subset(edges_plot, EdgeType == "Spoke-Spoke")

p6 <- ggplot() +
  geom_path(data = outer_circle, aes(x = x, y = y), color = "#E2E8F0", linetype = "dashed", linewidth = 0.5) +
  # Surviving spoke-spoke edges only (rare, weak)
  geom_segment(data = edges_spoke_only,
               aes(x = x1, y = y1, xend = x2, yend = y2),
               color = "#94A3B8", alpha = 0.25, linewidth = 0.35) +
  # Peripheral plants isolated (stranded)
  geom_point(data = subset(plant_nodes, Role == "Peripheral Plant"),
             aes(x = x, y = y), color = "#EF4444", alpha = 0.6, size = 2.6) +
  # Huge Red X over the 6 core plants
  geom_point(data = subset(plant_nodes, Role == "Core Plant"),
             aes(x = x, y = y), color = "#DC2626", size = 11, shape = 4, stroke = 3.5) +
  geom_label_repel(data = subset(plant_nodes, Role == "Core Plant"),
                   aes(x = x, y = y, label = paste0("❌ ", Species, "\nHUB WITHERED!")),
                   fontface = "bold.italic", size = 3.3, color = "#991B1B", fill = alpha("#FEF2F2", 0.95),
                   box.padding = 0.45, point.padding = 0.35, segment.color = "#DC2626", segment.size = 0.5) +
  # Top banner
  annotate("label", x = 0, y = 4.8, label = "🔴 HUB COLLAPSE: Shared Pollinator Web Unravels!",
           fill = "#FEF2F2", color = "#B91C1C", fontface = "bold", size = 3.8, label.r = unit(0.2, "lines")) +
  coord_fixed(xlim = c(-4.6, 4.6), ylim = c(-4.6, 5.1)) +
  base_theme

ggsave("images/plant_step6_hub.png", p6, width = 7.5, height = 6.4, dpi = 300)
cat("Saved plant_step6_hub.png\n")

cat("All plant steps generated successfully!\n")
