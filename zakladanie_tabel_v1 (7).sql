
CREATE TABLE RODZAJE_PRODUKTU(
	rodzaj_produktu TEXT PRIMARY KEY
);

SELECT * FROM RODZAJE_PRODUKTU;
--drop table RODZAJE_PRODUKTU;

--------------------------------------------------------------------------

CREATE TABLE TYPY_PRODUKTU(
	typ_produktu TEXT PRIMARY KEY,
	jednostka_ilosci VARCHAR(5) NOT NULL
		CHECK (jednostka_ilosci IN ('kg','szt.', 'l')), 
	rodzaj_produktu TEXT REFERENCES RODZAJE_PRODUKTU(rodzaj_produktu)
		ON DELETE SET NULL
		ON UPDATE CASCADE
		-- czy not null? i wartość 'inne' w RODZAJE_PRODUKTU
);
/*
INSERT INTO TYPY_PRODUKTU(typ_produktu,jednostka_ilosci,rodzaj_produktu) VALUES
('bulka','szt.','pieczywo'),
('marchewka','kg', 'warzywa'),
('jablko', 'kg', 'owoce'),
('mleko', 'l','nabial');

INSERT INTO TYPY_PRODUKTU(typ_produktu,jednostka_ilosci,rodzaj_produktu) VALUES
('szynka', 'kg', 'mieso'), ('ser zolty', 'kg', 'nabial');*/

--drop table TYPY_PRODUKTU;

--------------------------------------------------------------------------

CREATE TABLE TYPY_SPRZETU(
	typ_sprzetu TEXT PRIMARY KEY
);

/*INSERT INTO TYPY_SPRZETU(typ_sprzetu) VALUES
('piekarnik'),('mikrofala'),('mikser');*/


SELECT * FROM TYPY_SPRZETU;
--drop table TYPY_SPRZETU;

--------------------------------------------------------------------------


CREATE TABLE SPIZARNIA(
	miejsce TEXT PRIMARY KEY
);
/*
INSERT INTO SPIZARNIA(miejsce) VALUES
('lodówka nr 1'),('lodówka nr 2'),('szuflada nr 1'),
('szafka nr 1'), ('szafka nr 2'), ('szafka nr 3');
-- można być bardziej kreatwnym

INSERT INTO SPIZARNIA(miejsce) VALUES
('chlebak nr 1');

SELECT * FROM SPIZARNIA;*/
--drop table SPIZARNIA;

--------------------------------------------------------------------------

CREATE TABLE PRACOWNICY(
id_pracownika INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY, 
imie TEXT NOT NULL,
nazwisko TEXT NOT NULL,
stopien_zaawansowania INTEGER default(1) NOT NULL
	CHECK(stopien_zaawansowania>= 1 AND stopien_zaawansowania<=10),
haslo TEXT default('haslo') NOT NULL,
czy_szef BOOLEAN default(false) NOT NULL,
czy_zalogowany BOOLEAN default(false) NOT NULL
);
 --stopien_zaawansowania: można dać inny CHECK np od 0 do 10

/*INSERT INTO PRACOWNICY(imie,nazwisko,stopien_zaawansowania) VALUES
('Adam','Abacki', 5),
('Bartosz','Babacki',6),
('Grzegorz', 'Brzeczyszczykiewicz', 8),
('Anna','Nowak', 7),
('Jan','Kowalski',10);

INSERT INTO PRACOWNICY(imie,nazwisko) VALUES
('Tomasz','Sluszniak');

SELECT * FROM PRACOWNICY;*/
--drop table PRACOWNICY;

/*ALTER TABLE PRACOWNICY ADD COLUMN czy_szef BOOLEAN default(false) not null;
ALTER TABLE PRACOWNICY ADD COLUMN czy_zalogowany BOOLEAN default(false) not null;

ALTER TABLE PRACOWNICY ADD COLUMN haslo TEXT;
UPDATE PRACOWNICY SET haslo = "haslo" WHERE haslo is NULL; 
ALTER TABLE PRACOWNICY SET haslo NOT NULL;*/
--------------------------------------------------------------------------
CREATE TABLE PRZEPISY(
id_przepisu INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
tytul TEXT NOT NULL,
opis TEXT NOT NULL,
stopien_trudnosci INTEGER default(1) NOT NULL
	CHECK(stopien_trudnosci>= 1 AND stopien_trudnosci<=10),
czas_przygotowania_minuty INTEGER NOT NULL
	CHECK(czas_przygotowania_minuty> 0 AND czas_przygotowania_minuty<=480),
dla_ilu_osob INTEGER NOT NULL
	CHECK(dla_ilu_osob > 0)
);


INSERT INTO PRZEPISY(tytul,opis,czas_przygotowania_minuty,dla_ilu_osob) VALUES
('kanapki z serem','xd', '5', 1),('kanapki z szynką','xd', '5', 1);

