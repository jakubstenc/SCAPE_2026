library(ggplot2)
library(dplyr)
library(gridExtra)

cat("Generating visual comparison of Network Robustness: Spoke vs. Hub Loss...\n")

# Base theme
panel_theme <- theme_void() +
  theme(
    plot.margin = margin(12, 14, 12, 14),
    panel.background = element_rect(fill = "#FAFAFA", color = "#CBD5E1", linewidth = 1),
    plot.title = element_text(face = "bold", size = 15, hjust = 0.5, margin = margin(b = 6)),
    plot.subtitle = element_text(size = 11, hjust = 0.5, margin = margin(b = 10))
  )

# --- Define node positions for a clear hub-and-spoke schematic ---
# 1 central hub, 8 peripheral spokes
n_spokes <- 8
theta <- seq(0, 2 * pi, length.out = n_spokes + 1)[1:n_spokes]
r <- 3.2

nodes_base <- data.frame(
  id = 0:n_spokes,
  name = c("Core Hub\n(Heathrow / Centaurea)", paste0("Spoke ", 1:n_spokes)),
  x = c(0, r * cos(theta)),
  y = c(0, r * sin(theta)),
  type = c("Hub", rep("Spoke", n_spokes)),
  stringsAsFactors = FALSE
)

# Edges connecting hub to all spokes + a few spoke-spoke cross connections
edges_base <- data.frame(
  from = rep(0, n_spokes),
  to = 1:n_spokes
)
# Add some cross spoke edges
edges_cross <- data.frame(
  from = c(1, 3, 5, 7),
  to = c(2, 4, 6, 8)
)
edges_all <- rbind(edges_base, edges_cross)
edges_all <- merge(edges_all, nodes_base[, c("id", "x", "y")], by.x = "from", by.y = "id")
colnames(edges_all)[3:4] <- c("x1", "y1")
edges_all <- merge(edges_all, nodes_base[, c("id", "x", "y")], by.x = "to", by.y = "id")
colnames(edges_all)[5:6] <- c("x2", "y2")

# =========================================================================
# Panel 1: SPOKE FAILURE (Røros / Peripheral plant lost)
# Spoke 2 is lost
# =========================================================================
lost_spoke_id <- 2
nodes_p1 <- nodes_base
nodes_p1$status <- ifelse(nodes_p1$id == lost_spoke_id, "Lost", "Active")

edges_p1 <- edges_all
edges_p1$status <- ifelse(edges_p1$from == lost_spoke_id | edges_p1$to == lost_spoke_id, "Lost", "Active")

p1 <- ggplot() +
  # Active edges (robust blue)
  geom_segment(data = subset(edges_p1, status == "Active"),
               aes(x = x1, y = y1, xend = x2, yend = y2),
               color = "#3B82F6", alpha = 0.75, linewidth = 1.1) +
  # Lost edges (red dashed)
  geom_segment(data = subset(edges_p1, status == "Lost"),
               aes(x = x1, y = y1, xend = x2, yend = y2),
               color = "#EF4444", alpha = 0.5, linewidth = 0.9, linetype = "dashed") +
  # Active spoke nodes
  geom_point(data = subset(nodes_p1, type == "Spoke" & status == "Active"),
             aes(x = x, y = y), color = "#475569", size = 6.0) +
  # Lost spoke node (red X)
  geom_point(data = subset(nodes_p1, status == "Lost"),
             aes(x = x, y = y), color = "#DC2626", size = 6.5, shape = 4, stroke = 2.5) +
  # Hub node (central blue & gold)
  geom_point(data = subset(nodes_p1, type == "Hub"),
             aes(x = x, y = y), color = "#1E3A8A", size = 11.5) +
  geom_point(data = subset(nodes_p1, type == "Hub"),
             aes(x = x, y = y), color = "#FBBF24", size = 6.5) +
  # Annotations
  annotate("label", x = nodes_p1$x[nodes_p1$id == lost_spoke_id] + 0.3,
           y = nodes_p1$y[nodes_p1$id == lost_spoke_id] + 0.6,
           label = "Peripheral Spoke Fails\n(Røros fog / Lathyrus drought)",
           color = "#B91C1C", fill = "#FEF2F2", fontface = "bold", size = 3.4) +
  annotate("label", x = 0, y = -1.2,
           label = "Central Backbone Intact\nAll other nodes stay connected!",
           color = "#1E3A8A", fill = alpha("#EFF6FF", 0.9), fontface = "bold", size = 3.5) +
  annotate("label", x = 0, y = -4.3,
           label = "Network Status: 92% Routes Maintained\nShock absorbed with zero systemic damage",
           color = "#15803D", fill = "#F0FDF4", fontface = "bold", size = 3.6,
           label.padding = unit(0.35, "lines"), label.r = unit(0.2, "lines")) +
  coord_fixed(xlim = c(-4.8, 4.8), ylim = c(-4.9, 4.2)) +
  labs(
    title = "A  Random Spoke Failure",
    subtitle = "High Robustness: Network Absorbs the Perturbation"
  ) +
  panel_theme +
  theme(
    plot.title = element_text(color = "#15803D"),
    plot.subtitle = element_text(color = "#166534")
  )

