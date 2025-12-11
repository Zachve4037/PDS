-- 1. Pre každý mesiac v minulom roku vypíšte, koľko študentov v druhom ročníku malo narodeniny.
SELECT 
    EXTRACT(MONTH FROM TO_DATE(
        SUBSTR(rod_cislo, 5, 2) || '-' || 
        mod(SUBSTR(rod_cislo, 3, 2), 50) || '-' || 
        SUBSTR(rod_cislo, 1, 2), 'DD-MM-YY')) AS month_number,
    COUNT(os_cislo) AS pocet
FROM student
WHERE rocnik = 2
    AND EXTRACT(YEAR FROM TO_DATE(
        SUBSTR(rod_cislo, 5, 2) || '-' || 
        mod(SUBSTR(rod_cislo, 3, 2), 50) || '-' || 
        SUBSTR(rod_cislo, 1, 2), 'DD-MM-YY')) = EXTRACT(YEAR FROM SYSDATE) - 10
GROUP BY EXTRACT(MONTH FROM TO_DATE(
        SUBSTR(rod_cislo, 5, 2) || '-' || 
        mod(SUBSTR(rod_cislo, 3, 2), 50) || '-' || 
        SUBSTR(rod_cislo, 1, 2), 'DD-MM-YY'))
ORDER BY month_number;

--3. Pre každý deň v mesiaci február vypíšte počet študentov, ktorí sa narodili 
--v tento deň a zároveň ich prednášajúci bol Petr Cenek.
select extract(day from to_date(
    substr(rod_cislo, 5, 2) || '-' ||
    mod(substr(rod_cislo, 3, 2), 50) || '-' ||
    substr(rod_cislo, 1, 2), 'DD-MM-YY')
    ) as den,
    count(*) as pocet
 from student
 join zap_predmety using(os_cislo)
 where prednasajuci = 'Petr Cenek'
 group by extract(day from to_date(
    substr(rod_cislo, 5, 2) || '-' ||
    mod(substr(rod_cislo, 3, 2), 50) || '-' ||
    substr(rod_cislo, 1, 2), 'DD-MM-YY'));
    

--STATISTIKA
-- 1. Vypíšte počet študentov žijúcich v jednotlivých mestách podľa pohlavia, 
-- pričom každé pohlavie je zvlášť stĺpec.
select obec,
  count(case when to_number(substr(rod_cislo, 3, 2)) > 12 then 1 end) as zeny,
  count(case when mod(to_number(substr(rod_cislo, 3, 2)), 50) <= 12 then 1 end) as muzi
 from student
 join os_udaje using(rod_cislo)
 group by obec;
 
-- 2. Vypíšte štatistiku o počte zapísaných predmetov študentov podľa ročníku 
-- štúdia, pričom každý ročník štúdia je zvlášť stĺpec.
select count(case when rocnik = 1 then zp.cis_predm end) as prvy,
    count(case when rocnik = 2 then zp.cis_predm end) as druhy,
    count(case when rocnik = 3 then zp.cis_predm end) as treti,
    count(case when rocnik = 4 then zp.cis_predm end) as stvrti,
    count(case when rocnik = 5 then zp.cis_predm end) as piaty
from student
join zap_predmety zp using(os_cislo);


--ANALYTIKA
-- 1. Vypíšte 5 najmladších osôb.
select meno, priezvisko, 
    to_date(
    substr(rod_cislo, 5, 2) || '-' ||
    mod(substr(rod_cislo, 3, 2), 50) || '-' ||
    substr(rod_cislo, 1, 2), 'DD-MM-YY') as dat_nar
 from os_udaje
 where rownum <= 5
 order by dat_nar asc;

-- 2. Vypíšte 15% najúspešnejších študentov v minulom roku 
-- (úspešnosť sa počíta na základe priemeru známok v danom roku).
select meno, priezvisko, avg(
        case 
            when vysledok = 'A' then 1
            when vysledok = 'B' then 2
            when vysledok = 'C' then 3
            when vysledok = 'D' then 4
            when vysledok = 'E' then 5
            when vysledok = 'F' then 6 
        end
    ) as priemer
 from os_udaje
 join student using(rod_cislo)
 join zap_predmety using(os_cislo)
 where skrok = extract(year from sysdate) - 1
 group by meno, priezvisko, os_cislo
 order by priemer
 fetch first 15 percent rows only;
 
 
