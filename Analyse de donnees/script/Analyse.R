#Analyse de données
setwd("D:/MIAGE/MASTER2/projetBigData/data")

#--------------------------------------------#
# INSTALLATION/MAJ DES LIRAIRIES NECESSAIRES #
#--------------------------------------------#

install.packages("rpart")
install.packages("randomForest")
install.packages("kknn")
install.packages("ROCR")
install.packages("dplyr")
install.packages("ggplot2")
install.packages("tidyr")
install.packages("stringr")
#--------------------------------------#
# ACTIVATION DES LIRAIRIES NECESSAIRES #
#--------------------------------------#

library(rpart)
library(randomForest)
library(kknn)
library(ROCR)
library(dplyr)
library(ggplot2)
library(tidyr)
library(stringr)

#------------------------------------#
# 1 Analyse exploratoire des données #
#------------------------------------#
catalogue <- read.csv("Catalogue.csv", header = TRUE, sep = ";", dec = ".")
immatriculations <- read.csv("Immatriculations.csv", header = TRUE, sep = ";", dec = ".")
clients <- read.csv("Clients_0.csv", header = TRUE, sep = ";", dec = ".")
clients <- subset(clients, select = -id)

sum(is.na(catalogue))
sum(is.na(immatriculations))
sum(is.na(clients))

str(catalogue)
str(immatriculations)
str(clients)

summary(catalogue)
summary(immatriculations)
summary(clients)


# ----------------------PIE CHART AGE CLIENT---------------------------- #
labels <- c(0, 40, 60, 80, 100)
clients$age_cut <- cut(clients$age, labels)

#Suppression des valeurs manquantes pour la variable age
completeFun <- function(data, desiredCols) {
  completeVec <- complete.cases(data[, desiredCols])
  return(data[completeVec, ])
}
clients_pie <- completeFun(clients, "age_cut")


nb1 <- count(filter(clients_pie, age_cut == "(0,40]"))
nb2 <- count(filter(clients_pie, age_cut == "(40,60]"))
nb3 <- count(filter(clients_pie, age_cut == "(60,80]"))
nb4 <- count(filter(clients_pie, age_cut == "(80,100]"))

slices <- c(as.numeric(nb1), as.numeric(nb2), as.numeric(nb3), as.numeric(nb4))
str(slices)
lbls <- c("0 et 40 ans : ", "40 et 60 ans : ", "60 et 80 ans : ", "80 et 100 ans : ")
pct <- round(slices/sum(slices)*100)
lbls <- paste(lbls, pct) # add percents to labels
lbls <- paste(lbls,"%",sep="") # ad % to labels
pie(slices, labels = lbls, col=rainbow(length(lbls)),
    main="Pie Chart of Age client")

# ----------------------------------------------------------------------- #



#plus la voiture est chere, plus sa puissance est élevé ? 
#vrai ! corrélation entre le prix et la puissance de la voiture car coeff de corrélation proche de 1 : 0.87
cor(catalogue$puissance, catalogue$prix, method="pearson")
ggplot(catalogue, aes(x=prix, y=puissance)) + geom_point(aes(size=puissance))
boxplot(immatriculations$puissance, main="Boite à moustance de la colonne puissance") 

#plus le clients est agé, plus il a un taux d'entemment elevé ? 
#faux ! pas de corrélation entre l'age et le taux car coefficient de corrélation proche de 0
cor(clients$age, clients$taux, method="pearson")


#Les clients ayant un taux d'endettement élevé sont plus susceptible d'avoir une deuxième voiture : 
#Non, nous constatons que la majeur partie des clients possédant une deuxième voiture ont un t.e de 5xx euros.
#Le nombre de personnes ayant une 2ieme voiture n'augmente pas en fonction de la valeur du t.e
clients_taux <- clients

clients_taux$taux_group = ifelse(str_length(clients_taux$taux) == 3, paste(str_sub(clients_taux$taux,start=1, end = 1), "00", sep=""), paste(str_sub(clients_taux$taux,start=1, end = 2), "00", sep=""))
filter <- clients_taux %>%
  group_by(taux_group, X2eme.voiture) %>%
  summarise(nb = n())


df <- as.data.frame(filter(filter, taux_group != -100 & X2eme.voiture == "true"))
df <- transform(df, taux_group = as.numeric(taux_group))
str(df)
plot(df$taux_group, 
     df$nb, 
     xlab = "Taux d'endettement",
     ylab = " Nombre de clients",
     col = "red",
     main = "Nombre de clients possèdant une deuxième voiture selon leur taux d'endettement")


