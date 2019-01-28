import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.text.DecimalFormat;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Random;
import java.util.stream.Collectors;

public class Shuffler {

    public static void main(String ... args) throws IOException {

        Path c = Path.of("C:\\Users\\Lenovo\\Desktop\\AGH\\nauka\\Sem 3\\Bazy Danych\\projekt\\generator danych\\createdates.txt");
        Path s = Path.of("C:\\Users\\Lenovo\\Desktop\\AGH\\nauka\\Sem 3\\Bazy Danych\\projekt\\generator danych\\startdates.txt");
        Path cid = Path.of("C:\\Users\\Lenovo\\Desktop\\AGH\\nauka\\Sem 3\\Bazy Danych\\projekt\\generator danych\\confids.txt");
        DateTimeFormatter dtf = DateTimeFormatter.ofPattern("yyyy-MM-dd");
        List<String> conferenceIds = Files.lines(cid).collect(Collectors.toList());
        List<LocalDate> createDates = Files.lines(c).map(d -> LocalDate.from(dtf.parse(d))).collect(Collectors.toList());
        List<LocalDate> startDates = Files.lines(s).map(d -> LocalDate.from(dtf.parse(d))).collect(Collectors.toList());

        Random r = new Random();

        for(int i = 0; i < conferenceIds.size(); i++) {
            LocalDate createdOn = createDates.get(i).minusDays(1);
            LocalDate startOn = startDates.get(i);
            String conferenceId = conferenceIds.get(i);
            System.out.println("insert into ConferencePricetables (ConferenceID, PriceStartsOn, PriceEndsOn, DiscountRate) " +
                    "values (" + conferenceId + ", '" + dtf.format(createdOn) + "', '" + dtf.format(createdOn) + "', 1)\ngo");
            double currentDiscount = (r.nextDouble() + 1) / 2;
            LocalDate currentEndDiscountDate = createdOn;
            while(currentDiscount > 0) {
                LocalDate newDiscountStart = currentEndDiscountDate.plusDays(1);
                int discountLength = r.nextInt(10) + 7;
                LocalDate newDiscountEnd = newDiscountStart.plusDays(discountLength);
                if(newDiscountEnd.isAfter(startOn.minusDays(1))) break;
                currentDiscount -= r.nextDouble() / 2;
                if(currentDiscount < 0) break;
                System.out.println("insert into ConferencePricetables (ConferenceID, PriceStartsOn, PriceEndsOn, DiscountRate) " +
                        "values (" + conferenceId + ", '" + dtf.format(newDiscountStart) + "', '" + dtf.format(newDiscountEnd) + "', " + currentDiscount + ")");
                System.out.println("go");
                currentEndDiscountDate = newDiscountEnd;
            }
        }

    }

}
