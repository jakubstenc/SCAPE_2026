library(ggplot2)
library(igraph)

core_edges <- rbind(
  c(1, 2), c(2, 3), c(3, 4), c(4, 1),
  c(1, 3), c(2, 4)
)

inter_edges <- rbind(
  c(5, 1), c(5, 6),
  c(6, 2),
  c(7, 3), c(7, 8),
  c(8, 4)
)

periph_edges <- rbind(
  c(9, 5),
  c(10, 6),
  c(11, 7),
  c(12, 8),
  c(13, 1)
)

all_edges_mat <- rbind(core_edges, inter_edges, periph_edges)
g <- graph_from_edgelist(all_edges_mat, directed = FALSE)
k_vals <- coreness(g)

# Coordinates
lay <- matrix(0, nrow = 13, ncol = 2)

angles_core <- c(pi/4, 3*pi/4, 5*pi/4, 7*pi/4)
lay[1:4, 1] <- 0.95 * cos(angles_core)
lay[1:4, 2] <- 0.95 * sin(angles_core)

angles_inter <- c(0, pi/2, pi, 3*pi/2)
lay[5:8, 1] <- 2.15 * cos(angles_inter)
lay[5:8, 2] <- 2.15 * sin(angles_inter)

angles_periph <- c(0.15, pi/2 + 0.15, pi + 0.15, 3*pi/2 + 0.15, 3*pi/4 + 0.15)
lay[9:13, 1] <- 3.35 * cos(angles_periph)
lay[9:13, 2] <- 3.35 * sin(angles_periph)

df_nodes <- data.frame(
  id = 1:13,
  x = lay[, 1],
  y = lay[, 2],
  core = k_vals
)

df_edges <- data.frame(
  from = all_edges_mat[, 1],
  to = all_edges_mat[, 2]
)
df_edges$x1 <- df_nodes$x[df_edges$from]
df_edges$y1 <- df_nodes$y[df_edges$from]
df_edges$x2 <- df_nodes$x[df_edges$to]
df_edges$y2 <- df_nodes$y[df_edges$to]
df_edges$k_min <- pmin(df_nodes$core[df_edges$from], df_nodes$core[df_edges$to])
df_edges$is_core_core <- (df_nodes$core[df_edges$from] == 3 & df_nodes$core[df_edges$to] == 3)

# Synchronized Palette matching plant_step4_coreness.png
c_core_outer <- "#3B0F70"    # Deep Navy
c_core_inner <- "#FEB47B"    # Warm Golden Amber
c_core_edge  <- "#8C2981"    # Bold Blue
c_inter_node <- "#8C2981"    # Intermediate Blue
c_periph_node <- "#DE7BA9"   # Peripheral Coral/Red
c_spoke_edge <- "#C9A3D3"    # Light Sky Blue
c_ghost_node <- "#F8FAFC"    # Faint Slate Fill
c_ghost_stroke <- "#CBD5E1"  # Faint Slate Stroke
c_edge_ghost <- "#E2E8F0"    # Ghost dashed edge

theme_clean <- theme_void() +
  theme(
    plot.background = element_rect(fill = "#FFFFFF", color = NA),
    panel.background = element_rect(fill = "#FFFFFF", color = NA),
    plot.margin = margin(6, 6, 6, 6)
  )

# -------------------------------------------------------------
# Step 1: Intact Web (k >= 1)
# -------------------------------------------------------------
p1 <- ggplot() +
  # Concentric shell guidelines
  annotate("path", x = 3.35 * cos(seq(0, 2*pi, length.out=120)), y = 3.35 * sin(seq(0, 2*pi, length.out=120)),
           color = "#EDB3CE", linetype = "dashed", linewidth = 0.7, alpha = 0.7) +
  annotate("path", x = 2.15 * cos(seq(0, 2*pi, length.out=120)), y = 2.15 * sin(seq(0, 2*pi, length.out=120)),
           color = "#C9A3D3", linetype = "dashed", linewidth = 0.7, alpha = 0.7) +
  annotate("path", x = 0.95 * cos(seq(0, 2*pi, length.out=120)), y = 0.95 * sin(seq(0, 2*pi, length.out=120)),
           color = "#3B0F70", linetype = "dashed", linewidth = 0.7, alpha = 0.7) +
  # Spoke & intermediate edges
  geom_segment(data = subset(df_edges, !is_core_core),
               aes(x = x1, y = y1, xend = x2, yend = y2),
               color = "#64748B", linewidth = 0.8, alpha = 0.6) +
  # Core-Core backbone edges
  geom_segment(data = subset(df_edges, is_core_core),
               aes(x = x1, y = y1, xend = x2, yend = y2),
               color = c_core_edge, linewidth = 1.4, alpha = 0.9) +
  # Peripheral nodes (k = 1) -> Coral #DE7BA9 with white stroke
  geom_point(data = subset(df_nodes, core == 1),
             aes(x = x, y = y), shape = 21, size = 8.5, fill = c_periph_node, color = "white", stroke = 1.6) +
  # Intermediate nodes (k = 2) -> Blue #8C2981 with white stroke
  geom_point(data = subset(df_nodes, core == 2),
             aes(x = x, y = y), shape = 21, size = 8.5, fill = c_inter_node, color = "white", stroke = 1.6) +
  # Core nodes (k = 3): Navy outer circle + Gold inner dot
  geom_point(data = subset(df_nodes, core == 3),
             aes(x = x, y = y), shape = 21, size = 10, fill = c_core_outer, color = "white", stroke = 1.8) +
  geom_point(data = subset(df_nodes, core == 3),
             aes(x = x, y = y), shape = 19, size = 4.8, color = c_core_inner) +
  coord_fixed(xlim = c(-3.9, 3.9), ylim = c(-3.9, 3.9)) +
  theme_clean

