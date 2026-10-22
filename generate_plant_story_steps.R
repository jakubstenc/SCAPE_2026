library(igraph)
library(ggplot2)
library(dplyr)

cat("Step 1: Processing Handrkov pollinator sharing network with Natural Organic Layout...\n")
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

g_plant <- graph_from_adjacency_matrix(plant_adj, mode = "undirected", weighted = TRUE)

# --- Organic, Natural Layout ---
# The 6 core perennial species form a natural, organic hub cluster in the center (mirroring European mega-hubs like Frankfurt, Paris, London)
# Centaurea jacea is nestled centrally, while others cluster organically without forming a rigid pentagram or circle.
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

# Dedicated positions for the 3 labeled peripheral species representing peripheral spokes cleanly:
# Cirsium palustre: North periphery
coords["Cirsium palustre", ] <- c(0.20, 3.10)
# Lathyrus pratensis: South-West periphery
coords["Lathyrus pratensis", ] <- c(-2.70, -2.10)
# Ranunculus flammula: South-East periphery
coords["Ranunculus flammula", ] <- c(2.60, -2.20)

# Distribute remaining peripheral plants organically around the core based on shared visitors
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
  # Natural organic reach out to 3.8, matching the Europe map footprint
  dist_factor <- 2.4 + 1.4 * (1 - min(deg, 25) / 25) + rnorm(1, 0, 0.25)
  coords[sp, 1] <- center_x + dist_factor * cos(angle)
  coords[sp, 2] <- center_y + dist_factor * sin(angle)
}

# 80 relaxation steps for smooth organic spacing and no node overlaps
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

# Edge filtering: keep significant sharing connections
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
labels_core$LabelText <- labels_core$Species

ex_periph_df <- subset(plant_nodes, Species %in% c("Cirsium palustre", "Lathyrus pratensis", "Ranunculus flammula"))
ex_periph_df$LabelText <- ex_periph_df$Species
ex_periph_df$lbl_x <- c(0.20, -2.70, 2.60)
ex_periph_df$lbl_y <- c(3.70, -2.70, -2.80)

base_theme <- theme_void() +
  theme(
    plot.margin = margin(2, 2, 2, 2),
    panel.background = element_rect(fill = "#FAFAFA", color = "#CBD5E1", linewidth = 1)
  )

# --- Stage 1: Empty Meadow canvas ---
p1 <- ggplot() +
  coord_fixed(xlim = c(-4.6, 4.6), ylim = c(-4.6, 4.6)) +
  base_theme

ggsave("images/plant_step1_meadow.png", p1, width = 7.5, height = 6.4, dpi = 300)
cat("Saved plant_step1_meadow.png\n")

# --- Stage 2: Plant species as uniform dots scattered naturally ---
p2 <- ggplot() +
  geom_point(data = plant_nodes, aes(x = x, y = y), color = "#475569", alpha = 0.82, size = 2.8) +
  coord_fixed(xlim = c(-4.6, 4.6), ylim = c(-4.6, 4.6)) +
  base_theme

ggsave("images/plant_step2_plants.png", p2, width = 7.5, height = 6.4, dpi = 300)
cat("Saved plant_step2_plants.png\n")

# --- Stage 3: Shared pollinator routes connecting plants into an organic web ---
p3 <- ggplot() +
  geom_segment(data = edges_plot, aes(x = x1, y = y1, xend = x2, yend = y2),
               color = "#3B0F70", alpha = 0.18, linewidth = 0.45) +
  geom_point(data = plant_nodes, aes(x = x, y = y), color = "#334155", alpha = 0.85, size = 2.8) +
  coord_fixed(xlim = c(-4.6, 4.6), ylim = c(-4.6, 4.6)) +
  base_theme

ggsave("images/plant_step3_routes.png", p3, width = 7.5, height = 6.4, dpi = 300)
cat("Saved plant_step3_routes.png\n")

