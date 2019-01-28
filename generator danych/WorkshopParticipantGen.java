import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.stream.Collectors;

public class Shuffler {

    public static void main(String ... args) throws IOException {

        Path c = Path.of("C:\\Users\\Lenovo\\Desktop\\AGH\\nauka\\Sem 3\\Bazy Danych\\projekt\\generator danych\\workshopids.txt");
        Path s = Path.of("C:\\Users\\Lenovo\\Desktop\\AGH\\nauka\\Sem 3\\Bazy Danych\\projekt\\generator danych\\participantids.txt");
        Path out = Path.of("C:\\Users\\Lenovo\\Desktop\\AGH\\nauka\\Sem 3\\Bazy Danych\\projekt\\generator danych\\res.sql");

        List<String> workshopIds = Files.lines(c).collect(Collectors.toList());
        List<String> participantIds = Files.lines(s).collect(Collectors.toList());

        try(FileWriter fw = new FileWriter(out.toFile(), true);
            BufferedWriter bw = new BufferedWriter(fw);
            PrintWriter outt = new PrintWriter(bw)) {
            for (int i = 0; i < workshopIds.size(); i++) {
                outt.println("insert into WorkshopParticipants (ConferenceDayParticipantID, ConferenceDayWorkshopID) values (" +
                        participantIds.get(i) + ", " + workshopIds.get(i) + ")\ngo");
            }

        } catch(IOException e) {
            e.printStackTrace();
        }

    }

}