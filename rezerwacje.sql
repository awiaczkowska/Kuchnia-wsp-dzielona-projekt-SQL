
CREATE OR REPLACE FUNCTION sprawdz_zaaw2(id_przepis INTEGER, id_pracownik INTEGER)
RETURNS BOOLEAN AS $$
DECLARE
	zaawansowanie INTEGER;
	trudnosc INTEGER;
BEGIN
	SELECT pracownicy.stopien_zaawansowania INTO zaawansowanie
	FROM PRACOWNICY WHERE pracownicy.id_pracownika = id_pracownik;
	
	SELECT przepisy.stopien_trudnosci INTO trudnosc FROM PRZEPISY WHERE przepisy.id_przepisu = id_przepis;
	IF (zaawansowanie < trudnosc) THEN
			return false; -- potrzbeobalam tego
			END IF;
RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

select sprawdz_zaaw2(2,1); 


CREATE OR REPLACE FUNCTION sprawdz_dostep2(id_pracownik INTEGER, godzina_rozpoczec TIME, godzina_zakonczen TIME, termin DATE)
RETURNS BOOLEAN AS $$
DECLARE
	krotka RECORD;
BEGIN
	FOR krotka IN SELECT * FROM REZERWACJE LOOP
		IF (krotka.id_rezerwujacego = id_pracownik) THEN
			IF (krotka.termin = termin) THEN
				IF ((krotka.godzina_rozpoczecia <= godzina_rozpoczec AND godzina_rozpoczec <= krotka.godzina_zakonczenia)
				OR (krotka.godzina_rozpoczecia <= godzina_zakonczen AND godzina_zakonczen <= krotka.godzina_zakonczenia)) THEN
						return false ;
						END IF;
			END IF;
		END IF;
	END LOOP;
RETURN TRUE;	
END;
$$ LANGUAGE plpgsql;

--------------------------------------------
-- drop function REZERWACJA;



CREATE OR REPLACE FUNCTION REZERWACJA
( id_przepis INTEGER,ilosc_porcji INTEGER, godzina_rozpoczec TIME, godzina_zakonczen TIME, termin_ DATE)
RETURNS VOID AS $$
DECLARE	krotka RECORD;
--DECLARE	krotka2 RECORD;
--? DECLARE dostepny BOOLEAN;
DECLARE  id_pracownik INTEGER;
DECLARE id_rezerwacji_ INTEGER;
DECLARE id_sprzetu_ INTEGER;
--DECLARE  ilosc_potrzebna DECIMAL;
--DECLARE  id_prod INTEGER;
DECLARE czy_wszystkie BOOLEAN;

BEGIN
	if get_id_zalogowanego() IS NULL THEN
	RAISE EXCEPTION 'Aby zlozyc rezerwacje nalezy najpeirw sie zalogowac!';
	end if;

   select get_id_zalogowanego() into id_pracownik;
   IF (sprawdz_zaaw2(id_przepis, id_pracownik) = FALSE) THEN
		RAISE EXCEPTION 'Przepis jest na zbyt wysokim poziomie trudnosci.';
	END IF;
   
   IF sprawdz_dostep2(id_pracownik, godzina_rozpoczec, godzina_zakonczen, termin_) = FALSE THEN
		RAISE EXCEPTION 'Nie jestes dostepny w godzinach % - %. 
