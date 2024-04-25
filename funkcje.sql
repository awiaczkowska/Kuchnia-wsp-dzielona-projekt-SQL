
-- dodawanie produktów do tabeli 
	--spr czy jest juz stack
		--jesli tak: powieksz stack
		-- jesli nie insert
		
	-- + wyzwalacz spradzajacy ze nie ma stacku
	
CREATE OR REPLACE FUNCTION 
czy_jest_stack(typ_produktu_ TEXT, lokalizacja_ TEXT, termin_przydatnosci_ DATE) 
RETURNS BOOLEAN AS $$

DECLARE wystapienia INTEGER;
BEGIN
	SELECT count(id_produktu) INTO wystapienia
			FROM PRODUKTY 
		where (typ_produktu=typ_produktu_ and 
		lokalizacja=lokalizacja_ and  
		termin_przydatnosci = termin_przydatnosci_
		and  id_rezerwacji IS NULL);
	
	RETURN (wystapienia>0);

END;
$$LANGUAGE 'plpgsql';

SELECT czy_jest_stack('bulka','chlebak nr 1', '2023--01--31'); --t 
SELECT czy_jest_stack('bulka','chlebak nr 1', '2023--01--30'); --f

-------------------------------...

-- wyzwalacz
CREATE OR REPLACE FUNCTION stack_juz_istnieje() RETURNS TRIGGER AS $$
BEGIN
		
	IF czy_jest_stack(NEW.typ_produktu, NEW.lokalizacja, NEW.termin_przydatnosci)
		THEN RAISE EXCEPTION 
			'W tabeli PRODUKTY znajduje sie juz krotka (%, %, %).
Sproboj zwiekszyc w niej ilosc.',
			NEW.typ_produktu,NEW.lokalizacja,NEW.termin_przydatnosci;
	END IF;
	
	RETURN NEW;
END;
$$LANGUAGE 'plpgsql';

-- drop FUNCTION stack_juz_istnieje;

CREATE TRIGGER stack_juz_istnieje_trigger  BEFORE INSERT ON PRODUKTY 
	FOR EACH ROW EXECUTE PROCEDURE stack_juz_istnieje();

-- DROP TRIGGER stack_juz_istnieje_trigger ON PRODUKTY CASCADE;

-- w zasadzie ten trigger jest chyba niepotrzebny, bo uzytkownik nie wywołuje inserta z palca

--------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION dodaj_produkt
(typ_produktu_ TEXT, ilosc_ DECIMAL(10,3) ,lokalizacja_ TEXT, 
termin_przydatnosci_ DATE) 
RETURNS VOID AS $$
DECLARE id_stacku INTEGER;
BEGIN
	if (select jednostka_ilosci fromtypy_produktu where typ_produktu=typ_produktu_) = 'szt.'
	THEN RAISE EXCEPTION 'Liczba sztuk produktu musi byc licza calkowita!'.
	
	IF czy_jest_stack(typ_produktu_, lokalizacja_, termin_przydatnosci_) THEN
		SELECT id_produktu INTO id_stacku
		FROM PRODUKTY 
		WHERE (typ_produktu=typ_produktu_ and 
			lokalizacja=lokalizacja_ and  
			termin_przydatnosci = termin_przydatnosci_);
		
		UPDATE PRODUKTY SET ilosc=ilosc+ilosc_  WHERE id_produktu=id_stacku;
		--raise info 'id_stacku: % ',id_stacku;
	ELSE 
		INSERT INTO PRODUKTY(typ_produktu,ilosc,lokalizacja, termin_przydatnosci) VALUES
		(typ_produktu_ , ilosc_  ,lokalizacja_ , termin_przydatnosci_ );
	END IF;
			
	raise info 'Produkt dodano pomyslnie.';
END;
$$LANGUAGE 'plpgsql';

-- drop FUNCTION dodaj_produkt;

SELECT dodaj_produkt('bulka',3,'chlebak nr 1', '2024--01--31');  
SELECT dodaj_produkt('bulka',3,'chlebak nr 1', '2023--01--30'); 


 select * from produkty;
 
 
 
 
 
 
 --------------------------------------------------------------------------
 ----------------------------------edytowane----------------------------------------
 
 -- to byly widoki
CREATE OR REPLACE FUNCTION dostepne_produkty_suma_na_dzien
(data_ DATE DEFAULT(CURRENT_DATE)) --nowa fkcja
RETURNS TABLE (
	Typ_produktu TEXT,Ilosc DECIMAL(10,3),Jednostka_ilosci	TEXT)
