#Ce code permet de télécharger les données S2 et de les préparer à l'aide notamment de sen2r() 



# Ou télécharger les dépendances utiles au bon fonctionnement de sen2r ? 

#     sen2cor : install_sen2cor()  
#     aria : brew install aria2 sur le terminal (on peut aussi l'installer comme sen2cor avec windows)
#     il faut lancer le package rgdal sur R

# Chargement des bibliothèques necessaire
library(raster)
library(geojsonlint)
library(rgdal)
library(sen2r)
library(gdalUtils)


# vérifie que toute les dépendances sont bien installées...ou non.
check_sen2r_deps()

#chargement du fichier kml qui va servir de zonage et des fichiers shp pour la dépoupe. 
myextent_1 <- "/Users/hugotreuildussouet/Desktop/zone_liban/vecteur_decoup/zone_liban_sen2r.kml"
zone_liban <- readOGR('/Users/hugotreuildussouet/Desktop/zone_liban/vecteur_decoup/zone_liban.shp')

# pour reprojeter les images à 20m sans perdre d'information, on les découpe en un peu plus grand dans un premier temps
zone_liban_large <- readOGR('/Users/hugotreuildussouet/Desktop/zone_liban/vecteur_decoup/zone_liban_large.shp')


# Fonction pour télécharger les images sentinels 2 et les préparées (prétraitements, découpe...)
write_scihub_login('nom_utilisateur', 'code')

# boucle pour télécharger les données et les traiter jours par jours : 

annee<-'2019'
for (mois in c('01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12')){
  for (jour in c('01','02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12','13','14', '15', '16', '17', '18', '19', '20', '21', '22','23','24', '25', '26', '27', '28', '29', '30', '31')){
    tryCatch({    
      
      date <- paste(annee, mois,jour, sep='-')
      sen2r(
        gui = FALSE,
        apihub = NA,
        downloader = "aria2",
        max_cloud_safe = 100,
        timewindow = as.Date(date),
        timeperiod = "full",
        extent = myextent_1, 
        extent_name = "sen2r",
        list_prods = "BOA",
        mask_type = "clear_sky",  #  or "cloud_and_shadow"
        max_mask = 10,
        clip_on_extent = TRUE,
        extent_as_mask = TRUE,
        res = NA,
        outformat = "GTiff",
        path_l2a = "/Users/hugotreuildussouet/Desktop/zone_liban/1",
        processing_order = "by_groups",
      )
    }, error=function(e){})
    
    # on se rend à l'endroit ou sont placés les images
    
    setwd("/Users/hugotreuildussouet/Desktop/zone_liban/1")
    morceau_nom_dossier <-paste(annee,mois,jour, sep='')
    nom_image <- dir(path='.', pattern=paste("2A_",morceau_nom_dossier,sep=''))
    #  if (dir.exists(paste("/Users/hugotreuildussouet/Desktop/zone_liban/1/",nom_image,sep=""))==TRUE){

    nom_image <- dir(path='.', pattern=paste("2A_",morceau_nom_dossier,sep=''))
    if (length(nom_image)>0){
    
    #création des directions pour les images
      
      setwd("/Users/hugotreuildussouet/Desktop/Bekaa")
      dir.create(morceau_nom_dossier)
      getwd()
      setwd("/Users/hugotreuildussouet/Desktop/zone_liban/1")
      A <- dir(path='.', pattern=paste("2A_",morceau_nom_dossier,sep=''))
      setwd(A[1])
      A <- dir(path='.', pattern="GRANULE")
      setwd(A[1])
      A <- dir(path='.', pattern="L2")
      setwd(A[1])
      A <- dir(path='.', pattern="IMG_DATA")
      setwd(A[1])
      A1 <- dir(path='.', pattern="R10")
      setwd(A1[1])
      chemin <- getwd()
      
      # découpage des images aux pixels à 10m 
      for (bande in c('B02','B03','B04','B08')){
        la_bande <- list.files(path='.',pattern=bande)
        la_bande <- raster(la_bande[1])
        b2 <- crop(la_bande,zone_liban)
        
        setwd("/Users/hugotreuildussouet/Desktop/Bekaa")
        d <- dir(pattern=morceau_nom_dossier)
        setwd(d[1])
        nomfichier <- paste(bande,'_',morceau_nom_dossier,sep='')
        writeRaster(b2, nomfichier, format='GTiff', overwrite=TRUE)
        setwd(chemin)
      } 
      
      # changement de répertoire 
      setwd("../")
      A2 <- dir(path='.', pattern="R20")
      setwd(A2[1])
      chemin <- getwd()
      
      # découpage des images aux pixels à 20m, reprojection puis re-découpage
      for (bande in c('B05','B06','B07','B8A','B11','B12')){
        la_bande <- list.files(path='.',pattern=bande)
        la_bande <- raster(la_bande[1])
        b3 <- crop(la_bande,zone_liban_large)
        b4 <- projectRaster(b3,b2,res,crs,method="ngb",alignOnly = FALSE, over = FALSE)
        b5 <- crop(b4,zone_liban)
        
        setwd("/Users/hugotreuildussouet/Desktop/Bekaa")
        d <- dir(pattern=morceau_nom_dossier)
        setwd(d[1])
        nomfichier <- paste(bande,'_',morceau_nom_dossier,sep='')
        writeRaster(b5, nomfichier, format='GTiff', overwrite=TRUE)
        setwd(chemin)
      }
      
      setwd("/Users/hugotreuildussouet/Desktop/zone_liban/1")
      A <- dir(path='.', pattern=paste("2A_",morceau_nom_dossier,sep=''))
      unlink(A, recursive = TRUE)
    }
  }
}


