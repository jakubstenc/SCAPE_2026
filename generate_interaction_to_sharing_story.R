library(ggplot2)
library(grid)
library(png)
library(dplyr)

W <- 9.8
H <- 6.0

# -------------------------------------------------------------
# Read Badges & Pre-create RasterGrobs
# -------------------------------------------------------------
badge_ach <- rasterGrob(readPNG("images/story_badge_achillea_flower.png"), interpolate = TRUE)
badge_suc <- rasterGrob(readPNG("images/story_badge_succisa_flower.png"), interpolate = TRUE)
badge_cen <- rasterGrob(readPNG("images/story_badge_centaurea.png"), interpolate = TRUE)
badge_pim <- rasterGrob(readPNG("images/story_badge_pimpinella.png"), interpolate = TRUE)
badge_ran <- rasterGrob(readPNG("images/story_badge_ranunculus.png"), interpolate = TRUE)
badge_sel <- rasterGrob(readPNG("images/story_badge_selinum.png"), interpolate = TRUE)
badge_san <- rasterGrob(readPNG("images/story_badge_sanguisorba.png"), interpolate = TRUE)

badge_eri <- rasterGrob(readPNG("images/story_badge_eristalis.png"), interpolate = TRUE)
badge_but <- rasterGrob(readPNG("images/story_badge_butterfly.png"), interpolate = TRUE)
badge_zyg <- rasterGrob(readPNG("images/story_badge_zygaena.png"), interpolate = TRUE)

# Seamless slide theme - pure white background, completely borderless
clean_theme <- theme_void() +
  theme(
    plot.background = element_rect(fill = "#FFFFFF", color = NA),
    panel.background = element_rect(fill = "#FFFFFF", color = NA),
    plot.margin = margin(4, 4, 4, 4)
  )

# -------------------------------------------------------------
# Balanced Coordinate System for Bipartite Steps (1A, 1B, 2A)
# Y limits: [0.05, 6.0]
# Header pill: y = 5.76, Subtitle: y = 5.40
# Plant labels: y = 4.88 (names) and 4.62 (roles)
# Plant centers: y = 3.80 (radius 0.60 -> span [3.20, 4.40])
# Mid-zone (edges & curves): y in [2.10, 3.20]
# Pollinator centers: y = 1.45 (radius 0.65 -> span [0.80, 2.10])
# Pollinator labels: y = 0.68 (names) and 0.44 (subs)
# Bottom callout pill: y = 0.16
# -------------------------------------------------------------

# Coordinates:
# Plants: Ranunculus (0.95), Achillea (2.65), Succisa (5.25), Sanguisorba (7.55), Centaurea (9.25)
# Pollinators: Halictus (1.0), Eristalis (2.9), Butterfly (5.4), Zygaena (7.7), Syrphid (9.2)

all_edges <- data.frame(
  p = c("eristalis", "eristalis", "butterfly", "butterfly", "butterfly", "zygaena", "halictus", "halictus", "eristalis", "eristalis", "syrphid", "syrphid"),
  pl = c("achillea", "succisa", "succisa", "achillea", "sanguisorba", "sanguisorba", "ranunculus", "achillea", "ranunculus", "centaurea", "centaurea", "succisa"),
  x1 = c(2.9, 2.9, 5.4, 5.4, 5.4, 7.7, 1.0, 1.0, 2.9, 2.9, 9.2, 9.2),
  y1 = c(1.45, 1.45, 1.45, 1.45, 1.45, 1.45, 1.45, 1.45, 1.45, 1.45, 1.45, 1.45),
  x2 = c(2.65, 5.25, 5.25, 2.65, 7.55, 7.55, 0.95, 2.65, 0.95, 9.25, 9.25, 5.25),
  y2 = c(3.80, 3.80, 3.80, 3.80, 3.80, 3.80, 3.80, 3.80, 3.80, 3.80, 3.80, 3.80),
  initial = c(TRUE, FALSE, TRUE, FALSE, FALSE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE),
  weight = c(4, 4, 3, 2, 2, 3, 2, 2, 3, 3, 2, 2)
)

