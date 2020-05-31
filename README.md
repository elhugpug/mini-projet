# Mini-projet

Ce mini-projet à pour but d'explorer quelques possibilités de classification d'occupation du sol de la zone de Bekaa au Liban avec des images optiques et RADAR. Dans ce fichier README, seront expliquées les démarches suivies, avec quelques explications de codes présents dans les liens au-dessus.

Au delà de la recherche de résultats nous nous attacherons à présenter un cheminement intellectuel : les méthodes utilisées les résultats obtenus, mais aussi les pistes infructueuse et les difficultés rencontrées. 


## Introduction

La région de la Bekaa est une zone agricole de première importante pour le Liban. Il semble donc primordiale de connaitre l'occupation du sol de la région pour quantifier et prévoir les productions et les changements auquels pourrait être soumis la région. En complément du travail de terrain et de recherche classique,la télédétection est un outils précieux dans la mesure ou elle permet d’analyser le territoire sur de large surface et à une échelle multi-temporelle. Vaste champ, la télédétection peut également s’aborder par différentes composantes comme l’optique et le RADAR ce qui permet de recouper les résultats et d’enrichir l’analyse. 
C’est dans ce contexte que s’inscrit ce mini-projet qui a pour objectif la réalisation de cartes de l’occupation du sol de la région de Bekaa en 2019 à l’aide d’images optiques (Sentinel-2) et RADAR (Sentinel-1). On tachera d'analyser et de comparer les résultats des deux types d'images séparemment mais également dans leur complémentarité.


Voici le plan suivi tout au long de ce mini-projet :

* Classification des images optiques
* Classification des images RADAR
* Complémentarité des deux méthodes


## Classification de la Bekaa par images optiques
 
- qu'est ce que l'imagerie optique 
     - (point positif, négatif)
     - pourquoi sentinel-2 
     
- préparation (téléchargement, prétraitement, difficultés (problème espace, nuage, prétraitement))
- quel type de classification 

### Préparation des images 

code de téléchargement 


### Classification














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