AS $$

DECLARE krotka RECORD;

BEGIN

for krotka in 
	(SELECT p.typ_produktu,sum(p.ilosc) as ilosc,p.jednostka_ilosci
	from tabela_PRODUKTY p
	where p.id_rezerwacji IS NULL 
		and p.termin_przydatnosci > data_
	group by p.typ_produktu, p.jednostka_ilosci)
	
	LOOP
		Typ_produktu = krotka.typ_produktu;
		Ilosc =krotka.ilosc;
		Jednostka_ilosci=krotka.jednostka_ilosci;
		
		RETURN NEXT;
	END LOOP;
	
END;
$$LANGUAGE 'plpgsql';
 
 CREATE OR REPLACE FUNCTION czy_jest_dostepny_produkt
 (typ_produktu_ TEXT, ilosc_ DECIMAL, data_ DATE DEFAULT(CURRENT_DATE))
 RETURNS BOOLEAN  AS $$
 DECLARE ilosc_produktu DECIMAL;
 BEGIN 
	 SELECT ilosc into ilosc_produktu
	 from dostepne_produkty_suma_na_dzien(data_) --zmiana
	 where typ_produktu=typ_produktu_;
	 
	 RETURN (ilosc_produktu>=ilosc_);
 END;
$$LANGUAGE 'plpgsql';

 
 --select czy_jest_dostepny_produkt('brokuly', 1.4,'2024-02-01')



CREATE OR REPLACE FUNCTION produkty_przepis_kuchnia_w_dniu
(data_ DATE DEFAULT(CURRENT_DATE))
RETURNS TABLE (
	Id_przepisu INTEGER,Czy_konieczny BOOLEAN,Typ_produktu TEXT,
	Dostepna_ilosc DECIMAL(10,3),Potrzebna_ilosc DECIMAL(10,3),
	Jednostka_ilosci TEXT)
AS $$

DECLARE krotka RECORD;

BEGIN

for krotka in 
	(SELECT s.id_przepisu,s.czy_konieczny,
s.typ_produktu, d.ilosc as dostepna_ilosc, s.ilosc as potrzebna_ilosc,s. jednostka_ilosci 
from tabela_skladniki_przepisu s inner join
 dostepne_produkty_suma_na_dzien(data_) d USING (typ_produktu,jednostka_ilosci))
	
	LOOP
		Id_przepisu=krotka.id_przepisu;
		Czy_konieczny=krotka.czy_konieczny;
		Typ_produktu = krotka.typ_produktu;
		Dostepna_ilosc=krotka.dostepna_ilosc;
		Potrzebna_ilosc=krotka.potrzebna_ilosc;
		Jednostka_ilosci=krotka.jednostka_ilosci;
		RETURN NEXT;
	END LOOP;
	
END;
$$LANGUAGE 'plpgsql';


------------------------------------------------------------------


CREATE OR REPLACE FUNCTION skalowanie_ilosci_porcji
(id_przepisu_ INTEGER, ilosc_osob INTEGER)
RETURNS DECIMAL AS $$

DECLARE na_ile_os_przepis INTEGER;
DECLARE skala DECIMAL;
BEGIN
	SELECT dla_ilu_osob INTO na_ile_os_przepis 
	FROM przepisy
	where id_przepisu=id_przepisu_;
	
	SELECT ilosc_osob/na_ile_os_przepis into skala;
	RETURN skala;
 END;
$$LANGUAGE 'plpgsql';

----------------------

CREATE OR REPLACE FUNCTION czy_sa_konieczne_produkty_przepisu
(id_przepisu_ INTEGER, ilosc_osob INTEGER,data_ DATE DEFAULT(CURRENT_DATE))
RETURNS BOOLEAN  AS $$

DECLARE skala DECIMAL;
DECLARE krotka RECORD;

BEGIN 
	SELECT skalowanie_ilosci_porcji(id_przepisu_,ilosc_osob) into skala;
	
	FOR krotka IN SELECT typ_produktu,ilosc, jednostka_ilosci  
	FROM tabela_skladniki_przepisu
	where czy_konieczny= TRUE
	LOOP
		IF czy_jest_dostepny_produkt(krotka.typ_produktu,(skala*krotka.ilosc),data_)= FALSE
			THEN RETURN FALSE;
		END IF;
	END LOOP;
	
	RETURN TRUE;
	
 END;
