library(ggplot2)
library(ggforce)
library(png)

# Concept figure for the "next step" slide: shared visitation (solid) vs pollen transfer (dashed arrows)
COL_CORE  <- "#8C2981"
COL_VISIT <- "#3B0F70"
COL_POLL  <- "#F8765C"
COL_PER   <- "#B63679"

photo_files <- c("images/Centaurea_jaceae.png", "images/Succisa_pratensis.png",
                 "images/Achillea_ptarmica.png", "images/Selinum_carvifolia.png",
                 "images/Ranunculus_acris.png", "images/Pimpinella_saxifraga.png")
photos <- lapply(photo_files, readPNG)
# Half plant / half Succisa stigma, made by make_pollen_node_images.py (same species order)
split_files <- sprintf("images/pollen_node_%s.png",
                       c("centaurea", "succisa", "achillea", "selinum", "ranunculus", "pimpinella"))
split_photos <- lapply(split_files, readPNG)

# Core species on a hexagon
ang <- pi / 2 - (0:5) * pi / 3
core <- data.frame(id = 1:6, x = 2.3 * cos(ang), y = 2.3 * sin(ang))
photo_r <- 0.62

# Peripheral species to the sides, each attached to one core species
per <- data.frame(id = 7:10, x = c(-5.3, -5.3, 5.3, 5.3), y = c(1.6, -1.6, 1.6, -1.6),
                  anchor = c(6, 5, 2, 3))
per_r <- 0.32

nodes <- rbind(core[, c("id", "x", "y")], per[, c("id", "x", "y")])
node_r <- c(rep(photo_r, 6), rep(per_r, 4))

# Visitation links within the core: hexagon ring (diameters left out to keep the centre readable)
core_edges <- data.frame(from = c(1, 2, 3, 4, 5, 6), to = c(2, 3, 4, 5, 6, 1))

# Segment between two node rims, optionally shifted sideways (to sit next to the solid link)
rim_segment <- function(a, b, shift = 0, gap = 0.12) {
  p <- nodes[nodes$id == a, ]; q <- nodes[nodes$id == b, ]
  dx <- q$x - p$x; dy <- q$y - p$y; len <- sqrt(dx^2 + dy^2)
  ux <- dx / len; uy <- dy / len
  nx <- -uy; ny <- ux
  ra <- node_r[a] + gap; rb <- node_r[b] + gap
  data.frame(x = p$x + ux * ra + nx * shift, y = p$y + uy * ra + ny * shift,
             xend = q$x - ux * rb + nx * shift, yend = q$y - uy * rb + ny * shift)
}

# Pollen transfer within the core differs by direction, strength and year;
# year t + 1 flips every direction and swaps strong/weak links so the change is obvious
pollen_year <- function(forward, width) {
  do.call(rbind, lapply(seq_len(nrow(core_edges)), function(i) {
    a <- core_edges$from[i]; b <- core_edges$to[i]
    seg <- if (forward[i]) rim_segment(a, b, shift = 0.2) else rim_segment(b, a, shift = -0.2)
    seg$w <- width[i]
    seg
  }))
}
forward_t0 <- c(TRUE, FALSE, TRUE, TRUE, FALSE, TRUE)
width_t0   <- c(4.0, 0.7, 2.0, 0.7, 4.0, 0.7)
pollen_t0 <- pollen_year(forward_t0, width_t0)
pollen_t1 <- pollen_year(!forward_t0, c(0.7, 4.0, 0.7, 4.0, 0.7, 2.0))

# Peripheral links: one visitation link and two pollen arrows in opposite directions
per_visit <- do.call(rbind, lapply(seq_len(nrow(per)), function(i) rim_segment(per$id[i], per$anchor[i])))
per_pollen <- do.call(rbind, lapply(seq_len(nrow(per)), function(i) {
  out  <- rim_segment(per$anchor[i], per$id[i], shift = 0.2);  out$w  <- c(2.4, 0.8, 1.6, 2.4)[i]
  back <- rim_segment(per$id[i], per$anchor[i], shift = 0.2);  back$w <- c(0.8, 2.0, 0.8, 1.2)[i]
  rbind(out, back)
}))

