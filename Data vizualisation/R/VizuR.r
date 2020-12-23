#https://www.r-graph-gallery.com/

#https://jsfiddle.net/amenin/qscraok2/1/


setwd("D:/Documents/MIAGE/M2/TPA_BIGDATA/Groupe_TPT_1/data")

install.packages('tidyverse')
install.packages("scales")
install.packages("dplyr")
install.packages("jsonlite")



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
str(clients_0)
clients_0$taux <- as.numeric(as.character(clients_0$taux))
clients_0 <- clients_0 %>% filter(age >= 18 & age <= 84) %>%
  filter(nbEnfantsAcharge >= 0 &nbEnfantsAcharge <= 4) %>%
  filter(taux >= 544 & taux <= 74185)

##Immatriculations
immatriculations = immatriculations[,-1]
str(immatriculations)

imma_diffMarque <- as.data.frame(table(immatriculations$marque))
imma_diffMarque <- imma_diffMarque %>% arrange(Freq)
imma_diffMarqueMoinsVendu <- imma_diffMarque[0:10,]
imma_diffMarque <- imma_diffMarque %>% arrange(desc(Freq))
imma_diffMarque <- imma_diffMarque[0:10,]
imma_diffMarque$Var1 <- factor(imma_diffMarque$Var1, level = imma_diffMarque$Var1)
imma_diffMarqueMoinsVendu$Var1 <- factor(imma_diffMarqueMoinsVendu$Var1, level = imma_diffMarqueMoinsVendu$Var1)
str(imma_diffMarque)

imma_diffPrix <- as.data.frame(table(immatriculations$prix))
imma_diffPrix <- imma_diffPrix %>% arrange(desc(Freq))
imma_diffPrix <- imma_diffPrix[0:10,]


##Clients
## join client et immatriculations

client_join <- clients_0 %>% left_join(immatriculations, by=c("immatriculation"="immatriculation"))


client_groupBy <- client_join %>% mutate(number = 1) %>% group_by(age, nbEnfantsAcharge) %>% 
  summarise(number = sum(number), prix = sum(prix))  %>% 
  mutate(price_average = prix/number)



##JSON LITE

write_json(clients_0, "data_client.json")
write_json(client_groupBy, "data_client_groupby.json")
write_json(imma_diffMarque, "data_marquevendu.json")




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
