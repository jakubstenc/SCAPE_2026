library(igraph)
library(ggplot2)
library(maps)
library(dplyr)
library(gridExtra)
library(ggrepel)

cat("Step 1: Downloading & processing European airport network...\n")
airports <- read.csv('https://raw.githubusercontent.com/jpatokal/openflights/master/data/airports.dat', header=FALSE, stringsAsFactors=FALSE)
colnames(airports) <- c('AirportID', 'Name', 'City', 'Country', 'IATA', 'ICAO', 'Lat', 'Lon', 'Altitude', 'Timezone', 'DST', 'TzDatabase', 'Type', 'Source')

routes <- read.csv('https://raw.githubusercontent.com/jpatokal/openflights/master/data/routes.dat', header=FALSE, stringsAsFactors=FALSE)
colnames(routes) <- c('Airline', 'AirlineID', 'SourceAirport', 'SourceAirportID', 'DestAirport', 'DestAirportID', 'Codeshare', 'Stops', 'Equipment')

europe_airports <- subset(airports, Lat >= 36 & Lat <= 68 & Lon >= -10 & Lon <= 28 & IATA != "\\N" & nchar(IATA) == 3)
eu_routes <- subset(routes, SourceAirport %in% europe_airports$IATA & DestAirport %in% europe_airports$IATA)

g_air <- graph_from_data_frame(d = eu_routes[, c("SourceAirport", "DestAirport")], directed = FALSE)
g_air <- simplify(g_air)

deg_air <- degree(g_air)
kcore_air <- coreness(g_air)

air_nodes <- data.frame(
  IATA = names(deg_air),
  Degree = deg_air,
  Coreness = kcore_air,
  stringsAsFactors = FALSE
)
air_nodes <- merge(air_nodes, europe_airports[, c("IATA", "Name", "City", "Country", "Lat", "Lon")], by = "IATA")
air_nodes$Role <- ifelse(air_nodes$Coreness >= 25, "Core Hub", "Peripheral Spoke")

edges_air <- igraph::as_data_frame(g_air, what = "edges")
edges_air <- merge(edges_air, air_nodes[, c("IATA", "Lat", "Lon")], by.x = "from", by.y = "IATA")
colnames(edges_air)[3:4] <- c("lat1", "lon1")
edges_air <- merge(edges_air, air_nodes[, c("IATA", "Lat", "Lon")], by.x = "to", by.y = "IATA")
colnames(edges_air)[5:6] <- c("lat2", "lon2")

world_map <- map_data("world")
europe_poly <- subset(world_map, lat >= 35 & lat <= 70 & long >= -12 & long <= 30)

key_hubs <- c("AMS", "FRA", "CDG", "STN", "MUC")
key_regional <- c("RRS", "KID", "NVK")
labeled_airports <- subset(air_nodes, IATA %in% c(key_hubs, key_regional))
labeled_airports$Label <- ifelse(labeled_airports$IATA %in% key_hubs,
                                 paste0(labeled_airports$City, " (", labeled_airports$IATA, ")\nk=", labeled_airports$Degree, ", Coreness=", labeled_airports$Coreness),
                                 paste0(labeled_airports$City, " (", labeled_airports$IATA, ")\nk=", labeled_airports$Degree, ", Coreness=", labeled_airports$Coreness))

p_airport <- ggplot() +
  geom_polygon(data = europe_poly, aes(x = long, y = lat, group = group), fill = "#F1F5F9", color = "#CBD5E1", linewidth = 0.3) +
  geom_segment(data = edges_air, aes(x = lon1, y = lat1, xend = lon2, yend = lat2),
               color = "#60A5FA", alpha = 0.08, linewidth = 0.3) +
  geom_point(data = subset(air_nodes, Role == "Peripheral Spoke"),
             aes(x = Lon, y = Lat), color = "#F87171", alpha = 0.5, size = 1.6) +
  geom_point(data = subset(air_nodes, Role == "Core Hub"),
             aes(x = Lon, y = Lat), color = "#1E3A8A", size = 4.2, alpha = 0.95) +
  geom_point(data = subset(air_nodes, IATA %in% key_hubs),
             aes(x = Lon, y = Lat), color = "#FBBF24", size = 2.4) +
  geom_label_repel(data = subset(labeled_airports, IATA %in% key_hubs),
                   aes(x = Lon, y = Lat, label = Label),
                   fontface = "bold", size = 3.0, color = "#0F172A", fill = alpha("white", 0.9),
                   box.padding = 0.45, point.padding = 0.35, segment.color = "#1E3A8A", segment.size = 0.4) +
  geom_label_repel(data = subset(labeled_airports, IATA %in% key_regional),
                   aes(x = Lon, y = Lat, label = Label),
                   fontface = "bold", size = 2.8, color = "#B91C1C", fill = alpha("#FEF2F2", 0.95),
                   box.padding = 0.45, point.padding = 0.35, segment.color = "#DC2626", segment.size = 0.4) +
  coord_fixed(xlim = c(-9, 25), ylim = c(36, 68), ratio = 1.3) +
  theme_void() +
  labs(
    title = "A  European Aviation Network (Empirical Routes)",
    subtitle = "895 Airports | 15,194 Routes | Core = Top 5% of Hubs (Coreness = 29)"
  ) +
  theme(
    plot.title = element_text(face = "bold", size = 13.5, color = "#0F172A", hjust = 0),
    plot.subtitle = element_text(size = 10, color = "#475569", hjust = 0, margin = margin(b = 6)),
    plot.margin = margin(10, 10, 10, 10),
    panel.background = element_rect(fill = "#FAFAFA", color = "#E2E8F0", linewidth = 1)
  )