# Helper function to add standard plant and pollinator nodes
add_bipartite_nodes <- function(p, highlight_eristalis = FALSE) {
  # --- Pollinator Nodes (Bottom Row: y = 1.45) ---
  # Halictus bee (Far Left)
  p <- p + 
    annotate("point", x = 1.0, y = 1.45, size = 9, color = "#D97706") +
    annotate("point", x = 1.0, y = 1.45, size = 4.5, color = "#FEF3C7") +
    annotate("text", x = 1.0, y = 0.68, label = "Halictus bee", fontface = "bold", size = 3.1, color = "#451A03") +
    annotate("text", x = 1.0, y = 0.44, label = "(Solitary wild bee)", size = 2.5, color = "#78716C")

  # Syrphid fly (Far Right)
  p <- p + 
    annotate("point", x = 9.2, y = 1.45, size = 9, color = "#D97706") +
    annotate("point", x = 9.2, y = 1.45, size = 4.5, color = "#FEF3C7") +
    annotate("text", x = 9.2, y = 0.68, label = "Syrphid fly sp.", fontface = "bold", size = 3.1, color = "#451A03") +
    annotate("text", x = 9.2, y = 0.44, label = "(Flower visitor)", size = 2.5, color = "#78716C")

  # Eristalis hoverfly
  if (highlight_eristalis) {
    p <- p + annotate("point", x = 2.9, y = 1.45, size = 36, color = "#FEF3C7", alpha = 0.95)
  }
  p <- p + 
    annotate("point", x = 2.9, y = 1.45, size = 28, color = if(highlight_eristalis) "#F59E0B" else "#D97706") +
    annotate("point", x = 2.9, y = 1.45, size = 24, color = "white") +
    annotation_custom(badge_eri, xmin = 2.9 - 0.66, xmax = 2.9 + 0.66, ymin = 1.45 - 0.66, ymax = 1.45 + 0.66) +
    annotate("text", x = 2.9, y = 0.68, label = "Eristalis interruptus", fontface = "bold.italic", size = 3.6, color = if(highlight_eristalis) "#B45309" else "#451A03") +
    annotate("text", x = 2.9, y = 0.44, label = if(highlight_eristalis) "⭐ Shared Generalist Pollinator" else "Hoverfly (Abundant Generalist)",
             fontface = if(highlight_eristalis) "bold" else "plain", size = 2.6, color = if(highlight_eristalis) "#B45309" else "#78716C")

  # Butterfly
  p <- p + 
    annotate("point", x = 5.4, y = 1.45, size = 27, color = "#D97706") +
    annotate("point", x = 5.4, y = 1.45, size = 24, color = "white") +
    annotation_custom(badge_but, xmin = 5.4 - 0.66, xmax = 5.4 + 0.66, ymin = 1.45 - 0.66, ymax = 1.45 + 0.66) +
    annotate("text", x = 5.4, y = 0.68, label = "Meadow Butterfly", fontface = "bold", size = 3.6, color = "#451A03") +
    annotate("text", x = 5.4, y = 0.44, label = "Coenonympha / Lycaenid", fontface = "italic", size = 2.6, color = "#78716C")

  # Zygaena burnet moth
  p <- p + 
    annotate("point", x = 7.7, y = 1.45, size = 27, color = "#D97706") +
    annotate("point", x = 7.7, y = 1.45, size = 24, color = "white") +
    annotation_custom(badge_zyg, xmin = 7.7 - 0.66, xmax = 7.7 + 0.66, ymin = 1.45 - 0.66, ymax = 1.45 + 0.66) +
    annotate("text", x = 7.7, y = 0.68, label = "Zygaena burnet moth", fontface = "bold.italic", size = 3.6, color = "#451A03") +
    annotate("text", x = 7.7, y = 0.44, label = "Day-flying Zygaenid", size = 2.6, color = "#78716C")

  # --- Plant Photo Badges (Top Row: y = 3.80) ---
  pr <- 0.60

  # 1. Ranunculus acris (Far Left)
  p <- p +
    annotate("point", x = 0.95, y = 3.80, size = 26, color = "#1D2D6B") +
    annotate("point", x = 0.95, y = 3.80, size = 23, color = "white") +
    annotation_custom(badge_ran, xmin = 0.95 - pr, xmax = 0.95 + pr, ymin = 3.80 - pr, ymax = 3.80 + pr) +
    annotate("text", x = 0.95, y = 4.88, label = "Ranunculus acris", fontface = "bold.italic", size = 3.4, color = "#0F172A") +
    annotate("text", x = 0.95, y = 4.62, label = "Core Perennial Hub", fontface = "bold", size = 2.5, color = "#1D4ED8")

  # 2. Achillea ptarmica
  ach_ring_color <- if(highlight_eristalis) "#1D4ED8" else "#1D2D6B"
  ach_ring_size  <- if(highlight_eristalis) 32 else 28
  if (highlight_eristalis) {
    p <- p + annotate("point", x = 2.65, y = 3.80, size = 36, color = "#EFF6FF", alpha = 0.8)
  }
  p <- p + 
    annotate("point", x = 2.65, y = 3.80, size = ach_ring_size, color = ach_ring_color) +
    annotate("point", x = 2.65, y = 3.80, size = 25, color = "white") +
    annotation_custom(badge_ach, xmin = 2.65 - 0.66, xmax = 2.65 + 0.66, ymin = 3.80 - 0.66, ymax = 3.80 + 0.66) +
    annotate("text", x = 2.65, y = 4.88, label = "Achillea ptarmica", fontface = "bold.italic", size = 3.6, color = "#0F172A") +
    annotate("text", x = 2.65, y = 4.62, label = "Core Perennial Hub", fontface = "bold", size = 2.6, color = "#1D4ED8")

  # 3. Succisa pratensis
  suc_ring_color <- if(highlight_eristalis) "#1D4ED8" else "#1D2D6B"
  suc_ring_size  <- if(highlight_eristalis) 32 else 28
  if (highlight_eristalis) {
    p <- p + annotate("point", x = 5.25, y = 3.80, size = 36, color = "#EFF6FF", alpha = 0.8)
  }
  p <- p + 
    annotate("point", x = 5.25, y = 3.80, size = suc_ring_size, color = suc_ring_color) +
    annotate("point", x = 5.25, y = 3.80, size = 25, color = "white") +
    annotation_custom(badge_suc, xmin = 5.25 - 0.66, xmax = 5.25 + 0.66, ymin = 3.80 - 0.66, ymax = 3.80 + 0.66) +
    annotate("text", x = 5.25, y = 4.88, label = "Succisa pratensis", fontface = "bold.italic", size = 3.6, color = "#0F172A") +
    annotate("text", x = 5.25, y = 4.62, label = "Core Perennial Hub", fontface = "bold", size = 2.6, color = "#1D4ED8")

  # 4. Sanguisorba officinalis
  p <- p + 
    annotate("point", x = 7.55, y = 3.80, size = 27, color = "#DC2626") +
    annotate("point", x = 7.55, y = 3.80, size = 24, color = "white") +
    annotation_custom(badge_san, xmin = 7.55 - 0.62, xmax = 7.55 + 0.62, ymin = 3.80 - 0.62, ymax = 3.80 + 0.62) +
    annotate("text", x = 7.55, y = 4.88, label = "Sanguisorba officinalis", fontface = "bold.italic", size = 3.5, color = "#991B1B") +
    annotate("text", x = 7.55, y = 4.62, label = "Peripheral Flora", fontface = "italic", size = 2.6, color = "#B91C1C")

  # 5. Centaurea jacea (Far Right)
  p <- p +
    annotate("point", x = 9.25, y = 3.80, size = 26, color = "#1D2D6B") +
    annotate("point", x = 9.25, y = 3.80, size = 23, color = "white") +
    annotation_custom(badge_cen, xmin = 9.25 - pr, xmax = 9.25 + pr, ymin = 3.80 - pr, ymax = 3.80 + pr) +
    annotate("text", x = 9.25, y = 4.88, label = "Centaurea jacea", fontface = "bold.italic", size = 3.4, color = "#0F172A") +
    annotate("text", x = 9.25, y = 4.62, label = "Core Perennial Hub", fontface = "bold", size = 2.5, color = "#1D4ED8")

  return(p)
}