$$LANGUAGE 'plpgsql';

select czy_sa_konieczne_produkty_przepisu(1,2); -- dziala
-- drop function czy_sa_konieczne_produkty_przepisu;
-------------------------------------


CREATE OR REPLACE FUNCTION czy_sa_wszystkie_produkty_przepisu
(id_przepisu_ INTEGER, ilosc_osob INTEGER,data_ DATE DEFAULT(CURRENT_DATE))
RETURNS BOOLEAN  AS $$

DECLARE skala DECIMAL;
DECLARE krotka RECORD;

BEGIN 
	SELECT skalowanie_ilosci_porcji(id_przepisu_,ilosc_osob) into skala;
	
	FOR krotka IN SELECT typ_produktu,ilosc, jednostka_ilosci  
	FROM tabela_skladniki_przepisu
	LOOP
		IF czy_jest_dostepny_produkt(krotka.typ_produktu,(skala*krotka.ilosc),data_)= FALSE
			THEN RETURN FALSE;
		END IF;
	END LOOP;
	
	RETURN TRUE;
 END;
$$LANGUAGE 'plpgsql';

--------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
-- drop function wypisz_brakujace_produkty_przepisu;

CREATE OR REPLACE FUNCTION wypisz_brakujace_produkty_przepisu
(id_przepisu_ INTEGER, ilosc_osob INTEGER, data_ DATE DEFAULT(CURRENT_DATE))
RETURNS TABLE (
	Czy_konieczny BOOLEAN, Typ_produktu TEXT,Dostepna_ilosc DECIMAL(10,3),
	Potrzebna_ilosc DECIMAL(10,3),
	Jednostka_ilosci TEXT)
AS $$

DECLARE skala DECIMAL;
DECLARE krotka RECORD;

BEGIN

        SELECT skalowanie_ilosci_porcji(id_przepisu_,ilosc_osob) into skala;

        IF czy_sa_wszystkie_produkty_przepisu(id_przepisu_,ilosc_osob, data_)
                THEN raise EXCEPTION 'Dostepne sa wszystkie skladniki tego przepisu.';
        END IF;
        IF czy_sa_konieczne_produkty_przepisu(id_przepisu_,ilosc_osob, data_)
                THEN raise info 'Dostepne sa wszystkie konieczne skladniki tego przepisu.';
        END IF;

        for krotka in ( SELECT p.czy_konieczny,p.typ_produktu,p.dostepna_ilosc,
		p.potrzebna_ilosc * skala as potrzebna_ilosc,
		p.jednostka_ilosci
                from produkty_przepis_kuchnia_w_dniu(data_) p
		where p.id_przepisu=id_przepisu_ and ((p.potrzebna_ilosc * skala)> p.dostepna_ilosc)) 
		LOOP
			Czy_konieczny:=krotka.czy_konieczny;
			Typ_produktu:=krotka.typ_produktu;
			Dostepna_ilosc:=krotka.dostepna_ilosc;
			Potrzebna_ilosc:=krotka.potrzebna_ilosc;
			Jednostka_ilosci:=krotka.jednostka_ilosci;
			RETURN NEXT;
		END LOOP;
	
END;
$$LANGUAGE 'plpgsql';

select wypisz_brakujace_produkty_przepisu(1,40);


select wypisz_brakujace_produkty_przepisu(1,40);
------------------------------------------------------------------------------------
-------------------------------------------------------------------------------

---------------------------------------NOWE-------------------------------------------



CREATE OR REPLACE FUNCTION usun_stare_rezerwacje()
RETURNS void   AS $$
BEGIN
	   

	DELETE from produkty where id_produktu in 
	
	(select id_produktu from tabela_rezerwacje_przepisow
	where 
	termin<(select data_dzis from dane_ogolne) or
	(termin=(select data_dzis from dane_ogolne) and 
		(select godzina_logowania from dane_ogolne) > godzina_zakonczenia)
	)  ;
	
	
	DELETe from rezerwacje cascade
	where 
	termin<(select data_dzis from dane_ogolne) or
	(termin=(select data_dzis from dane_ogolne) and 
		(select godzina_logowania from dane_ogolne) > godzina_zakonczenia)
	;
	
END;
$$LANGUAGE 'plpgsql';

select usun_stare_rezerwacje();

CREATE OR REPLACE FUNCTION get_id_zalogowanego()
RETURNS INTEGER  AS $$
DECLARE login INTEGER;
BEGIN
	SELECT id_pracownika into login from pracownicy 
	where czy_zalogowany;
	RETURN login;

