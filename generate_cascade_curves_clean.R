library(bipartite)
library(ggplot2)
library(dplyr)
library(tidyr)
library(scales)

cat("Generating clean extinction cascade curves...\n")

# Load 2015 dataset
df_15 <- read.csv("data/sit_ net15 .csv", row.names=1)
mat_full <- as.matrix(df_15)
mat_full[is.na(mat_full)] <- 0
mat_full <- mat_full[rowSums(mat_full) > 0, colSums(mat_full) > 0]

# Calculate extinction curves
ext_core <- second.extinct(mat_full, participant="lower", method="degree")
ext_periph <- second.extinct(mat_full, participant="lower", method="abundance") 
set.seed(42)
ext_rand <- second.extinct(mat_full, participant="lower", method="random")

parse_curve <- function(ext_obj, label) {
  df <- as.data.frame(unclass(ext_obj))
  df$prop_plants_extinct <- cumsum(df$ext.lower) / sum(df$ext.lower)
  df$prop_polls_survive <- 1 - (cumsum(df$ext.higher) / sum(df$ext.higher))
  
  start_row <- data.frame(no=0, ext.lower=0, ext.higher=0, prop_plants_extinct=0, prop_polls_survive=1, Scenario=label)
  df$Scenario <- label
  return(rbind(start_row, df))
}

curve_core <- parse_curve(ext_core, "Core")
curve_periph <- parse_curve(ext_periph, "Peripheral")
curve_rand <- parse_curve(ext_rand, "Random")

all_curves <- bind_rows(curve_core, curve_periph, curve_rand)

# Base theme for crisp, bold curves
curve_theme <- theme_classic(base_size = 22) +
  theme(
    axis.title = element_text(face = "bold", size = 20, color = "#0F172A"),
    axis.text = element_text(size = 17, color = "#1E293B", face = "bold"),
    axis.line = element_line(color = "#0F172A", linewidth = 1.2),
    axis.ticks = element_line(color = "#0F172A", linewidth = 1.0),
    legend.position = c(0.28, 0.26),
    legend.title = element_blank(),
    legend.text = element_text(size = 18, face = "bold", color = "#1E293B"),
    legend.key.width = unit(2.2, "lines"),
    legend.key.height = unit(1.2, "lines"),
    legend.background = element_rect(fill = alpha("white", 0.8), color = NA),
    plot.background = element_rect(fill = "transparent", color = NA),
    panel.background = element_rect(fill = "transparent", color = NA),
    plot.margin = margin(10, 15, 10, 10)
  )

# 1. EMPTY IMAGE (completely transparent)
p_empty <- ggplot() +
  theme_void() +
  theme(plot.background = element_rect(fill = "transparent", color = NA))
ggsave("images/cascade_curve_empty.png", p_empty, width = 6, height = 6, dpi = 300, bg = "transparent")
cat("Saved cascade_curve_empty.png\n")

# 2. AXES ONLY (No curves, no legend, no letter R)
p_axes <- ggplot() +
  scale_x_continuous(labels = scales::percent, limits = c(0, 1), breaks = seq(0, 1, 0.25)) +
  scale_y_continuous(labels = scales::percent, limits = c(0, 1), breaks = seq(0, 1, 0.25)) +
  labs(x = "Plants Extinct", y = "Pollinators Surviving") +
  curve_theme +
  theme(legend.position = "none")

ggsave("images/cascade_curve_axes.png", p_axes, width = 6, height = 6, dpi = 300, bg = "transparent")
cat("Saved cascade_curve_axes.png\n")

# 3. RANDOM LINE ONLY
df_rand <- all_curves %>% filter(Scenario == "Random")
df_rand$Scenario <- factor(df_rand$Scenario, levels = c("Random"))

p_rand <- ggplot(df_rand, aes(x = prop_plants_extinct, y = prop_polls_survive, color = Scenario, linetype = Scenario)) +
  geom_line(linewidth = 2.4) +
  scale_color_manual(values = c("Random" = "#64748B")) +
  scale_linetype_manual(values = c("Random" = "dotted")) +
  scale_x_continuous(labels = scales::percent, limits = c(0, 1), breaks = seq(0, 1, 0.25)) +
  scale_y_continuous(labels = scales::percent, limits = c(0, 1), breaks = seq(0, 1, 0.25)) +
  labs(x = "Plants Extinct", y = "Pollinators Surviving") +
  curve_theme

ggsave("images/cascade_curve_rand.png", p_rand, width = 6, height = 6, dpi = 300, bg = "transparent")
cat("Saved cascade_curve_rand.png\n")

# 4. PERIPHERAL + RANDOM
df_periph <- all_curves %>% filter(Scenario %in% c("Random", "Peripheral"))
df_periph$Scenario <- factor(df_periph$Scenario, levels = c("Random", "Peripheral"))

p_periph <- ggplot(df_periph, aes(x = prop_plants_extinct, y = prop_polls_survive, color = Scenario, linetype = Scenario)) +
  geom_line(linewidth = 2.4) +
  scale_color_manual(values = c("Random" = "#64748B", "Peripheral" = "#B63679")) +
  scale_linetype_manual(values = c("Random" = "dotted", "Peripheral" = "dashed")) +
  scale_x_continuous(labels = scales::percent, limits = c(0, 1), breaks = seq(0, 1, 0.25)) +
  scale_y_continuous(labels = scales::percent, limits = c(0, 1), breaks = seq(0, 1, 0.25)) +
  labs(x = "Plants Extinct", y = "Pollinators Surviving") +
  curve_theme

ggsave("images/cascade_curve_periph.png", p_periph, width = 6, height = 6, dpi = 300, bg = "transparent")
cat("Saved cascade_curve_periph.png\n")

# 5. CORE + PERIPHERAL + RANDOM
df_core <- all_curves %>% filter(Scenario %in% c("Random", "Peripheral", "Core"))
df_core$Scenario <- factor(df_core$Scenario, levels = c("Random", "Peripheral", "Core"))

p_core <- ggplot(df_core, aes(x = prop_plants_extinct, y = prop_polls_survive, color = Scenario, linetype = Scenario)) +
  geom_line(linewidth = 2.4) +
  scale_color_manual(values = c("Random" = "#64748B", "Peripheral" = "#B63679", "Core" = "#3B0F70")) +
  scale_linetype_manual(values = c("Random" = "dotted", "Peripheral" = "dashed", "Core" = "solid")) +
  scale_x_continuous(labels = scales::percent, limits = c(0, 1), breaks = seq(0, 1, 0.25)) +
  scale_y_continuous(labels = scales::percent, limits = c(0, 1), breaks = seq(0, 1, 0.25)) +
  labs(x = "Plants Extinct", y = "Pollinators Surviving") +
  curve_theme

ggsave("images/cascade_curve_core.png", p_core, width = 6, height = 6, dpi = 300, bg = "transparent")
cat("Saved cascade_curve_core.png\n")

cat("All cascade curves successfully generated!\n")
