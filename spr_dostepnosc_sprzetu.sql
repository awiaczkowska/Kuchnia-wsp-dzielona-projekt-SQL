CREATE VIEW tabela_rezerwacje_sprzetow  AS 
SELECT * - nazwa
FROM rezerwacje_sprzetow  JOIN rezerwacje
USING(id_rezerwacji)
JOIN sprzety using(id_sprzetu);

select * from tabela_rezerwacje_sprzetow;

------------------------------------------------------------------


CREATE OR REPLACE FUNCTION czy_jest_dostepny_sprzet
(typ_sprzetu_ TEXT,  godzina_rozpoczec TIME, godzina_zakonczen TIME,termin_ DATE DEFAULT(CURRENT_DATE) )
 RETURNS BOOLEAN  AS $$
 DECLARE licznik INTEGER;
 BEGIN 
 
	-- wybieramy te sprzety ktore są w danej chwili wolne i liczymy ile ich jest
	select count(*) into licznik from sprzety
	where 
	typ_sprzetu=typ_sprzetu_ and  czy_sprawny and
	id_sprzetu not in
		-- eliminujemy kolidujace rezerwacje, czyli wyłuskujemy sprzety ktorych nie uzyjemy:
	(select id_sprzetu from tabela_rezerwacje_sprzetow
	where termin = termin_ or godzina_rozpoczecia < godzina_zakonczen 
		or godzina_zakonczenia > godzina_rozpoczec);
	 
	 RETURN ( licznik>0 );
 END;
$$LANGUAGE 'plpgsql';

 select czy_jest_dostepny_sprzet ('garnek' , '15:00:00' , '17:00:00' ,'2024-01-29 ' );

--------------------------------------------------------------


CREATE OR REPLACE FUNCTION czy_sa_dostepne_sprzety_przepisu
(id_przepisu_ INTEGER,godzina_rozpoczec TIME, godzina_zakonczen TIME,termin_ DATE )
RETURNS BOOLEAN  AS $$

DECLARE krotka RECORD;

BEGIN 
	
	FOR krotka IN (SELECT * from sprzety_przepisu where id_przepisu=id_przepisu_)
	LOOP
		IF  (select 
		czy_jest_dostepny_sprzet(krotka.typ_sprzetu ,godzina_rozpoczec , godzina_zakonczen ,termin_ ))= FALSE
			THEN RETURN FALSE;
		END IF;
	END LOOP;
	
	RETURN TRUE;
 END;
$$LANGUAGE 'plpgsql';


select czy_sa_dostepne_sprzety_przepisu(1,'12:00:00', '13:00:00', '2024-01-29 ');

----------------------------------------------------------------------------------------------------------------
-- drop function get_id_dostepnego_sprzetu;

CREATE OR REPLACE FUNCTION get_id_dostepnego_sprzetu
(typ_sprzetu_ TEXT,  godzina_rozpoczec TIME, godzina_zakonczen TIME,termin_ DATE DEFAULT(CURRENT_DATE) )
 RETURNS integer  AS $$
 DECLARE id INTEGER;
 BEGIN 
 
	-- wybieramy te sprzety ktore są w danej chwili wolne i liczymy ile ich jest
	select max(id_sprzetu ) into id from sprzety
	where 
	typ_sprzetu=typ_sprzetu_ and  czy_sprawny and
	id_sprzetu not in
		-- eliminujemy kolidujace rezerwacje, czyli wyłuskujemy sprzety ktorych nie uzyjemy:
	(select id_sprzetu from tabela_rezerwacje_sprzetow
	where termin = termin_ or godzina_rozpoczecia < godzina_zakonczen 
		or godzina_zakonczenia > godzina_rozpoczec);
	 
	 RETURN id;
 END;
$$LANGUAGE 'plpgsql';

 select get_id_dostepnego_sprzetu ('garnek' , '15:00:00' , '17:00:00' ,'2024-01-29 ' );

--------------------------------------------------------------

