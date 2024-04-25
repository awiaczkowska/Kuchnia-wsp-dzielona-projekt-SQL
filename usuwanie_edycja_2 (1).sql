CREATE OR REPLACE FUNCTION USUWANIE()
RETURNS VOID AS $$
BEGIN 
	 Delete from produkty where termin_przydatnosci < (select data_dzis from dane_ogolne);
END;
$$LANGUAGE 'plpgsql';

# Nie działa:

CREATE OR REPLACE FUNCTION Edytuj_dane(hasl TEXT, nazwisk_nowe TEXT, nazwisk_stare TEXT)
RETURNS VOID AS $$
DECLARE
	czy_moze BOOLEAN;
BEGIN 
	czy_moze = (SELECT PRACOWNICY.czy_szef WHERE PRACOWNICY.haslo = hasl);
	IF(czy_moze = TRUE) THEN
		UPDATE pracownicy SET pracownicy.nazwisko = nazwisk_nowe WHERE pracownicy.nazwisko = nazwisk_stare; 
		Pracownicy.nazwisko := nazwisk;
		RAISE NOTICE 'Zmieniono nazwisko.';
	ELSE
		RAISE NOTICE 'Nie jestes szefem, nie mozesz zmienic nazwiska';
	END IF;
	
END;
$$LANGUAGE 'plpgsql';