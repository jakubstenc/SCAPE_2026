library(grid)
library(png)

# Square panels: shown ~320 px wide on the slide, so text and marks are drawn large
w <- 1000
h <- 1000

COL_CORE <- "#8C2981"
COL_EDGE <- "#3B0F70"
COL_PER  <- "#B63679"
COL_DRY  <- "#F8765C"

# ==============================================================================
# 1. TAKE-HOME 1: ARCHITECTURE - the 6 core species as a fully linked web
# ==============================================================================
cat("Rendering Figure 1: Architecture...\n")
png("images/takehome_1_architecture.png", width = w, height = h, res = 150, bg = "white")
grid.newpage()

genus <- c("Centaurea", "Succisa", "Achillea", "Selinum", "Ranunculus", "Pimpinella")
photo_files <- c("images/Centaurea_jaceae.png", "images/Succisa_pratensis.png",
                 "images/Achillea_ptarmica.png", "images/Selinum_carvifolia.png",
                 "images/Ranunculus_acris.png", "images/Pimpinella_saxifraga.png")

ang <- pi / 2 - (0:5) * pi / 3
ring_r <- 0.285
node_x <- 0.5 + ring_r * cos(ang)
node_y <- 0.49 + ring_r * sin(ang)
photo_r <- 0.115

# Every core species shares pollinators with every other one
for (i in 1:5) {
  for (j in (i + 1):6) {
    grid.lines(x = node_x[c(i, j)], y = node_y[c(i, j)],
               gp = gpar(col = COL_EDGE, lwd = 7, alpha = 0.55, lineend = "round"))
  }
}

for (i in 1:6) {
  grid.circle(x = node_x[i], y = node_y[i], r = photo_r + 0.008,
              gp = gpar(fill = "white", col = COL_CORE, lwd = 5))
  grid.raster(readPNG(photo_files[i]), x = node_x[i], y = node_y[i],
              width = photo_r * 2, height = photo_r * 2)
  # Names sit outside the ring so they never cross the links
  lab_y <- node_y[i] + ifelse(sin(ang[i]) > 0.1, photo_r + 0.045, -(photo_r + 0.045))
  grid.text(genus[i], x = node_x[i], y = lab_y,
            gp = gpar(fontface = "bold.italic", fontsize = 19, col = "#0F172A"))
}

dev.off()


# ==============================================================================
# 2. TAKE-HOME 2: FRAGILITY - periphery fades in drought, visits shift to the core
# ==============================================================================
cat("Rendering Figure 2: Fragility...\n")
png("images/takehome_2_liferaft.png", width = w, height = h, res = 150, bg = "white")
grid.newpage()

# Schematic floral response
x0 <- 0.14; x1 <- 0.86
grid.lines(x = c(x0 - 0.04, x1 + 0.04), y = c(0.47, 0.47), gp = gpar(col = "#94A3B8", lwd = 4))
grid.lines(x = c(x0, x1), y = c(0.88, 0.62), gp = gpar(col = COL_PER, lwd = 11, lty = "22", lineend = "round"))
grid.lines(x = c(x0, x1), y = c(0.62, 0.635), gp = gpar(col = COL_CORE, lwd = 13, lineend = "round"))
grid.text("Periphery", x = 0.50, y = 0.86, gp = gpar(fontface = "bold", fontsize = 22, col = COL_PER))
grid.text("Core", x = 0.50, y = 0.56, gp = gpar(fontface = "bold", fontsize = 22, col = COL_CORE))
grid.text("Wet", x = x0, y = 0.42, gp = gpar(fontface = "bold", fontsize = 19, col = "#64748B"))
grid.text("Dry", x = x1, y = 0.42, gp = gpar(fontface = "bold", fontsize = 19, col = COL_DRY))

# Core share of all pollinator visits (mean 2011-14 vs 2023-25)
grid.text("46%", x = 0.24, y = 0.22, gp = gpar(fontface = "bold", fontsize = 40, col = "#64748B"))
grid.text("→", x = 0.50, y = 0.22, gp = gpar(fontface = "bold", fontsize = 40, col = "#94A3B8"))
grid.text("86%", x = 0.76, y = 0.22, gp = gpar(fontface = "bold", fontsize = 40, col = COL_DRY))
grid.text("of visits go to the core", x = 0.50, y = 0.08,
          gp = gpar(fontsize = 23, col = "#334155"))

dev.off()


# ==============================================================================
# 3. TAKE-HOME 3: CONSERVATION - the species to protect
# ==============================================================================
cat("Rendering Figure 3: Conservation...\n")
png("images/takehome_3_conservation.png", width = w, height = h, res = 150, bg = "white")
grid.newpage()

photo_r3 <- 0.44
grid.circle(x = 0.5, y = 0.5, r = photo_r3 + 0.012, gp = gpar(fill = "white", col = "#40695B", lwd = 8))
grid.raster(readPNG("images/Suc_pra_motyle.png"), x = 0.5, y = 0.5,
            width = photo_r3 * 2, height = photo_r3 * 2)

dev.off()
cat("Re-rendering complete!\n")
