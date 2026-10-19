library(igraph)
library(ggplot2)
library(maps)
library(dplyr)
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
key_regional <- c("RRS", "KID")
labeled_airports <- subset(air_nodes, IATA %in% c(key_hubs, key_regional))
labeled_airports$Label <- ifelse(labeled_airports$IATA %in% key_hubs,
                                 paste0(labeled_airports$City, " (", labeled_airports$IATA, ")\nk=", labeled_airports$Degree, ", Coreness=", labeled_airports$Coreness),
                                 paste0(labeled_airports$City, " (", labeled_airports$IATA, ")\nk=", labeled_airports$Degree, ", Coreness=", labeled_airports$Coreness))

base_theme <- theme_void() +
  theme(
    plot.margin = margin(10, 10, 10, 10),
    panel.background = element_rect(fill = "#FAFAFA", color = "#E2E8F0", linewidth = 1)
  )

# --- Stage 1: Map only ---
p1 <- ggplot() +
  geom_polygon(data = europe_poly, aes(x = long, y = lat, group = group), fill = "#F1F5F9", color = "#CBD5E1", linewidth = 0.3) +
  coord_fixed(xlim = c(-9, 25), ylim = c(36, 68), ratio = 1.3) +
  base_theme

ggsave("images/airport_step1_map.png", p1, width = 7.5, height = 6.4, dpi = 300)
cat("Saved airport_step1_map.png\n")

# --- Stage 2: Airports as uniform points ---
p2 <- ggplot() +
  geom_polygon(data = europe_poly, aes(x = long, y = lat, group = group), fill = "#F1F5F9", color = "#CBD5E1", linewidth = 0.3) +
  geom_point(data = air_nodes, aes(x = Lon, y = Lat), color = "#475569", alpha = 0.75, size = 2.0) +
  coord_fixed(xlim = c(-9, 25), ylim = c(36, 68), ratio = 1.3) +
  base_theme

ggsave("images/airport_step2_airports.png", p2, width = 7.5, height = 6.4, dpi = 300)
cat("Saved airport_step2_airports.png\n")

# --- Stage 3: Flight connections (routes) appear ---
p3 <- ggplot() +
  geom_polygon(data = europe_poly, aes(x = long, y = lat, group = group), fill = "#F1F5F9", color = "#CBD5E1", linewidth = 0.3) +
  geom_segment(data = edges_air, aes(x = lon1, y = lat1, xend = lon2, yend = lat2),
               color = "#60A5FA", alpha = 0.08, linewidth = 0.3) +
  geom_point(data = air_nodes, aes(x = Lon, y = Lat), color = "#334155", alpha = 0.75, size = 2.0) +
  coord_fixed(xlim = c(-9, 25), ylim = c(36, 68), ratio = 1.3) +
  base_theme

ggsave("images/airport_step3_routes.png", p3, width = 7.5, height = 6.4, dpi = 300)
cat("Saved airport_step3_routes.png\n")

# --- Stage 4: Coreness sizing & coloring (Hubs pop out) ---
p4 <- ggplot() +
  geom_polygon(data = europe_poly, aes(x = long, y = lat, group = group), fill = "#F1F5F9", color = "#CBD5E1", linewidth = 0.3) +
  geom_segment(data = edges_air, aes(x = lon1, y = lat1, xend = lon2, yend = lat2),
               color = "#60A5FA", alpha = 0.08, linewidth = 0.3) +
  geom_point(data = subset(air_nodes, Role == "Peripheral Spoke"),
             aes(x = Lon, y = Lat), color = "#F87171", alpha = 0.5, size = 1.8) +
  geom_point(data = subset(air_nodes, Role == "Core Hub"),
             aes(x = Lon, y = Lat), color = "#1E3A8A", size = 4.4, alpha = 0.95) +
  geom_point(data = subset(air_nodes, IATA %in% key_hubs),
             aes(x = Lon, y = Lat), color = "#FBBF24", size = 2.5) +
  geom_label_repel(data = subset(labeled_airports, IATA %in% key_hubs),
                   aes(x = Lon, y = Lat, label = Label),
                   fontface = "bold", size = 3.0, color = "#0F172A", fill = alpha("white", 0.9),
                   box.padding = 0.45, point.padding = 0.35, segment.color = "#1E3A8A", segment.size = 0.4) +
  geom_label_repel(data = subset(labeled_airports, IATA %in% key_regional),
                   aes(x = Lon, y = Lat, label = Label),
                   fontface = "bold", size = 2.8, color = "#B91C1C", fill = alpha("#FEF2F2", 0.95),
                   box.padding = 0.45, point.padding = 0.35, segment.color = "#DC2626", segment.size = 0.4) +
  coord_fixed(xlim = c(-9, 25), ylim = c(36, 68), ratio = 1.3) +
  base_theme

ggsave("images/airport_step4_coreness.png", p4, width = 7.5, height = 6.4, dpi = 300)
cat("Saved airport_step4_coreness.png\n")

cat("All steps generated successfully!\n")
