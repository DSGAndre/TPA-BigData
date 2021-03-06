#Analyse de donn�es
setwd("D:/MIAGE/MASTER2/projetBigData/data")

#Avant l'ex�cution du script Analyse.R, nous devons mettre � jour le chemin du 
#r�pertoire de travail o� sont contenus les data :
#1) Cloner le repository Git https://github.com/DSGAndre/TPA-BigData 
#2) Mettre � jour le chemin du r�pertoire de travail en se rendant sur l'onglet
#Session > Set Working Directory > Choose Director, 
#et en choisissant le r�pertoire data qui se trouve dans le dossier clon� � l'�tape 1 : Analyse_de_donnees/script/data

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
install.packages("ROCR")
install.packages("pROC")
installed.packages("nnet")
install.packages("naivebayes")


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
library(ROCR)
library(pROC)
library(nnet)
library(naivebayes)

#------------------------------------#
# 1 Analyse exploratoire des donn�es #
#------------------------------------#
#Importation des donn�es
catalogue <- read.csv("Catalogue.csv", header = TRUE, sep = ";", dec = ".")
immatriculations <- read.csv("Immatriculations.csv", header = TRUE, sep = ";", dec = ".")
clients <- read.csv("Clients_0.csv", header = TRUE, sep = ";", dec = ".")

#Nettoyage dataframe clients
clients <- subset(clients, select = -id)
clients <- subset(clients, taux !=-1 &
                    nbEnfantsAcharge != -1 &
                    age != -1 &
                    sexe != "Undefined" &
                    X2eme.voiture != "Undefined" &
                    situationFamiliale != "Undefined"
                  )
clients$situationFamiliale = ifelse(clients$situationFamiliale == "Seule" | 
                                      clients$situationFamiliale == "Seul" | 
                                      clients$situationFamiliale == "Divorc�e", 
                                    "C�libataire", clients$situationFamiliale
                                    )

clients %>%
  select(situationFamiliale) %>%
  distinct

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
labels <- c(18, 40, 60, 80, 100)
clients$age_cut <- cut(clients$age, labels)

#Suppression des valeurs manquantes pour la variable age
completeFun <- function(data, desiredCols) {
  completeVec <- complete.cases(data[, desiredCols])
  return(data[completeVec, ])
}
clients_pie <- completeFun(clients, "age_cut")


nb1 <- count(filter(clients_pie, age_cut == "(18,40]"))
nb2 <- count(filter(clients_pie, age_cut == "(40,60]"))
nb3 <- count(filter(clients_pie, age_cut == "(60,80]"))
nb4 <- count(filter(clients_pie, age_cut == "(80,100]"))

slices <- c(as.numeric(nb1), as.numeric(nb2), as.numeric(nb3), as.numeric(nb4))
str(slices)
lbls <- c("18 et 40 ans : ", "40 et 60 ans : ", "60 et 80 ans : ", "80 et 100 ans : ")
pct <- round(slices/sum(slices)*100)
lbls <- paste(lbls, pct) # add percents to labels
lbls <- paste(lbls,"%",sep="") # ad % to labels
pie(slices, labels = lbls, col=rainbow(length(lbls)),
    main="R�partition de l'�ge des clients")


clients <- subset(clients, select = -age_cut)
# ----------------------------------------------------------------------- #

# ----------------------------------------------------------------------- #
#distribution de la variable age
nbRowEA <- round(nrow(clients)*(2/3))
clients_age_EA <- clients[1:nbRowEA,]
clients_age_ET <- clients[(nbRowEA+1):42368,]

boxplot(clients_age_EA$age, main="Distribution dans l'ensemble d'apprentissage") 
boxplot(clients_age_ET$age, main="Distribution dans l'ensemble de test") 
#On constate aucune diff�rence significative entre les distributions des valeurs de la variable Age entre les deux ensembles

#plus le clients est ag�, plus il a un taux d'entemment elev� ? 
#faux ! pas de corr�lation entre l'age et le taux car coefficient de corr�lation proche de 0
cor(clients$age, clients$taux, method="pearson")

#plus la voiture est chere, plus sa puissance est �lev� ? 
#vrai ! corr�lation entre le prix et la puissance de la voiture car coeff de corr�lation proche de 1 : 0.87
cor(catalogue$puissance, catalogue$prix, method="pearson")
ggplot(catalogue, aes(x=prix, y=puissance)) + geom_point(aes(size=puissance))

