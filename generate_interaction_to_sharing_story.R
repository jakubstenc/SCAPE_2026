library(ggplot2)
library(dplyr)

W <- 9.6
H <- 5.6

# Refined theme with smooth clean border and subtle cream-grey background matching Reveal theme
slide_theme <- theme_void() +
  theme(
    plot.margin = margin(12, 12, 12, 12),
    panel.background = element_rect(fill = "#FAFAF9", color = "#CBD5E1", linewidth = 1.2)
  )

# --- Nodes Setup ---
# 7 Plants at y = 2.3
plants <- data.frame(
  id = 1:7,
  x = c(-3.6, -2.4, -1.2, 0.0, 1.2, 2.4, 3.6),
  y = 2.3,
  role = c("periph", "core", "periph", "core", "periph", "core", "periph")
)
plants$color <- ifelse(plants$role == "core", "#1D2D6B", "#E06A55")
plants$size <- ifelse(plants$role == "core", 11.5, 8.5)

# 5 Pollinators at y = -2.3
polls <- data.frame(
  id = 1:5,
  x = c(-2.8, -1.4, 0.0, 1.4, 2.8),
  y = -2.3,
  color = "#F59E0B"
)

# Interactions
all_edges <- data.frame(
  p = c(1, 2, 2, 2, 3, 4, 4, 4, 5, 6, 6, 6, 7),
  a = c(1, 1, 2, 3, 2, 2, 3, 4, 4, 3, 4, 5, 5),
  initial = c(TRUE, FALSE, FALSE, FALSE, FALSE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, TRUE, FALSE)
)

edges_df <- data.frame(
  x1 = plants$x[all_edges$p],
  y1 = plants$y[all_edges$p],
  x2 = polls$x[all_edges$a],
  y2 = polls$y[all_edges$a],
  initial = all_edges$initial,
  p = all_edges$p,
  a = all_edges$a
)

# Plant-plant links
plant_links <- data.frame(
  p1 = c(2, 4, 2, 1, 3, 3, 5, 5, 7),
  p2 = c(4, 6, 6, 2, 2, 4, 4, 6, 6),
  weight = c(2, 2, 1, 1, 1, 1, 1, 1, 1),
  type = c("core-core", "core-core", "core-core", "spoke", "spoke", "spoke", "spoke", "spoke", "spoke")
)
plant_links$x1 <- plants$x[plant_links$p1]
plant_links$y1 <- plants$y[plant_links$p1]
plant_links$x2 <- plants$x[plant_links$p2]
plant_links$y2 <- plants$y[plant_links$p2]

# -------------------------------------------------------------
# PLOT 1A: Observed interactions emerge
# -------------------------------------------------------------
p_1a <- ggplot() +
  # Dim ghost nodes
  geom_point(data = polls, aes(x = x, y = y), color = "#E2E8F0", size = 8.5, shape = 15) +
  geom_point(data = plants, aes(x = x, y = y), color = "#E2E8F0", size = plants$size) +
  # Initial active interaction lines
  geom_segment(data = subset(edges_df, initial), aes(x = x1, y = y1, xend = x2, yend = y2),
               color = "#0284C7", linewidth = 2.0, lineend = "round") +
  # Active pollinator nodes
  geom_point(data = polls[c(1, 3, 5), ], aes(x = x, y = y), color = "#B45309", size = 9.5, shape = 15) +
  geom_point(data = polls[c(1, 3, 5), ], aes(x = x, y = y), color = "#F59E0B", size = 7.5, shape = 15) +
  # Active plant nodes
  geom_point(data = plants[c(1, 4, 6), ], aes(x = x, y = y), color = "white", size = plants$size[c(1, 4, 6)] + 3) +
  geom_point(data = plants[c(1, 4, 6), ], aes(x = x, y = y), color = plants$color[c(1, 4, 6)], size = plants$size[c(1, 4, 6)]) +
  coord_fixed(xlim = c(-4.3, 4.3), ylim = c(-3.2, 3.2)) +
  slide_theme

ggsave("images/story_step1a_few_visits.png", p_1a, width = W, height = H, dpi = 300)

# -------------------------------------------------------------
# PLOT 1B: Complete Bipartite Network of Interactions
# -------------------------------------------------------------
p_1b <- ggplot() +
  geom_segment(data = edges_df, aes(x = x1, y = y1, xend = x2, yend = y2),
               color = "#64748B", alpha = 0.65, linewidth = 1.1) +
  geom_point(data = polls, aes(x = x, y = y), color = "#B45309", size = 9.5, shape = 15) +
  geom_point(data = polls, aes(x = x, y = y), color = "#F59E0B", size = 7.5, shape = 15) +
  geom_point(data = plants, aes(x = x, y = y), color = "white", size = plants$size + 3) +
  geom_point(data = plants, aes(x = x, y = y), color = plants$color, size = plants$size) +
  coord_fixed(xlim = c(-4.3, 4.3), ylim = c(-3.2, 3.2)) +
  slide_theme

