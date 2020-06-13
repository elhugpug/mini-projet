
# Code pour générer un Random Forest qui distingue les types d'occupation du sol en fonction 
# de leur évolution temporelle propre

# Ici nous distinguons : les sols agricoles, les forêts, les espaces en eau et les sols nus et artificialisés (les espaces urbains ont également été séparer pour un test)

####################################
# on importe les bibliothèques nécessaire 

library(raster) # raster permet le travail avec les données raster
library(rgdal) # rgdal permet le travail avec des  vecteurs
library(velox) # velox permet de travailler de manière efficace sur la manipulation et l'extraction de données raster (https://www.rdocumentation.org/packages/velox/versions/0.2.0)
library(randomForest) # randomForest permet de classifier avec la méthode du Random Forest

les_dates <- list.files("/Users/hugotreuildussouet/Desktop/Bekaa", full.names = TRUE)
stack_NDVI <- stack() 

# cette boucle génère les raster des bandes rouges et infrarouge pour créer un NDVI que l'on place ensuite dans un stack
# c'est à partir de la 11eme image (31-05-2019) que la neige disparait totalement de la zone 
for (dates in les_dates[11:31]){
  setwd(dates)
  b <- list.files(".", pattern='B0[4;8]')
  b4 <- raster(b[1])
  b8 <- raster(b[2])
  
  NDVI <- (b8-b4)/(b8+b4)
  stack_NDVI <- stack( stack_NDVI , NDVI )
}

# On créé 3 raster contenants les valeurs minimal, maximal et leur amplitude que l'on place dans un stack
NDVImin <- min(stack_NDVI)
NDVImax <- max(stack_NDVI)
amplitude <- NDVImax - NDVImin
stack_max_min_amp <- stack(NDVImin, NDVImax, amplitude)
names(stack_max_min_amp) <- c('Min', 'Max', 'Amplitude')

#####
# Si l'on souahite ne pas prendre les min/max mais plutôt les quartiles (pour enlever les valeurs extrêmes)

# 1- il est possible de créer une fonction :
fonction_1er_q <- function(mon_vecteur){
  le_1er_q <- quantile(mon_vecteur, 0.25,names=FALSE) # ici 0.25 pour le premier quartile mais n'importe quelle valeur entre 0 et 1 fonctionne
  return(le_1er_q)
}
# 2- on modifie également la boucle for vu plus haut en remplacant le stack par une vectorisation des images que l'on place les unes en dessous des autres :
NDVIvec <- as.vector(NDVI)
if (compteur==1) NDVItab <- NDVIvec else NDVItab <- rbind(NDVItab, NDVIvec)

# 3- on applique ensuite la fonction au vecteur créé puis on rasterize l'image de nouveau
resultat <- apply(NDVItab, 2, fonction_1er_q)
resultat_matrice <- matrix(resultat, nrow=nrow(NDVI), ncol=ncol(NDVI))
quantile_20 <- raster(t(resultat_matrice), template=NDVI)
#####

# on importe le fichier SHP contenant les ROI des types d'occupation du sol
entrainement <- readOGR(dsn = '/Users/hugotreuildussouet/Desktop/mini_projet/données_liban/OS_Liban/',layer = 'grands_ensembles')
# on reprojette le raster pour qu'il corresponde aux ROI
stack_max_min_amp2 <- projectRaster(stack_max_min_amp, crs = projection(entrainement), method='ngb')
plot(NDVImax)
plot(entrainement, add= TRUE)

# on extrait la valeur des pixels appartenant à chaque polygone à l'aide de velox 
img <- velox(stack_max_min_amp2)
extr_1 <- img$extract(entrainement, df = TRUE)

# l'ID des ROI est transformé en format numérique (sinon ID commence à 0 et non à 1)
extr_1$ID_sp<- as.numeric(extr_1$ID_sp)

# on joint ensuite les ID qui correspondent au même type d'occupation du sol (3 polygones par type)
extr_2 <- extr_1
extr_2$ID_sp<- 0
extr_2$ID_sp[extr_1$ID_sp %in% 1:7] <- 1  # eau
extr_2$ID_sp[extr_1$ID_sp %in% 8:14] <- 2  # sols nus
extr_2$ID_sp[extr_1$ID_sp %in% 15:21] <- 3  # urbain
extr_2$ID_sp[extr_1$ID_sp %in% 22:33] <- 4  # agriculture
extr_2$ID_sp[extr_1$ID_sp %in% 34:39] <- 5  # foret
names(extr_2) <- c('ID', 'Min', 'Max', 'Amplitude')

# création du Random Forest
rfmod <- randomForest(as.factor(ID)~., data=extr_2, ntree=500)
IdF <- predict(stack_max_min_amp, rfmod, type='class', progress = 'text')
plot(IdF)

# nous montre l'OOB et la matrice de confusion
print(rfmod)


# enregistre la classification si on souhaite
setwd("/Users/hugotreuildussouet/Desktop/")
nomfichier <- "random_forest"
rf <- writeRaster(IdF, filename=nomfichier, format="ENVI", overwrite=TRUE)

