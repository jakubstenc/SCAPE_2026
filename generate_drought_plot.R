library(dplyr)
library(ggplot2)
library(HanPolNet)

cache_file <- "data/climate_annual_1975_2025.rds"
dir.create("data", showWarnings = FALSE)

if (file.exists(cache_file)) {
  message("Loading cached TerraClimate data...")
  climate_annual <- readRDS(cache_file)
} else {
  message("Fetching TerraClimate data (1975-2025)...")
  plots_centroid <- data.frame(
    plot_id = "Handrkov_Center",
    lon = mean(HanPolNet::hanpolnet_plots$X_WSG, na.rm = TRUE),
    lat = mean(HanPolNet::hanpolnet_plots$Y_WSG, na.rm = TRUE)
  )

  climate_raw <- HanPolNet::get_terraclimate_data(plots_centroid, years = 1975:2025)

  climate_annual <- climate_raw %>%
    filter(month %in% 7:8) %>%
    group_by(year) %>%
    summarise(
      summer_spei_6 = mean(spei_6, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(Drought_Severity = -1 * summer_spei_6) %>%
    rename(Year = year)

  saveRDS(climate_annual, cache_file)
  message("Cached climate data to ", cache_file)
}

message("Generating 50-year plot (without 2x SD line/text)...")
p <- ggplot(climate_annual, aes(x = Year, y = Drought_Severity)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50", linewidth = 1) +
  geom_bar(stat = "identity", aes(fill = Drought_Severity), color = "black", linewidth = 0.3) +
  scale_fill_gradient2(low = "#1D2D6B", mid = "white", high = "#D6604D", midpoint = 0, guide = "none") +
  theme_classic(base_size = 20) +
  labs(
    x = "Year",
    y = "Drought Severity\n(Summer inverted SPEI-6)"
  ) +
  theme(
    plot.background = element_rect(fill = "transparent", color = NA),
    panel.background = element_rect(fill = "transparent", color = NA)
  )

ggsave("images/drought_severity_50yrs.png", plot = p, width = 10, height = 4, dpi = 300, bg = "transparent")
message("Saved to images/drought_severity_50yrs.png")

message("Generating highlighted plot...")
p_rect <- p + annotate("rect", xmin = 2010.5, xmax = 2025.5, ymin = -Inf, ymax = Inf, fill = NA, color = "red", linewidth = 1.5)
ggsave("images/drought_severity_50yrs_rect.png", plot = p_rect, width = 10, height = 4, dpi = 300, bg = "transparent")
message("Saved to images/drought_severity_50yrs_rect.png")

message("Generating zoomed plot (2011-2025 without 2x SD line/text)...")
p_zoomed <- ggplot(climate_annual %>% filter(Year >= 2011 & Year <= 2025), aes(x = Year, y = Drought_Severity)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50", linewidth = 1) +
  geom_bar(stat = "identity", aes(fill = Drought_Severity), color = "black", linewidth = 0.5) +
  scale_fill_gradient2(low = "#1D2D6B", mid = "white", high = "#D6604D", midpoint = 0, guide = "none") +
  theme_classic(base_size = 20) +
  scale_x_continuous(breaks = 2011:2025) +
  labs(
    x = "Year",
    y = "Drought Severity\n(Summer inverted SPEI-6)"
  ) +
  theme(
    plot.background = element_rect(fill = "transparent", color = NA),
    panel.background = element_rect(fill = "transparent", color = NA)
  )

ggsave("images/drought_severity_zoomed.png", plot = p_zoomed, width = 10, height = 4, dpi = 300, bg = "transparent")
message("Saved to images/drought_severity_zoomed.png")

message("Generating future plot (2011-2030 without 2x SD line/text)...")
p_future <- ggplot(climate_annual %>% filter(Year >= 2011 & Year <= 2025), aes(x = Year, y = Drought_Severity)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50", linewidth = 1) +
  geom_bar(stat = "identity", aes(fill = Drought_Severity), color = "black", linewidth = 0.5) +
  scale_fill_gradient2(low = "#1D2D6B", mid = "white", high = "#D6604D", midpoint = 0, guide = "none") +
  theme_classic(base_size = 20) +
  scale_x_continuous(breaks = seq(2011, 2030, by=2), limits = c(2010.5, 2030.5)) +
  labs(
    x = "Year",
    y = "Drought Severity\n(Summer inverted SPEI-6)"
  ) +
  annotate("text", x = 2028, y = 0, label = "?", size = 45, color = "gray60", fontface = "bold", alpha = 0.5) +
  theme(
    plot.background = element_rect(fill = "transparent", color = NA),
    panel.background = element_rect(fill = "transparent", color = NA)
  )

ggsave("images/drought_severity_future.png", plot = p_future, width = 10, height = 4, dpi = 300, bg = "transparent")
message("Saved to images/drought_severity_future.png")

message("All drought plots successfully updated without 2x SD line/text!")
