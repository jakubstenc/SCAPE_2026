suppressMessages({
    library(dplyr)
    library(tidyr)
    library(purrr)
    library(vegan)
    library(ggplot2)
    library(ggrepel)
})

base_dir <- "/home/meow/ownCloud - Mgr Jakub Štenc Phd@owncloud.cesnet.cz/Psani_clanku/2025/Annual_dynamics_pollinator_sharing/"

# 1. Load Interaction Data
interactions <- read.csv(file.path(base_dir, "data/published_data/annual_sharing_interactions.csv"), stringsAsFactors = FALSE) %>%
    mutate(Year = as.integer(Year))

interactions_agg <- interactions %>%
    filter(!is.na(Plant_species), !is.na(Insect_species), Standardized_rate > 0) %>%
    group_by(Year, Plant_species, Insect_species) %>%
    summarise(rate = sum(Standardized_rate, na.rm = TRUE), .groups = "drop")

years <- sort(unique(interactions_agg$Year))

# 2. Compute Annual Directed PAC Matrices
get_pac_vector <- function(yr_data) {
    mat <- yr_data %>%
        select(Plant_species, Insect_species, rate) %>%
        pivot_wider(names_from = Insect_species, values_from = rate, values_fill = 0) %>%
        tibble::column_to_rownames("Plant_species") %>%
        as.matrix()
    mat <- mat[rowSums(mat) > 0, , drop = FALSE]
    if (nrow(mat) < 2) return(NULL)
    pac <- suppressWarnings(bipartite::PAC(mat))
    diag(pac) <- 0
    g <- expand.grid(Target = rownames(pac), Driver = colnames(pac), stringsAsFactors = FALSE)
    g$v <- as.vector(pac)
    g <- g[g$Target != g$Driver, ]
    setNames(g$v, paste0(g$Driver, "->", g$Target))
}

pac_vecs <- map(years, function(y) {
    v <- get_pac_vector(interactions_agg %>% filter(Year == y))
    tibble::tibble(Year = as.integer(y), pair = names(v), sharing = v)
}) %>% bind_rows()

year_mat_pac <- pac_vecs %>%
    pivot_wider(names_from = pair, values_from = sharing, values_fill = 0) %>%
    tibble::column_to_rownames("Year") %>%
    as.matrix()

# 3. NMDS
set.seed(42)
nmds_res <- metaMDS(year_mat_pac, distance = "bray", k = 2, trymax = 200, trace = FALSE)

nmds_points <- as.data.frame(scores(nmds_res, display = "sites")) %>%
    tibble::rownames_to_column("Year") %>%
    mutate(Year = as.integer(Year)) %>%
    arrange(Year)

# 4. Climate
climate_raw <- subset(read.csv(file.path(base_dir, "data/climate/terraclimate_handrkov_monthly.csv"), stringsAsFactors = FALSE), year %in% (2011:2025))

climate_annual <- climate_raw %>%
    filter(month %in% 7:8) %>%
    group_by(year) %>%
    summarise(
        summer_spei_6 = mean(spei_6, na.rm = TRUE),
        summer_t2m = mean(t2m, na.rm = TRUE),
        .groups = "drop"
    ) %>%
    mutate(
        Drought_Severity = -1 * summer_spei_6,
        Temperature = summer_t2m
    ) %>%
    rename(Year = year)

joined_data <- nmds_points %>%
    inner_join(climate_annual, by = "Year")

set.seed(42)
ef <- envfit(nmds_res ~ Drought_Severity + Temperature + Year, data = joined_data, permutations = 9999)

path_segs <- joined_data %>%
    arrange(Year) %>%
    mutate(
        xend = lead(NMDS1),
        yend = lead(NMDS2),
        mid_year = (Year + lead(Year)) / 2
    ) %>%
    filter(!is.na(xend))