#Les clients ayant un taux d'endettement �lev� sont plus susceptible d'avoir une deuxi�me voiture : 
#Non, nous constatons que la majeur partie des clients poss�dant une deuxi�me voiture ont un t.e de 5xx euros.
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
     main = "Nombre de clients poss�dant une deuxi�me voiture selon leur taux d'endettement")
# ----------------------------------------------------------------------- #

#---------------------------------------------#
# 2 Identificaton des cat�gories de v�hicules #
#---------------------------------------------#
#Crit�res �tablit en fonction des r�sultats trouv�s sur largus.fr, pour chaque mod�le de v�hicule du fichier Catalogue.csv
#Une diff�renciation pour le mod�le Audi A2 1.4 qui est qualifi� de monospace (malgr� sa courte longueur) sur largus.fr et de citadine par notre mod�le
#https://www.largus.fr/fiche-technique/Audi/A2/I/2002/Monospace+5+Portes/14+75+Reference-708362.html

#Le prix n'est pas entr� dans les crit�res car en fonction des marques haut de gamme (exemple Mercedes) 
#le prix moyen d'une compacte toutes marques confondues peut �tre �quivalent � un prix d'une citadine chez Mercedes

#les citadines : puissance inf�rieure � 90 CV || longueur : courte 
#les compactes : puissance superieure � 90 CV || longueur : courte ou moyenne 
#les sportives : puissance sup�rieure � 300 CV
#les familiales : nb de place > 5, || longueur : longue, tr�s longue
#les berlines : puissance : entre 100 et 300 CV || longueur : longue, tr�s longue

catalogue$categorie = ifelse(catalogue$puissance<90 & catalogue$longueur == "courte", "citadine",
                             ifelse(catalogue$puissance>300 , "sportive",
                                    ifelse(catalogue$longueur == "moyenne" | catalogue$longueur == "courte" & catalogue$puissance>=90  , "compacte",
                                           ifelse(catalogue$nbPlaces>5 & (catalogue$longueur == "longue" | catalogue$longueur == "tr�s longue"), "familiale",
                                                  ifelse(catalogue$puissance>=100 & catalogue$puissance<=300 & (catalogue$longueur == "longue" | catalogue$longueur == "tr�s longue"), "berline", "autre"
                                                  )
                                           )
                                    )
                             )
)

table(catalogue$categorie)
write.table(catalogue, file="catalogue_and_categorie.csv", sep = "\t",  dec = ".",  row.names = F)
#On peut constater sur le nuage de points que les cat�gories de voitures peuvent se distinguer par le prix et puissance
ggplot(catalogue, aes(x=categorie, y=prix)) + geom_jitter(aes(size=puissance))

#------------------------------------------------------------------------------------#
# 3 Application des cat�gories de v�hicules d�finies au donn�es des Immatriculations #
#------------------------------------------------------------------------------------#

immatriculations$categorie = ifelse(immatriculations$puissance<90 & immatriculations$longueur == "courte", "citadine",
                                    ifelse(immatriculations$puissance>300, "sportive",
                                           ifelse(immatriculations$longueur == "moyenne" | immatriculations$longueur == "courte" & immatriculations$puissance>=90  , "compacte",
                                                  ifelse(immatriculations$nbPlaces>5 & (immatriculations$longueur == "longue" | immatriculations$longueur == "tr�s longue"), "familiale",
                                                         ifelse(immatriculations$puissance>=100 & immatriculations$puissance<=300 & 
                                                                  (immatriculations$longueur == "longue" | immatriculations$longueur == "tr�s longue"), "berline", "autre"
                                                         )
                                                  )
                                           )
                                    )
                              )

str(immatriculations)
#-------------------------------------------------#
# 4 Fusion des donn�es Clients et Immatriculation #
#-------------------------------------------------#
#Selection des colonnes de la table immatratriculation, utiles � la jointure : immatriculation et categorie
immatriculations_join <- select(immatriculations, immatriculation, categorie)
#Jointure des tables immatriculations_join et clients par la colonne commune immatriculation
clients_categorie <- inner_join(clients,immatriculations_join, by="immatriculation")
str(clients_categorie$categorie)

#O ligne selectionn� car pas de voiture avec nbPlaces > 5 dans immatriculations 
count(filter(clients_categorie, categorie == "familiale"))


# ----------------------------------------------------------------------- #
#Les personnes poss�dant une deuxi�me voiture opte principalement pour une sportive ou une citadine.
clients_categorie%>% 
  group_by(categorie, X2eme.voiture)%>% 
  summarise(nb = n()) %>% 
  arrange(desc(nb))
