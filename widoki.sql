
--- produkty z ich rodzajami
CREATE VIEW tabela_PRODUKTY AS 
SELECT p.id_produktu, p.ilosc, t.jednostka_ilosci,p.typ_produktu,
t.rodzaj_produktu, p.lokalizacja,p. termin_przydatnosci , p.id_rezerwacji
FROM produkty p JOIN typy_produktu t
ON p.typ_produktu=t.typ_produktu;

SELECT * from tabela_produkty;


SELECT * from tabela_produkty;

--- skladniki przepisu z ich rodzajami
CREATE VIEW tabela_skladniki_przepisu  AS 
SELECT p.id_przepisu, p.ilosc, t.jednostka_ilosci,p.typ_produktu,
t.rodzaj_produktu, p.czy_konieczny
FROM skladniki_przepisu p JOIN typy_produktu t
USING(typ_produktu);

SELECT * from tabela_skladniki_przepisu;

--??? potrzebne to?
SELECT *
FROM sprzety_przepisu p JOIN sprzety t
USING(typ_sprzetu);


SELECT * from tabela_skladniki_przepisu;

--------------------------------
-- produkty przeterminowane (ale to trywialny widok)
SELECT * 
from tabela_PRODUKTY 
where termin_przydatnosci < CURRENT_DATE;


-- to potrzebne :)
CREATE VIEW tabela_rezwrwacje_sprzetow  AS 
SELECT *
FROM rezerwacje_sprzetow  JOIN rezerwacje
USING(id_rezerwacji);

select * from tabela_rezwrwacje_sprzetow;


CREATE VIEW tabela_rezerwacje_przepisow  AS 
select * from produkty join rezerwacje  using(id_rezerwacji);

select * from tabela_rezerwacje_przepisow;