poll_arrow <- arrow(length = unit(0.32, "cm"), type = "closed")

build_plot <- function(step) {
  core_visit <- do.call(rbind, lapply(seq_len(nrow(core_edges)),
                                      function(i) rim_segment(core_edges$from[i], core_edges$to[i])))
  p <- ggplot() +
    geom_segment(data = core_visit, aes(x, y, xend = xend, yend = yend),
                 color = COL_VISIT, linewidth = 2.6, alpha = 0.75, lineend = "round")

  if (step >= 3) {
    p <- p +
      geom_segment(data = per_visit, aes(x, y, xend = xend, yend = yend),
                   color = COL_VISIT, linewidth = 2.6, alpha = 0.75, lineend = "round") +
      geom_segment(data = per_pollen, aes(x, y, xend = xend, yend = yend, linewidth = w),
                   color = COL_POLL, linetype = "22", arrow = poll_arrow) +
      geom_circle(data = per, aes(x0 = x, y0 = y, r = per_r), fill = COL_PER, color = "white", linewidth = 1.2) +
      annotate("text", x = c(-5.3, 5.3), y = 2.6, label = "Peripheral", color = COL_PER,
               size = 6.5, fontface = "bold")
  }
  if (step >= 2) {
    pollen <- if (step == 4) pollen_t1 else pollen_t0
    p <- p +
      geom_segment(data = pollen, aes(x, y, xend = xend, yend = yend, linewidth = w),
                   color = COL_POLL, linetype = "22", arrow = poll_arrow) +
      annotate("label", x = 0, y = 3.75, label = if (step == 4) "Year t + 1" else "Year t",
               size = 7.5, fontface = "bold", color = if (step == 4) "white" else "#0F172A",
               fill = if (step == 4) COL_POLL else "#F1F5F9")
  }

  # Core photos on top (split plant/stigma once pollen transfer is shown)
  node_imgs <- if (step >= 2) split_photos else photos
  p <- p + geom_circle(data = core, aes(x0 = x, y0 = y, r = photo_r + 0.06),
                       fill = "white", color = COL_CORE, linewidth = 2)
  for (i in 1:6) {
    p <- p + annotation_raster(node_imgs[[i]], xmin = core$x[i] - photo_r, xmax = core$x[i] + photo_r,
                               ymin = core$y[i] - photo_r, ymax = core$y[i] + photo_r)
  }

  # Legend drawn by hand at the bottom
  p <- p +
    annotate("segment", x = -5.6, xend = -4.6, y = -3.75, yend = -3.75, color = COL_VISIT, linewidth = 2.6) +
    annotate("text", x = -4.4, y = -3.75, label = "shared visitors", hjust = 0, size = 6.5, color = "#334155")
  if (step >= 2) {
    p <- p +
      annotate("segment", x = 0.9, xend = 1.9, y = -3.75, yend = -3.75, color = COL_POLL,
               linewidth = 1.6, linetype = "22", arrow = poll_arrow) +
      annotate("text", x = 2.1, y = -3.75, label = "pollen transfer", hjust = 0, size = 6.5, color = "#334155")
  }

  p +
    scale_linewidth_identity() +
    coord_fixed(xlim = c(-6.2, 6.2), ylim = c(-4.1, 4.1), expand = FALSE) +
    theme_void() +
    theme(plot.background = element_rect(fill = "transparent", color = NA),
          panel.background = element_rect(fill = "transparent", color = NA))
}

for (s in 1:4) {
  ggsave(sprintf("images/pollen_concept_%d.png", s), build_plot(s),
         width = 12.4, height = 8.2, dpi = 200, bg = "transparent")
}
cat("Successfully generated pollen transfer concept steps 1 to 4.\n")