# ----------------------------------------------------------------------- #

#-----------------------------------------------------------------------------------------------------#
# 5 Cr�ation d'un mod�le de classification supervis�e pour la pr�diction de la cat�gorie de v�hicules #
#-----------------------------------------------------------------------------------------------------#
# Creation des ensembles d'apprentissage et de test
clients_categorie_EA <- clients_categorie[1:25519,]
clients_categorie_ET <- clients_categorie[25520:38278,]

clients_categorie_EA <- subset(clients_categorie_EA, select = -immatriculation)
clients_categorie_ET <- subset(clients_categorie_ET, select = -immatriculation)

#----------------------#
# FONCTION CALCUL AUC  #
#----------------------#
calcul_auc <- function(arg1, arg2, arg3) {
  col1 <- arg3[arg1]
  col2 <- 1 - col1
  prob_auc <- data.frame(col1, col2)
  
  categorie <- ifelse(arg3$observed == arg1, arg1, arg2)
  data_auc <- data.frame(categorie)
  
  rf_pred <- prediction(prob_auc[,2], data_auc$categorie)
  rf_auc <- performance(rf_pred, "auc")
  cat(paste("\n ------------", arg1, "---------------- \n"))
  cat(paste("AUC", arg1, " = "), as.character(attr(rf_auc, "y.values")))
  cat("\n -------------------------------------- \n")
  invisible()
}  

#-------------------------#
# ARBRE DE DECISION RPART #
#-------------------------#

# Definition de la fonction d'apprentissage, test et evaluation par courbe ROC
test_rpart <- function(arg1, arg2){
  cat(paste("\n------ARBRE DE DECISION RPART (split=", arg1, ") et (minbucket =", arg2, ")------"))
  # Apprentissage du classifeur
  dt <- rpart(categorie~., clients_categorie_EA, parms = list(split = arg1), control = rpart.control(minbucket = arg2))
  # Tests du classifieur : classe predite
  dt_class <- predict(dt, clients_categorie_ET, type="class")
  
  # Matrice de confusion
  cat("\n\nMatrice de confusion :\n")
  print(table(clients_categorie_ET$categorie, dt_class))
  
  # Test du classifeur : probabilites pour chaque prediction
  predictions <- as.data.frame(predict(dt, clients_categorie_ET, type="prob"))
  predictions$predict <- names(predictions)[1:4][apply(predictions[,1:4], 1, which.max)] 
  predictions$observed <- clients_categorie_ET$categorie
  
  # Courbe ROC
  roc.berline <- roc(ifelse(predictions$observed=="berline", "berline", "non-berline"), as.numeric(predictions$berline)) 
  roc.citadine <- roc(ifelse(predictions$observed=="citadine", "citadine", "non-citadine"), as.numeric(predictions$citadine)) 
  roc.compacte <- roc(ifelse(predictions$observed=="compacte", "compacte", "non-compacte"), as.numeric(predictions$compacte)) 
  roc.sportive <- roc(ifelse(predictions$observed=="sportive", "sportive", "non-sportive"), as.numeric(predictions$sportive)) 
  plot(roc.berline, col = "orange", main = paste("Classifeurs Arbre de d�cision (split : ", arg1, ", minbucket : ", arg2, ")"))
  lines(roc.compacte, col = "red") 
  lines(roc.sportive, col = "green") 
  lines(roc.citadine, col = "blue") 
  
  legend(0.3, 0.4, legend=c("berline", "compacte", "sportive", "citadine"),
         col=c("orange", "red", "green", "blue"), lty=1:2, cex=0.8)
  
  # Calcul de l'AUC et affichage par la fonction cat()
  calcul_auc("berline", "nonberline", predictions)
  calcul_auc("citadine", "noncitadine", predictions)
  calcul_auc("compacte", "noncompacte", predictions)
  calcul_auc("sportive", "nonsportive", predictions)
  
  # Return sans affichage sur la console
  invisible()
}

# Arbres de decision
test_rpart("gini", 10)
test_rpart("gini", 5)
test_rpart("information", 10)
test_rpart("information", 5)

#----------------#
# RANDOM FORESTS #
#----------------#