cat("Step 2: Processing Handrkov pollinator sharing network...\n")
load('/home/meow/ownCloud - Mgr Jakub Štenc Phd@owncloud.cesnet.cz/Psani_clanku/2025/Annual_dynamics_pollinator_sharing/local_packages/HanPolNet/data/interaction_data.rda')
core_def <- read.csv('/home/meow/ownCloud - Mgr Jakub Štenc Phd@owncloud.cesnet.cz/Psani_clanku/2025/Annual_dynamics_pollinator_sharing/outputs/Data_Prep/core_definition.csv')

valid_interactions <- subset(interaction_data, network_species != "not_network_species" & !is.na(plant_name) & plant_name != "")

bip_tab <- table(valid_interactions$plant_name, valid_interactions$network_species)
bip_mat <- as.matrix(bip_tab > 0) + 0

# Plant-plant shared pollinator count
plant_adj <- bip_mat %*% t(bip_mat)
diag(plant_adj) <- 0

common_plants <- intersect(rownames(plant_adj), core_def$Plant_Species)
plant_adj <- plant_adj[common_plants, common_plants]

plant_nodes <- data.frame(
  Species = common_plants,
  stringsAsFactors = FALSE
)
plant_nodes <- merge(plant_nodes, core_def[, c("Plant_Species", "Mean_k", "Obs_Mean_Gc", "Core_Status")], by.x = "Species", by.y = "Plant_Species")
plant_nodes$Role <- ifelse(plant_nodes$Core_Status == "Core", "Core Plant", "Peripheral Plant")
plant_nodes$Mean_k_round <- round(plant_nodes$Mean_k, 1)
plant_nodes$Gc_round <- round(plant_nodes$Obs_Mean_Gc, 2)

# Concentric layout
core_sp <- subset(plant_nodes, Role == "Core Plant")$Species
periph_sp <- subset(plant_nodes, Role == "Peripheral Plant")$Species

n_core <- length(core_sp)
n_periph <- length(periph_sp)

set.seed(42)
# Arrange core species in inner circle
theta_core <- seq(0, 2 * pi, length.out = n_core + 1)[1:n_core]
r_core <- 1.45

# Arrange peripheral species in outer ring with slight organic dispersion
theta_periph <- seq(0, 2 * pi, length.out = n_periph + 1)[1:n_periph]
r_periph <- 3.85 + rnorm(n_periph, 0, 0.2)

coords <- matrix(0, nrow = nrow(plant_nodes), ncol = 2)
rownames(coords) <- plant_nodes$Species

coords[core_sp, 1] <- r_core * cos(theta_core)
coords[core_sp, 2] <- r_core * sin(theta_core)

coords[periph_sp, 1] <- r_periph * cos(theta_periph)
coords[periph_sp, 2] <- r_periph * sin(theta_periph)

plant_nodes$x <- coords[plant_nodes$Species, 1]
plant_nodes$y <- coords[plant_nodes$Species, 2]

# Edge filtering: keep significant sharing connections
g_plant <- graph_from_adjacency_matrix(plant_adj, mode = "undirected", weighted = TRUE)
edges_plant <- igraph::as_data_frame(g_plant, what = "edges")
edges_plant <- merge(edges_plant, plant_nodes[, c("Species", "x", "y", "Role")], by.x = "from", by.y = "Species")
colnames(edges_plant)[4:6] <- c("x1", "y1", "role1")
edges_plant <- merge(edges_plant, plant_nodes[, c("Species", "x", "y", "Role")], by.x = "to", by.y = "Species")
colnames(edges_plant)[7:9] <- c("x2", "y2", "role2")

