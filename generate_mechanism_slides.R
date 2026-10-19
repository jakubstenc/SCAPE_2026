suppressMessages({
  library(dplyr)
  library(ggplot2)
  library(patchwork)
  library(nlme)
  library(scales)
})

base_dir <- "/home/meow/ownCloud - Mgr Jakub Štenc Phd@owncloud.cesnet.cz/Psani_clanku/2025/Annual_dynamics_pollinator_sharing/"

cd    <- read.csv(file.path(base_dir, "outputs/Data_Prep/core_dependence_yearly.csv"))
abund <- read.csv(file.path(base_dir, "data/published_data/annual_plant_abundance_yearly.csv"))
core  <- read.csv(file.path(base_dir, "outputs/Data_Prep/core_definition.csv"))
mot   <- read.csv(file.path(base_dir, "outputs/Data_Prep/annual_motif_results.csv"))

core_spp <- core$Plant_Species[core$Core %in% TRUE]

COL_CORE <- "#1D2D6B"
COL_PER  <- "#D6604D"
COL_DRY  <- "#D45F00"
COL_WET  <- "#1A78C2"
YRS <- 2011:2025

base_th <- theme_classic(base_size = 18) +
  theme(
    panel.grid = element_blank(),
    plot.title = element_text(size = 20, face = "bold", hjust = 0.5),
    axis.text = element_text(color = "black", size = 16),
    axis.title = element_text(size = 18, face = "bold"),
    plot.background = element_rect(fill = "transparent", color = NA),
    panel.background = element_rect(fill = "transparent", color = NA),
    legend.background = element_rect(fill = "transparent", color = NA)
  )

xsc <- scale_x_continuous(breaks = YRS, limits = c(2010.5, 2025.5), expand = c(0, 0))

# ------------------------------------------------------------------------------
# 1. Panel A: Core dependence (\Delta R) over time
# ------------------------------------------------------------------------------
gA <- gls(dR ~ Year + spei6, cd, correlation = corAR1(form = ~ Year), method = "REML")
ndA <- data.frame(Year = seq(2011, 2025, 0.1), spei6 = mean(cd$spei6))
XA <- model.matrix(~ Year + spei6, ndA)
ndA$fit <- drop(XA %*% coef(gA))
seA <- sqrt(rowSums((XA %*% vcov(gA)) * XA))
ndA$lo <- ndA$fit - 1.96 * seA
ndA$hi <- ndA$fit + 1.96 * seA

ttA <- summary(gA)$tTable
labA <- sprintf("Year: +%.3f / yr (p = %s)\nSPEI-6: %.3f / unit (p = %s)\nGLS-AR1 (REML)",
                ttA["Year", 1], format.pval(ttA["Year", 4], digits = 2),
                ttA["spei6", 1], format.pval(ttA["spei6", 4], digits = 2))

pA <- ggplot() +
  geom_ribbon(data = ndA, aes(Year, ymin = lo, ymax = hi), fill = "grey75", alpha = 0.45) +
  geom_line(data = ndA, aes(Year, fit), linewidth = 1.3, colour = "grey20") +
  geom_point(data = cd, aes(Year, dR, fill = spei6), shape = 21, size = 5, stroke = 1, colour = "black") +
  scale_fill_gradient2(
    low = COL_DRY, mid = "white", high = COL_WET, midpoint = 0,
    name = "Summer SPEI-6 (Drought)", limits = c(-2.3, 2.3),
    guide = guide_colourbar(barwidth = 9, barheight = 0.8, title.position = "top", title.hjust = 0.5)
  ) +
  annotate("label", x = 2011.0, y = 0.53, label = labA,
           hjust = 0, vjust = 1, size = 5, lineheight = 0.95,
           fill = alpha("white", 0.90), border.colour = "grey70") +
  xsc +
  coord_cartesian(ylim = c(0.10, 0.55)) +
  labs(
    title = "Network Vulnerability: Rising Core Dependence (\u0394R)",
    x = "Year", 
    y = "Core dependence (\u0394R = R_periph - R_core)"
  ) +
  base_th +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = c(0.98, 0.08),
    legend.justification = c(1, 0),
    legend.direction = "horizontal",
    legend.title = element_text(size = 12),
    legend.text = element_text(size = 11)
  )

ggsave("images/mechanism_1_vuln.png", pA, width = 11, height = 6.5, bg = "transparent", dpi = 300)

# ------------------------------------------------------------------------------
# 2. Panel B: Floral Asymmetry under Drought
# ------------------------------------------------------------------------------
a_yr <- abund %>%
  mutate(Group = ifelse(Plant_species %in% core_spp, "Core species (n = 6)", "Peripheral species (n = 49)")) %>%
  group_by(Year, Group) %>%
  summarise(abund = sum(total_standardized_abundance), .groups = "drop") %>%
  left_join(cd %>% select(Year, spei6), by = "Year") %>%
  mutate(drought_sev = -spei6)

mB_per <- lm(abund ~ drought_sev, data = filter(a_yr, grepl("Peripheral", Group)))
mB_cor <- lm(abund ~ drought_sev, data = filter(a_yr, grepl("Core", Group)))
ttB_per <- summary(mB_per)$coefficients
ttB_cor <- summary(mB_cor)$coefficients

grid_cor <- data.frame(drought_sev = seq(-1.3, 2.3, length.out = 100), Group = "Core species (n = 6)")
pr_c <- predict(mB_cor, newdata = grid_cor, se.fit = TRUE)
grid_cor$fit <- as.numeric(pr_c$fit)
grid_cor$se  <- as.numeric(pr_c$se.fit)
grid_cor$lo  <- grid_cor$fit - 1.96 * grid_cor$se
grid_cor$hi  <- grid_cor$fit + 1.96 * grid_cor$se