# Definition de la fonction d'apprentissage, test et evaluation par courbe ROC
test_rf <- function(arg1, arg2){
  cat(paste("\n------RANDOM FORESTS (ntree=", arg1, ") et (mtry =", arg2, ")------"))
  clients_categorie_EA$categorie <- factor(clients_categorie_EA$categorie)
  
  # Apprentissage du classifeur
  rf <- randomForest(categorie~., clients_categorie_EA, ntree = arg1, mtry = arg2)
  
  # Test du classifeur : classe predite
  rf_class <- predict(rf,clients_categorie_ET, type="response")
  
  # Matrice de confusion
  cat("\n\nMatrice de confusion :\n")
  print(table(clients_categorie_ET$categorie, rf_class))
  
  # Test du classifeur : probabilites pour chaque prediction
  predictions <- as.data.frame(predict(rf, clients_categorie_ET, type="prob"))
  predictions$predict <- names(predictions)[1:4][apply(predictions[,1:4], 1, which.max)] 
  predictions$observed <- clients_categorie_ET$categorie
  
  # Courbe ROC
  roc.berline <- roc(ifelse(predictions$observed=="berline", "berline", "non-berline"), as.numeric(predictions$berline)) 
  roc.citadine <- roc(ifelse(predictions$observed=="citadine", "citadine", "non-citadine"), as.numeric(predictions$citadine)) 
  roc.compacte <- roc(ifelse(predictions$observed=="compacte", "compacte", "non-compacte"), as.numeric(predictions$compacte)) 
  roc.sportive <- roc(ifelse(predictions$observed=="sportive", "sportive", "non-sportive"), as.numeric(predictions$sportive)) 
  plot(roc.berline, col = "orange", main = paste("Classifeurs Random Forest (ntree : ", arg1, ", mtry : ", arg2, ")"))
  lines(roc.compacte, col = "red") 
  lines(roc.sportive, col = "green") 
  lines(roc.citadine, col = "blue") 
  
  legend(0.3, 0.4, legend=c("berline", "compacte", "sportive", "citadine"),
         col=c("orange", "red", "green", "blue"), lty=1:2, cex=0.8)
  
  # Calcul de l'AUC et affichage par la fonction cat()
  calcul_auc("berline", "nonberline", predictions)
  calcul_auc("citadine", "noncitadine", predictions)
  calcul_auc("compacte", "noncompacte", predictions)
  calcul_auc("sportive", "nonsportive", predictions)

  # Return sans affichage sur la console
  invisible()
}

# Forets d'arbres decisionnels aleatoires
test_rf(300, 3)
test_rf(200, 3)
test_rf(300, 5)
test_rf(500, 3)
test_rf(500, 5)

#-------------#
# NAIVE BAYES #
#-------------#

# Definition de la fonction d'apprentissage, test et evaluation par courbe ROC
test_nb <- function(arg1, arg2){
  cat(paste("\n------NAIVE BAYES (laplace=", arg1, ") et (usekernel =", arg2, ")------"))
  # Apprentissage du classifeur 
  nb <- naive_bayes(categorie~., clients_categorie_EA, laplace = arg1, usekernel = arg2)
  
  # Test du classifeur : classe predite
  nb_class <- predict(nb, clients_categorie_ET, type="class")
  
  # Matrice de confusion
  cat("\n\nMatrice de confusion :\n")
  print(table(clients_categorie_ET$categorie, nb_class))
  
  # Test du classifeur : probabilites pour chaque prediction
  predictions <- as.data.frame(predict(nb, clients_categorie_ET, type="prob"))
  predictions$predict <- names(predictions)[1:4][apply(predictions[,1:4], 1, which.max)] 
  predictions$observed <- clients_categorie_ET$categorie
  
  # Courbe ROC
  roc.berline <- roc(ifelse(predictions$observed=="berline", "berline", "non-berline"), as.numeric(predictions$berline)) 
  roc.citadine <- roc(ifelse(predictions$observed=="citadine", "citadine", "non-citadine"), as.numeric(predictions$citadine)) 
  roc.compacte <- roc(ifelse(predictions$observed=="compacte", "compacte", "non-compacte"), as.numeric(predictions$compacte)) 
  roc.sportive <- roc(ifelse(predictions$observed=="sportive", "sportive", "non-sportive"), as.numeric(predictions$sportive)) 
  plot(roc.berline, col = "orange", main = paste("Classifieurs bayesiens naiveBayes( (laplace : ", arg1, ", usekernel : ", arg2, ")"))
  lines(roc.compacte, col = "red") 
  lines(roc.sportive, col = "green") 
  lines(roc.citadine, col = "blue") 
  
  legend(0.3, 0.4, legend=c("berline", "compacte", "sportive", "citadine"),
         col=c("orange", "red", "green", "blue"), lty=1:2, cex=0.8)
  
  # Calcul de l'AUC et affichage par la fonction cat()
  calcul_auc("berline", "nonberline", predictions)
  calcul_auc("citadine", "noncitadine", predictions)
  calcul_auc("compacte", "noncompacte", predictions)
  calcul_auc("sportive", "nonsportive", predictions)
  
  # Return sans affichage sur la console
  invisible()
}

