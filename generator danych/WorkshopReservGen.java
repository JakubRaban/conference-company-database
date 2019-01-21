import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.util.List;
import java.util.Random;
import java.util.stream.Collectors;

public class Shuffler {

    public static void main(String ... args) throws IOException {

        Path p = Path.of("C:\\Users\\Lenovo\\Desktop\\AGH\\nauka\\Sem 3\\Bazy Danych\\projekt\\generator danych\\dayreservationids.txt");
        List<Integer> reservationIds = Files.lines(p).mapToInt(Integer::parseInt).boxed().collect(Collectors.toList());
        Path w = Path.of("C:\\Users\\Lenovo\\Desktop\\AGH\\nauka\\Sem 3\\Bazy Danych\\projekt\\generator danych\\workshopids.txt");
        List<Integer> workshopIds = Files.lines(w).mapToInt(Integer::parseInt).boxed().collect(Collectors.toList());
        int reservationIdsSize = reservationIds.size();
        int workshopIdsSize = workshopIds.size();

        Random r = new Random();

        for(int i = 0; i < 5000; i++) {
            int seats = r.nextInt(20) + 1;
            int index = r.nextInt(11930);
            int reservationId = reservationIds.get(index);
            int workshopId = workshopIds.get(index);
            StringBuilder sql = new StringBuilder("insert into WorkshopReservation " +
                    "(ConferenceDayWorkshopID, ConferenceDayReservationID, ReservedSeats) values (");
            if (r.nextDouble() > 3.0 / 4.0) {
                seats = 1;
            }
            sql.append(workshopId + ", " + reservationId + ", " + seats + ")");
            sql.append("\ngo");
            System.out.println(sql);
        }

    }

}