# =============================================================
# 1A: Observed Flower Visits
# =============================================================
p_1a <- ggplot() +
  # Top Header Pill & Subtitle
  annotate("label", x = 5.1, y = 5.76, label = "  STEP 1 • EMPIRICAL FLOWER VISITS IN THE MEADOW  ",
           fill = "#F0FDF4", color = "#15803D", fontface = "bold", size = 3.8, label.r = unit(0.3, "lines")) +
  annotate("text", x = 5.1, y = 5.40, label = "Field surveys record individual insect visits on co-flowering plant species in the meadow",
           fontface = "italic", size = 3.6, color = "#475569") +
  # Ghost edges for potential links
  geom_segment(data = subset(all_edges, !initial), aes(x = x1, y = y1, xend = x2, yend = y2),
               color = "#F1F5F9", linewidth = 1.0) +
  # Active initial visit lines (vibrant azure/cyan)
  geom_segment(data = subset(all_edges, initial), aes(x = x1, y = y1, xend = x2, yend = y2),
               color = "#0284C7", linewidth = 3.2, lineend = "round") +
  # Contact / pulse markers on the visit links
  geom_point(data = subset(all_edges, initial), aes(x = 0.5*(x1+x2), y = 0.5*(y1+y2)),
             color = "#38BDF8", size = 5.5) +
  geom_point(data = subset(all_edges, initial), aes(x = 0.5*(x1+x2), y = 0.5*(y1+y2)),
             color = "white", size = 2.6) +
  # Clean, centered visit callout pill at the bottom
  annotate("label", x = 5.1, y = 0.16, 
           label = "Observation: Each visit registers an insect species foraging on a plant species",
           fill = "#F8FAFC", color = "#0369A1", fontface = "italic", size = 3.2, label.r = unit(0.2, "lines")) +
  coord_fixed(xlim = c(0, 10.2), ylim = c(0.05, 6.0)) +
  clean_theme