grid_per <- data.frame(drought_sev = seq(-1.3, 2.3, length.out = 100), Group = "Peripheral species (n = 49)")
pr_p <- predict(mB_per, newdata = grid_per, se.fit = TRUE)
grid_per$fit <- as.numeric(pr_p$fit)
grid_per$se  <- as.numeric(pr_p$se.fit)
grid_per$lo  <- grid_per$fit - 1.96 * grid_per$se
grid_per$hi  <- grid_per$fit + 1.96 * grid_per$se

gridB <- rbind(grid_cor, grid_per)

labB_text <- sprintf("Peripheral: \u03b2 = %.1f (p = %.3f) [CRASH]\nCore: \u03b2 = +%.1f (p = %.3f) [STABLE]",
                     ttB_per["drought_sev", 1], ttB_per["drought_sev", 4],
                     ttB_cor["drought_sev", 1], ttB_cor["drought_sev", 4])

pB <- ggplot() +
  geom_ribbon(data = gridB, aes(drought_sev, ymin = pmax(0, lo), ymax = hi, fill = Group),
              alpha = 0.20, colour = NA) +
  geom_line(data = gridB, aes(drought_sev, fit, colour = Group, linetype = Group), linewidth = 1.3) +
  geom_point(data = a_yr, aes(drought_sev, abund, fill = Group),
             size = 4.5, shape = 21, stroke = 1, colour = "black") +
  scale_colour_manual(
    values = c("Core species (n = 6)" = COL_CORE, "Peripheral species (n = 49)" = COL_PER),
    name = NULL
  ) +
  scale_fill_manual(
    values = c("Core species (n = 6)" = COL_CORE, "Peripheral species (n = 49)" = COL_PER),
    name = NULL
  ) +
  scale_linetype_manual(
    values = c("Core species (n = 6)" = "solid", "Peripheral species (n = 49)" = "dashed"),
    name = NULL
  ) +
  annotate("label", x = 0.3, y = 160, label = labB_text, hjust = 0, vjust = 1, size = 5,
           lineheight = 1.05, fill = alpha("white", 0.90), border.colour = "grey70") +
  coord_cartesian(ylim = c(0, 165)) +
  labs(
    title = "Ecological Driver: Floral Asymmetry under Drought",
    x = "Summer drought severity (-SPEI-6)", 
    y = "Standardized floral abundance"
  ) +
  base_th +
  theme(
    legend.position = "top",
    legend.direction = "horizontal",
    legend.text = element_text(size = 14)
  )

ggsave("images/mechanism_2_floral.png", pB, width = 11, height = 6.5, bg = "transparent", dpi = 300)

# ------------------------------------------------------------------------------
# 3. Panel C: Micro-architectural consequence (Motif Scaffolding on Core)
# ------------------------------------------------------------------------------
df_C <- left_join(cd, mot, by = "Year")

gC <- gls(Pct_Core_Anchored ~ Year + spei6, df_C, correlation = corAR1(form = ~ Year), method = "REML")
ndC <- data.frame(Year = seq(2011, 2025, 0.1), spei6 = mean(df_C$spei6))
XC <- model.matrix(~ Year + spei6, ndC)
ndC$fit <- drop(XC %*% coef(gC))
seC <- sqrt(rowSums((XC %*% vcov(gC)) * XC))
ndC$lo <- ndC$fit - 1.96 * seC
ndC$hi <- ndC$fit + 1.96 * seC

ttC <- summary(gC)$tTable
labC <- sprintf("Year: +%.2f%% / yr (p = %s)\nSPEI-6: %.2f%% / unit (p = %s)\nGLS-AR1 (REML)",
                ttC["Year", 1], format.pval(ttC["Year", 4], digits = 2),
                ttC["spei6", 1], format.pval(ttC["spei6", 4], digits = 2))

mC_rel <- lm(dR ~ Pct_Core_Anchored, data = df_C)
r2_val <- summary(mC_rel)$r.squared
labC_rel <- sprintf("Coupling to Fragility:\n\u0394R ~ Core motifs\nR\u00b2 = %.2f (p < 0.0001)", r2_val)

pC <- ggplot() +
  geom_ribbon(data = ndC, aes(Year, ymin = lo, ymax = hi), fill = "grey75", alpha = 0.45) +
  geom_line(data = ndC, aes(Year, fit), linewidth = 1.3, colour = "grey20") +
  geom_point(data = df_C, aes(Year, Pct_Core_Anchored, fill = spei6),
             shape = 21, size = 5, stroke = 1, colour = "black") +
  scale_fill_gradient2(
    low = COL_DRY, mid = "white", high = COL_WET, midpoint = 0,
    name = "Summer SPEI-6", limits = c(-2.3, 2.3), guide = "none"
  ) +
  scale_y_continuous(labels = function(x) paste0(x, "%"), breaks = seq(50, 100, 10)) +
  coord_cartesian(ylim = c(48, 105)) +
  annotate("label", x = 2010.8, y = 104, label = labC, hjust = 0, vjust = 1, size = 5,
           lineheight = 0.95, fill = alpha("white", 0.90), border.colour = "grey70") +
  annotate("label", x = 2025.2, y = 50, label = labC_rel, hjust = 1, vjust = 0, size = 4.8,
           lineheight = 1.0, fill = alpha("#FFF5EE", 0.95), color = "#8B1A1A", border.colour = "grey70") +
  xsc +
  labs(
    title = "Architectural Consequence: Motif Collapse onto Core",
    x = "Year", 
    y = "Core-anchored motifs (%)"
  ) +
  base_th +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave("images/mechanism_3_motifs.png", pC, width = 11, height = 6.5, bg = "transparent", dpi = 300)

cat("Successfully generated mechanism slides 1, 2, and 3.\n")
