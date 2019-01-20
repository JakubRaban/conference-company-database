import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Random;

public class Shuffler {

    public static void main(String ... args) {

        List<String> words = Arrays.asList("Zabawa","Czesto","Nigdy","Czlowiek","Zdrowie","Odpoczynek",
                "Zaufanie", "Prawie", "Zupelnie", "Pewnosc", "Czystosc", "Jednoznacznie", "Praktycznie", "Rower", "Kanibalizm",
                "Z Pomyslem", "Polska", "Reedukacja", "Ciekawie");

        for(int i = 0; i < 1000; i++) {
            int l = new Random().nextInt(4) + 2;
            Collections.shuffle(words);
            StringBuilder sb = new StringBuilder();
            for(int j = 0; j < l; j++) sb.append(words.get(j)).append(" ");
            System.out.println(sb.toString().trim());
        }

    }

}
