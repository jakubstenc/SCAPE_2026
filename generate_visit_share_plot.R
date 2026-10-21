library(ggplot2)
library(dplyr)

# Core share of pollinator visits vs core share of flowers, styled like generate_robustness_slides.R
base_dir <- "/home/meow/ownCloud - Mgr Jakub Štenc Phd@owncloud.cesnet.cz/Psani_clanku/2025/Annual_dynamics_pollinator_sharing/outputs/Data_Prep"
conc <- read.csv(file.path(base_dir, "pollinator_concentration_by_year.csv"))
cd   <- read.csv(file.path(base_dir, "core_dependence_yearly.csv"))

years <- 2011:2025

drought_df <- cd %>% transmute(Year, Drought_Severity = -spei6)

df_long <- bind_rows(
  conc %>% transmute(Year, Share = 100 * prop_visits_core, Series = "Visits to core species"),
  conc %>% transmute(Year, Share = 100 * prop_abund_core,  Series = "Flowers of core species")
)
df_long$Series <- factor(df_long$Series, levels = c("Visits to core species", "Flowers of core species"))

series_cols  <- c("Visits to core species" = "#3B0F70", "Flowers of core species" = "gray45")
series_lines <- c("Visits to core species" = "solid",   "Flowers of core species" = "dotted")

build_plot <- function(show_series) {
  df_sub <- filter(df_long, Series %in% show_series)
  ggplot() +
    # Drought strip along the bottom (bar height = summer drought severity; wet years have no bar)
    geom_hline(yintercept = -3, color = "grey80", linewidth = 0.5) +
    geom_rect(data = drought_df, aes(xmin = Year - 0.35, xmax = Year + 0.35,
                                     ymin = -30, ymax = -30 + pmax(Drought_Severity, 0) * 11),
              fill = "#F8765C", alpha = 0.75) +
    annotate("text", x = 2010.6, y = -4.5, label = "Summer drought", hjust = 0, vjust = 1,
             size = 5, color = "#C4472F", fontface = "bold") +
    geom_line(data = df_sub, aes(Year, Share, color = Series, linetype = Series), linewidth = 1.5) +
    geom_point(data = df_sub, aes(Year, Share, color = Series), size = 3.5) +
    scale_color_manual(values = series_cols, drop = TRUE, name = NULL) +
    scale_linetype_manual(values = series_lines, drop = TRUE, name = NULL) +
    scale_x_continuous(breaks = years, limits = c(min(years) - 0.5, max(years) + 0.5), expand = c(0, 0)) +
    scale_y_continuous(breaks = seq(0, 100, 25), labels = function(x) paste0(x, "%")) +
    coord_cartesian(ylim = c(-30, 100)) +
    labs(x = "Year", y = "Share held by the 6 core species") +
    theme_classic(base_size = 20) +
    theme(
      legend.position = "top",
      legend.key.width = unit(1.6, "cm"),
      panel.grid = element_blank(),
      plot.background = element_rect(fill = "transparent", color = NA),
      panel.background = element_rect(fill = "transparent", color = NA),
      legend.background = element_rect(fill = "transparent", color = NA),
      legend.key = element_rect(fill = "transparent", color = NA),
      axis.text.x = element_text(angle = 45, hjust = 1)
    )
}

# 1. Visits only
# (legend sits on top, so dropping the flowers entry leaves the panel unchanged)
p1 <- build_plot("Visits to core species")
ggsave("images/visit_share_1_visits.png", p1, width = 11, height = 6, bg = "transparent", dpi = 300)

# 2. Visits + flowers
p2 <- build_plot(levels(df_long$Series))
ggsave("images/visit_share_2_flowers.png", p2, width = 11, height = 6, bg = "transparent", dpi = 300)

cat("Successfully generated visit share slides 1 and 2.\n")
