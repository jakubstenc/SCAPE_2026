library(ggplot2)
library(dplyr)

core_file <- "/home/meow/ownCloud - Mgr Jakub Štenc Phd@owncloud.cesnet.cz/Psani_clanku/2025/Annual_dynamics_pollinator_sharing/outputs/Data_Prep/core_definition.csv"
df <- read.csv(core_file, stringsAsFactors = FALSE)

# Filter species that have valid centrality and p-values
df <- df %>% filter(!is.na(Obs_Mean_Gc), !is.na(P_adj))

df$Difference <- df$Obs_Mean_Gc - df$Null_Mean_Gc
df$Role <- df$Core_Status
df$Sig <- ifelse(df$P_adj < 0.001, "***", ifelse(df$P_adj < 0.01, "**", ifelse(df$P_adj < 0.05, "*", "")))

df <- df %>% arrange(Difference)
df$Plant_Species <- factor(df$Plant_Species, levels = df$Plant_Species)

p <- ggplot(df, aes(x = Difference, y = Plant_Species, fill = Role)) +
  geom_bar(stat = "identity", width = 0.75) +
  geom_text(aes(label = Sig, x = Difference + 0.03), hjust = 0, color = "#222222", size = 6, vjust = 0.75) +
  scale_fill_manual(values = c("Core" = "#3B0F70", "Peripheral" = "#B63679")) +
  theme_minimal() +
  scale_x_continuous(expand = expansion(mult = c(0.05, 0.2))) +
  labs(
    x = "Centrality beyond random expectation (Observed Gc - Null Gc)", 
    y = "",
    title = "Identifying the True Core (Flowering-constrained Null Model)"
  ) +
  theme(
    text = element_text(color = "#333333"),
    axis.text.y = element_text(
      color = ifelse(df$Role == "Core", "#3B0F70", "#555555"), 
      size = 14, 
      face = ifelse(df$Role == "Core", "bold.italic", "italic")
    ),
    axis.text.x = element_text(color = "#555555", size = 16),
    axis.title = element_text(color = "#333333", size = 20, margin = margin(t = 15)),
    plot.title = element_blank(),
    legend.position = c(0.8, 0.2),
    legend.background = element_rect(fill = "transparent", color = NA),
    legend.text = element_text(color = "#333333", size = 18),
    legend.title = element_blank(),
    panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_line(color = "#cccccc"),
    plot.background = element_rect(fill = "transparent", color = NA),
    panel.background = element_rect(fill = "transparent", color = NA)
  )

ggsave("images/core_stability_simplified.png", p, width = 14, height = 11, bg = "transparent", dpi = 150)
cat("Updated images/core_stability_simplified.png successfully.\n")