# =========================================================================
# Panel 2: CORE HUB FAILURE (Heathrow / Centaurea lost)
# Hub (id 0) is lost
# =========================================================================
lost_hub_id <- 0
nodes_p2 <- nodes_base
nodes_p2$status <- ifelse(nodes_p2$id == lost_hub_id, "Lost", "Isolated")

edges_p2 <- edges_all
edges_p2$status <- ifelse(edges_p2$from == lost_hub_id | edges_p2$to == lost_hub_id, "Lost", "Surviving")

p2 <- ggplot() +
  # Lost hub edges (red dashed)
  geom_segment(data = subset(edges_p2, status == "Lost"),
               aes(x = x1, y = y1, xend = x2, yend = y2),
               color = "#EF4444", alpha = 0.45, linewidth = 0.9, linetype = "dashed") +
  # Surviving cross edges (few, weak)
  geom_segment(data = subset(edges_p2, status == "Surviving"),
               aes(x = x1, y = y1, xend = x2, yend = y2),
               color = "#94A3B8", alpha = 0.6, linewidth = 0.8) +
  # Isolated spoke nodes (disconnected, hollow red outline)
  geom_point(data = subset(nodes_p2, type == "Spoke"),
             aes(x = x, y = y), color = "#EF4444", fill = "#FEE2E2", shape = 21, size = 6.0, stroke = 1.5) +
  # Lost central hub (large Red X)
  geom_point(data = subset(nodes_p2, type == "Hub"),
             aes(x = x, y = y), color = "#DC2626", size = 16, shape = 4, stroke = 4) +
  # Annotations
  annotate("label", x = 0, y = 1.2,
           label = "Core Hub Collapses!\n(Heathrow shut / Centaurea withered)",
           color = "#B91C1C", fill = "#FEF2F2", fontface = "bold", size = 3.6) +
  annotate("label", x = 0, y = -1.2,
           label = "Bridging Routes Shattered!\nSpokes isolated from each other",
           color = "#7F1D1D", fill = alpha("#FEF2F2", 0.9), fontface = "bold", size = 3.5) +
  annotate("label", x = 0, y = -4.3,
           label = "Network Status: Systemic Fragmentation\nShared pollinator services collapse community-wide",
           color = "#B91C1C", fill = "#FEF2F2", fontface = "bold", size = 3.6,
           label.padding = unit(0.35, "lines"), label.r = unit(0.2, "lines")) +
  coord_fixed(xlim = c(-4.8, 4.8), ylim = c(-4.9, 4.2)) +
  labs(
    title = "B  Targeted Hub Failure",
    subtitle = "Catastrophic Fragility: The Network's Achilles' Heel"
  ) +
  panel_theme +
  theme(
    plot.title = element_text(color = "#B91C1C"),
    plot.subtitle = element_text(color = "#991B1B")
  )

# Combine panels
p_combined <- grid.arrange(p1, p2, ncol = 2)

ggsave("images/network_robustness_visual.png", p_combined, width = 13.5, height = 6.2, dpi = 300)
cat("Saved images/network_robustness_visual.png successfully!\n")

# Also save individual panel images for potential step animations
ggsave("images/robustness_step1_spoke.png", p1, width = 6.8, height = 6.2, dpi = 300)
ggsave("images/robustness_step2_hub.png", p2, width = 6.8, height = 6.2, dpi = 300)
cat("Saved individual panel images successfully!\n")
