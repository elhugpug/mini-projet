# téléchargement du package "getSpatialData"
devtools::install_github("16EAGLE/getSpatialData")

# chargment des bibliothèques
library(devtools)
library(getSpatialData)
library(raster)
library(sf)
library(sp)
library(rgdal)

#pour selectionner les images en passant par l'AOI
set_aoi()


# on renseigne la zone d'intêret
zone_liban <- readOGR('/Users/hugotreuildussouet/Desktop/zone_liban/vecteur_decoup/zone_liban.shp')
set_aoi(zone_liban) # nous montre la zone dans une fenêtre
view_aoi()

# On choisis les dates et la plateforme d'intérêt
time_range <-  c("2019-12-01", "2019-12-04")
platform <- "Sentinel-1"

# On rentre ces identifiants Copernicus
login_CopHub(username = "user", password = "password") 

# chemin d'enregistrement des images
set_archive("/Users/hugotreuildussouet/Desktop/test1")

records <- getSentinel_query(time_range = time_range, platform = platform)

# montre ce que Copernicus a trouvé comme images
View(records) 

#permet de voir les filtres possible
colnames(records) 
unique(records$title)

#télécharge les images
datasets <- getSentinel_data(records = records)



