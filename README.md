# Classification de l'occupation du sol 

Ce mini-projet à pour but d'explorer quelques possibilités de classification d'occupation du sol de la zone de Bekaa au Liban avec des images optiques et RADAR. Dans ce fichier README, seront expliquées les démarches suivies, avec quelques explications de codes présents dans les liens au-dessus.

Au delà de la recherche de résultats nous nous attacherons à présenter un cheminement intellectuel : les méthodes utilisées les résultats obtenus, mais aussi les pistes infructueuse et les difficultés rencontrées. 


## 1- Introduction

La région de la Bekaa est une zone agricole de première importante pour le Liban. Il semble donc primordiale de connaitre l'occupation du sol de la région pour quantifier et prévoir les productions et les changements auquels pourrait être soumis la région. En complément du travail de terrain et de recherche classique,la télédétection est un outils précieux dans la mesure ou elle permet d’analyser le territoire sur de large surface et à une échelle multi-temporelle. Vaste champ, la télédétection peut également s’aborder par différentes composantes comme l’optique et le RADAR ce qui permet de recouper les résultats et d’enrichir l’analyse. 
C’est dans ce contexte que s’inscrit ce mini-projet qui a pour objectif la réalisation de cartes de l’occupation du sol de la région de Bekaa en 2019 à l’aide d’images optiques (Sentinel-2) et RADAR (Sentinel-1). On tachera d'analyser et de comparer les résultats des deux types d'images séparemment mais également dans leur complémentarité.


Voici le plan suivi tout au long de ce mini-projet :

je suis meilleur dans le premier, plus facile a comparer ensuite
* Classification des images optiques
* Classification des images RADAR
* Complémentarité des deux méthodes

## 2- Les données disponibles

### Les données de terrains
### Les images Sentinel-2
     - qu'est ce que l'imagerie optique 
     - (point positif, négatif)
     - pourquoi sentinel-2 
     
     - préparation (téléchargement, prétraitement, difficultés (problème espace, nuage, prétraitement))
### Les images Sentinel-1



## 3- Classification de la Bekaa par images optiques
  
### Classifications
2 méthodes de classification (Random forest et technique 2)

#### Random Forest

Comme nous l'avons vu, il y a plus de 20 types d'occupation du sol à classifier et il semble difficile d'obtenir un resultat précis en un seul calcul. Aussi dans un premier temps, il est préférable d'établir une classification plus grossière pour séparer les grands types d'éléments (étape 1). Nous procéderons ensuite à la classification précise de chaque type d'occuation  du sol (étape 2).

##### Etape 1
 Plusieurs méthodes ont été tenté pour séparer les grands types d'occupation du sol. 
 
###### Essaie 1
Nous avons tenté tout d'abord de séparer les types d'occuation du sol par leurs potentielles évolutions temporelles au cours de l'année. Après avoir créer une série temporelle de NDVI, nous avons lancé ensuite un Random Forest (avec le package `randomForest`)qui prenait en compte le NDVI minimum, le NDVI maximum et l'amplitude min/max. Quatre types d'espaces pouvait ainsi être discriminés : 

1. **les sols agricoles** caractérisés par un NDVI fluctuant 
2. **les forêts** caractérisées par un NVDI élevé et plutôt constant
3. **les espaces en eau** caractérisés par un NDVI très faible 
4. **les sols nus et artificialisés** caractérisés par un NDVI moyen et plutôt constant

A l'aide d'image sentinel-2 et d'images très hautes résolutions de google map, nous avons dessiné des ROI correspondants à chacuns des types vu plus hauts sur Qgis (5 par types). Les NDVI ont été calculé pour toutes les dates ne comprennant pas de neige afin d'avoir le maximum de différence possible sans pour autant que les valeurs ne soit tronquées par la neige. 

Cependant, cette méthode n'a pas porté ces preuves et ne séparait que partiellement ces espaces. L'erreur out of bag (OOB) s'élevait à 21% mais surtout la validation du Random Forest semblaient déterminé par les polygones tests, ce qui, après plusieurs essais pouvait déboucher à une classification avec 1% d'OOB alors que celle-ci n'était clairement pas satisfaisante... Il est fort probable qu'une donnée nous ai échappé dans la préparation de ce code.  
Pour cette raison, le détail de la méthode ne sera pas détaillé plus que cela mais ![le code du test se trouve ici](optique_RF_1_1.R) (code : optique_RF_1_1)


###### Essaie 2

J'ai donc pensé dans un premier temps que le Random Forest avait surement quelques difficultés avec les sols nus, dans la mesures ou la matrice de confusion du premier essai montrait que ce type d'espace était rarement classé correctement (plus de la moitié des pixels).
Cependant, dans la mesure ou le premier essai a donné des résutats pour le moins étrange et que cette méthode de classification avait déjà été testé avec succès dans d'autres travaux, il a été jugé nécessaire de persisté dans cette voie. 