END;
$$LANGUAGE 'plpgsql';




CREATE OR REPLACE FUNCTION logowanie(login_ INTEGER, haslo_ TEXT)
RETURNS VOID  AS $$
DECLARE haslo_pracownika TEXT;
BEGIN
	if  get_id_zalogowanego() IS not NULL THEN
		raise EXCEPTION 'Uzytkownik o identyfikatorze % jest obecnie zalogowany!
Nalezy go najpierw wylogowac przed zalogowaniem kolejnej osoby.',get_id_zalogowanego();
	end if;
	
	if(select count(haslo) from pracownicy where id_pracownika=login_)=0 THEN
		raise EXCEPTION 'W bazie brak pracownika o identyfikatorze %.', login_;
	end if;
	
	SELECT haslo into haslo_pracownika from pracownicy where id_pracownika=login_;
	
	if haslo_!=haslo_pracownika THEN
		raise EXCEPTION 'Haslo niepoprawne!';
	end if;
	
	update  PRACOWNICY SET czy_zalogowany = TRUE where id_pracownika = login_;
	delete from dane_ogolne;
	INSERT INTO DANE_OGOLNE(data_dzis,godzina_logowania) VALUES (CURRENT_DATE,CURRENT_TIME);
	
	select usun_stare_rezerwacje() ;
	RAISE INFO 'Logowanie uzytkownika o identyfikatorze % powiodlo sie.', login_;
END;
$$LANGUAGE 'plpgsql';


-- wylogowywanie:
update  PRACOWNICY SET czy_zalogowany = false;


--- funkcja manipulacji czasem
CREATE OR REPLACE FUNCTION podroz_w_czasie(data_ DATE, godzina_ TIME)
RETURNS VOID  AS $$
BEGIN
	delete from dane_ogolne;
	INSERT INTO DANE_OGOLNE(data_dzis,godzina_logowania) VALUES (data_,godzina_);
	select usun_stare_rezerwacje() ;
END;
$$LANGUAGE 'plpgsql';

---------------------------------------------------------------------
----------------------------------------------------------------------
--  wyzwalacz spr czy godzina rozpoczecia rezerwacji < zakonczenia

CREATE OR REPLACE FUNCTION spr_godziny_rezerwacji() RETURNS TRIGGER AS $$
BEGIN
		if new.godzina_rozpoczecia>=new.godzina_zakonczenia THEN
			raise EXCEPTION 'Godzina rozpoczecia musi byc pozniej niz godzina zakonczenia!';
		END if;
		
		if new.termin < (select data_dzis from dane_ogolne) or  
		new.termin = (select data_dzis from dane_ogolne) and 
		new.godzina_rozpoczecia<(select godzina_logowania from dane_ogolne) then
			raise EXCEPTION 'Nie mozna zrobic rezerwacji na termin, ktory minal!';
		end if; 
		
		if 
		sprawdz_dostep(new.id_rezerwujacego, new.godzina_rozpoczecia, new.godzina_zakonczenia, new.termin )
		=  false THEN
			RAISE EXCEPTION 'Pracownik nie jest dostepny w podanym terminie!';
		end if;
		
	RETURN NEW;
END;
$$LANGUAGE 'plpgsql';


CREATE TRIGGER spr_godziny_rezerwacji_trigger  BEFORE INSERT ON REZERWACJE 
	FOR EACH ROW EXECUTE PROCEDURE spr_godziny_rezerwacji();
	
	
------------------------------------------------------------------------	
-- drop function get_id_dostepnego_produktu;
CREATE OR REPLACE FUNCTION get_id_dostepnego_produktu
(typ_produktu_ TEXT, data_ DATE DEFAULT(CURRENT_DATE))
RETURNS INTEGER AS $$

DECLARE id INTEGER;
DECLARE min_termin DATE;
BEGIN
	SELECT min(termin_przydatnosci) into min_termin
	from tabela_produkty
	where typ_produktu=typ_produktu_
		and termin_przydatnosci>=data_;
		
	select id_produktu into id 
	from
	(SELECT * from tabela_produkty
	where typ_produktu=typ_produktu_
		and id_rezerwacji IS NULL 
		and termin_przydatnosci>=data_) as t
		where t.termin_przydatnosci=min_termin;

	RETURN id;
END;
$$LANGUAGE 'plpgsql';

select get_id_dostepnego_produktu('mleko UHT', '2024-01-31');


