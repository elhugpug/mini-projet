# Code pour créer des courbes temporelles de NDVI sur les polygones de grands ensembles (eau, sols nus, sols agricoles, forêts)

####################################

#chrgement des bibliothèques
library(parallel)
library(velox)
library(ggplot2)
library(reshape2)
library(raster) 
library(rgdal)

# code pour créer un stack avec les valeur de NDVI entre la 11ème date et la 31ème 
for (dates in les_dates[11:31]){
  setwd(dates)
  b <- list.files(".", pattern='B0[4;8]')
  b4 <- raster(b[1])
  b8 <- raster(b[2])
  
  NDVI <- (b8-b4)/(b8+b4)
  stack_NDVI <- stack(stack_NDVI, NDVI)
}

# importation du fichier vecteur avec les 4 classes (eau, sols nus, sols agricoles, forêts)
entrainement <- readOGR(dsn = '/Users/hugotreuildussouet/Desktop/mini_projet/données_liban/OS_Liban/',layer = 'grands_ensembles')

# De ce fichier, on choisis la classe que l'on a envi de représenter en courbe (ici la classe 4)
part <-(entrainement[entrainement$id=="4",])

# extraction des valeurs du stack par polygones
img <- velox(le_stack)
test1 <- mclapply(seq_along(1), function(x){
  img$extract(part, fun=function(t) mean(t,na.rm=T))
})
# transformation du resultat de lapply en dataframe 
tab <- as.data.frame(do.call(rbind, test1))

# mis en place du fichier pour qu'il soit utilisable par ggplot. 
# on inverse les lignes et colonnes 
tab_bis <- t(tab)
#on le transforme de nouveau en data.frame
tab_bis <-as.data.frame(tab_bis)
#on rajoute une colonne avec des chiffre de 1 jusqu'au nombre de date (ici 21 dates) que l'on place en première colonne et que l'on renomme
tab_bis[,ncol(tab_bis)+1] <- 1:length(tab_bis[,1])
tab_bis <- tab_bis[, c(length(tab_bis), 1:length(tab_bis)-1)]
colnames(tab_bis) <- c(paste("X",1:length(colnames(tab_bis)),sep=""))

# on fond le tableau avec la fonction melt() de reshape2 
tab2 <- melt(tab_bis, id.vars = "X1")

# on affiche le graphique 
ggplot(tab2, aes(X1,value)) + geom_line(aes(colour = variable))+
  labs(title = "Forêt", x ="Evolution sur ann\u00e9e" , y = "NDVI")
