CREATE OR REPLACE FUNCTION REZERWACJA(id_pracownik INTEGER, id_przepis INTEGER, godzina_rozpoczec TIME, godzina_zakonczen TIME, termin DATE)
RETURNS VOID AS $$
DECLARE
	krotka RECORD;
	dostepny BOOLEAN;
BEGIN
	IF (sprawdz_zaaw(id_przepis, id_pracownik) = TRUE AND sprawdz_dostep(id_pracownik, godzina_rozpoczec, godzina_zakonczen, termin) = TRUE)
		FOR krotka IN SELECT * FROM Skladniki_przepisu LOOP
			IF (krotka.id_przepisu = id_przepis)
				dostepny = czy_jest_dostepny_produkt(krotka.typ_produktu, krotka.ilosc)
				IF (dostepny = FALSE)
					RAISE EXCEPTION 'Dany produkt nie jest dostepny w odpowiedniej ilosci.';
				END IF;
			END IF;
		FOR krotka IN SELECT * FROM Skladniki_przepisu LOOP
			IF (krotka.id_przepisu = id_przepis)
				
			END IF;
	END IF;

END;
$$ LANGUAGE plpgsql;