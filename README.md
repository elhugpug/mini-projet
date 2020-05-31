# Mini-projet

Ce mini-projet à pour but d'explorer quelques possibilités de classification d'occupation du sol avec des images optiques (Sentinel-2) et RADAR (Sentinel-1). Dans ce fichier README, seront expliquées les démarches suivies avec quelques explications des codes présents au-dessus.

Voici le plan suivi tout au long de ce mini-projet :
* Classification des images optiques
* Classification des images RADAR
* Complémentarité des deux méthodes
* Conclusion

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

[code de téléchargement des images S2](docs/CONTRIBUTING.md)

