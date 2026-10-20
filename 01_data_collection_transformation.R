library(tidyverse)
library(readr)
library(sf)
library(styler)

# Direction de travail

wd <- getwd()
setwd(wd)


#-------------Données entreprises de nantes 44109
data <- read_csv2("244400404_base-sirene-entreprises-nantes-metropole.csv")


entreprise_data <- data |>
  filter(
    `Code commune de l'établissement` == 44109,
    `Etat administratif de l'établissement` == "Actif"
  ) |>
  separate(
    col = `Géolocalisation de l'établissement`,
    into = c("lat", "lon"),
    sep = ",",
    convert = TRUE
  ) |>
  mutate(code_naf = `Activité principale de l'établissement...47`) |>
  select(
    SIREN,
    SIRET,
    `Dénomination usuelle de l'établissement`,
    `Date du début de la période de l'établissement`,
    `Tranche de l'effectif de l'unité légale`,
    code_naf,
    lon,
    lat
  )

# Transformation en données géographiques:
entreprise_data_sf <- entreprise_data |>
  filter(!is.na(lat) & !is.na(lon)) |>
  st_as_sf(coords = c("lon", "lat"), crs = 4326) |>
  st_transform(2154)

st_write(entreprise_data_sf,
  "entreprises_nantes.geojson",
  delete_layer = TRUE
)

#----------------------Données économique et démographiques

#--Population:
pop <- read_csv2("base-ic-evol-struct-pop-2022.CSV")

pop_iris <- pop |>
  filter(COM == "44109") |>
  select(IRIS, P22_POP) |>
  rename(population = P22_POP, CODE_IRIS = IRIS)

#--Proxy du niveau de vie:
ve <- read_csv2("BASE_TD_FILO_IRIS_2021_DISP.csv")

niv_vie <- ve |>
  mutate(COM = str_sub(IRIS, start = 1, end = 5)) |>
  filter(COM == "44109") |>
  select(IRIS, DISP_TP6021, DISP_MED21) |>
  rename(
    CODE_IRIS = IRIS,
    taux_pauv = DISP_TP6021,
    med_uc = DISP_MED21
  ) |>
  mutate(
    med_uc = na_if(med_uc, "ns"),
    taux_pauv = na_if(taux_pauv, "ns")
  )


#----------------------IRIS des quartiers

# Extraction des quartiers de Nantes
# iris_nantes<-st_read("CONTOURS-IRIS.shp") |>
# filter(INSEE_COM==44109)

# Sauvegarde de notre fichier filtré
# st_write(iris_nantes, "iris_nantes.geojson", delete_layer = TRUE)

iris_nantes <- st_read("iris_nantes.geojson")
entreprise_data_sf <- st_read("entreprise_nantes.geojson")


#-----------------------Jointure information complémentaire par iris (niveau de vie et population base INSEE 2022)

iris_nantesv2 <- iris_nantes |>
  left_join(pop_iris, by = "CODE_IRIS") |>
  left_join(niv_vie, by = "CODE_IRIS")

# Sauvegarde de notre fichier final 

st_write(iris_nantesv2, "iris_nantesv2.geojson", delete_layer = TRUE)