ggsave("images/story_step1b_full_bipartite.png", p_1b, width = W, height = H, dpi = 300)

# -------------------------------------------------------------
# PLOT 2A: Shared Pollinators bridging plants
# -------------------------------------------------------------
p_2a <- ggplot() +
  # Dimmed background interactions
  geom_segment(data = edges_df, aes(x = x1, y = y1, xend = x2, yend = y2),
               color = "#CBD5E1", alpha = 0.35, linewidth = 0.8) +
  # Highlight edges to shared pollinators
  geom_segment(data = subset(edges_df, a == 3), aes(x = x1, y = y1, xend = x2, yend = y2),
               color = "#F59E0B", linewidth = 2.2, lineend = "round") +
  # Direct plant-plant curved sharing arcs emerging above!
  geom_curve(data = subset(plant_links, type == "core-core"),
             aes(x = x1, y = y1 + 0.35, xend = x2, yend = y2 + 0.35),
             curvature = -0.38, color = "#2563EB", linewidth = 2.2, lineend = "round") +
  # Pollinators (dimmed except shared hub)
  geom_point(data = subset(polls, id != 3), aes(x = x, y = y), color = "#E2E8F0", size = 7.5, shape = 15) +
  geom_point(data = subset(polls, id == 3), aes(x = x, y = y), color = "#B45309", size = 11.5, shape = 15) +
  geom_point(data = subset(polls, id == 3), aes(x = x, y = y), color = "#F59E0B", size = 9.5, shape = 15) +
  # Plants
  geom_point(data = plants, aes(x = x, y = y), color = "white", size = plants$size + 3) +
  geom_point(data = plants, aes(x = x, y = y), color = plants$color, size = plants$size) +
  coord_fixed(xlim = c(-4.3, 4.3), ylim = c(-3.2, 3.2)) +
  slide_theme

ggsave("images/story_step2a_sharing_bridge.png", p_2a, width = W, height = H, dpi = 300)

# -------------------------------------------------------------
# PLOT 2B: Full Plant-Plant Pollinator Sharing Web
# -------------------------------------------------------------
t_circ <- seq(0, 2*pi, length.out = 5)[1:4]
r_p <- 2.7
periph_circ <- data.frame(
  id = c(1, 3, 5, 7),
  x = r_p * cos(t_circ + pi/4),
  y = r_p * sin(t_circ + pi/4),
  role = "periph",
  color = "#E06A55",
  size = 8.5
)

t_core <- seq(0, 2*pi, length.out = 4)[1:3]
r_c <- 1.15
core_circ <- data.frame(
  id = c(2, 4, 6),
  x = r_c * cos(t_core + pi/6),
  y = r_c * sin(t_core + pi/6),
  role = "core",
  color = "#1D2D6B",
  size = 12.5
)

circ_plants <- rbind(periph_circ, core_circ)
rownames(circ_plants) <- circ_plants$id

circ_links <- plant_links
circ_links$x1 <- circ_plants[as.character(circ_links$p1), "x"]
circ_links$y1 <- circ_plants[as.character(circ_links$p1), "y"]
circ_links$x2 <- circ_plants[as.character(circ_links$p2), "x"]
circ_links$y2 <- circ_plants[as.character(circ_links$p2), "y"]

p_2b <- ggplot() +
  # Spoke edges
  geom_segment(data = subset(circ_links, type == "spoke"),
               aes(x = x1, y = y1, xend = x2, yend = y2),
               color = "#93C5FD", alpha = 0.6, linewidth = 1.0) +
  # Core-Core backbone edges
  geom_segment(data = subset(circ_links, type == "core-core"),
               aes(x = x1, y = y1, xend = x2, yend = y2),
               color = "#1D4ED8", alpha = 0.95, linewidth = 2.4) +
  # Peripheral plants
  geom_point(data = subset(circ_plants, role == "periph"),
             aes(x = x, y = y), color = "white", size = 11.5) +
  geom_point(data = subset(circ_plants, role == "periph"),
             aes(x = x, y = y), color = "#E06A55", size = 9.0) +
  # Core plants
  geom_point(data = subset(circ_plants, role == "core"),
             aes(x = x, y = y), color = "white", size = 15.5) +
  geom_point(data = subset(circ_plants, role == "core"),
             aes(x = x, y = y), color = "#1D2D6B", size = 12.5) +
  coord_fixed(xlim = c(-3.8, 3.8), ylim = c(-3.2, 3.2)) +
  slide_theme

ggsave("images/story_step2b_sharing_web.png", p_2b, width = W, height = H, dpi = 300)
cat("Refined 4 plots generated!\n")