Przygotowujesz rezerwacje o identyfikatorze %.', godzina_rozpoczec, godzina_zakonczen,
	(SELECT min(id_rezerwacji) from REZERWACJE
	where id_rezerwujacego=id_pracownik and termin=termin_ and 
	(godzina_zakonczenia>godzina_rozpoczec or godzina_rozpoczecia<godzina_zakonczen) );
	end if;
	
	-- if za krotki czas na przygotowanie przepisu
	
	
	if czy_sa_konieczne_produkty_przepisu(id_przepis,ilosc_porcji,termin_)=false THEN
		RAISE EXCEPTION 'Brak odpowiedniej ilosci koniecznych produktów do przygotowania przepisu % na dzien %.', 
		id_przepis, termin_;
	end if;
	
	if czy_sa_dostepne_sprzety_przepisu	(id_przepis,godzina_rozpoczec , godzina_zakonczen ,termin_ )=false THEN
		raise EXCEPTION 'Brak dostepnych sprzetow do przygotowania przepisu % na podany termin.', id_przepis;
	end if;
	
	select czy_wszystkie_produkty_przepisu(id_przepis,ilosc_porcji,termin_) into czy_wszystkie;
	if czy_sa_wszystkie=false THEN
		RAISE INFO 'Brakuje pewnych produktow opcjonalnych.';
	end if;
	
	--------------	
	if (select count(*) from REZERWACJE) = 0
	THEN id_rezerwacji_=1;
	else	
	select (last_value+1)  into  id_rezerwacji_ from rezerwacje_id_rezerwacji_seq ;
	end if;
	 
	insert into REZERWACJE(termin,godzina_rozpoczecia,godzina_zakonczenia,id_rezerwujacego) VALUES
	(termin_,godzina_rozpoczec,godzina_zakonczen,id_pracownik);
	
	-- dodawanie sprzetow
	FOR krotka IN (SELECT * FROM sprzety_przepisu WHERE id_przepisu=id_przepis)
	LOOP 
		select get_id_dostepnego_sprzetu(krotka.typ_sprzetu,  godzina_rozpoczec, godzina_zakonczen,termin_ )
		into id_sprzetu_;
		insert into REZERWACJE_SPRZETOW(id_sprzetu,id_rezerwacji) VALUES
		(id_sprzetu_,id_rezerwacji_);

	END LOOP;
	
		-- dodawanie produktow 
	FOR krotka IN (SELECT * FROM tabela_skladniki_przepisu WHERE id_przepisu=id_przepis)
	LOOP
	ilosc_potrzebna=krotka.ilosc;
	if(krotka.jednostka_ilosci='szt.') THEN ilosc_potrzebna=ceil(ilosc_potrzebna);
	
		WHILE ilosc_potrzebna>0 LOOP
		
			select get_id_dostepnego_produktu(krotka.typ_produktu , termin_)
				into id_prod;
			if id_prod IS NULL THEN CONTINUE; -- przechodzimy do kolejnej itercji
				
			if (SELECT ilosc from tabela_produkty where id_produktu=id_prod ) > ilosc_potrzebna
			then -- rozdziel stack
				UPDATE PRODUKTY SET ilosc=ilosc-ilosc_potrzebna where id_produktu=id_prod;
				SELECT * into krotka2 from tabela_produkty where id_produktu=id_prod ;
			
				INSERT INTO PRODUKTY(typ_produktu,ilosc,lokalizacja, termin_przydatnosci,id_rezerwacji) VALUES
				(krotka2.typ_produktu ,ilosc_potrzebna  ,krotka2.lokalizacja , krotka2.termin_przydatnosci ,id_rezerwacji_);
				ilosc_potrzebna=0;
			
			else -- edytuj krotkę
			UPDATE PRODUKTY SET id_rezerwacji=id_rezerwacji_ where id_produktu=id_prod;
			ilosc_potrzebna=ilosc_potrzebna-(SELECT ilosc from tabela_produkty where id_produktu=id_prod);
			end if;
			
			
		END LOOP;
	
	END LOOP;
	
	RAISE INFO 'Rezerwacja zostala zapisana';
END;
$$ LANGUAGE plpgsql;
	
	
	 select logowanie(1,'haslo');
select REZERWACJA
( 2,1, '12:00:00', '12:00:00', '2024-01-30');

 select logowanie(5,'haslo');
select REZERWACJA
( 2,1, '12:00:00', '12:00:00', '2024-01-30');
	
	select REZERWACJA
( 2,1, '12:00:00', '16:00:00', '2024-01-30');
	
	
   
	/*IF (sprawdz_zaaw(id_przepis, id_pracownik) = TRUE 
	AND sprawdz_dostep(id_pracownik, godzina_rozpoczec, godzina_zakonczen, termin) = TRUE)
	
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
$$ LANGUAGE plpgsql;*/