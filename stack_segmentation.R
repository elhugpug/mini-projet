# Code qui intervient après la segmentation (avec i.segment) et la vectorisation effectuées sur Qgis. 
# Il vise à créer un stack de NDVI segmentés. 


# Chargement des bibliothèques necesaire
library(raster)
library(velox)
library(rgdal)
library(parallel)
library(dplyr)

# Chargment de la segmentation rasterisée effectué sur Qgis
setwd('/Users/hugotreuildussouet/Desktop/mini_projet/données_liban/OS_Liban/')
segm <- raster('segmentation_all_NDVI.tif')


# Chargement de la segmentation vectorisée effectué sur Qgis 
vec <- readOGR(dsn = '/Users/hugotreuildussouet/Desktop/mini_projet/données_liban/OS_Liban/', "segm_all_NDVI_vec")

# vec doit être nettoyé et préparé (on enleve les colonnes inutiles, on convertit en tableau, on classe...)
vec2 <- vec
vec2 <- vec2[,-(2)] 
vec.df <- as(vec2, "data.frame")
vec.df <- vec.df[order(vec.df$fid),] 

# Chargment des images et création d'un stack
les_dates <- list.files("/Volumes/Treuil Data/Bekaa", full.names = TRUE)
stack_NDVI <- stack() 

# code pour créer un stack de meanshift segmentation avec les valeur de NDVI (entre la 11ème date et la 31ème)
for (dates in les_dates[11:31]){
  setwd(dates)
  b <- list.files(".", pattern='B0[4;8]')
  b4 <- raster(b[1])
  b8 <- raster(b[2])
  NDVI <- (b8-b4)/(b8+b4)
  
  # extraction des valeurs du NDVI moyen par segments en utilisant la segmentation vectorisée  
  NDVI2 <- velox(NDVI)
  test1 <- mclapply(seq_along(1), function(x){
    NDVI2$extract(vec2, fun=function(t) mean(t,na.rm=T))
    })
  
  # resultat convertit en tableau
  tab <- as.data.frame(do.call(rbind, test1))
  tab[,length(tab)+1] <- 1:nrow(tab) 
  
  # transforme en vecteur le raster de segmentation
  segmvec <- as.vector(segm)
  segmvec2 <- segmvec
  
  # on règle un problème de numérotation des segments  
  jointure <- left_join(tab, vec.df, 
                        by = c("V2" = "fid"))
  # on ordonne de nouveau 
  jointure2 <- jointure[order(jointure$DN2),]
  
  # on remplace les valeurs des numéros des segments par celles du NDVI moyen du segment. 
  for (poly in 1:nrow(tab)){
    segmvec2[segmvec %in% poly] <- jointure2[poly,1]
  }
  
  # on transforme le vecteur en une image raster. 
  resultat_matrice <- matrix(segmvec2, nrow=nrow(NDVI), ncol=ncol(NDVI))
  mean_segm <- raster(t(resultat_matrice), template=NDVI)
  
  # on place l'image du NDVI segmenté dans le stack
  stack_NDVI <- stack(stack_NDVI, mean_segm)
}

