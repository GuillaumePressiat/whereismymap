library(readr)
library(dplyr)
library(ggplot2)
library(ggthemes)
library(sf)
library(rmapshaper)
library(smoothr)
#library(spatialEco)

corr_postal_insee <- readr::read_csv2('raw_data/laposte_hexamal/laposte_hexamal.csv', locale = readr::locale(encoding = "latin1")) %>%
  janitor::clean_names()

# make shapefile POSTAL CODE
map <- sf::read_sf(dsn="raw_data/ign_admin_express/",layer="COMMUNE")
map <- sf::st_transform(map, 4326)

# plot(map)

# Bretagne example
map <- map %>% filter(INSEE_REG == '53')

# observation : multi postal communes
corr_postal_insee %>%
  group_by(number_code_commune_insee) %>%
  mutate(nb = n_distinct(code_postal)) %>%
  arrange(desc(nb))

corr_postal_insee_reshaped <- corr_postal_insee %>%
  group_by(number_code_commune_insee) %>%
  summarise(code_postal = paste0(unique(code_postal), collapse = "/"),
            libelle_d_acheminement = paste0(unique(libelle_d_acheminement), collapse = ", "),
            nb_postal = n_distinct(code_postal),
            nb_ligne_5 = n_distinct(ligne_5))

map <- left_join(map, corr_postal_insee_reshaped,
                 by=c('INSEE_COM' = 'number_code_commune_insee') )

map2 <- map %>%
  group_by(code_postal) %>%
  summarise(geometry = sf::st_union(geometry, by_feature = FALSE),
            pop_postal = sum(POPULATION),
            insee_pop = sum(POPULATION),
            libelle_d_acheminement = libelle_d_acheminement[POPULATION == max(POPULATION)]) %>%
  mutate(geometry_type = sf::st_geometry_type(geometry),
         geometry_length = purrr::map_int(geometry, length))



map22_s <-ms_simplify(map2, keep = 0.18)
map22_s <- smoothr::smooth(map22_s, method = "chaikin")

map22_s %>%
  filter(grepl('^29', code_postal)) %>%
  ggplot(data = .) +
  geom_sf(aes(fill = insee_pop)) +
  scico::scale_fill_scico(palette = "lajolla", direction = -1) +
  theme_hc()


# check if all INSEE have its postal code ?
map2 %>% filter(is.na(code_postal))

# corr$number_code_commune_insee
#map_postals <- spatialEco::sf_dissolve(map, 'code_postal')
map_postals <- map2

# populations <- map %>%
#   sf::st_drop_geometry() %>%
#   group_by(code_postal) %>%
#   summarise(insee_pop = sum(POPULATION),
#             libelle_d_acheminement = NOM[POPULATION == max(POPULATION)])
#
# sum(populations$insee_pop)
#
# map_postals <- map_postals %>%
#   left_join(populations, by = join_by(code_postal))

map_postals_centroid <- sf::st_centroid(map_postals)

sf::st_write(map_postals, 'outputs/map_postal/CODE_POSTAL.shp', append = FALSE)

library(geojsonio)
geojson_write(map_postals, file = "outputs/map_postal/postal_bretagne.geojson")


geojson_write(map22_s %>%
                filter(substr(code_postal,1,2) == '29') %>%
                mutate(name = paste0(code_postal, " - ", libelle_d_acheminement)),
              file = "outputs/map_postal/postal_finistere_light.geojson")


map22 <- fortify(map_postals, region="code_postal")
map11 <- fortify(map, region = "INSEE_COM")

# dep <- unionSpatialPolygons(map, map@data$INSEE_DEP)
# dep11 <- fortify(dep, region = "INSEE_DEP")

# dep11_centroid <- rgeos::gCentroid(dep, byid = TRUE) %>%
  # as_tibble(rownames = 'insee_dep')

map11 <- map11 %>% filter(INSEE_DEP == '29')
map22 <- map22 %>% filter(substr(code_postal,1,2) == '29')

map22_centroid <- sf::st_centroid(map22)
map11_centroid <- sf::st_centroid(map11)

library(rmapshaper)
library(smoothr)

map22_s <-ms_simplify(map22, keep = 0.18)
map22_s <- smoothr::smooth(map22_s, method = "chaikin")

