import java.io.BufferedReader;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class dataCheckError {
    public static void main(String[] args) throws Exception {

        List<String> split = new ArrayList<String>();
        int ageTest = 0;
        String sexeTest;
        String booleanTest = "";
        List<String> situationFamilialePossibilites = new ArrayList<>();
        situationFamilialePossibilites.add("En Couple");
        situationFamilialePossibilites.add("Seule");
        situationFamilialePossibilites.add("Célibataire");
        situationFamilialePossibilites.add("Marié(e)");
        situationFamilialePossibilites.add("Divorcée");
        int nbEnfantsACharge = 0;

        try (BufferedReader br = Files.newBufferedReader(Paths.get("ARemplacerParLeCheminAbsoluDuFichier"), StandardCharsets.ISO_8859_1)) {
            br.readLine();
            for (String line = null; (line = br.readLine()) != null; ) {
                split = Arrays.asList(line.split(","));

                try {
                    ageTest = Integer.parseInt(split.get(0));
                    Integer.parseInt(split.get(2));
                    nbEnfantsACharge = Integer.parseInt(split.get(4));
                } catch (NumberFormatException e) {
                    System.out.println(e);
                }

                if (ageTest < 0 || ageTest > 200)
                    // if (ageTest != -1) ou égale à " " et "?"
                    System.out.println("error age" + ageTest);

                sexeTest = split.get(1);
                if (!sexeTest.equals("F") && !sexeTest.equals("H"))
                    /* if (!sexeTest.equals("M")
                            && !sexeTest.equals("Homme")
                            && !sexeTest.equals("?")
                            && !sexeTest.equals("Femme")
                            && !sexeTest.equals("Masculin")
                            && !sexeTest.equals("N/D")
                            && !sexeTest.equals("Féminin")
                            && !sexeTest.trim().isEmpty())*/
                    System.out.println("error sexe " + sexeTest);


                if (!situationFamilialePossibilites.contains(split.get(3)))
                    if (!split.get(3).equals("Seul"))
                        //if(!split.get(3).equals("N/D") && !split.get(3).equals("?") && !split.get(3).trim().isEmpty())
                        System.out.println("error situation famiale" + split.get(3));


                if (nbEnfantsACharge < 0 || nbEnfantsACharge > 100)
                    //if (nbEnfantsACharge != -1) ou égale à " " et "?"
                    System.out.println("error nb enfants " + nbEnfantsACharge);


                booleanTest = split.get(5);
                if (!booleanTest.equals("false") && !booleanTest.equals("true"))
                    //if (!booleanTest.equals("?") && !booleanTest.trim().isEmpty())
                    System.out.println("error 2eme voiture " + booleanTest);


                if (split.get(6).length() < 8 || split.get(6).length() > 10)
                    System.out.println("error immatriculation " + split.get(6));

            }
        }
    }
}