p_1a <- add_bipartite_nodes(p_1a, highlight_eristalis = FALSE)
ggsave("images/story_step1a_few_visits.png", p_1a, width = W, height = H, dpi = 300)
cat("Generated story_step1a_few_visits.png\n")


# =============================================================
# 1B: Complete Bipartite Network
# =============================================================
p_1b <- ggplot() +
  annotate("label", x = 5.1, y = 5.76, label = "  STEP 2 • THE BIPARTITE INTERACTION WEB  ",
           fill = "#EFF6FF", color = "#1D4ED8", fontface = "bold", size = 3.8, label.r = unit(0.3, "lines")) +
  annotate("text", x = 5.1, y = 5.40, label = "Over 15 years, hundreds of observed visits weave together into a two-mode interaction network",
           fontface = "italic", size = 3.6, color = "#475569") +
  # All bipartite edges
  geom_segment(data = all_edges, aes(x = x1, y = y1, xend = x2, yend = y2, linewidth = weight),
               color = "#64748B", alpha = 0.65, lineend = "round") +
  scale_linewidth_continuous(range = c(1.3, 3.2), guide = "none") +
  annotate("label", x = 5.1, y = 0.16, 
           label = "The traditional view: Bipartite network of plant-pollinator feeding interactions",
           fill = "#F8FAFC", color = "#475569", fontface = "italic", size = 3.2, label.r = unit(0.2, "lines")) +
  coord_fixed(xlim = c(0, 10.2), ylim = c(0.05, 6.0)) +
  clean_theme

p_1b <- add_bipartite_nodes(p_1b, highlight_eristalis = FALSE)
ggsave("images/story_step1b_full_bipartite.png", p_1b, width = W, height = H, dpi = 300)
cat("Generated story_step1b_full_bipartite.png\n")


# =============================================================
# 2A: The Shared Pollinator Bridge
# =============================================================
p_2a <- ggplot() +
  annotate("label", x = 5.1, y = 5.76, label = "  STEP 3 • THE LIVING BRIDGE: SHARED POLLINATORS  ",
           fill = "#FEF3C7", color = "#B45309", fontface = "bold", size = 3.8, label.r = unit(0.3, "lines")) +
  annotate("text", x = 5.1, y = 5.40, label = "Plants do not interact directly — shared flower visitors carry pollen between them!",
           fontface = "italic", size = 3.6, color = "#475569") +
  # Dimmed background edges
  geom_segment(data = subset(all_edges, !(p == "eristalis" & (pl %in% c("achillea", "succisa")))),
               aes(x = x1, y = y1, xend = x2, yend = y2),
               color = "#E2E8F0", alpha = 0.45, linewidth = 0.9) +
  # Glowing visit links to Eristalis (Golden V-bridge)
  geom_segment(data = subset(all_edges, p == "eristalis" & (pl %in% c("achillea", "succisa"))),
               aes(x = x1, y = y1, xend = x2, yend = y2),
               color = "#F59E0B", linewidth = 4.5, lineend = "round")

