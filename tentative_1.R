# Ce code tente de classifier les zones agricoles en utilisant l'écart de la valeur 
# des segments par rapport à celles des zones agricoles. Pour que cela fonctionne, il faut 
# dans un premier temps accorder les séries temporelles des espaces agricole de la même manière
# (hausse, pic et baisse du NDVI en même temps)
# Théoriquement plus l'ecart général est faible, plus le segment a une courbe qui se 
# rapproche de celles des zones agricoles et peut être classé comme tel. 


# On charge les bibliothèques nécessaire. 
# 'sf' et 'exactextractr' permettent de réaliser le même travail que la 
# fonction 'zonal statistic' sur Qgis à savoir extraire les valeurs 
# d'une couche vecteur en gardant la spatialité de celui-ci.
# 'fasterize' permet de rasteriser un vecteur rapidement

library(raster)
library(rgdal)
library(sf)
library(exactextractr)
library(fasterize)

# On charge les stack de NDVI de l'année et le vecteur des segmentations
setwd('/Users/hugotreuildussouet/Desktop/')
stack_NDVI<- stack('multilayer_norm.tif')
stack_NDVI<- stack('multilayer_all.tif')
vec <- readOGR(dsn = '/Users/hugotreuildussouet/Desktop/mini_projet/données_liban/OS_Liban/', "segm_all_NDVI_vec3")


# création des fonctions
# 1) fonction de roulement qui permet de décaler les valeurs tel une boucle (code trouvé sur internet)
# ex : 'abcde' décalé de 2 vers la droite donne 'deabc'.
shifter <- function(x, n = 1) {
  if (n == 0) x else c(tail(x, -n), head(x, n))
}

# 2) Dans cette fonction de recentrage, on utilise la fonction shifter pour décaler 
# la série temporelle des NDVI moyen des segments (vec_sf$valeurs) afin que le pic de NDVI 
# soit placer au rang du milieu (donc à 16 pour 31 dates)

fonction_centrage <- function(mon_vecteur){
  num <- which(mon_vecteur==max(mon_vecteur))
  med <- 16
  diff <- (med - num)
  col2 <- shifter(mon_vecteur, -diff)
  return(col2)
}


# On convertit vec en objet sf
vec_sf <- st_as_sf(vec)

# pour chaque segment, on extrait la valeur moyenne
vec_sf$valeurs <- exact_extract(stack_NDVI, vec_sf, 'mean')


# recentrage des valeurs (attention, le segment 3967 bloque parce qu'il a exactement les mêmes valeurs a deux dates)

vec_sf$valeurs <- t(apply(vec_sf$valeurs, 1, fonction_centrage))


# Création d'une série temporelle témoin pour les terres agricoles (ici de polygone vérifiés):

#importation du fichier polygone
grands_ensemble <- readOGR(dsn = '/Users/hugotreuildussouet/Desktop/mini_projet/données_liban/OS_Liban/',layer = 'grands_ensembles')
part <-(grands_ensemble[grands_ensemble$id=="3",]) # 3 = terres agricoles

# création de la moyenne des NDVI de parcelles agricoles par dates
part_sf <- st_as_sf(part)
agri <- exact_extract(stack_NDVI, part_sf, 'mean')
agri_mean <- apply(agri, 2, mean)

# centrage des valeurs 
agri_mean_centr <- fonction_centrage(agri_mean)


# calcul en absolu de l'ecart entre les NDVI moyens des champs agricoles par dates et ceux des segments
vec_sf2 <- vec_sf 
for (i in 1:ncol(vec_sf$valeurs)){
  vec_sf2$valeurs[,i] <- abs(vec_sf$valeurs[,i] - agri_mean_centr[i])
}

# on peut aussi créer un nouveau champs avec par exemple les moyennes
vec_sf2$valeurs_mean <- apply(vec_sf2$valeurs, 1, mean)


# on rasterise ensuite avec le champs souhaité (ici vec_sf2$valeurs) que l'on place dans un stack
stack_NDVIi <- stack()
for (j in 1:ncol(vec_sf2$valeurs)){
  vec_sff <- vec_sf2
  vec_sff$valeurs <- vec_sf2$valeurs[,j]
  ecart_NDVI <- fasterize(vec_sff, stack_NDVI[[j]], field = "valeurs")
  stack_NDVIi <- stack(stack_NDVIi, ecart_NDVI)
}

# ou uniquement le champs des moyennes par exemples
ecart_NDVI <- fasterize(vec_sf2, stack_NDVI[[2]], field = "valeurs_mean")


# NDVImean  nous donne théoriquement une carte avec des valeur de 0 à 1 ou :
# 0 = segments à l'évolution du NDVI très proche de celui des terres agricoles témoins
# 1 = segments à l'évolution du NDVI très différente 
NDVImean <- mean(stack_NDVIi)



