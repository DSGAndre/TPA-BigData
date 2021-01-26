package loaders;

import oracle.kv.KVStore;
import java.util.List;
import java.util.Iterator;
import oracle.kv.KVStoreConfig;
import oracle.kv.KVStoreFactory;
import oracle.kv.FaultException;
import oracle.kv.StatementResult;
import oracle.kv.table.TableAPI;
import oracle.kv.table.Table;
import oracle.kv.table.Row;
import oracle.kv.table.PrimaryKey;
import oracle.kv.ConsistencyException;
import oracle.kv.RequestTimeoutException;
import java.lang.Integer;
import oracle.kv.table.TableIterator;
import oracle.kv.table.EnumValue;
import java.io.File;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.PrintWriter;

import java.util.StringTokenizer;
import java.util.ArrayList;
import java.util.List;



/**
 * Executing this class with load the data into the Oracle NoSQL DB.
 */
public class OracleNoSQLDataLoader {
    private final KVStore store;
    private final String tabCustomersName = "CUSTOMER_GROUPE1_2020";
    private final String tabCatalogueName = "CATALOGUE_GROUPE1_2020";
    private final String tabRegistrationName = "REGISTRATION_GROUPE1_2020";

    public static void main(String args[]) {
        try {
            OracleNoSQLDataLoader dL = new OracleNoSQLDataLoader();
            dL.initTables();
            dL.loadCustomerDataFromFile(args[0]);
            dL.loadCarDataFromFile(args[1], true);
            dL.loadCarDataFromFile(args[2], false);
        } catch (RuntimeException e) {
            e.printStackTrace();
        }
    }

    public OracleNoSQLDataLoader() {
        this.store = KVStoreFactory.getStore(new KVStoreConfig("kvstore", "localhost:5000"));
    }


    /**
     * Execute DDL commands
     * @param statement
     */
    public void executeDDL(String statement) {
        TableAPI tableAPI = store.getTableAPI();
        try {
            StatementResult result = store.executeSync(statement);
            displayLogs(result, statement);
        } catch (IllegalArgumentException e) {
            System.out.println("Invalid statement:\n" + e.getMessage());
        } catch (FaultException e) {
            System.out.println("Statement couldn't be executed, please retry: " + e);
        }
    }


    /**
     * Display logs for the DDL commands (CREATE, ALTER, DROP)
     */
    private void displayLogs(StatementResult result, String statement) {
        System.out.println("===========================");
        if (result.isSuccessful()) {
            System.out.println("Statement was successful:\n\t" +
                    statement);
            System.out.println("Results:\n\t" + result.getInfo());
        } else if (result.isCancelled()) {
            System.out.println("Statement was cancelled:\n\t" +
                    statement);
        } else {
            /*
             * statement was not successful: may be in error, or may still
             * be in progress.
             */
            if (result.isDone()) {
                System.out.println("Statement failed:\n\t" + statement);
                System.out.println("Problem:\n\t" +
                        result.getErrorMessage());
            }
            else {
                System.out.println("Statement in progress:\n\t" +
                        statement);
                System.out.println("Status:\n\t" + result.getInfo());
            }
        }
    }

    /**
     * Init tables : drop and create tables.
     */
    public void initTables() {
        this.dropTableCustomers();
        this.dropTableCatalogue();
        this.dropTableRegistration();
        this.createTableCustomer();
        this.createTableCatalogue();
        this.createTableRegistration();
    }

    /**
     * Drop the table for the customers.
     */
    public void dropTableCustomers() {
        String statement = null;

        statement ="drop table " + this.tabCustomersName;
        executeDDL(statement);
    }

    /**
     * Drop the table for the catalogue.
     */
    public void dropTableCatalogue() {
        String statement = null;

        statement ="drop table "+ this.tabCatalogueName;
        executeDDL(statement);
    }

    /**
     * Drop the table for the registrations.
     */
    public void dropTableRegistration() {
        String statement = null;

        statement ="drop table "+ this.tabRegistrationName;
        executeDDL(statement);
    }