# Add standard nodes with Eristalis highlighted
p_2a <- add_bipartite_nodes(p_2a, highlight_eristalis = TRUE)

# Direct Plant-Plant Sharing Bridge connecting Achillea <-> Succisa
p_2a <- p_2a +
  # Glowing cyan backdrop halo for the bridge
  geom_segment(aes(x = 3.35, y = 3.80, xend = 4.55, yend = 3.80),
               color = "#93C5FD", linewidth = 7.5, alpha = 0.60, lineend = "round") +
  # Royal blue double-arrow bridge
  geom_segment(aes(x = 3.35, y = 3.80, xend = 4.55, yend = 3.80),
               color = "#1D4ED8", linewidth = 3.8, lineend = "round",
               arrow = arrow(length = unit(0.24, "cm"), ends = "both", type = "closed")) +
  # Fitted pill centered right above the arrow
  annotate("label", x = 3.95, y = 4.14, 
           label = "🔄 Indirect Pollen Link",
           fill = "#EFF6FF", color = "#1D4ED8", fontface = "bold", size = 2.8, label.r = unit(0.2, "lines")) +
  # Explanatory callout pill in open space
  annotate("label", x = 6.65, y = 2.55,
           label = "⭐ THE LIVING BRIDGE\nEristalis visits both flowers,\ncarrying pollen between them",
           fill = "#FEF3C7", color = "#B45309", fontface = "bold", size = 2.9,
           label.r = unit(0.25, "lines"), lineheight = 1.15) +
  # Bottom callout pill
  annotate("label", x = 5.1, y = 0.16, 
           label = "The Living Bridge: Co-visited plants become linked through indirect pollen transfer",
           fill = "#EFF6FF", color = "#1E40AF", fontface = "italic", size = 3.2, label.r = unit(0.2, "lines")) +
  coord_fixed(xlim = c(0, 10.2), ylim = c(0.05, 6.0)) +
  clean_theme

ggsave("images/story_step2a_sharing_bridge.png", p_2a, width = W, height = H, dpi = 300)
cat("Generated story_step2a_sharing_bridge.png\n")


# =============================================================
# 2B: Full Plant-Plant Pollinator Sharing Web
# Refined with all core flower photo badges!
# =============================================================
net_nodes <- data.frame(
  id = c("achillea", "succisa", "centaurea", "pimpinella", "ranunculus", "selinum",
         "sanguisorba", "cirsium", "lathyrus", "flammula", "lychnis", "hypericum"),
  name = c("Achillea ptarmica", "Succisa pratensis", "Centaurea jacea", "Pimpinella saxifraga", "Ranunculus acris", "Selinum carvifolia",
           "Sanguisorba officinalis", "Cirsium palustre", "Lathyrus pratensis", "Ranunculus flammula", "Lychnis flos-cuculi", "Hypericum maculatum"),
  x = c(3.30, 7.00, 4.95, 6.45, 3.75, 5.30,
        8.50, 4.95, 1.95, 7.40, 1.55, 2.35),
  y = c(2.95, 2.45, 3.45, 4.05, 1.65, 1.45,
        3.55, 4.55, 1.00, 0.95, 3.40, 4.30),
  role = c(rep("core", 6), rep("periph", 6)),
  has_badge = c(TRUE, TRUE, TRUE, TRUE, TRUE, TRUE,
                TRUE, FALSE, FALSE, FALSE, FALSE, FALSE)
)
rownames(net_nodes) <- net_nodes$id

