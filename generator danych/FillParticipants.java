import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Random;
import java.util.stream.Collectors;

public class Shuffler {

    static String randomPhone() {
        String phone = "";
        Random r = new Random();
        for(int i = 0; i < 9; i++) {
            phone = phone.concat(Character.toString((char) (r.nextInt(9) + 49)));
        }
        return phone;
    }

    static String randomEmail() {
        String allowedChars = "abcdefghijklmnopqrstuvwxyz0123456789";
        String email = "";
        Random r = new Random();
        int length = r.nextInt(8) + 6;
        for(int i = 0; i < length; i++) {
            email = email.concat(Character.toString(allowedChars.charAt(r.nextInt(allowedChars.length()))));
        }
        return email + "@example.com";
    }

    public static void main(String ... args) throws IOException {

        Path c = Path.of("C:\\Program Files (x86)\\Red Gate\\SQL Data Generator 4\\Config\\NamesFirst.txt");
        Path s = Path.of("C:\\Program Files (x86)\\Red Gate\\SQL Data Generator 4\\Config\\NamesLast.txt");
        Path p = Path.of("C:\\Users\\Lenovo\\Desktop\\AGH\\nauka\\Sem 3\\Bazy Danych\\projekt\\generator danych\\participantids.txt");
        Path out = Path.of("C:\\Users\\Lenovo\\Desktop\\AGH\\nauka\\Sem 3\\Bazy Danych\\projekt\\generator danych\\res2.sql");

        List<String> firstNames = Files.lines(c).collect(Collectors.toList());
        List<String> lastNames = Files.lines(s).collect(Collectors.toList());
        List<String> participantIds = Files.lines(p).collect(Collectors.toList());
        Random r = new Random();

        try(FileWriter fw = new FileWriter(out.toFile(), true);
            BufferedWriter bw = new BufferedWriter(fw);
            PrintWriter outt = new PrintWriter(bw)) {
            for (String participantId : participantIds) {
                outt.println("update Participants set FirstName = '" + firstNames.get(r.nextInt(firstNames.size())) + "', " +
                        "LastName = '" + lastNames.get(r.nextInt(lastNames.size())) + "', Phone = '" + randomPhone() +
                        "', Email = '" + randomEmail() + "' where LastName is null and ParticipantID = " + participantId + "\ngo");
            }

        } catch(IOException e) {
            e.printStackTrace();
        }

    }

}