    /**
     * Create the table for the customers.
     */
    public void createTableCustomer() {
        String statement = null;
        statement="Create table " + this.tabCustomersName +" ("
                + "id INTEGER,"
                + "age INTEGER,"
                + "sexe ENUM(M,F, undefined),"
                + "rate INTEGER,"
                + "familystatus ENUM(en_couple, celibataire, seule, marie_e, divorce_e, undefined),"
                + "nbofchildren INTEGER,"
                + "secondcar BOOLEAN,"
                + "registration STRING,"
                + "PRIMARY KEY (id))";
        System.out.println(statement);
        executeDDL(statement);
    }

    /**
     * Drop the table for the catalogue.
     */
    public void createTableCatalogue() {
        String statement = null;
        statement="Create table " + this.tabCatalogueName +" ("
                + "id INTEGER,"
                + "brand STRING,"
                + "name STRING,"
                + "power INTEGER,"
                + "length ENUM(courte, moyenne, longue, tres_longue, undefined),"
                + "nbofseats INTEGER,"
                + "nbofdoors INTEGER,"
                + "color STRING,"
                + "secondhandcar BOOLEAN,"
                + "price INTEGER,"
                + "PRIMARY KEY (id))";
        executeDDL(statement);
    }

    /**
     * Drop the table for the registrations.
     */
    public void createTableRegistration() {
        String statement = null;
        statement="Create table " + this.tabRegistrationName +" ("
                + "id INTEGER,"
                + "registration STRING,"
                + "brand STRING,"
                + "name STRING,"
                + "power INTEGER,"
                + "length ENUM(courte, moyenne, longue, tres_longue, undefined),"
                + "nbofseats INTEGER,"
                + "nbofdoors INTEGER,"
                + "color STRING,"
                + "secondhandcar BOOLEAN,"
                + "price INTEGER,"
                + "PRIMARY KEY (id))";
        executeDDL(statement);
    }

    /**
     * Insert a row in the table for the customers.
     */
    private void insertCustomerRow(
            int id,
            int age,
            String sexe,
            int rate,
            String familystatus,
            int nbofchildren,
            boolean secondcar,
            String registration
    ){
        StatementResult result = null;
        String statement = null;
        System.out.println("********************************** insertCustomerRow *********************************" );

        try {

            TableAPI tableH = store.getTableAPI();
            Table tableCustomers = tableH.getTable(this.tabCustomersName);
            Row customersRow = tableCustomers.createRow();

            customersRow.put("id", id);
            customersRow.put("age", age);
            switch (sexe) {
                case "Masculin":
                case "Homme":
                case "M":
                    customersRow.putEnum("sexe", "M");
                    break;
                case "Féminin":
                case "Femme":
                case "F":
                    customersRow.putEnum("sexe", "F");
                    break;
                default:
                    customersRow.putEnum("sexe", "undefined");
            }
            customersRow.put("rate", rate);
            switch (familystatus) {
                case "Mari�(e)":
                    customersRow.putEnum("familystatus", "marie_e");
                    break;
                case "Divorc�":
                case "Divorc�e":
                    customersRow.putEnum("familystatus", "divorce_e");
                    break;
                case "En Couple":
                    customersRow.putEnum("familystatus", "en_couple");
                    break;
                case "C�libataire":
                case "Seule":
                case "Seul":
                    customersRow.putEnum("familystatus", "celibataire");
                    break;
                default:
                    customersRow.putEnum("familystatus", "undefined");
            }
            customersRow.put("nbofchildren", nbofchildren);
            customersRow.put("secondcar", secondcar);
            customersRow.put("registration", registration);

            tableH.put(customersRow, null, null);
        }
        catch (IllegalArgumentException e) {
            System.out.println("Invalid statement:\n" + e.getMessage());
        }
        catch (FaultException e) {
            System.out.println("Statement couldn't be executed, please retry: " + e);
        }
    }