#---------------------------------------------#
# 2 Identificaton des catégories de véhicules #
#---------------------------------------------#
#Critères établit en focntion des résultats trouvés sur largus.fr, pour chaque modèle de véhicule du fichier Catalogue.csv
#Une différenciation pour le modèle Audi A2 1.4 qui est qualifié de monospace (malgré sa courte longueur) sur largus.fr et de citadine par notre modèle
#https://www.largus.fr/fiche-technique/Audi/A2/I/2002/Monospace+5+Portes/14+75+Reference-708362.html

#Le prix n'est pas entré dans les critères car en fonction des marques haut de gamme (exemple Mercedes) 
#le prix moyen d'une compacte toutes marques confondues peut être équivalent à un prix d'une citadine chez Mercedes

#les citadines : puissance inférieur a 90 CV || longueur : courte 
#les compactes : puissance superieur a 90 CV || longueur : courte ou moyenne 
#les sportives : puissance supérieur a 300 CV
#les familiale : nb de place > 5, || longueur : longue, très longue
#les berlines : puissance : entre 100 et 300 CV || longueur : longue, très longue




catalogue$categorie = ifelse(catalogue$puissance<90 & catalogue$longueur == "courte", "citadine",
                             ifelse(catalogue$puissance>300 , "sportive",
                                    ifelse(catalogue$longueur == "moyenne" | catalogue$longueur == "courte" & catalogue$puissance>=90  , "compacte",
                                           ifelse(catalogue$nbPlaces>5 & (catalogue$longueur == "longue" | catalogue$longueur == "très longue"), "familiale",
                                                  ifelse(catalogue$puissance>=100 & catalogue$puissance<=300 & (catalogue$longueur == "longue" | catalogue$longueur == "très longue"), "berline", "autre"
                                                  )
                                           )
                                    )
                             )
)



table(catalogue$categorie)
write.table(catalogue, file="catalogue_and_categorie.csv", sep = "\t",  dec = ".",  row.names = F)
#On peut constater sur le nuage de points que les catégories de voitures peuvent se distinguer par le prix et puissance
ggplot(catalogue, aes(x=categorie, y=prix)) + geom_point(aes(size=puissance))

#------------------------------------------------------------------------------------#
# 3 Application des catégories de véhicules définies au données des Immatriculations #
#------------------------------------------------------------------------------------#

immatriculations$categorie = ifelse(immatriculations$puissance<90 & immatriculations$longueur == "courte", "citadine",
                                    ifelse(immatriculations$puissance>300 , "sportive",
                                           ifelse(immatriculations$longueur == "moyenne" | immatriculations$longueur == "courte" & immatriculations$puissance>=90  , "compacte",
                                                  ifelse(immatriculations$nbPlaces>5 & (immatriculations$longueur == "longue" | immatriculations$longueur == "très longue"), "familiale",
                                                         ifelse(immatriculations$puissance>=100 & immatriculations$puissance<=300 & (immatriculations$longueur == "longue" | immatriculations$longueur == "très longue"), "berline", "autre"
                                                         )
                                                  )
                                           )
                                    )
)

str(immatriculations)


#-------------------------------------------------#
# 4 Fusion des données Clients et Immatriculation #
#-------------------------------------------------#
#Selection des colonnes de la table immatratriculation, utiles à la jointure : immatriculation et categorie
immatriculations_join <- select(immatriculations, immatriculation, categorie)
#Jointure des tables immatriculations_join et clients par la colonne commune immatriculation
clients_categorie <- left_join(clients,immatriculations_join, by="immatriculation")
str(clients_categorie$categorie)
#O ligne selectionné car pas de voiture avec nbPlaces > 5 dans immatriculations filter(clients_categorie, categorie == "familiale")


#-----------------------------------------------------------------------------------------------------#
# 5 Création d'un modèle de classification supervisée pour la prédiction de la catégorie de véhicules #
#-----------------------------------------------------------------------------------------------------#
# Creation des ensembles d'apprentissage et de test
clients_categorie_EA <- clients_categorie[1:500,]
clients_categorie_ET <- clients_categorie[501:700,]

clients_categorie_EA <- subset(clients_categorie_EA, select = -immatriculation)
clients_categorie_ET <- subset(clients_categorie_ET, select = -immatriculation)

#-------------------------#
# ARBRE DE DECISION RPART #
#-------------------------#

tree1 <- rpart(categorie ~ ., clients_categorie_EA)
plot(tree1) 
text(tree1, pretty=0)
test_tree1 <- predict(tree1, clients_categorie_ET, type="class")
table(test_tree1)
#immatriculations$categorie <- test_tree1

mc_tree1 <- table(clients_categorie_ET$categorie, test_tree1)
print(mc_tree1)


#-------------------------#
# ARBRE DE DECISION RPART #
#-------------------------#

