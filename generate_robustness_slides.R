library(ggplot2)
library(dplyr)

rob_file <- "/home/meow/ownCloud - Mgr Jakub Štenc Phd@owncloud.cesnet.cz/Psani_clanku/2025/Annual_dynamics_pollinator_sharing/outputs/Data_Prep/annual_robustness_results.csv"
rob_data <- read.csv(rob_file, stringsAsFactors = FALSE)

# Filter the 3 main scenarios
df_plot <- rob_data %>%
  filter(Scenario %in% c("Core_Removal_R", "Periph_Removal_R", "Whole_Community_R"))

years <- 2011:2025

build_plot <- function(df_sub) {
  p_new <- ggplot() +
    annotate("rect", xmin = 2014.5, xmax = 2015.5, ymin = -Inf, ymax = Inf, alpha = 0.15, fill = "#D45F00") +
    annotate("rect", xmin = 2017.5, xmax = 2018.5, ymin = -Inf, ymax = Inf, alpha = 0.15, fill = "#D45F00")
    
  # To keep dimensions exactly the same, we MUST always draw the legend.
  if (nrow(df_sub) == 0) {
    df_sub <- df_plot[1, ]
    df_sub$Mean_R <- -999
    df_sub$CI_Lower <- -999
    df_sub$CI_Upper <- -999
  }
  
  p_new <- p_new + 
    geom_ribbon(data = df_sub, aes(x = Year, ymin = CI_Lower, ymax = CI_Upper, fill = Scenario), alpha = 0.2, color = NA) +
    geom_line(data = df_sub, aes(x = Year, y = Mean_R, color = Scenario, linetype = Scenario), linewidth = 1.3) +
    geom_point(data = df_sub, aes(x = Year, y = Mean_R, color = Scenario), size = 3)
  
  p_new <- p_new +
    theme_classic(base_size = 20) +
    labs(
      title = NULL,
      x = "Year",
      y = "Network Robustness (R)",
      color = "Scenario",
      fill = "Scenario",
      linetype = "Scenario"
    ) +
    scale_x_continuous(breaks = years, limits = c(min(years), max(years))) +
    coord_cartesian(ylim = c(0.35, 0.95)) +
    scale_color_manual(
      values = c("Core_Removal_R" = "#1D2D6B", "Periph_Removal_R" = "#D6604D", "Whole_Community_R" = "gray40"),
      labels = c("Core_Removal_R" = "Core Removed First", "Periph_Removal_R" = "Periphery Removed First", "Whole_Community_R" = "Random Order"),
      drop = FALSE
    ) +
    scale_fill_manual(
      values = c("Core_Removal_R" = "#1D2D6B", "Periph_Removal_R" = "#D6604D", "Whole_Community_R" = "gray40"),
      labels = c("Core_Removal_R" = "Core Removed First", "Periph_Removal_R" = "Periphery Removed First", "Whole_Community_R" = "Random Order"),
      drop = FALSE
    ) +
    scale_linetype_manual(
      values = c("Core_Removal_R" = "solid", "Periph_Removal_R" = "dashed", "Whole_Community_R" = "dotted"),
      labels = c("Core_Removal_R" = "Core Removed First", "Periph_Removal_R" = "Periphery Removed First", "Whole_Community_R" = "Random Order"),
      drop = FALSE
    ) +
    theme(
      legend.position = "bottom",
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      plot.background = element_rect(fill = "transparent", color = NA),
      panel.background = element_rect(fill = "transparent", color = NA),
      legend.background = element_rect(fill = "transparent", color = NA),
      axis.text.x = element_text(angle = 45, hjust = 1)
    )
    
  return(p_new)
}

# 1. Only Axis
p1 <- build_plot(df_plot[0, ])
ggsave("images/robustness_1_axis.png", plot = p1, width = 11, height = 6, bg = "transparent", dpi = 300)

# 2. Random Order
df_random <- subset(df_plot, Scenario == "Whole_Community_R")
p2 <- build_plot(df_random)
ggsave("images/robustness_2_random.png", plot = p2, width = 11, height = 6, bg = "transparent", dpi = 300)

# 3. Add Peripheral
df_periph <- subset(df_plot, Scenario %in% c("Whole_Community_R", "Periph_Removal_R"))
p3 <- build_plot(df_periph)
ggsave("images/robustness_3_periph.png", plot = p3, width = 11, height = 6, bg = "transparent", dpi = 300)

# 4. Add Core
p4 <- build_plot(df_plot)
ggsave("images/robustness_4_all.png", plot = p4, width = 11, height = 6, bg = "transparent", dpi = 300)

cat("Successfully generated robustness slides 1 to 4.\n")
