CREATE OR REPLACE FUNCTION anuluj_rezerwacje(id_rezerwacji_ INTEGER)
RETURNS VOID AS $$

BEGIN 
-- tylko szef może anulować wszystkie rezerwacje; racownik może tylko swoje
	if( 
	(select czy_szef from pracownicy where id_pracownika= get_id_zalogowanego()) = FALSE  and 
	get_id_zalogowanego() != (select id_rezerwujacego from rezerwacje where id_rezerwacji=id_rezerwacji_)
	 )
	THEN 
		raise EXCEPTION 'Nie masz uprawnien do anulowania tej rezerwacji!';
	end if;

	DELETE from rezerwacje where id_rezerwacji=id_rezerwacji_;

END;
$$LANGUAGE 'plpgsql';