    /**
     * Insert a row in the table for the catalogue.
     */
    private void insertCatalogueRow(
            int id,
            String brand,
            String name,
            int power,
            String length,
            int nbofseats,
            int nbofdoors,
            String color,
            boolean secondhandcar,
            int price
    ){
        StatementResult result = null;
        String statement = null;
        System.out.println("********************************** insertCatalogueRow *********************************" );

        try {
            TableAPI tableH = store.getTableAPI();
            Table tableCatalogue = tableH.getTable(this.tabCatalogueName);
            Row catalogueRow = tableCatalogue.createRow();

            catalogueRow.put("id", id);
            catalogueRow.put("brand", brand);
            catalogueRow.put("name", name);
            catalogueRow.put("power", power);
            if (length.equals("tr�s longue")) {
                catalogueRow.putEnum("length", "tres_longue");
            } else {
                catalogueRow.putEnum("length", length);
            }
            catalogueRow.put("nbofseats", nbofseats);
            catalogueRow.put("nbofdoors", nbofdoors);
            catalogueRow.put("color", color);
            catalogueRow.put("secondhandcar", secondhandcar);
            catalogueRow.put("price", price);

            tableH.put(catalogueRow, null, null);
        }
        catch (IllegalArgumentException e) {
            System.out.println("Invalid statement:\n" + e.getMessage());
        }
        catch (FaultException e) {
            System.out.println("Statement couldn't be executed, please retry: " + e);
        }
    }

    /**
     * Insert a row in the table for the registrations.
     */
    private void insertRegistrationRow(
            int id,
            String registration,
            String brand,
            String name,
            int power,
            String length,
            int nbofseats,
            int nbofdoors,
            String color,
            boolean secondhandcar,
            int price
    ){
        StatementResult result = null;
        String statement = null;
        System.out.println("********************************** insertRegistrationRow *********************************" );

        try {
            TableAPI tableH = store.getTableAPI();
            Table tableRegistration = tableH.getTable(this.tabRegistrationName);
            Row registrationRow = tableRegistration.createRow();

            registrationRow.put("id", id);
            registrationRow.put("registration", registration);
            registrationRow.put("brand", brand);
            registrationRow.put("name", name);
            registrationRow.put("power", power);
            if (length.equals("tr�s longue")) {
                registrationRow.putEnum("length", "tres_longue");
            } else {
                registrationRow.putEnum("length", length);
            }
            registrationRow.put("nbofseats", nbofseats);
            registrationRow.put("nbofdoors", nbofdoors);
            registrationRow.put("color", color);
            registrationRow.put("secondhandcar", secondhandcar);
            registrationRow.put("price", price);

            tableH.put(registrationRow, null, null);
        }
        catch (IllegalArgumentException e) {
            System.out.println("Invalid statement:\n" + e.getMessage());
        }
        catch (FaultException e) {
            System.out.println("Statement couldn't be executed, please retry: " + e);
        }
    }

    /**
     * Load customers data from a file's path given as parameter.
     */
    void loadCustomerDataFromFile(String customerDataFileName){
        InputStreamReader 	ipsr;
        BufferedReader 		br=null;
        InputStream 		ips;
        String line;
        int id = -1;

        System.out.println("********************************** loading customers' data from " + customerDataFileName + "... *********************************");

        /* parcourir les lignes du fichier texte et découper chaque ligne */
        try {
            ips  = new FileInputStream(customerDataFileName);
            ipsr = new InputStreamReader(ips);
            br   = new BufferedReader(ipsr);
            br.readLine();

            while ((line = br.readLine()) != null) {
                ArrayList<String> customerRecord= new ArrayList<String>();
                StringTokenizer val = new StringTokenizer(line,",");
                while(val.hasMoreTokens()) {
                    customerRecord.add(val.nextToken().toString());
                }

                int age;
                if (this.isDataInvalid(customerRecord.get(0))) {
                    age = -1;
                } else {
                    age = Integer.parseInt(customerRecord.get(0));
                }

                String sexe = customerRecord.get(1);

                int taux;
                if (this.isDataInvalid(customerRecord.get(2))) {
                    taux = -1;
                } else {
                    taux = Integer.parseInt(customerRecord.get(2));
                }

                String familyStatus = customerRecord.get(3);

                int nbOfChildren;
                if (this.isDataInvalid(customerRecord.get(4))) {
                    nbOfChildren = -1;
                } else {
                    nbOfChildren = Integer.parseInt(customerRecord.get(4));
                }

                boolean secondCar;
                if (this.isDataInvalid(customerRecord.get(5))) {
                    secondCar = false;
                } else {
                    secondCar = Boolean.parseBoolean(customerRecord.get(5));
                }

                String registration;
                if (this.isDataInvalid(customerRecord.get(6))) {
                    registration = "undefined";
                } else {
                    registration = customerRecord.get(6);
                }
                // Add the customer in the KVStore
                this.insertCustomerRow(++id, age, sexe, taux, familyStatus, nbOfChildren, secondCar, registration);
            }
        }
        catch(Exception e){
            e.printStackTrace();
        }
    }