map11_s <-ms_simplify(map11, keep = 0.18)
map11_s <- smoothr::smooth(map11_s, method = "chaikin")

ggplot() +
  geom_sf(data = map11_s,
               color = 'grey70', fill = 'whitesmoke', lwd = 0.1) +
  geom_sf(data = map22_s,
            color = alpha('sienna3', 0.3), fill = NA, lwd = 0.5) +
  geom_sf_text(data = map11_centroid,
               aes(label = stringr::str_replace_all(stringi::stri_trans_totitle(NOM), '-', '\n')),
               size = 0.8, color = 'grey40') +
  geom_sf_text(data = map22_centroid,
               aes(label = stringr::str_replace_all(stringi::stri_trans_totitle(libelle_d_acheminement), '-', '\n')),
               size = 1.7, color = 'sienna3', fontface = 'bold', alpha = 0.8) +
  ggthemes::theme_map() +
  ggtitle(label = 'Regroupements de communes INSEE par codes postaux') +
  theme(title = element_text(colour = 'sienna3', size = 20, face = 'bold'))

ggsave('outputs/rgp_insee-postal_bretagne.pdf', width = 12, height = 12)

map_s <-ms_simplify(map_postals)



map_dep <- sf::st_read('raw_data/ign_admin_express/DEPARTEMENT.shp')

map_com <- sf::st_read('outputs/map_postal/postal_bretagne.geojson')

map_s <-ms_simplify(map_com, keep = 0.1)
map_com_s <- smoothr::smooth(map_s, method = "chaikin")

map_dep_s <- ms_simplify(map_dep, keep = 0.04, keep_shapes = FALSE) %>%
  filter(INSEE_REG == '53')
map_dep_s <- smoothr::smooth(map_dep_s, method = "chaikin")

map_postals_centroid <- sf::st_centroid(map_com_s)

# plot(map_com_s)

map22 <- fortify(map_com_s, region="code_postal")
# breaks <- classInt::classIntervals(map22$insee_pop, n = 4, style = "jenks")

map22$break_colors <- classInt::classify_intervals(map22$insee_pop, n = 5, style = "jenks")

ggplot() +
  geom_sf(data = map22, aes(fill = break_colors)) +
  geom_sf_text(data = map_postals_centroid, aes(
                                       label = stringr::str_replace_all(
                                         stringi::stri_trans_totitle(libelle_d_acheminement), '-', '\n')), lineheight = 0.7,
            size = 1.2, color = 'grey75') +
  # geom_sf(data = map_dep_s, color = alpha('grey35', 0.7), fill = NA, lwd = 1) +
  # viridis::scale_fill_viridis(name = "Classe de population (jenks)",discrete = TRUE, end = 0.8, direction = -1) +
  ggthemes::scale_fill_pander(name = "Population INSEE\nsource :\nADMIN-EXPRESS 2024") +
  ggthemes::theme_map() +
  theme(panel.background = element_rect(fill = "grey30"),
        legend.background = element_rect(fill = "grey65"))


ggsave('outputs/bretagne.pdf', width = 19, height = 11)



library(echarts4r)

json <- jsonlite::read_json("https://raw.githubusercontent.com/shawnbot/topogram/master/data/us-states.geojson")

json <- jsonlite::read_json('outputs/map_postal/postal_finistere_light.geojson')

# rownames(map_postals) <- map_postals$code_postal

map_postals |>
  # filter(substr(code_postal,1,2) == '29') |>
  st_drop_geometry() %>%
  filter(substr(code_postal,1,2) == '29') %>%
  mutate(name = paste0(code_postal, " - ", libelle_d_acheminement)) %>%
  select(name, insee_pop2 = insee_pop) |>
  # tibble::rownames_to_column("states") |>
  e_charts(name) |>
  e_map_register("cp", json) |>
  e_map(insee_pop2, map = "cp") |>
  e_visual_map(insee_pop2) %>%
  e_datazoom()

json_u <- jsonlite::read_json("https://raw.githubusercontent.com/shawnbot/topogram/master/data/us-states.geojson")

USArrests |>
  tibble::rownames_to_column("states") |>
  e_charts(states) |>
  e_map_register("USA", json_u) |>
  e_map(Murder, map = "USA") |>
  e_visual_map(Murder)