# --- Stage 4: Coreness highlighted (Core Plant hubs naturally anchor the meadow) ---
p4 <- ggplot() +
  # Spoke routes
  geom_segment(data = subset(edges_plot, EdgeType != "Core-Core"),
               aes(x = x1, y = y1, xend = x2, yend = y2),
               color = "#3B0F70", alpha = 0.18, linewidth = 0.4) +
  # Core-Core backbone routes (natural organic cluster, no pentagram)
  geom_segment(data = subset(edges_plot, EdgeType == "Core-Core"),
               aes(x = x1, y = y1, xend = x2, yend = y2),
               color = "#3B0F70", alpha = 0.88, linewidth = 1.2) +
  # Peripheral plants
  geom_point(data = subset(plant_nodes, Role == "Peripheral Plant"),
             aes(x = x, y = y), color = "#DE7BA9", alpha = 0.75, size = 2.8) +
  # Core plants
  geom_point(data = subset(plant_nodes, Role == "Core Plant"),
             aes(x = x, y = y), color = "#F8765C", size = 6.8, alpha = 0.95) +
  geom_point(data = subset(plant_nodes, Role == "Core Plant"),
             aes(x = x, y = y), color = "#FCFDBF", size = 3.6) +
  # Callout lines for core labels
  geom_segment(data = labels_core, aes(x = x, y = y, xend = lbl_x, yend = lbl_y),
               color = "#8C2981", alpha = 0.6, linewidth = 0.5) +
  # Callout lines for peripheral labels
  geom_segment(data = ex_periph_df, aes(x = x, y = y, xend = lbl_x, yend = lbl_y),
               color = "#B63679", alpha = 0.6, linewidth = 0.5) +
  # Core labels
  geom_label(data = labels_core, aes(x = lbl_x, y = lbl_y, label = LabelText),
             fontface = "bold.italic", size = 3.3, color = "#0F172A", fill = alpha("white", 0.95),
             label.padding = unit(0.25, "lines"), label.r = unit(0.2, "lines")) +
  # Peripheral labels
  geom_label(data = ex_periph_df, aes(x = lbl_x, y = lbl_y, label = LabelText),
             fontface = "italic", size = 3.0, color = "#7A1F5C", fill = alpha("#FBEFF5", 0.96),
             label.padding = unit(0.25, "lines"), label.r = unit(0.2, "lines")) +
  coord_fixed(xlim = c(-4.6, 4.6), ylim = c(-4.6, 4.6)) +
  base_theme

ggsave("images/plant_step4_coreness.png", p4, width = 7.5, height = 6.4, dpi = 300)
cat("Saved plant_step4_coreness.png\n")

# --- Stage 4b: Random Loss (Random mixture of species knocked out) ---
rand_lost_periph <- c("Cirsium palustre", "Lathyrus pratensis")
rand_lost_core <- c("Ranunculus acris")
all_rand_lost <- c(rand_lost_periph, rand_lost_core)

# Filter edges: remove connections attached to lost nodes
edges_rand <- edges_plot %>%
  filter(!((from %in% all_rand_lost) | (to %in% all_rand_lost)))