# -------------------------------------------------------------
# Step 2: Pruning Outer Shell (k >= 2)
# -------------------------------------------------------------
p2 <- ggplot() +
  # Remaining shell guidelines
  annotate("path", x = 2.15 * cos(seq(0, 2*pi, length.out=120)), y = 2.15 * sin(seq(0, 2*pi, length.out=120)),
           color = "#C9A3D3", linetype = "dashed", linewidth = 0.7, alpha = 0.7) +
  annotate("path", x = 0.95 * cos(seq(0, 2*pi, length.out=120)), y = 0.95 * sin(seq(0, 2*pi, length.out=120)),
           color = "#3B0F70", linetype = "dashed", linewidth = 0.7, alpha = 0.7) +
  # Ghosted edges (pruned with k=1)
  geom_segment(data = subset(df_edges, k_min == 1),
               aes(x = x1, y = y1, xend = x2, yend = y2),
               color = c_edge_ghost, linewidth = 0.5, linetype = "dashed") +
  # Active intermediate edges
  geom_segment(data = subset(df_edges, k_min >= 2 & !is_core_core),
               aes(x = x1, y = y1, xend = x2, yend = y2),
               color = "#64748B", linewidth = 0.9, alpha = 0.7) +
  # Core-Core backbone edges
  geom_segment(data = subset(df_edges, is_core_core),
               aes(x = x1, y = y1, xend = x2, yend = y2),
               color = c_core_edge, linewidth = 1.4, alpha = 0.9) +
  # Ghosted k=1 nodes (peeled away)
  geom_point(data = subset(df_nodes, core == 1),
             aes(x = x, y = y), shape = 21, size = 6.5, fill = c_ghost_node, color = c_ghost_stroke, stroke = 0.9) +
  # Intermediate nodes (k = 2)
  geom_point(data = subset(df_nodes, core == 2),
             aes(x = x, y = y), shape = 21, size = 8.5, fill = c_inter_node, color = "white", stroke = 1.6) +
  # Core nodes (k = 3): Navy outer + Gold inner
  geom_point(data = subset(df_nodes, core == 3),
             aes(x = x, y = y), shape = 21, size = 10, fill = c_core_outer, color = "white", stroke = 1.8) +
  geom_point(data = subset(df_nodes, core == 3),
             aes(x = x, y = y), shape = 19, size = 4.8, color = c_core_inner) +
  coord_fixed(xlim = c(-3.9, 3.9), ylim = c(-3.9, 3.9)) +
  theme_clean

# -------------------------------------------------------------
# Step 3: Innermost Core Backbone (k = k_max = 3)
# -------------------------------------------------------------
p3 <- ggplot() +
  # Innermost core boundary
  annotate("path", x = 0.95 * cos(seq(0, 2*pi, length.out=120)), y = 0.95 * sin(seq(0, 2*pi, length.out=120)),
           color = "#3B0F70", linetype = "solid", linewidth = 0.9, alpha = 0.45) +
  # Ghosted edges for all outer connections
  geom_segment(data = subset(df_edges, k_min < 3),
               aes(x = x1, y = y1, xend = x2, yend = y2),
               color = c_edge_ghost, linewidth = 0.45, linetype = "dashed") +
  # Preserved Core-Core backbone edges
  geom_segment(data = subset(df_edges, is_core_core),
               aes(x = x1, y = y1, xend = x2, yend = y2),
               color = c_core_edge, linewidth = 1.8, alpha = 0.95) +
  # Ghosted outer nodes (k < 3)
  geom_point(data = subset(df_nodes, core < 3),
             aes(x = x, y = y), shape = 21, size = 6.0, fill = c_ghost_node, color = c_ghost_stroke, stroke = 0.7) +
  # Core nodes: Navy outer + Gold inner
  geom_point(data = subset(df_nodes, core == 3),
             aes(x = x, y = y), shape = 21, size = 11, fill = c_core_outer, color = "white", stroke = 2.0) +
  geom_point(data = subset(df_nodes, core == 3),
             aes(x = x, y = y), shape = 19, size = 5.2, color = c_core_inner) +
  coord_fixed(xlim = c(-3.9, 3.9), ylim = c(-3.9, 3.9)) +
  theme_clean

ggsave("images/kcore_step1_web.png", p1, width = 5.2, height = 5.2, dpi = 300)
ggsave("images/kcore_step2_peel.png", p2, width = 5.2, height = 5.2, dpi = 300)
ggsave("images/kcore_step3_core.png", p3, width = 5.2, height = 5.2, dpi = 300)
cat("Palette-synchronized kcore step images saved successfully!\n")
