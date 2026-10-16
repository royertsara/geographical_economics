library(tidyverse)
library(readr)
library(sf)



wd<-getwd()
setwd(wd)

data<-read_csv2("244400404_base-sirene-entreprises-nantes-metropole.csv") 
  
  
fastfood_data<-data |> 
  filter(
    `Code commune de l'établissement`==44109,
    `Activité principale de l'établissement...47`=="56.10C",
    `Etat administratif de l'établissement`=="Actif"
  ) |> 
  separate(col=`Géolocalisation de l'établissement`,
           into=c("lat","lon"),
           sep=",",
           convert=TRUE
           
           ) |> 
  select(SIREN,
         SIRET,
         `Dénomination usuelle de l'établissement`,
         `Date du début de la période de l'établissement`,
         `Tranche de l'effectif de l'unité légale`,
         lon,
         lat)

# Transformation en données géographiques:
 fastfood_data_sf<-fastfood_data |> 
   filter(!is.na(lat) & !is.na(lon)) |> 
   st_as_sf(coords=c("lon","lat"),crs=4326) |> 
   st_transform(2154)

st_write(fastfood_data_sf,"fastfood_nantes.geojson",delete_layer = TRUE)

# IRIS des quartiers

# Extraction des quartiers de Nantes 
#iris_nantes<-st_read("CONTOURS-IRIS.shp") |> 
# filter(INSEE_COM==44109)

# Sauvegarde de notre fichier filtrer
#st_write(iris_nantes, "iris_nantes.geojson", delete_layer = TRUE)

iris_nantes<-st_read("iris_nantes.geojson")
fastfood_data_sf<-st_read("fastfood_nantes.geojson")