arrow_scale <- ordiArrowMul(ef) * 0.78
envfit_vectors <- as.data.frame(scores(ef, display = "vectors")) %>%
    tibble::rownames_to_column("Variable") %>%
    mutate(
        xend = NMDS1 * arrow_scale,
        yend = NMDS2 * arrow_scale,
        r2 = ef$vectors$r,
        pval = ef$vectors$pvals,
        var_name = case_when(
            Variable == "Drought_Severity" ~ "Drought Severity",
            Variable == "Temperature" ~ "Temperature",
            Variable == "Year" ~ "Time (Year)"
        ),
        label = sprintf("%s\n(r² = %.2f, p = %.3f)", var_name, r2, pval),
        nudge_x = case_when(
            Variable == "Drought_Severity" ~ 0.00,
            Variable == "Temperature" ~ -0.03,
            Variable == "Year" ~ -0.06
        ),
        nudge_y = case_when(
            Variable == "Drought_Severity" ~ -0.08,
            Variable == "Temperature" ~ 0.08,
            Variable == "Year" ~ 0.06
        )
    )

base_nmds_theme <- theme_classic(base_size = 22) +
    theme(
        plot.title = element_text(size = 26, face = "bold", hjust = 0.5),
        axis.title = element_text(size = 22, face = "bold"),
        axis.text = element_text(size = 18),
        legend.position = "right",
        legend.title = element_text(size = 20, face = "bold"),
        legend.text = element_text(size = 16),
        plot.background = element_rect(fill = "transparent", color = NA),
        panel.background = element_rect(fill = "transparent", color = NA),
        legend.background = element_rect(fill = "transparent", color = NA)
    )

# Slide 1: Empty axes
p_empty <- ggplot(joined_data, aes(x = NMDS1, y = NMDS2)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey80", linewidth = 0.8) +
    geom_vline(xintercept = 0, linetype = "dashed", color = "grey80", linewidth = 0.8) +
    annotate("text", x = Inf, y = -Inf, label = sprintf("Stress = %.3f", nmds_res$stress),
             hjust = 1.15, vjust = -1.2, size = 7, fontface = "italic", color = "grey40") +
    coord_cartesian(xlim = c(-0.70, 1.15), ylim = c(-0.45, 0.65)) +
    labs(
        title = "Temporal Trajectory of Pollinator Sharing (PAC NMDS)",
        x = "NMDS Axis 1 (Acute Climate Pulse)",
        y = "NMDS Axis 2 (Decadal Press)"
    ) +
    base_nmds_theme

ggsave("images/nmds_climate_envfit_empty.png", p_empty, width = 11, height = 7, bg = "transparent", dpi = 300)

# Slide 2: Trajectory + points
p_points <- p_empty +
    geom_segment(
        data = path_segs,
        aes(x = NMDS1, y = NMDS2, xend = xend, yend = yend, color = mid_year),
        linewidth = 2.2, lineend = "round", alpha = 0.85, inherit.aes = FALSE
    ) +
    geom_point(aes(color = Year), shape = 16, size = 8) +
    scale_color_viridis_c(option = "magma", name = "Year", direction = 1) +
    geom_text_repel(
        aes(label = Year),
        fontface = "bold", size = 6.5, color = "black",
        box.padding = 0.8, point.padding = 0.6, force = 4, max.overlaps = Inf, seed = 42
    )

ggsave("images/nmds_climate_envfit_points.png", p_points, width = 11, height = 7, bg = "transparent", dpi = 300)

# Slide 3: Full with Environmental vectors
p_full <- p_points +
    geom_segment(
        data = envfit_vectors,
        aes(x = 0, y = 0, xend = xend, yend = yend),
        arrow = arrow(length = unit(0.5, "cm"), type = "closed"),
        color = "black", linewidth = 1.6, inherit.aes = FALSE
    ) +
    geom_label_repel(
        data = envfit_vectors,
        aes(x = xend, y = yend, label = label),
        fontface = "bold", size = 6.0, color = "black",
        fill = alpha("white", 0.92), label.size = 0.4,
        box.padding = 0.5, point.padding = 0.4,
        nudge_x = envfit_vectors$nudge_x,
        nudge_y = envfit_vectors$nudge_y,
        inherit.aes = FALSE, seed = 42
    )

ggsave("images/nmds_climate_envfit.png", p_full, width = 11, height = 7, bg = "transparent", dpi = 300)

cat("Successfully generated NMDS slide progression.\n")