# Edges
net_edges <- data.frame(
  from = c("achillea", "achillea", "succisa", "achillea", "succisa", "centaurea", "pimpinella", "selinum", "centaurea",
           "sanguisorba", "sanguisorba", "cirsium", "cirsium", "lathyrus", "lathyrus", "flammula", "flammula", "lychnis", "hypericum", "hypericum"),
  to = c("succisa", "centaurea", "centaurea", "ranunculus", "selinum", "pimpinella", "succisa", "ranunculus", "selinum",
         "succisa", "centaurea", "centaurea", "pimpinella", "ranunculus", "achillea", "succisa", "selinum", "achillea", "achillea", "centaurea"),
  type = c(rep("core-core", 9), rep("spoke", 11)),
  weight = c(4.2, 3.5, 3.8, 2.8, 3.0, 2.9, 2.6, 2.5, 2.8, 1.8, 1.6, 1.5, 1.4, 1.6, 1.4, 1.5, 1.3, 1.5, 1.4, 1.2)
)
net_edges$x1 <- net_nodes[net_edges$from, "x"]
net_edges$y1 <- net_nodes[net_edges$from, "y"]
net_edges$x2 <- net_nodes[net_edges$to, "x"]
net_edges$y2 <- net_nodes[net_edges$to, "y"]

br <- 0.49