# Naive Bayes
test_nb(20, FALSE)
test_nb(0, TRUE)
test_nb(20, TRUE)
test_nb(0, FALSE)



#---------------------#
# K-NEAREST NEIGHBORS #
#---------------------#

# Definition de la fonction d'apprentissage, test et evaluation par courbe ROC
test_knn <- function(arg1, arg2){
  cat(paste("\n------K-NEAREST NEIGHBORS (k=", arg1, ") et (distance =", arg2, ")------"))
  # Apprentissage et test simultanes du classifeur de type k-nearest neighbors
  clients_categorie_EA$categorie <- factor(clients_categorie_EA$categorie)
  
  knn <- kknn(categorie~., clients_categorie_EA, clients_categorie_ET, k = arg1, distance = arg2)
  
  # Matrice de confusion
  cat("\n\nMatrice de confusion :\n")
  print(table(clients_categorie_ET$categorie, knn$fitted.values))
  
  # Test du classifeur : probabilites pour chaque prediction
  predictions <- as.data.frame(predict(knn, clients_categorie_ET, type="prob"))
  predictions$predict <- names(predictions)[1:4][apply(predictions[,1:4], 1, which.max)] 
  predictions$observed <- clients_categorie_ET$categorie
  
  # Courbe ROC
  roc.berline <- roc(ifelse(predictions$observed=="berline", "berline", "non-berline"), as.numeric(predictions$berline)) 
  roc.citadine <- roc(ifelse(predictions$observed=="citadine", "citadine", "non-citadine"), as.numeric(predictions$citadine)) 
  roc.compacte <- roc(ifelse(predictions$observed=="compacte", "compacte", "non-compacte"), as.numeric(predictions$compacte)) 
  roc.sportive <- roc(ifelse(predictions$observed=="sportive", "sportive", "non-sportive"), as.numeric(predictions$sportive)) 
  plot(roc.berline, col = "orange", main = paste("Classifieurs K-NEAREST NEIGHBORS ( k : ", arg1, ", distance : ", arg2, ")"))
  lines(roc.compacte, col = "red") 
  lines(roc.sportive, col = "green") 
  lines(roc.citadine, col = "blue") 
  
  legend(0.3, 0.4, legend=c("berline", "compacte", "sportive", "citadine"),
         col=c("orange", "red", "green", "blue"), lty=1:2, cex=0.8)
  
  # Calcul de l'AUC et affichage par la fonction cat()
  calcul_auc("berline", "nonberline", predictions)
  calcul_auc("citadine", "noncitadine", predictions)
  calcul_auc("compacte", "noncompacte", predictions)
  calcul_auc("sportive", "nonsportive", predictions)
  
  # Return sans affichage sur la console
  invisible()
}

# K plus proches voisins
test_knn(10, 1)
test_knn(10, 2)
test_knn(20, 1)
test_knn(20, 2)


#-------------------------------------------------------------#
# 6 Application du mod�le de pr�diction aux donn�es Marketing #
#-------------------------------------------------------------#
#Classifieur le plus performant choisi : Random Forest > ntry : 500 mtry : 3
marketing <- read.csv("Marketing.csv", header = TRUE, sep = ",", dec = ".")
clients_categorie_EA$categorie <- factor(clients_categorie_EA$categorie)
rf <- randomForest(categorie~., clients_categorie_EA, ntree = 500, mtry = 3)
# Test du classifeur : classe predite
rf_class <- predict(rf,marketing, type="response")
marketing$predict_categorie <- rf_class
write.table(marketing, file="marketing_prediction.csv", sep = ";",  dec = ".",  row.names = F)

#Autre classifieur pour comparaison
marketing_rpart <- read.csv("Marketing.csv", header = TRUE, sep = ",", dec = ".")
dt <- rpart(categorie~., clients_categorie_EA, parms = list(split = "gini"), control = rpart.control(minbucket = 10))
dt_class <- predict(dt, marketing_rpart, type="class")
marketing_rpart$predict_categorie <- dt_class

#On constate 2 differences de prediction
#Pour les individus de la ligne 3 et 9
#La pr�diction pour l'algo rpart est compacte pour les 2 individus 
#La prediction pour l'algo random forest est citadine pour les 2 individus