# Definition de la fonction d'apprentissage, test et evaluation par courbe ROC
test_rpart <- function(arg1, arg2, arg3, arg4){
  # Apprentissage du classifeur
  dt <- rpart(categorie~., clients_categorie_EA, parms = list(split = arg1), control = rpart.control(minbucket = arg2))
  
  # Tests du classifieur : classe predite
  dt_class <- predict(dt, clients_categorie_ET, type="class")
  
  # Matrice de confusion
  print(table(clients_categorie_ET$categorie, dt_class))
  
  # Tests du classifieur : probabilites pour chaque prediction
  dt_prob <- predict(dt, clients_categorie_ET, type="prob")
  
  # Courbes ROC
  dt_pred <- prediction(dt_prob[,2], clients_categorie_ET$categorie)
  dt_perf <- performance(dt_pred,"tpr","fpr")
  plot(dt_perf, main = "Arbres de decision rpart()", add = arg3, col = arg4)
  
  # Calcul de l'AUC et affichage par la fonction cat()
  dt_auc <- performance(dt_pred, "auc")
  cat("AUC = ", as.character(attr(dt_auc, "y.values")))
  
  # Return sans affichage sur la console
  invisible()
}

#----------------#
# RANDOM FORESTS #
#----------------#

# Definition de la fonction d'apprentissage, test et evaluation par courbe ROC
test_rf <- function(arg1, arg2, arg3, arg4){
  # Apprentissage du classifeur
  rf <- randomForest(categorie~., clients_categorie_EA, ntree = arg1, mtry = arg2)
  
  # Test du classifeur : classe predite
  rf_class <- predict(rf,clients_categorie_ET, type="response")
  
  # Matrice de confusion
  print(table(clients_categorie_ET$categorie, rf_class))
  
  # Test du classifeur : probabilites pour chaque prediction
  rf_prob <- predict(rf, clients_categorie_ET, type="prob")
  
  # Courbe ROC
  rf_pred <- prediction(rf_prob[,2], clients_categorie_ET$categorie)
  rf_perf <- performance(rf_pred,"tpr","fpr")
  plot(rf_perf, main = "Random Forests randomForest()", add = arg3, col = arg4)
  
  # Calcul de l'AUC et affichage par la fonction cat()
  rf_auc <- performance(rf_pred, "auc")
  cat("AUC = ", as.character(attr(rf_auc, "y.values")))
  
  # Return sans affichage sur la console
  invisible()
}

#---------------------#
# K-NEAREST NEIGHBORS #
#---------------------#

# Definition de la fonction d'apprentissage, test et evaluation par courbe ROC
test_knn <- function(arg1, arg2, arg3, arg4){
  # Apprentissage et test simultanes du classifeur de type k-nearest neighbors
  knn <- kknn(categorie~., clients_categorie_EA, clients_categorie_ET, k = arg1, distance = arg2)
  
  # Matrice de confusion
  print(table(clients_categorie_ET$categorie, knn$fitted.values))
  
  # Courbe ROC
  knn_pred <- prediction(knn$prob[,2], clients_categorie_ET$categorie)
  knn_perf <- performance(knn_pred,"tpr","fpr")
  plot(knn_perf, main = "Classifeurs K-plus-proches-voisins kknn()", add = arg3, col = arg4)
  
  # Calcul de l'AUC et affichage par la fonction cat()
  knn_auc <- performance(knn_pred, "auc")
  cat("AUC = ", as.character(attr(knn_auc, "y.values")))
  
  # Return sans affichage sur la console
  invisible()
}

#-------------------------------------------------#
# APPRENTISSAGE DES CONFIGURATIONS ALGORITHMIQUES #
#-------------------------------------------------#

# Arbres de decision
test_rpart("gini", 10, FALSE, "red")
test_rpart("gini", 5, TRUE, "blue")
test_rpart("information", 10, TRUE, "green")
test_rpart("information", 5, TRUE, "orange")

# Forets d'arbres decisionnels aleatoires
test_rf(300, 3, FALSE, "red")
test_rf(300, 5, TRUE, "blue")
test_rf(500, 3, TRUE, "green")
test_rf(500, 5, TRUE, "orange")

# K plus proches voisins
test_knn(10, 1, FALSE, "red")
test_knn(10, 2, TRUE, "blue")
test_knn(20, 1, TRUE, "green")
test_knn(20, 2, TRUE, "orange")



#-------------------------------------------------------------#
# 6 Application du modèle de prédiction aux données Marketing #
#-------------------------------------------------------------#
marketing <- read.csv("Marketing.csv", header = TRUE, sep = ",", dec = ".")
marketing$predict_categorie <- test_tree1





