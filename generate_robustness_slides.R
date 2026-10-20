library(ggplot2)
library(dplyr)

rob_file <- "/home/meow/ownCloud - Mgr Jakub Štenc Phd@owncloud.cesnet.cz/Psani_clanku/2025/Annual_dynamics_pollinator_sharing/outputs/Data_Prep/annual_robustness_results.csv"
rob_data <- read.csv(rob_file, stringsAsFactors = FALSE)

# Filter the 3 main scenarios
df_plot <- rob_data %>%
  filter(Scenario %in% c("Core_Removal_R", "Periph_Removal_R", "Whole_Community_R"))

df_plot$Scenario <- factor(df_plot$Scenario, levels = c("Whole_Community_R", "Periph_Removal_R", "Core_Removal_R"))

years <- 2011:2025

build_plot <- function(df_sub = NULL, step = 4) {
  p_new <- ggplot()
  
  if (step == 1) {
    # Step 1: empty plot, axes only, no drought bars, no lines, transparent legend to preserve layout
    dummy_df <- data.frame(
      Year = c(2011, 2012),
      Mean_R = c(-999, -999),
      CI_Lower = c(-999, -999),
      CI_Upper = c(-999, -999),
      Scenario = factor("Whole_Community_R", levels = levels(df_plot$Scenario))
    )
    p_new <- p_new +
      geom_point(data = dummy_df, aes(x = Year, y = Mean_R, color = Scenario), alpha = 0) +
      geom_line(data = dummy_df, aes(x = Year, y = Mean_R, color = Scenario, linetype = Scenario), alpha = 0) +
      geom_ribbon(data = dummy_df, aes(x = Year, ymin = CI_Lower, ymax = CI_Upper, fill = Scenario), alpha = 0) +
      guides(
        color = guide_legend(override.aes = list(color = "transparent", fill = "transparent", alpha = 0, linetype = "blank")),
        fill = "none",
        linetype = "none"
      ) +
      theme(
        legend.title = element_text(color = "transparent"),
        legend.text = element_text(color = "transparent"),
        legend.key = element_rect(fill = "transparent", color = "transparent")
      )
  } else {
    p_new <- p_new + 
      geom_ribbon(data = df_sub, aes(x = Year, ymin = CI_Lower, ymax = CI_Upper, fill = Scenario), alpha = 0.2, color = NA) +
      geom_line(data = df_sub, aes(x = Year, y = Mean_R, color = Scenario, linetype = Scenario), linewidth = 1.3) +
      geom_point(data = df_sub, aes(x = Year, y = Mean_R, color = Scenario), size = 3)
  }
  
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
      values = c("Whole_Community_R" = "gray40", "Periph_Removal_R" = "#D6604D", "Core_Removal_R" = "#1D2D6B"),
      labels = c("Whole_Community_R" = "Random Order", "Periph_Removal_R" = "Periphery Removed First", "Core_Removal_R" = "Core Removed First"),
      drop = TRUE
    ) +
    scale_fill_manual(
      values = c("Whole_Community_R" = "gray40", "Periph_Removal_R" = "#D6604D", "Core_Removal_R" = "#1D2D6B"),
      labels = c("Whole_Community_R" = "Random Order", "Periph_Removal_R" = "Periphery Removed First", "Core_Removal_R" = "Core Removed First"),
      drop = TRUE
    ) +
    scale_linetype_manual(
      values = c("Whole_Community_R" = "dotted", "Periph_Removal_R" = "dashed", "Core_Removal_R" = "solid"),
      labels = c("Whole_Community_R" = "Random Order", "Periph_Removal_R" = "Periphery Removed First", "Core_Removal_R" = "Core Removed First"),
      drop = TRUE
    ) +
    theme(
      legend.position = "bottom",
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      plot.background = element_rect(fill = "transparent", color = NA),
      panel.background = element_rect(fill = "transparent", color = NA),
      legend.background = element_rect(fill = "transparent", color = NA),
      legend.key = element_rect(fill = "transparent", color = NA),
      axis.text.x = element_text(angle = 45, hjust = 1)
    )
    
  if (step == 1) {
    p_new <- p_new +
      theme(
        legend.title = element_text(color = "transparent"),
        legend.text = element_text(color = "transparent")
      )
  }
    
  return(p_new)
}

# 1. Only Axis (empty plot)
p1 <- build_plot(step = 1)
ggsave("images/robustness_1_axis.png", plot = p1, width = 11, height = 6, bg = "transparent", dpi = 300)

# 2. Random Order
df_random <- subset(df_plot, Scenario == "Whole_Community_R")
p2 <- build_plot(df_random, step = 2)
ggsave("images/robustness_2_random.png", plot = p2, width = 11, height = 6, bg = "transparent", dpi = 300)

# 3. Add Peripheral
df_periph <- subset(df_plot, Scenario %in% c("Whole_Community_R", "Periph_Removal_R"))
p3 <- build_plot(df_periph, step = 3)
ggsave("images/robustness_3_periph.png", plot = p3, width = 11, height = 6, bg = "transparent", dpi = 300)

# 4. Add Core
p4 <- build_plot(df_plot, step = 4)
ggsave("images/robustness_4_all.png", plot = p4, width = 11, height = 6, bg = "transparent", dpi = 300)

cat("Successfully generated robustness slides 1 to 4.\n")