p_2b <- ggplot() +
  # Top Header Pill & Subtitle
  annotate("label", x = 5.1, y = 5.76, label = "  STEP 4 • PROJECTION: THE MEADOW POLLINATOR-SHARING WEB  ",
           fill = "#EEF2FF", color = "#3730A3", fontface = "bold", size = 3.8, label.r = unit(0.3, "lines")) +
  annotate("text", x = 5.1, y = 5.42, label = "Projecting shared visitors yields an indirect topological plant network anchored by stable core hubs",
           fontface = "italic", size = 3.6, color = "#475569") +

  # Spoke links
  geom_segment(data = subset(net_edges, type == "spoke"), aes(x = x1, y = y1, xend = x2, yend = y2),
               color = "#93C5FD", alpha = 0.55, linewidth = 1.3) +
  # Core-Core backbone links
  geom_segment(data = subset(net_edges, type == "core-core" & !(from == "achillea" & to == "succisa")),
               aes(x = x1, y = y1, xend = x2, yend = y2),
               color = "#1D4ED8", alpha = 0.85, linewidth = 2.4) +
  # Achillea-Succisa primary backbone highlight (from Step 3 bridge!)
  geom_segment(data = subset(net_edges, from == "achillea" & to == "succisa"),
               aes(x = x1, y = y1, xend = x2, yend = y2),
               color = "#93C5FD", linewidth = 6.5, alpha = 0.5) +
  geom_segment(data = subset(net_edges, from == "achillea" & to == "succisa"),
               aes(x = x1, y = y1, xend = x2, yend = y2),
               color = "#1D4ED8", linewidth = 3.8) +

  # Peripheral non-badge nodes
  geom_point(data = subset(net_nodes, role == "periph" & !has_badge), aes(x = x, y = y),
             color = "#F87171", size = 4.5) +
  geom_point(data = subset(net_nodes, role == "periph" & !has_badge), aes(x = x, y = y),
             color = "white", size = 2.2) +

  # Peripheral labels
  annotate("text", x = net_nodes["cirsium", "x"] + 0.16, y = net_nodes["cirsium", "y"] + 0.14,
           label = "Cirsium palustre", fontface = "italic", size = 2.8, color = "#B91C1C", hjust = 0) +
  annotate("text", x = net_nodes["hypericum", "x"] - 0.15, y = net_nodes["hypericum", "y"] + 0.15,
           label = "Hypericum maculatum", fontface = "italic", size = 2.8, color = "#B91C1C", hjust = 1) +
  annotate("text", x = net_nodes["lychnis", "x"] - 0.16, y = net_nodes["lychnis", "y"] + 0.18,
           label = "Lychnis flos-cuculi", fontface = "italic", size = 2.8, color = "#B91C1C", hjust = 1) +
  annotate("text", x = net_nodes["lathyrus", "x"] - 0.15, y = net_nodes["lathyrus", "y"] - 0.18,
           label = "Lathyrus pratensis", fontface = "italic", size = 2.8, color = "#B91C1C", hjust = 1) +
  annotate("text", x = net_nodes["flammula", "x"] + 0.15, y = net_nodes["flammula", "y"] - 0.18,
           label = "Ranunculus flammula", fontface = "italic", size = 2.8, color = "#B91C1C", hjust = 0) +

  # Selinum carvifolia badge node
  annotate("point", x = net_nodes["selinum", "x"], y = net_nodes["selinum", "y"], size = 28, color = "#1D4ED8", alpha = 0.3) +
  annotate("point", x = net_nodes["selinum", "x"], y = net_nodes["selinum", "y"], size = 25, color = "#1E3A8A") +
  annotate("point", x = net_nodes["selinum", "x"], y = net_nodes["selinum", "y"], size = 22, color = "white") +
  annotation_custom(badge_sel,
                    xmin = net_nodes["selinum", "x"] - br, xmax = net_nodes["selinum", "x"] + br,
                    ymin = net_nodes["selinum", "y"] - br, ymax = net_nodes["selinum", "y"] + br) +
  annotate("label", x = net_nodes["selinum", "x"], y = net_nodes["selinum", "y"] - 0.65,
           label = "Selinum carvifolia\n(Core Hub)", fill = "#FFFFFF", color = "#0F172A", fontface = "bold.italic", size = 3.0, hjust = 0.5, label.r = unit(0.2, "lines")) +

  # Achillea ptarmica badge node
  annotate("point", x = net_nodes["achillea", "x"], y = net_nodes["achillea", "y"], size = 28, color = "#1D4ED8", alpha = 0.3) +
  annotate("point", x = net_nodes["achillea", "x"], y = net_nodes["achillea", "y"], size = 25, color = "#1E3A8A") +
  annotate("point", x = net_nodes["achillea", "x"], y = net_nodes["achillea", "y"], size = 22, color = "white") +
  annotation_custom(badge_ach,
                    xmin = net_nodes["achillea", "x"] - br, xmax = net_nodes["achillea", "x"] + br,
                    ymin = net_nodes["achillea", "y"] - br, ymax = net_nodes["achillea", "y"] + br) +
  annotate("label", x = net_nodes["achillea", "x"] - 0.60, y = net_nodes["achillea", "y"] - 0.12,
           label = "Achillea ptarmica\n(Core Hub)", fill = "#FFFFFF", color = "#0F172A", fontface = "bold.italic", size = 3.0, hjust = 1, label.r = unit(0.2, "lines")) +

  # Succisa pratensis badge node
  annotate("point", x = net_nodes["succisa", "x"], y = net_nodes["succisa", "y"], size = 28, color = "#1D4ED8", alpha = 0.3) +
  annotate("point", x = net_nodes["succisa", "x"], y = net_nodes["succisa", "y"], size = 25, color = "#1E3A8A") +
  annotate("point", x = net_nodes["succisa", "x"], y = net_nodes["succisa", "y"], size = 22, color = "white") +
  annotation_custom(badge_suc,
                    xmin = net_nodes["succisa", "x"] - br, xmax = net_nodes["succisa", "x"] + br,
                    ymin = net_nodes["succisa", "y"] - br, ymax = net_nodes["succisa", "y"] + br) +
  annotate("label", x = net_nodes["succisa", "x"] + 0.60, y = net_nodes["succisa", "y"] - 0.12,
           label = "Succisa pratensis\n(Core Hub)", fill = "#FFFFFF", color = "#0F172A", fontface = "bold.italic", size = 3.0, hjust = 0, label.r = unit(0.2, "lines")) +

  # Centaurea jacea badge node
  annotate("point", x = net_nodes["centaurea", "x"], y = net_nodes["centaurea", "y"], size = 28, color = "#1D4ED8", alpha = 0.3) +
  annotate("point", x = net_nodes["centaurea", "x"], y = net_nodes["centaurea", "y"], size = 25, color = "#1E3A8A") +
  annotate("point", x = net_nodes["centaurea", "x"], y = net_nodes["centaurea", "y"], size = 22, color = "white") +
  annotation_custom(badge_cen,
                    xmin = net_nodes["centaurea", "x"] - br, xmax = net_nodes["centaurea", "x"] + br,
                    ymin = net_nodes["centaurea", "y"] - br, ymax = net_nodes["centaurea", "y"] + br) +
  annotate("label", x = net_nodes["centaurea", "x"] - 0.52, y = net_nodes["centaurea", "y"] + 0.50,
           label = "Centaurea jacea\n(Core Hub)", fill = "#FFFFFF", color = "#0F172A", fontface = "bold.italic", size = 3.0, hjust = 0.5, label.r = unit(0.2, "lines")) +

  # Pimpinella saxifraga badge node
  annotate("point", x = net_nodes["pimpinella", "x"], y = net_nodes["pimpinella", "y"], size = 28, color = "#1D4ED8", alpha = 0.3) +
  annotate("point", x = net_nodes["pimpinella", "x"], y = net_nodes["pimpinella", "y"], size = 25, color = "#1E3A8A") +
  annotate("point", x = net_nodes["pimpinella", "x"], y = net_nodes["pimpinella", "y"], size = 22, color = "white") +
  annotation_custom(badge_pim,
                    xmin = net_nodes["pimpinella", "x"] - br, xmax = net_nodes["pimpinella", "x"] + br,
                    ymin = net_nodes["pimpinella", "y"] - br, ymax = net_nodes["pimpinella", "y"] + br) +
  annotate("label", x = net_nodes["pimpinella", "x"] + 0.55, y = net_nodes["pimpinella", "y"] + 0.38,
           label = "Pimpinella saxifraga\n(Core Hub)", fill = "#FFFFFF", color = "#0F172A", fontface = "bold.italic", size = 3.0, hjust = 0, label.r = unit(0.2, "lines")) +

  # Ranunculus acris badge node
  annotate("point", x = net_nodes["ranunculus", "x"], y = net_nodes["ranunculus", "y"], size = 28, color = "#1D4ED8", alpha = 0.3) +
  annotate("point", x = net_nodes["ranunculus", "x"], y = net_nodes["ranunculus", "y"], size = 25, color = "#1E3A8A") +
  annotate("point", x = net_nodes["ranunculus", "x"], y = net_nodes["ranunculus", "y"], size = 22, color = "white") +
  annotation_custom(badge_ran,
                    xmin = net_nodes["ranunculus", "x"] - br, xmax = net_nodes["ranunculus", "x"] + br,
                    ymin = net_nodes["ranunculus", "y"] - br, ymax = net_nodes["ranunculus", "y"] + br) +
  annotate("label", x = net_nodes["ranunculus", "x"] - 0.60, y = net_nodes["ranunculus", "y"] - 0.10,
           label = "Ranunculus acris\n(Core Hub)", fill = "#FFFFFF", color = "#0F172A", fontface = "bold.italic", size = 3.0, hjust = 1, label.r = unit(0.2, "lines")) +

  # Sanguisorba officinalis badge node
  annotate("point", x = net_nodes["sanguisorba", "x"], y = net_nodes["sanguisorba", "y"], size = 24, color = "#DC2626") +
  annotate("point", x = net_nodes["sanguisorba", "x"], y = net_nodes["sanguisorba", "y"], size = 21, color = "white") +
  annotation_custom(badge_san,
                    xmin = net_nodes["sanguisorba", "x"] - 0.46, xmax = net_nodes["sanguisorba", "x"] + 0.46,
                    ymin = net_nodes["sanguisorba", "y"] - 0.46, ymax = net_nodes["sanguisorba", "y"] + 0.46) +
  annotate("label", x = net_nodes["sanguisorba", "x"], y = net_nodes["sanguisorba", "y"] - 0.60,
           label = "Sanguisorba officinalis\n(Peripheral Flora)", fill = "#FEF2F2", color = "#991B1B", fontface = "bold.italic", size = 2.8, hjust = 0.5, label.r = unit(0.2, "lines")) +

  # Legend box in upper right corner with plenty of space
  annotate("label", x = 10.0, y = 4.88,
           label = "● Core Perennial Hubs (High Sharing)\n● Peripheral Spokes (Specialist / Ephemeral)",
           fill = "#F8FAFC", color = "#334155", fontface = "plain", size = 2.8,
           label.r = unit(0.25, "lines"), hjust = 1) +

  # Bottom callout pill
  annotate("label", x = 5.1, y = 0.16, 
           label = "Topological Projection: The full community connects through an enduring 6-species core",
           fill = "#EEF2FF", color = "#3730A3", fontface = "italic", size = 3.2, label.r = unit(0.2, "lines")) +

  coord_fixed(xlim = c(0, 10.2), ylim = c(0.05, 6.0)) +
  clean_theme

ggsave("images/story_step2b_sharing_web.png", p_2b, width = W, height = H, dpi = 300)
cat("Generated story_step2b_sharing_web.png\n")
cat("All 4 story steps regenerated successfully with real core flower photos!\n")
