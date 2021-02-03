#https://www.r-graph-gallery.com/

#https://jsfiddle.net/amenin/qscraok2/1/

install.packages('tidyverse')
install.packages("scales")
install.packages("dplyr")
install.packages("jsonlite")


#Onglet Session -> Set working directory -> To source file location
setwd("../data")
getwd()


library(tidyverse)
library(dplyr)
library(scales)
library(jsonlite)



#Chargements des csv
catalogue <- read.csv("Catalogue.csv", header = TRUE, sep = ",", dec = ".")
clients_0 <- read.csv("Clients_0.csv", header = TRUE, sep = ",", dec = ".")
clients_8 <- read.csv("Clients_8.csv", header = TRUE, sep = ",", dec = ".")
co2 <- read.csv("CO2.csv", header = TRUE, sep = ",", dec = ".")
immatriculations <- read.csv("Immatriculations.csv", header = TRUE, sep = ",", dec = ".")
marketing <- read.csv("Marketing.csv", header = TRUE, sep = ",", dec = ".")



#Premier traitement
clients_0$id <- NULL

str(clients_0)
clients_0$taux <- as.numeric(as.character(clients_0$taux))
clients_0$situationFamiliale[clients_0$situationFamiliale == "CÃ©libataire"] <- "Célibataire"
clients_0$situationFamiliale[clients_0$situationFamiliale == "MariÃ©(e)"] <- "Marié(e)"
clients_0 <- clients_0 %>% filter(age >= 18 & age <= 84) %>%
  filter(nbEnfantsAcharge >= 0 &nbEnfantsAcharge <= 4) %>%
  filter(taux >= 544 & taux <= 74185) %>%
  filter(sexe == "F" | sexe == "M") %>%
  filter(situationFamiliale == "Célibataire" | situationFamiliale == "Divorcée" | situationFamiliale == "En Couple" | situationFamiliale == "Marié(e)" | situationFamiliale == "Seul" | situationFamiliale == "Seule")




#str(clients_8)
clients_8$taux <- as.numeric(as.character(clients_8$taux))
clients_8$situationFamiliale[clients_8$situationFamiliale == "CÃ©libataire"] <- "Célibataire"
clients_8$situationFamiliale[clients_8$situationFamiliale == "MariÃ©(e)"] <- "Marié(e)"
clients_8 <- clients_8 %>% filter(age >= 18 & age <= 84) %>%
  filter(nbEnfantsAcharge >= 0 &nbEnfantsAcharge <= 4) %>%
  filter(taux >= 544 & taux <= 74185) %>%
  filter(sexe == "F" | sexe == "M") %>%
  filter(situationFamiliale == "Célibataire" | situationFamiliale == "Divorcée" | situationFamiliale == "En Couple" | situationFamiliale == "Marié(e)" | situationFamiliale == "Seul" | situationFamiliale == "Seule")



clientsCleaned <- rbind(clients_0,clients_8)
str(clientsCleaned)

immatriculationsCleaned <- immatriculations %>% filter(puissance >= 55 & puissance <= 507) %>%
  filter(nbPlaces >= 5 & nbPlaces <= 7) %>%
  filter(nbPortes >= 3 & nbPortes <= 5) %>%
  filter(prix >= 7500 & prix <= 101300)


##Immatriculations
#immatriculationsTest = immatriculations[,-1]
#str(immatriculations)


####
##Voiture plus et moins vendu
##Pie chart plus(imma_diffMarque)/moins(imma_diffMarqueMoinsVendu) vendu
imma_diffMarque <- as.data.frame(table(immatriculations$marque))
imma_diffMarque <- imma_diffMarque %>% arrange(Freq)
imma_diffMarqueMoinsVendu <- imma_diffMarque[0:10,]
imma_diffMarque <- imma_diffMarque %>% arrange(desc(Freq))
imma_diffMarque <- imma_diffMarque[0:10,]
imma_diffMarque$Var1 <- factor(imma_diffMarque$Var1, level = imma_diffMarque$Var1)
imma_diffMarqueMoinsVendu$Var1 <- factor(imma_diffMarqueMoinsVendu$Var1, level = imma_diffMarqueMoinsVendu$Var1)
str(imma_diffMarque)

imma_diffPrix <- as.data.frame(table(immatriculations$prix ))
imma_diffPrix <- imma_diffPrix %>% arrange(desc(Freq))
imma_diffPrix <- imma_diffPrix[0:10,]
##

##Group immatriculations
immaGroup <- immatriculations %>% 
  select(puissance, prix, marque, nom) %>% 
  mutate(number = 1) %>%
  group_by(puissance, prix, marque, nom) %>%
  summarise(number = sum(number))

##
####


####
##
table(immatriculation_client$situationFamiliale)

