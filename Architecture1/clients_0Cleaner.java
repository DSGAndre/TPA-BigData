import java.io.BufferedReader;
import java.io.IOException;
import java.io.PrintWriter;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.Arrays;
import java.util.List;

public class clients_0Cleaner {

    public static void main(String args[]) throws IOException {
        List<String> split;
        int id;
        int age;
        String sexe;
        int taux;
        String situationFamiliale;
        int nbEnfantsACharge;
        String secondVoiture;
        String immatriculation;
        PrintWriter writer = new PrintWriter("test.csv");
        writer.println("id,age,sexe,taux,situationFamiliale,nbEnfantsAcharge,2eme voiture,immatriculation");
        try (BufferedReader br = Files.newBufferedReader(Paths.get("ARemplacerParLeCheminAbsolu"), StandardCharsets.ISO_8859_1)) {
            br.readLine();
            id = 0;
            for (String line = null; (line = br.readLine()) != null; ) {
                split = Arrays.asList(line.split(","));
                age = checkAge(checkIntCommunsErrors(split.get(0)));
                sexe = checkSexe(checkStringCommunsErrors(split.get(1)));
                taux = checkTaux(checkIntCommunsErrors(split.get(2)));
                situationFamiliale = checkSituationFamilial(checkStringCommunsErrors(split.get(3)));
                nbEnfantsACharge = checkNbEnfantsACharge(checkIntCommunsErrors(split.get(4)));
                secondVoiture = check2EmeVoiture(checkStringCommunsErrors(split.get(5)));
                immatriculation = checkImmatriculation(checkStringCommunsErrors(split.get(6)));
                writer.println(id + "," + age + "," + sexe + "," + taux + "," + situationFamiliale + "," + nbEnfantsACharge + "," + secondVoiture + "," + immatriculation);
                id++;
            }
        }
        writer.close();
    }

    static int checkIntCommunsErrors(String field) {
        if (field.equals("?") || field.trim().isEmpty() || field.equals("-1"))
            return -1;
        else
            return Integer.parseInt(field);
    }

    static String checkStringCommunsErrors(String field) {
        if (field.equals("?") || field.trim().isEmpty() || field.equals("N/D"))
            return "Undefined";
        else
            return field;
    }

    static String checkSexe(String sexe) {
        switch (sexe) {
            case "F":
                return sexe;
            case "Femme":
                return "F";
            case "Féminin":
                return "F";
            case "M":
                return sexe;
            case "H":
                return "M";
            case "Homme":
                return "M";
            case "Masculin":
                return "M";
            default:
                return "Undefined";
        }
    }

    static int checkAge(int age) {
        if (age > 18 && age < 84) {
            return age;
        } else
            return -1;
    }

    static int checkTaux(int taux) {
        if (taux > 544 && taux < 74185) {
            return taux;
        } else
            return -1;
    }

    static String checkSituationFamilial(String situationFamiliale) {

        switch (situationFamiliale) {
            case "Célibataire":
                return situationFamiliale;
            case "Divorcée":
                return situationFamiliale;
            case "En Couple":
                return situationFamiliale;
            case "Marié(e)":
                return situationFamiliale;
            case "Seul":
                return situationFamiliale;
            case "Seule":
                return situationFamiliale;
            default:
                return situationFamiliale;
        }
    }

    static int checkNbEnfantsACharge(int nbEnfantsACharge) {
        if (nbEnfantsACharge >= 0 && nbEnfantsACharge <= 4)
            return nbEnfantsACharge;
        else
            return -1;
    }

    static String check2EmeVoiture(String secondVoiture) {
        if (secondVoiture.equals("true") || secondVoiture.equals("false"))
            return secondVoiture;
        else
            return "Undefined";
    }

    static String checkImmatriculation(String immatriculation) {
        char[] chars = immatriculation.toCharArray();
        if (chars.length != 10)
            return "Undefined";

        String firstPart = "" + chars[0] + chars[1] + chars[2] + chars[3];
        String middlePart = "" + chars[5] + chars[6];
        String lastPart = "" + chars[8] + chars[9];

        if (!firstPart.matches("[0-9]+") && !lastPart.matches("[0-9]+"))
            return "Undefined";


        if (!(chars[4] + "").equals(" ") && !(chars[7] + "").equals(" "))
            return "Undefined";


        if (!middlePart.matches("[a-zA-Z]+"))
            return "Undefined";

        return immatriculation;
    }

}