p_rand <- ggplot() +
  # Surviving spoke edges
  geom_segment(data = subset(edges_rand, EdgeType != "Core-Core"),
               aes(x = x1, y = y1, xend = x2, yend = y2),
               color = "#3B0F70", alpha = 0.18, linewidth = 0.4) +
  # Surviving core edges
  geom_segment(data = subset(edges_rand, EdgeType == "Core-Core"),
               aes(x = x1, y = y1, xend = x2, yend = y2),
               color = "#3B0F70", alpha = 0.85, linewidth = 1.1) +
  # Peripheral plants surviving
  geom_point(data = subset(plant_nodes, Role == "Peripheral Plant" & !(Species %in% rand_lost_periph)),
             aes(x = x, y = y), color = "#DE7BA9", alpha = 0.7, size = 2.8) +
  # Core plants surviving
  geom_point(data = subset(plant_nodes, Role == "Core Plant" & !(Species %in% rand_lost_core)),
             aes(x = x, y = y), color = "#F8765C", size = 6.8, alpha = 0.95) +
  geom_point(data = subset(plant_nodes, Role == "Core Plant" & !(Species %in% rand_lost_core)),
             aes(x = x, y = y), color = "#FCFDBF", size = 3.6) +
  # Knocked out peripheral nodes (Red X)
  geom_point(data = subset(plant_nodes, Species %in% rand_lost_periph),
             aes(x = x, y = y), color = "#B63679", size = 6.0, shape = 4, stroke = 2.5) +
  # Knocked out core node (Red X)
  geom_point(data = subset(plant_nodes, Species %in% rand_lost_core),
             aes(x = x, y = y), color = "#B63679", size = 7.5, shape = 4, stroke = 3.0) +
  # Callout lines for surviving core labels
  geom_segment(data = subset(labels_core, !(Species %in% rand_lost_core)),
               aes(x = x, y = y, xend = lbl_x, yend = lbl_y),
               color = "#8C2981", alpha = 0.6, linewidth = 0.5) +
  geom_label(data = subset(labels_core, !(Species %in% rand_lost_core)),
             aes(x = lbl_x, y = lbl_y, label = LabelText),
             fontface = "bold.italic", size = 3.3, color = "#0F172A", fill = alpha("white", 0.95),
             label.padding = unit(0.25, "lines"), label.r = unit(0.2, "lines")) +
  # Knockout label for core plant
  geom_label(data = subset(labels_core, Species %in% rand_lost_core),
             aes(x = lbl_x, y = lbl_y, label = paste0("❌ ", Species, "\nLOST AT RANDOM")),
             fontface = "bold.italic", size = 3.1, color = "#7A1F5C", fill = alpha("#FBEFF5", 0.95),
             label.padding = unit(0.25, "lines"), label.r = unit(0.2, "lines")) +
  # Top banner
  annotate("label", x = 0, y = 4.3, label = "🎲 RANDOM LOSS: Moderate Buffering (Intermediate decline)",
           fill = "#F8FAFC", color = "#475569", fontface = "bold", size = 3.6, label.r = unit(0.2, "lines")) +
  coord_fixed(xlim = c(-4.6, 4.6), ylim = c(-4.6, 4.6)) +
  base_theme

ggsave("images/plant_step_rand.png", p_rand, width = 7.5, height = 6.4, dpi = 300)
cat("Saved plant_step_rand.png\n")

# --- Stage 5: Spoke Loss (Peripheral species like Lathyrus knocked out) ---
p5 <- ggplot() +
  # Spoke edges
  geom_segment(data = subset(edges_plot, EdgeType != "Core-Core"),
               aes(x = x1, y = y1, xend = x2, yend = y2),
               color = "#3B0F70", alpha = 0.18, linewidth = 0.4) +
  # Core-Core backbone edges
  geom_segment(data = subset(edges_plot, EdgeType == "Core-Core"),
               aes(x = x1, y = y1, xend = x2, yend = y2),
               color = "#3B0F70", alpha = 0.88, linewidth = 1.2) +
  # Peripheral plants surviving
  geom_point(data = subset(plant_nodes, Role == "Peripheral Plant" & !(Species %in% c("Lathyrus pratensis", "Ranunculus flammula"))),
             aes(x = x, y = y), color = "#DE7BA9", alpha = 0.7, size = 2.8) +
  # Core plants intact
  geom_point(data = subset(plant_nodes, Role == "Core Plant"),
             aes(x = x, y = y), color = "#F8765C", size = 6.8, alpha = 0.95) +
  geom_point(data = subset(plant_nodes, Role == "Core Plant"),
             aes(x = x, y = y), color = "#FCFDBF", size = 3.6) +
  # Knocked out peripheral plants (Red X)
  geom_point(data = subset(plant_nodes, Species %in% c("Lathyrus pratensis", "Ranunculus flammula")),
             aes(x = x, y = y), color = "#B63679", size = 6.5, shape = 4, stroke = 2.8) +
  # Callout lines for core labels
  geom_segment(data = labels_core, aes(x = x, y = y, xend = lbl_x, yend = lbl_y),
               color = "#8C2981", alpha = 0.6, linewidth = 0.5) +
  geom_label(data = labels_core, aes(x = lbl_x, y = lbl_y, label = LabelText),
             fontface = "bold.italic", size = 3.3, color = "#0F172A", fill = alpha("white", 0.95),
             label.padding = unit(0.25, "lines"), label.r = unit(0.2, "lines")) +
  # Knockout label
  geom_label(data = subset(ex_periph_df, Species == "Lathyrus pratensis"),
             aes(x = lbl_x, y = lbl_y, label = "❌ Lathyrus pratensis\nSPOKE FAILED"),
             fontface = "italic", size = 3.1, color = "#7A1F5C", fill = alpha("#FBEFF5", 0.95),
             label.padding = unit(0.25, "lines"), label.r = unit(0.2, "lines")) +
  # Top banner
  annotate("label", x = 0, y = 4.3, label = "🟢 SPOKE LOSS: Meadow Web Absorbs Shock (Core intact)",
           fill = "#EEF3F1", color = "#40695B", fontface = "bold", size = 3.6, label.r = unit(0.2, "lines")) +
  coord_fixed(xlim = c(-4.6, 4.6), ylim = c(-4.6, 4.6)) +
  base_theme