Au gré des recherches effectuées pour comprendre quelle aurait été l'erreur commise, une autre bibliothèque de classification a semblé intéressante à explorer. 
La package `RStoolbox` s'appuie sur le package `raster`. Il permet d'intervenir sur différents aspects du travail effectué sur des images raster : l'importation de donnée, la préparation des images, la classification... 
Le code R de la classification issu de ce package est simple, compact et assez rapide (https://bleutner.github.io/RStoolbox/)

Le package est sur le CRAN et peut être installé de la manière suivante :

`install.packages("RStoolbox")` 

Ici va être détaillé certains morceaux du code de cette classification que l'on peut également retrouver ici. Il reprend des éléments du code du premier essai. 

On importe les bibliothèques nécessaire au bon fonctionnement de la classification

`library("RStoolbox")` 

`library(raster)`   #  permet le travail avec des données raster

`library(rgdal)`    #  permet le travail avec des  données vecteurs



Le code ci-dessous permet de récupérer les images des bandes 4 et 8 pour chacune des dates (en excluant les 10 premières dates ou la neige présente apportait une confusion) et de créer un NDVI que l'on place ensuite dans un stack. 
On importe également les fichiers vecteurs des quatres types d'occupation du sol décrit dans l'essai 1. 

```
 les_dates <- list.files("chemins vers les dossiers des images", full.names = TRUE)
 le_stack <- stack() 

 for (dates in les_dates[11:31]){
   setwd(dates)
   b <- list.files(".", pattern='B0[4;8]')
   b4 <- raster(b[1])
   b8 <- raster(b[2])
  
   NDVI <- (b8-b4)/(b8+b4)
   le_stack <- stack(le_stack, NDVI)
 }
 
 entrainement <- readOGR(dsn = 'chemin ves le fichier shp',layer = 'nom du fichier')

```

Tout comme lors du premier essai, on créé des rasters avec les valeurs minimum, maximum et l'amplitude que l'on met dans un stack. 

```
NDVImin <- min(stack_NDVI)
NDVImax <- max(stack_NDVI)
amplitude <- NDVImax - NDVImin
stack_max_min_amp <- stack(NDVImin, NDVImax, amplitude)
names(stack_max_min_amp) <- c('Min', 'Max', 'Amplitude')
```

C'est à partir de là que les choses se modifient par rapport à la classification de la bibliothèques randomForest. 
Le random forest est effectué avec la fonction `superClass()`. On lui spécifie les rasters d'entrées, les polygones de tests, la colonne des polygones a prendre en compte (ici l'id permet de séparer les 4 types de polygones), le nombre d'itération, le pourcentage de polygone à utiliser pour l'entrainement (ici 70% des polygones, chiffre que l'on trouve régulièrement dans la littérature)...

```
test <-   superClass(stack_max_min_amp, entrainement, valData = NULL, responseCol = "id",
                     nSamples = 1000, polygonBasedCV = FALSE, trainPartition = 0.7,
                     model = "rf", tuneLength = 3, kfold = 5, minDist = 2,
                     mode = "classification", predict = TRUE, predType = "raw")
plot(test$map)
test
```
Voici la carte de classification : 

Les résultats sont ici très encourageant. En effet l'overall accuracy qui calcul le pourcentage de pixel bien placé est de 0,961 (sur 1) et l'indice de Kappa qui calcul la part de hasard dans cette classification est de 0,947 (sur 1).  Enfin, les résultats sont significatif dans la mesure ou la p-value est inferieur à 2.2e-16. 
La matrice de confusion quant à elle nous révèle d'intéressantes informations. 
La classe 1 (l'eau) a été systématiquement bien prédite (tous les pixels de référence eau sont bien placé dans l'eau). Il y a quelques faux-positifs dans la mesure ou des pixels de sols ont été classé en eau. 
La classe 2 (sol/urbain) rencontre plus de problème. En effet 3,7% de ces pixels ont été classés en zone agricole ou forestière et plusieurs pixels agricoles ont été classé comme du sol nu/urbain. 
La classe 3 (agriculture) est la moins bien classé. 10% de ces pixels ont été classé dans une autre catégorie et quelques pixels ont été classé en tant que sol nu/urbain.
La classe 4 (forêt) est très bien classé (avec cependant le plus grand pourcentage de faux-positifs). 

```
Confusion Matrix

          Reference
Prediction    1    2    3    4
         1 1001    1    0    0
         2    0  965   43    0
         3    0   24  910    0
         4    0   12   49  358
```







1. **les sols nus et artificialisés** 
2. **les sols agricoles** (blé, alfalfa, choux, chou-fleur, haricot, oignon, laitue, courgette, tomate, pomme de terre, jachères)
3. **les forêts** 
4. **les espaces artificialisés** (zones urbaine, serres)
5. **les espaces en eau** 

> Selon Hale Hage Hassan & all (Les changements d’occupation des sols dans la Béqaa Ouest (Liban) : le rôle des actions anthropiques, 2019) d'autres éléments tel que les broussailles sont présents dans la région mais il semble que cela puisse être confondus avec les espaces en jachères.






On utilise `library(raster)` pour travailler sur des raster

```
fun_gcc <- function(limage){
  img <- velox(limage)
  test1 <- mclapply(seq_along(1), function(x){
    img$extract(ROI, fun=function(t) mean(t,na.rm=T))
  })
  tab <- as.data.frame(do.call(rbind, test1))
  roi_gcc <- tab[,2]/(tab[,1]+tab[,2]+tab[,3])
  
  return(roi_gcc)
}
```



![image S2](file:///Users/hugotreuildussouet/Desktop/IMG_4363.jpg)


<img src="images/Rplot.jpeg" width="500">
