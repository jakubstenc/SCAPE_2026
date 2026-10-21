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
        label_name_only = var_name,
        label_full = sprintf("%s\n(r² = %.2f, p = %.3f)", var_name, r2, pval),
        # Label boxes sit in empty corners of the ordination, away from the year points
        lab_x = case_when(
            Variable == "Drought_Severity" ~ 0.93,
            Variable == "Temperature" ~ 0.93,
            Variable == "Year" ~ 0.42
        ),
        lab_y = case_when(
            Variable == "Drought_Severity" ~ 0.40,
            Variable == "Temperature" ~ -0.10,
            Variable == "Year" ~ 0.57
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

# Compute stable label coordinates using geom_text_repel once
p_ref <- ggplot(joined_data, aes(x = NMDS1, y = NMDS2)) +
    geom_point(aes(color = Year), shape = 16, size = 8) +
    scale_color_viridis_c(option = "magma", name = "Year", direction = 1) +
    geom_text_repel(
        aes(label = Year),
        fontface = "bold", size = 6.5, color = "black",
        box.padding = 0.8, point.padding = 0.6, force = 4, max.overlaps = Inf, seed = 42
    ) +
    coord_cartesian(xlim = c(-0.70, 1.15), ylim = c(-0.45, 0.65)) +
    base_nmds_theme

gb <- ggplot_build(p_ref)
year_labels_df <- gb$data[[2]][, c("label", "x", "y")]

# Base plot template (axes only)
create_base_plot <- function(has_visible_legend = TRUE) {
    p <- ggplot(joined_data, aes(x = NMDS1, y = NMDS2)) +
        geom_hline(yintercept = 0, linetype = "dashed", color = "grey80", linewidth = 0.8) +
        geom_vline(xintercept = 0, linetype = "dashed", color = "grey80", linewidth = 0.8) +
        annotate("text", x = Inf, y = -Inf, label = sprintf("Stress = %.3f", nmds_res$stress),
                 hjust = 1.15, vjust = -1.2, size = 7, fontface = "italic", color = "grey40") +
        coord_cartesian(xlim = c(-0.70, 1.15), ylim = c(-0.45, 0.65)) +
        labs(
            title = NULL,
            x = "NMDS 1",
            y = "NMDS 2"
        ) +
        base_nmds_theme
        
    if (!has_visible_legend) {
        p <- p +
            geom_point(aes(color = Year), alpha = 0) +
            scale_color_gradient(
                low = "transparent", high = "transparent", name = "Year",
                guide = guide_colorbar(
                    title.theme = element_text(color = "transparent"),
                    label.theme = element_text(color = "transparent"),
                    frame.colour = "transparent",
                    ticks.colour = "transparent"
                )
            )
    } else {
        p <- p + scale_color_viridis_c(option = "magma", name = "Year", direction = 1)
    }
    return(p)
}

# Helper for year labels
add_year_labels <- function(p, text_color = "black") {
    p + geom_text_repel(
        data = joined_data,
        aes(x = NMDS1, y = NMDS2, label = Year),
        fontface = "bold", size = 6.5, color = text_color,
        box.padding = 0.5, point.padding = 0.4,
        force = 3, max.overlaps = Inf, seed = 42,
        inherit.aes = FALSE
    )
}

# --- Step 1: Empty axes (with layout space locked) ---
p1 <- create_base_plot(has_visible_legend = FALSE)
ggsave("images/nmds_step1_axes.png", p1, width = 11, height = 7, bg = "transparent", dpi = 300)

# --- Step 2: Points only (with year labels) ---
p2 <- create_base_plot(has_visible_legend = TRUE) +
    geom_point(aes(color = Year), shape = 16, size = 8)
p2 <- add_year_labels(p2, "black")
ggsave("images/nmds_step2_points.png", p2, width = 11, height = 7, bg = "transparent", dpi = 300)

# --- Step 3: Trajectory (Points + Connecting path segments) ---
p3 <- create_base_plot(has_visible_legend = TRUE) +
    geom_segment(
        data = path_segs,
        aes(x = NMDS1, y = NMDS2, xend = xend, yend = yend, color = mid_year),
        linewidth = 2.2, lineend = "round", alpha = 0.85, inherit.aes = FALSE
    ) +
    geom_point(aes(color = Year), shape = 16, size = 8)
p3 <- add_year_labels(p3, "black")
ggsave("images/nmds_step3_trajectory.png", p3, width = 11, height = 7, bg = "transparent", dpi = 300)

# Dimmed points/trajectory + a chosen subset of fitted arrows with leader-linked labels
vector_plot <- function(vecs, label_col, label_size) {
    p <- create_base_plot(has_visible_legend = TRUE) +
        geom_segment(
            data = path_segs,
            aes(x = NMDS1, y = NMDS2, xend = xend, yend = yend, color = mid_year),
            linewidth = 2.0, lineend = "round", alpha = 0.25, inherit.aes = FALSE
        ) +
        geom_point(aes(color = Year), shape = 16, size = 8, alpha = 0.30)
    add_year_labels(p, "grey55") +
        geom_segment(
            data = vecs,
            aes(x = 0, y = 0, xend = xend, yend = yend),
            arrow = arrow(length = unit(0.5, "cm"), type = "closed"),
            color = "black", linewidth = 1.8, inherit.aes = FALSE
        ) +
        geom_segment(
            data = vecs,
            aes(x = lab_x, y = lab_y, xend = xend, yend = yend),
            color = "grey45", linewidth = 0.6, inherit.aes = FALSE
        ) +
        geom_label(
            data = vecs,
            aes(x = lab_x, y = lab_y, label = .data[[label_col]]),
            fontface = "bold", size = label_size, color = "black",
            fill = alpha("white", 0.95), label.size = 0.4,
            inherit.aes = FALSE
        )
}

climate_vectors <- filter(envfit_vectors, Variable != "Year")

# --- Step 4a: Climate arrows only (names) ---
p4a <- vector_plot(climate_vectors, "label_name_only", 6.2)
ggsave("images/nmds_step4a_climate_names.png", p4a, width = 11, height = 7, bg = "transparent", dpi = 300)

# --- Step 4b: Climate + time arrows (names) ---
p4 <- vector_plot(envfit_vectors, "label_name_only", 6.2)
ggsave("images/nmds_step4_vectors_names.png", p4, width = 11, height = 7, bg = "transparent", dpi = 300)

# --- Step 5: All arrows with NAMES + NUMBERS (r², p) ---
p5 <- vector_plot(envfit_vectors, "label_full", 6.0)
ggsave("images/nmds_step5_vectors_stats.png", p5, width = 11, height = 7, bg = "transparent", dpi = 300)
# Also overwrite original for backward compatibility
ggsave("images/nmds_climate_envfit.png", p5, width = 11, height = 7, bg = "transparent", dpi = 300)

cat("Successfully generated all 6 NMDS steps.\n")