ggsave("images/plant_step5_spoke.png", p5, width = 7.5, height = 6.4, dpi = 300)
cat("Saved plant_step5_spoke.png\n")

# --- Stage 6: Hub Loss (Core Perennials knocked out) ---
edges_spoke_only <- subset(edges_plot, EdgeType == "Spoke-Spoke")

p6 <- ggplot() +
  # Surviving spoke-spoke edges only (rare, weak)
  geom_segment(data = edges_spoke_only,
               aes(x = x1, y = y1, xend = x2, yend = y2),
               color = "#3B0F70", alpha = 0.18, linewidth = 0.35) +
  # Peripheral plants isolated (stranded)
  geom_point(data = subset(plant_nodes, Role == "Peripheral Plant"),
             aes(x = x, y = y), color = "#B63679", alpha = 0.6, size = 2.6) +
  # Huge Red X over the 6 core plants
  geom_point(data = subset(plant_nodes, Role == "Core Plant"),
             aes(x = x, y = y), color = "#B63679", size = 11, shape = 4, stroke = 3.5) +
  geom_label(data = labels_core[c(1, 3, 5), ],
             aes(x = lbl_x, y = lbl_y, label = paste0("❌ ", Species, "\nHUB WITHERED!")),
             fontface = "bold.italic", size = 3.1, color = "#7A1F5C", fill = alpha("#FBEFF5", 0.95),
             label.padding = unit(0.25, "lines"), label.r = unit(0.2, "lines")) +
  # Top banner
  annotate("label", x = 0, y = 4.3, label = "🔴 HUB COLLAPSE: Shared Pollinator Web Unravels!",
           fill = "#FBEFF5", color = "#7A1F5C", fontface = "bold", size = 3.6, label.r = unit(0.2, "lines")) +
  coord_fixed(xlim = c(-4.6, 4.6), ylim = c(-4.6, 4.6)) +
  base_theme

ggsave("images/plant_step6_hub.png", p6, width = 7.5, height = 6.4, dpi = 300)
cat("Saved plant_step6_hub.png\n")

cat("All plant steps regenerated successfully with organic natural layout!\n")

# --- Text-free versions for the robustness slide (no labels, callouts or banners) ---
strip_text <- function(p) {
  keep <- vapply(p$layers, function(l) {
    is_text <- inherits(l$geom, "GeomLabel") || inherits(l$geom, "GeomText")
    is_callout <- inherits(l$geom, "GeomSegment") && !is.null(l$mapping$xend) &&
      grepl("lbl_x", rlang::as_label(l$mapping$xend))
    !(is_text || is_callout)
  }, logical(1))
  p$layers <- p$layers[keep]
  p
}
for (nm in c("step4_coreness", "step_rand", "step5_spoke", "step6_hub")) {
  p_src <- switch(nm, step4_coreness = p4, step_rand = p_rand, step5_spoke = p5, step6_hub = p6)
  ggsave(sprintf("images/plant_%s_clean.png", nm), strip_text(p_src), width = 7.5, height = 6.4, dpi = 300)
}
cat("Saved text-free robustness network steps.\n")

# Crop the empty transparent side margins (same box for every step) so the slide does not squeeze the network
for (f in list.files("images", pattern = "^plant_step.*\\.png$", full.names = TRUE)) {
  magick::image_write(magick::image_crop(magick::image_read(f), "1920x1920+165+0"), f)
}
cat("Cropped plant steps to plot area.\n")