immatriculation_client <- immatriculationsCleaned %>% left_join(clientsCleaned, by=c("immatriculation"="immatriculation")) %>% 
  mutate(sf_celib = ifelse(situationFamiliale == "Seul" | situationFamiliale == "Seule" | situationFamiliale == "Célibataire", 1, 0)) %>% 
  mutate(sf_divorce = ifelse(situationFamiliale == "Divorcée", 1, 0)) %>% 
  mutate(sf_couple = ifelse(situationFamiliale == "En Couple", 1, 0)) %>% 
  mutate(sf_marie = ifelse(situationFamiliale == "Marié(e)", 1, 0)) %>% 
  mutate(sf_count = ifelse(is.na(situationFamiliale), 0, 1)) %>% 
  mutate(sf_celib = ifelse(is.na(sf_celib), 0, sf_celib))  %>% 
  mutate(sf_divorce = ifelse(is.na(sf_divorce), 0, sf_divorce))  %>% 
  mutate(sf_marie = ifelse(is.na(sf_marie), 0, sf_marie)) %>% 
  mutate(sf_couple = ifelse(is.na(sf_couple), 0, sf_couple)) %>%  
  mutate(age_1831 = ifelse(age >= 18 & age <= 31, 1, 0)) %>%
  mutate(age_3242 = ifelse(age >= 32 & age <= 42, 1, 0)) %>% 
  mutate(age_4359 = ifelse(age >= 43 & age <= 59, 1, 0)) %>% 
  mutate(age_6084 = ifelse(age >= 60 & age <= 84, 1, 0)) %>% 
  mutate(age_1831 = ifelse(is.na(age_1831), 0, age_1831))  %>% 
  mutate(age_3242 = ifelse(is.na(age_3242), 0, age_3242))  %>% 
  mutate(age_4359 = ifelse(is.na(age_4359), 0, age_4359)) %>% 
  mutate(age_6084 = ifelse(is.na(age_6084), 0, age_6084)) 

immatriculation_client_group <- immatriculation_client %>% mutate(number = 1) %>% 
  group_by(puissance, prix, marque, nom) %>% 
  summarise(number = sum(number), sf_celib=sum(sf_celib), sf_divorce=sum(sf_divorce), sf_couple=sum(sf_couple), sf_marie=sum(sf_marie), sf_count=sum(sf_count),  age_1831=sum(age_1831), age_3242=sum(age_3242),age_4359=sum(age_4359), age_6084=sum(age_6084)) 

str(immatriculation_client_group)
##
####


####
##Clients
## join client et immatriculations

client_join_Cleaned <- clientsCleaned %>% inner_join(immatriculationsCleaned, by=c("immatriculation"="immatriculation"))
#client_join_Dirty <- clientsDirty %>% left_join(immatriculations, by=c("immatriculation"="immatriculation"))

client_groupBy <- client_join_Cleaned %>% mutate(number = 1) %>% group_by(age, nbEnfantsAcharge) %>% 
  summarise(number = sum(number), prix = sum(prix))  %>% 
  mutate(price_average = prix/number)

client_join_Cleaned_group <- client_join_Cleaned %>% group_by(age, situationFamiliale, nbEnfantsAcharge, marque, puissance, longueur, nbPlaces, nbPortes, couleur, prix) %>% 
  summarise() 
str(client_join_Cleaned_group)

#Melanger et prendre seulement N lignes
client_join_Cleaned_group_shuffle <- client_join_Cleaned_group[sample(nrow(client_join_Cleaned_group)),]
client_join_Cleaned_group_shuffle <- client_join_Cleaned_group_shuffle[0:4000,]
##
####


####
##JSON LITE

##write_json(clients, "data_client.json")
write_json(client_groupBy, "data_client_groupby.json")
#Pour pie chart : Voiture les plus vendus
write_json(imma_diffMarque, "data_marquevendu.json")
#Modèles de voitures différentes groupées pour sortir le nombre d'unit vendu pour chaque
write_json(immaGroup, "imma_groupby.json")
#Pour parallel  chart : clients regroupés pour sortir les différents modèles achetés par profil différents
write_json(client_join_Cleaned_group, "client_join_Cleaned_group.json")
#Pour parallel chart: shuffle pour ne prendre que N lignes
write_json(client_join_Cleaned_group_shuffle, "client_join_Cleaned_group_shuffle.json")
#Pour bubble chart : différentes marques de voiture avec les différentes tranches d'age et situation familiale associés
write_json(immatriculation_client_group, "immatriculation_client_group.json")

##
####



#pie chart
ggplot(imma_diffMarque, aes(x="", y=Freq, fill=Var1)) +
  geom_bar(stat="identity", width=1, color="white") +
  coord_polar("y", start=0) +
  theme_void()

ggplot(imma_diffPrix, aes(x="", y=Freq, fill=Var1)) +
  geom_bar(stat="identity", width=1, color="white") +
  coord_polar("y", start=0) +
  theme_void()  +
  ggtitle("Proportions des prix des ventes") + 
  labs(y="", x = "")

#bar chart
##Voiture plus vendus
ggplot(imma_diffMarque, aes(x=Var1, y=Freq)) + 
  geom_bar(stat = "identity") + theme_bw() +
  theme(axis.text.x = element_text(angle = 60, hjust = 1)) +
  scale_y_continuous(labels = number_format(scale = 1)) +
  ggtitle("Nombres de voitures vendus (parmis les meilleures ventes)") + 
  labs(y="Nombre d'unites vendues", x = "Marque voiture")

##Voiture moins vendu
ggplot(imma_diffMarqueMoinsVendu, aes(x=Var1, y=Freq)) + 
  geom_bar(stat = "identity") + theme_bw() +
  theme(axis.text.x = element_text(angle = 60, hjust = 1)) +
  scale_y_continuous(labels = number_format(scale = 1)) +
  ggtitle("Nombres de voitures vendus (parmis les moins bonnes ventes)") + 
  labs(y="Nombre d'unites vendues", x = "Marque voiture")


ggplot(client_groupBy, aes(x=nbEnfantsAcharge, y=age, size = price_average)) +
  geom_point(alpha=0.2) 