edges_plant$EdgeType <- ifelse(edges_plant$role1 == "Core Plant" & edges_plant$role2 == "Core Plant", "Core-Core",
                        ifelse(edges_plant$role1 == "Core Plant" | edges_plant$role2 == "Core Plant", "Core-Spoke", "Spoke-Spoke"))

# Filter weak spoke-spoke edges to highlight hub routing
edges_plot <- subset(edges_plant, EdgeType == "Core-Core" | (EdgeType == "Core-Spoke" & weight >= 3) | (EdgeType == "Spoke-Spoke" & weight >= 8))

plant_nodes$Label <- ifelse(plant_nodes$Role == "Core Plant",
                           paste0(plant_nodes$Species, "\nk=", plant_nodes$Mean_k_round, ", Gc=", plant_nodes$Gc_round),
                           "")

ex_periph <- c("Lathyrus pratensis", "Ranunculus flammula", "Cirsium palustre")
plant_nodes$Label[plant_nodes$Species %in% ex_periph] <- paste0(plant_nodes$Species[plant_nodes$Species %in% ex_periph], "\nk=", plant_nodes$Mean_k_round[plant_nodes$Species %in% ex_periph], ", Gc=", plant_nodes$Gc_round[plant_nodes$Species %in% ex_periph])

p_plant <- ggplot() +
  # Spoke edges
  geom_segment(data = subset(edges_plot, EdgeType != "Core-Core"),
               aes(x = x1, y = y1, xend = x2, yend = y2),
               color = "#93C5FD", alpha = 0.22, linewidth = 0.35) +
  # Core-Core backbone edges
  geom_segment(data = subset(edges_plot, EdgeType == "Core-Core"),
               aes(x = x1, y = y1, xend = x2, yend = y2),
               color = "#1D4ED8", alpha = 0.85, linewidth = 1.2) +
  # Peripheral plants
  geom_point(data = subset(plant_nodes, Role == "Peripheral Plant"),
             aes(x = x, y = y), color = "#F87171", alpha = 0.65, size = 2.4) +
  # Core plants
  geom_point(data = subset(plant_nodes, Role == "Core Plant"),
             aes(x = x, y = y), color = "#1E3A8A", size = 5.6, alpha = 0.95) +
  geom_point(data = subset(plant_nodes, Role == "Core Plant"),
             aes(x = x, y = y), color = "#FBBF24", size = 3.0) +
  # Labels
  geom_label_repel(data = subset(plant_nodes, Role == "Core Plant"),
                   aes(x = x, y = y, label = Label),
                   fontface = "bold.italic", size = 2.9, color = "#0F172A", fill = alpha("white", 0.9),
                   box.padding = 0.5, point.padding = 0.4, segment.color = "#1E3A8A", segment.size = 0.4) +
  geom_label_repel(data = subset(plant_nodes, Species %in% ex_periph),
                   aes(x = x, y = y, label = Label),
                   fontface = "italic", size = 2.7, color = "#B91C1C", fill = alpha("#FEF2F2", 0.95),
                   box.padding = 0.45, point.padding = 0.35, segment.color = "#DC2626", segment.size = 0.4) +
  coord_fixed(xlim = c(-5.5, 5.5), ylim = c(-5.5, 5.5)) +
  theme_void() +
  labs(
    title = "B  Meadow Pollinator-Sharing Web (Handrkov 15-Yr Data)",
    subtitle = "57 Plant Species | Hub & Spoke Architecture | Core = 6 Perennial Plant Anchors"
  ) +
  theme(
    plot.title = element_text(face = "bold", size = 13.5, color = "#0F172A", hjust = 0),
    plot.subtitle = element_text(size = 10, color = "#475569", hjust = 0, margin = margin(b = 6)),
    plot.margin = margin(10, 10, 10, 10),
    panel.background = element_rect(fill = "#FAFAFA", color = "#E2E8F0", linewidth = 1)
  )

cat("Step 3: Combining into side-by-side figure...\n")
p_combined <- grid.arrange(p_airport, p_plant, ncol = 2)

ggsave("images/airport_vs_pollinator_empirical.png", p_combined, width = 14, height = 6.4, dpi = 300)
cat("Saved to images/airport_vs_pollinator_empirical.png successfully!\n")