    /**
     * Load catalogue or registrations data from a file's path given as parameter.
     */
    void loadCarDataFromFile(String catalogueDataFileName, boolean isCatalogueTyped){
        InputStreamReader 	ipsr;
        BufferedReader 		br=null;
        InputStream 		ips;
        String line;
        int id = -1;

        System.out.println("********************************** loading catalogue data from " + catalogueDataFileName + "... *********************************");

        /* parcourir les lignes du fichier texte et découper chaque ligne */
        try {
            ips  = new FileInputStream(catalogueDataFileName);
            ipsr = new InputStreamReader(ips);
            br   = new BufferedReader(ipsr);
            br.readLine();

            while ((line = br.readLine()) != null) {
                ArrayList<String> carRecord= new ArrayList<String>();
                StringTokenizer val = new StringTokenizer(line,",");
                while(val.hasMoreTokens()) {
                    carRecord.add(val.nextToken().toString());
                }
                int index = -1;
                String registration = "";

                if(!isCatalogueTyped) {
                    if (this.isDataInvalid(carRecord.get(++index))) {
                        registration = "undefined";
                    } else {
                        registration = carRecord.get(index);
                    }
                }

                String brand;
                if (this.isDataInvalid(carRecord.get(++index))) {
                    brand = "undefined";
                } else {
                    brand = carRecord.get(index);
                }

                String name;
                if (this.isDataInvalid(carRecord.get(++index))) {
                    name = "undefined";
                } else {
                    name = carRecord.get(index);
                }

                int power;
                if (this.isDataInvalid(carRecord.get(++index))) {
                    power = -1;
                } else {
                    power = Integer.parseInt(carRecord.get(index));
                }

                String length;
                if (this.isDataInvalid(carRecord.get(++index))) {
                    length = "undefined";
                } else {
                    length = carRecord.get(index);
                }

                int nbOfSeats;
                if (this.isDataInvalid(carRecord.get(index))) {
                    nbOfSeats = -1;
                } else {
                    nbOfSeats = Integer.parseInt(carRecord.get(++index));
                }

                int nbOfDoors;
                if (this.isDataInvalid(carRecord.get(++index))) {
                    nbOfDoors = -1;
                } else {
                    nbOfDoors = Integer.parseInt(carRecord.get(index));
                }

                String color;
                if (this.isDataInvalid(carRecord.get(++index))) {
                    color = "undefined";
                } else {
                    color = carRecord.get(index);
                }

                boolean secondHandCar;
                if (this.isDataInvalid(carRecord.get(++index))) {
                    secondHandCar = false;
                } else {
                    secondHandCar = Boolean.parseBoolean(carRecord.get(index));
                }

                int price;
                if (this.isDataInvalid(carRecord.get(++index))) {
                    price = -1;
                } else {
                    price = Integer.parseInt(carRecord.get(index));
                }

                // Add the car data in the KVStore
                if (isCatalogueTyped) {
                    this.insertCatalogueRow(++id, brand, name, power, length, nbOfSeats, nbOfDoors, color, secondHandCar, price);
                } else {
                    this.insertRegistrationRow(++id, registration, brand, name, power, length, nbOfSeats, nbOfDoors, color, secondHandCar, price);
                }
            }
        }
        catch(Exception e){
            e.printStackTrace();
        }
    }

    boolean isDataInvalid(String str) {
        return str.trim().equals("?") || str.trim().isEmpty();
    }
}