SELECT * from przepisy;
--drop table PRZEPISY;
--------------------------------------------------------------------------
CREATE TABLE SKLADNIKI_PRZEPISU(
ilosc DECIMAL(10,3) NOT NULL
	CHECK(ilosc>0),
czy_konieczny BOOLEAN default(TRUE) NOT NULL,
typ_produktu TEXT REFERENCES TYPY_PRODUKTU(typ_produktu)
	ON DELETE SET NULL
	ON UPDATE CASCADE,
id_przepisu INTEGER REFERENCES PRZEPISY(id_przepisu)
	ON DELETE SET NULL
	ON UPDATE CASCADE,
PRIMARY KEY(typ_produktu, id_przepisu)
);
INSERT INTO SKLADNIKI_PRZEPISU(ilosc,typ_produktu,id_przepisu) VALUES
(2, 'bulka', 1);
--drop table PRZEPISY;
--------------------------------------------------------------------------
CREATE TABLE SPRZETY_przepisu(
typ_sprzetu TEXT REFERENCES TYPY_SPRZETU(typ_sprzetu)
	ON DELETE CASCADE
	ON UPDATE CASCADE,
id_przepisu INTEGER REFERENCES PRZEPISY(id_przepisu)
	ON DELETE CASCADE
	ON UPDATE CASCADE,
PRIMARY KEY(typ_sprzetu, id_przepisu)
);
--------------------------------------------------------------------------
CREATE TABLE SPRZETY(
id_sprzetu INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
nazwa TEXT NOT NULL,
czy_sprawny BOOLEAN default(TRUE) NOT NULL,
typ_sprzetu TEXT NOT NULL REFERENCES TYPY_SPRZETU(typ_sprzetu)
	ON DELETE CASCADE
	ON UPDATE CASCADE
);
--------------------------------------------------------------------------
CREATE TABLE REZERWACJE(
id_rezerwacji INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
termin DATE NOT NULL,
godzina_rozpoczecia TIME NOT NULL,
godzina_zakonczenia TIME NOT NULL,
id_rezerwujacego INTEGER NOT NULL REFERENCES PRACOWNICY(id_pracownika)
	ON DELETE CASCADE
	ON UPDATE CASCADE 
);
insert into REZERWACJE (termin,godzina_rozpoczecia,godzina_zakonczenia,id_rezerwujacego) VALUES
('2024-01-29', '16:00:00', '18:00:00',4), ('2024-01-28', '16:00:00', '18:00:00',5),
('2024-01-29', '17:00:00', '18:00:00',6);
--------------------------------------------------------------------------
CREATE TABLE REZERWACJE_SPRZETOW(
id_sprzetu INTEGER REFERENCES SPRZETY(id_sprzetu)
	ON DELETE CASCADE
	ON UPDATE CASCADE,
id_rezerwacji INTEGER REFERENCES REZERWACJE(id_rezerwacji)
	ON DELETE CASCADE
	ON UPDATE CASCADE,
PRIMARY KEY(id_sprzetu, id_rezerwacji)
);
insert into REZERWACJE_SPRZETOW(id_sprzetu,id_rezerwacji) VALUES
(2,6), (8,6), (8,7), (1,7)

--------------------------------------------------------------------------
CREATE TABLE PRODUKTY(
id_produktu INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
ilosc DECIMAL(10,3) NOT NULL
	CHECK(ilosc>0),
typ_produktu TEXT REFERENCES TYPY_PRODUKTU(typ_produktu)
	ON DELETE CASCADE
	ON UPDATE CASCADE,
lokalizacja TEXT default(NULL) REFERENCES SPIZARNIA(miejsce) 
	ON DELETE SET NULL
	ON UPDATE CASCADE,
id_rezerwacji INTEGER default(NULL) REFERENCES REZERWACJE(id_rezerwacji)
	ON DELETE SET NULL
	ON UPDATE CASCADE,
termin_przydatnosci DATE NOT NULL 
);


INSERT INTO PRODUKTY(ilosc,typ_produktu,lokalizacja, termin_przydatnosci) VALUES
(3,'bulka','chlebak nr 1', '2023--01--31');

INSERT INTO PRODUKTY(ilosc,typ_produktu,lokalizacja, termin_przydatnosci) VALUES
(0.5,'ser zolty','lodówka nr 1', '2023--02--28'), (0.3,'szynka','lodówka nr 1', '2023--02--28');

INSERT INTO PRODUKTY(ilosc,typ_produktu,lokalizacja, termin_przydatnosci) VALUES
(0.5,'ser zolty','lodówka nr 1', '2023--03--01');

/*INSERT INTO PRODUKTY(ilosc,typ_produktu,lokalizacja, termin_przydatnosci) VALUES
(3,'bulka','chlebak nr 1', '2023--01--31'); -- zwraca error :)*/

SELECT dodaj_produkt('bulka',3,'chlebak nr 1', '2023--01--31'); 
SELECT dodaj_produkt('szynka',0.2,'lodówka nr 1','2023--02--10'); --dziala
 select * from produkty;
 
 drop  TABLE PRODUKTY;
 SELECT dodaj_produkt('bulka',3,'chlebak nr 1', '2024--01--31');
 SELECT dodaj_produkt('ser zolty',0.5,'lodówka nr 1', '2024--02--28');
 SELECT dodaj_produkt('szynka',0.3,'lodówka nr 1', '2024--02--28');
 SELECT dodaj_produkt('bulka pszenna',4,'chlebak nr 1', '2024--01--31');
   
			
 --DELETE from produkty;

 --drop table PRODUKTY;


--------------------------------------------------------------------------
CREATE TABLE DANE_OGOLNE (
data_dzis DATE default(CURRENT_DATE),
godzina_logowania TIME default(CURRENT_TIME)
);



INSERT INTO DANE_OGOLNE(data_dzis) VALUES 
(CURRENT_DATE);
SELECT * from DANE_OGOLNE;