--GENEROVANIE PRIKAZOV
--1. Pomocou príkazu SELECT vygenerujte INSERT INTO VALUE príkazy pre tabuľku 
--os_udaje, ktoré vložia všetky existujúce záznamy do tabuľky os_udaje_2, 
--ktorá je už vytvorená a má rovnakú štruktúru ako tabuľka os_udaje.
select 'INSERT INTO os_udaje_2 VALUES(''' ||
    rod_cislo || ''', ''' ||
    meno || ''', ''' ||
    priezvisko || ''', ''' ||
    ulica || ''', ''' ||
    psc || ''', ''' ||
    obec || ''');'
    from os_udaje;
    rollback;
    
--2. Pomocou SELECT vygenerujte príkazy, ktoré zrušia indexy ktorých názov 
--začína prefixom 'IDX_', pre všetky tabuľky.
select 'DROP INDEX ' || index_name || ';'
from user_indexes
where index_name like 'IDX_%';
rollback;

-- 3. Pomocou SELECT vygenerujte príkazy, ktoré pre všetky tabuľky vytvoria 
-- primárny kľúč pre stĺpce, ktoré končia na _ID a majú dátový typ NUMBER.
select 'ALTER TABLE ' || table_name ||
    ' ADD CONSTRAINT PK_' || table_name ||
    ' PRIMARY KEY (' || column_name || ');'
from user_tab_columns
where column_name like '%_ID'
and data_type = 'number';
rollback;

-- 4. Pomocou SELECT vygenerujte príkazy, ktoré vypnú všetky triggre pre všetky 
-- tabuľky v aktuálnej schéme.
select 'ALTER TRIGGER ' || trigger_name || 'DISABLE;'
from user_triggers;

rollback;

--KURZORY
--1. Napíšte PL/SQL blok, ktorý pomocou implicitného kurzora FOR vypíše meno, 
--priezvisko a počet koľkokrát bola osoba študentom pre všetky osoby. 
--Je potrebné, aby vo výsledku boli zahrnuté aj osoby, ktoré nikdy neštudovali 
--s počtom štúdii 0.
DECLARE
BEGIN
    for rec in(
        select meno, priezvisko, count(os_cislo) as pocet
        from os_udaje
        join student using(rod_cislo)
        group by meno, priezvisko
    ) loop
        dbms_output.put_line(rec.meno || ' ' || rec.priezvisko || ' ' || rec.pocet);
    end loop;
END;
/
set serveroutput on;

-- 2. Napíšte PL/SQL blok, ktorý pomocou explicitného kurzora vypíše číslo 
-- predmetu, názov predmetu a garanta predmetu pred 20-timi rokmi.
DECLARE
BEGIN
    for rec in (
        select cis_predm, nazov, meno, priezvisko
        from zap_predmety zp
        join predmet p using(cis_predm)
        join predmet_bod pb using(cis_predm)
        join ucitel u on (u.os_cislo = pb.garant)
        where extract(year from datum_sk) = extract(year from sysdate) - 20
        
    ) loop
        dbms_output.put_line(rec.cis_predm || ' ' || rec.nazov || ' ' || rec.meno || ' ' || rec.priezvisko);
    end loop;
END;
/

-- 3. Napíšte PL/SQL blok, ktorý pomocou parametrizovaného kurzora vypíše ku 
-- každému predmetu študentov, ktorý daný predmet absolvovali so známkou lepšou 
-- ako C, pričom parameter kurzora bude školský rok, v ktorom študenti daný 
-- predmet absolvovali.
DECLARE 
    cursor cur_predmety(p_skrok NUMBER) is
        select nazov, os_cislo 
        from predmet
        join zap_predmety using(cis_predm)
        join student using(os_cislo)
        where vysledok in ('A', 'B')
        and skrok = p_skrok;
    v_skrok NUMBER;
BEGIN
    v_skrok := 2025;
    for rec in cur_predmety(v_skrok)
        loop
            dbms_output.put_line(rec.nazov || ' ' || rec.os_cislo);    
        end loop;
END;
/

-- 4. Napíšte PL/SQL blok, ktorý pomocou parametrizovaného kurzora vypíše 
-- ku každému učiteľovi zvlášť študentov, ktorým je prednášajúci pre každý 
-- predmet v školskom roku, ktorý je parametrom kurzora.
DECLARE
    cursor c1(p_skrok number) is
        select meno, priezvisko, s.os_cislo
        from ucitel u
        join zap_predmety zp on(u.os_cislo = zp.prednasajuci)
        join student s on(zp.os_cislo = s.os_cislo);
        v_skrok number;
BEGIN
    v_skrok := 2025;
    for rec in c1(v_skrok)
    loop
        dbms_output.put_line(rec.meno || ' ' || rec.priezvisko || ' ' || 
            rec.os_cislo);
    end loop;
END;
/

rollback;

--KOLEKCIE
-- 1. Definujete t_student s atribútmi os_cislo INTEGER, meno VARCHAR2(15) a 
--rocnik CHAR(1). Definujete t_student_tab ako NESTED TABLE typu t_student a 
--premennú tohto typu. Kolekciu naplníte študentmi z tabuliek student a os_udaje. 
--Z kolekcie odstránite všetkých študentov druhého ročníka. Na konci vypíšete celú kolekciu.
create or replace type t_student as object (
    os_cislo integer,
    meno varchar2(15),
    rocnik char(1)
);
/

create or replace type t_student_tab as table of t_student;
/

declare
    v_students t_student_tab:=t_student_tab();
begin
    select t_student(s.os_cislo, u.meno, s.rocnik)
    bulk collect into v_students
    from student s
    join os_udaje u using(rod_cislo);
    
    for i in reverse v_students.first .. v_students.last
    loop
        if v_students(i).rocnik = '2'
            then v_students.delete(i);
        end if;    
    end loop;
end;
/

drop type t_student_tab;
delete t_student;


rollback;


create or replace type t_ucitel as object (
    os_cislo_ucitel char(5),
    meno varchar2(15),
    katedra char(4)
);

create or replace type t_ucitel_tab as table of t_ucitel;
/

declare
    v_ucitelia v_ucitel_tab := t_ucitel_tab();
begin
    select os_cislo, meno, katedra
    bulk collect into v_ucitelia
    from ucitel;
    
    for i in reverse v_ucitelia.first .. v_ucitelia.last
    loop
        if v_ucitelia(i).
    end loop;
end;
/
create table t1 (val integer);

insert into t1 values(5);
insert into t1 values(55);
savepoint s1;
insert into t1 values(15);
savepoint s2;
insert into t1 values(25);
rollback to s1;
insert into t1 values (35);
rollback;
select count(*) from t1;
delete from t1;


--OUTER JOIN
-- 1. Vypíšte všetky osoby a ak sú aktuálnymi študentmi (ukončenie IS NULL), 
-- vypíšte aj číslo štúdia, odbor a zameranie.
select rod_cislo, st_skupina, s.st_odbor, s.st_zameranie
from student s
left join st_odbory o on(s.st_odbor = o.st_odbor and s.st_zameranie = o.st_zameranie)
where ukoncenie is null;

-- 2. Vypíšte všetky osoby a ak niekedy študovali odbor "Informatika", vypíšte údaje o tomto štúdiu.
select distinct meno, priezvisko, rod_cislo, s.st_odbor, popis_odboru
from os_udaje
left join student s using(rod_cislo)
left join st_odbory o on(s.st_odbor = o.st_odbor and s.st_zameranie = o.st_zameranie)
where popis_odboru = 'Informatika';

-- 3. Pre každú osobu vypíšte počet predmetov zapísaných v školskom roku 2003. 
-- Uveďte aj osoby ktoré nemali v danom roku zapísané žiadne predmety.
select rod_cislo, count(cis_predm)
 from student
 left join zap_predmety using(os_cislo)
 where skrok = 2003
 group by rod_cislo;
 
--4. Pre každú osobu vypíšte počet absolvovaných predmetov (výsledok ≠ "F") u 
-- učiteľa Petr Cenek. Vo výstupe musia byť aj osoby bez absolvovaných predmetov.
select s.rod_cislo, u.meno, u.priezvisko, count(zp.cis_predm)
from student s
left join zap_predmety zp using(os_cislo)
left join ucitel u on(zp.prednasajuci = u.os_cislo)
where vysledok <> 'F' and
    u.meno = 'Petr' and
    u.priezvisko = 'Cenek'
    group by s.rod_cislo, u.meno, u.priezvisko;
    
--IN / EXISTS
--1. Vypíšte všetky predmety, ktoré nemá zapísaný žiadny študent;
select cis_predm
from zap_predmety
where not exists
(
    select cis_predm
    from student
    join zap_predmety using(os_cislo)
);

--2. Vypíšte všetkých študentov, ktorí majú aspoň jeden úspešne absolvovaný 
--predmet (výsledok je iný ako F a zároveň nie je NULL);
select os_cislo
from student
where exists(
    select os_cislo
    from student
    join zap_predmety using(os_cislo)
    where vysledok <> 'F'
);

--3. Vypíšte osoby, ktoré nikdy neboli študentmi.
select rod_cislo
from os_udaje
where not exists(
    select rod_cislo
    from student
);

--4. Vypíšte študentov, ktorí majú zapísaný aspoň jeden predmet 
--garantovaný učiteľom Petr Cenek
select os_cislo
from zap_predmety
where exists (
    select u.meno, u.priezvisko
    from ucitel u
    join zap_predmety zp on(u.os_cislo = zp.prednasajuci)
    where u.meno = 'Petr' and u.priezvisko = 'Cenek';
);

--OBJEKTY
-- 1. Doplňte ORDER MEMBER FUNCTION cmp v objektovom type t_studium_hist 
-- (atribúty napr. os_cislo, st_odbor, st_zameranie, dat_zapisu, dat_ukoncenia) 
-- tak, aby porovnávala záznamy najprv podľa dat_zapisu a pri rovnosti podľa 
-- st_odbor; následne utrieďte tabuľku studium_hist podľa stĺpca polozka.

create or replace type t_studium_hist as object(
    os_cislo integer,
    st_odbor number,
    st_zameranie number,
    dat_zapisu Date,
    dat_ukoncenia Date,
    order member function cmp(other t_studium_hist) return integer
);
/
create or replace type body t_studium_hist as 
    order member function cmp(other t_studium_hist) return integer is
    begin
        if self.dat_zapisu < other.dat_zapisu then
            return -1;
        elsif self.dat_zapisu > other.dat_zapisu then
            return 1;
        else
            if self.st_odbor < other.st_odbor then
                return -1;
            elsif self.st_odbor > other.st_odbor then
                return 1;
            else 
                return 0;
            end if;
        end if;
    end cmp;
end;
/

create table studium_hist(
    polozka t_studium_hist
);

select * from studium_hist
order by polozka;

drop type t_studium_hist;
drop table studium_hist;

-- 2. Do objektového typu t_student (obsahuje napr. rod_cislo, meno, 
-- priezvisko, rok_nastupu, st_odbor, st_zameranie) pridajte MEMBER funkciu 
-- cele_meno, ktorá vráti reťazec vo formáte 'PRIEZVISKO MENO'; vypíšte z 
-- objektovej tabuľky student_obj pre všetkých študentov rod_cislo a výsledok cele_meno().

create or replace type tt_student as object(
    rod_cislo char(11),
    meno varchar2(15),
    priezvisko varchar2(15),
    rok_nastupu number,
    st_odbor number,
    st_zameranie number,
    map member function cele_meno return varchar2
);
/

create or replace type body tt_student as
    map member function cele_meno return varchar2 is
    begin
        return self.meno || ' ' || self.priezvisko;
    end cele_meno;   
end;
/

create table tab_students of tt_student;

select s.cele_meno() from tab_students s;

rollback;

