library(igraph)

airports <- read.csv('https://raw.githubusercontent.com/jpatokal/openflights/master/data/airports.dat', header=FALSE, stringsAsFactors=FALSE)
colnames(airports) <- c('AirportID', 'Name', 'City', 'Country', 'IATA', 'ICAO', 'Lat', 'Lon', 'Altitude', 'Timezone', 'DST', 'TzDatabase', 'Type', 'Source')

routes <- read.csv('https://raw.githubusercontent.com/jpatokal/openflights/master/data/routes.dat', header=FALSE, stringsAsFactors=FALSE)
colnames(routes) <- c('Airline', 'AirlineID', 'SourceAirport', 'SourceAirportID', 'DestAirport', 'DestAirportID', 'Codeshare', 'Stops', 'Equipment')

# Filter to European bounding box and non-empty IATA
europe_airports <- subset(airports, Lat > 35 & Lat < 70 & Lon > -15 & Lon < 35 & IATA != "\\N" & nchar(IATA) == 3)
cat("European airports:", nrow(europe_airports), "\n")

# Valid routes between these airports
eu_routes <- subset(routes, SourceAirport %in% europe_airports$IATA & DestAirport %in% europe_airports$IATA)
cat("European routes:", nrow(eu_routes), "\n")

# Keep only connected airports
g <- graph_from_data_frame(d = eu_routes[, c("SourceAirport", "DestAirport")], directed = FALSE)
g <- simplify(g)

deg <- degree(g)
kcore <- coreness(g)
betw <- betweenness(g)
eigen <- eigen_centrality(g)$vector

top_airports <- data.frame(
  IATA = names(deg),
  Name = europe_airports$Name[match(names(deg), europe_airports$IATA)],
  City = europe_airports$City[match(names(deg), europe_airports$IATA)],
  Country = europe_airports$Country[match(names(deg), europe_airports$IATA)],
  Degree = deg,
  Coreness = kcore,
  Betweenness = round(betw, 1),
  Eigen = round(eigen, 3)
)
top_airports <- top_airports[order(-top_airports$Degree), ]
cat("\n--- TOP AIRPORT HUBS (CORE) ---\n")
print(head(top_airports, 10))

cat("\n--- REGIONAL AIRSTRIPS (PERIPHERY) ---\n")
print(tail(top_airports, 10))
