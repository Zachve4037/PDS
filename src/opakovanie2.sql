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

drop table tab_students;
drop type tt_student;
commit;

--3. Do objektového typu t_studium pridajte MEMBER procedúru 
--ukonci(p_datum DATE), ktorá nastaví atribút dat_ukoncenia na zadaný dátum; 
--napíšte príkaz, ktorým ukončíte štúdium konkrétneho študenta 
--(vyberte podľa rod_cislo) k dátumu 30.06.2003 v objektovej tabuľke studium_obj.
create or replace type t_studium as object (
    os_cislo integer,
    st_odbor number,
    st_zameranie number,
    dat_ukoncenia date,
    member procedure ukonci(p_datum Date)
);
/

create or replace type body t_studium as
 member procedure ukonci(p_datum Date) is
  begin
    self.dat_ukoncenia := p_datum;
  end ukonci;
end;
/
 

 
declare
    v_studium t_studium;
begin
    select value(s) into v_studium
    from student s
    where s.rod_cislo = '123456/1234';
    
    v_studium.ukonci(to_date('30.06.2003', 'DD.MM.YYYY')
    
    update studium_obj
    set s = v_studium
    where s.rod_cislo = '123456/1234';
end;
/


--4. Vytvorte objektovú tabuľku zapisy_obj OF t_zapis_predmetu (atribúty napr. 
--os_cislo, cis_predm, skrok, vysledok) a napíšte INSERT, ktorý do nej vloží 
--všetky zápisy predmetov študentov odboru „Informatika“ v školskom roku 2003; 
--údaje čerpajte z tabuliek student, st_odbor a zap_predmety, pričom 
--predpokladajte, že typ t_zapis_predmetu má vhodný konštruktor.
create or replace type t_zapis_predmetu as object (
    os_cislo number,
    cis_predm char(5),
    skrok number,
    vysledok char(1)
);
/

create or replace type zapisy_obj as table of t_zapis_predmetu;
/


insert into zapisy_obj 
 select t_zapis_predmetu(
        zp.os_cislo, 
        zp.cis_predm, 
        zp.skrok, 
        zp.vysledok
    )
 from zap_predmety zp
 join student s on(s.os_cislo = zp.os_cislo)
 join st_odbory z on(s.st_odbor = z.st_odbor and s.st_zameranie = z.st_zameranie)
 where popis_odboru = 'Informatika'
  and skrok = 2003;
  
--1
insert into tomas.backup_predmet@remote_link select * from p_predmet;

--2
insert into lenka.data_vzdelanie@remote_link select * from p_vzdelanie;

--3
insert into lenka.log_osoby@remote_link 
    select * from p_osoba 
     where id_osoby not in(
        select id_osoby
        from log_osoby
    );
    
--4
update p_poistenie p
    set dat_do = sysdate
    where exists (
        select 1 from dusan.data_osoby@remote_link d 
         where d.id_osoby = p.id_osoby
);

--5
update p_zamestnanec pz
set stav_zamestnania = 'NEAKTIVNY'
where id_zamestnanca in (
    select * from tomas.inactive_ids@remote_link t
    where pz.id_zamestnanca = t.id_zamestnanca
    );
    
--6
update p_student s
set ukoncenie
where os_cislo in (
    select * from lenka.ukonceni_studenti@remote_link l
    where s.os_cislo = l.os_cislo
);

--7
insert into p_predmet
select * from martin.predmet_link@remote_link;

--8
insert into p_ucty
select * from lenka.backup_ucty@remote_link;

--9
delete from p_poberatel p
where exists (
    select id_poberatela
    from andrea.del_ids@remote_link a
    where p.id_poberatela = a.id_poberatela
);

--10
delete from p_nepritomnost n
where exists (
    select * 
    from tomas.del_neprit@remote_link t
    where t.id_neprit = n.id_neprit
);

--11
select 'DROP INDEX ' || index_name || ';' 
from user_indexes
where table_name = 'p_poistenie'
and index_type = 'NORMAL';

--12
--what the fuck ved nemozes mat rovnake indexy
select 'DROP INDEX ' || index_name || ';'
from user_indexes
where table_name = 'p_mesto'
and usert_constraints <> 'U';

--13
select 'alter index ' || index_name || 'rebuild;'
from user_indexes ui
where ui.table_name in (
    select table_name
     from user_constraint us
     where us.constraint_type = 'R'
);

--INDEXI
create index ind on p_osoba(lower(priezvisko));
create index ind on p_osoba(psc);
create index ind on p_prispevky(extract(year from kedy));
create index ind on p_postihnutie(lower(nazov));
create index ind on zamestnanec(case when datum_do is null then 1 end);
create index ind on p_osoba(substr(rod_cislo, 1, 1));

--JSON
--50
select json_value(b.doc, '$.nazov') as nazov
from kniha_json b where json_value(b.doc, '$.autor') like 'M%';

--51
select json_value(b.doc, '$.nazov') as nazov
from kniha_json b where to_number(json_value(b.doc, '$.rok_vydania')) > 2010;

--52
select json_value(b.doc, '$.student') as stud
from student_json b where to_number(json_value(b.doc, '$.rocnik')) > 2;

--53
select json_value(b.doc, '$.meno') as mena
from student_json b where to_number(json_value(b.doc, '$.priemer')) < 2.0;

--54
select b.doc from produkt_json b where to_number(json_value(b.doc, '$.cena')) > 20;

--56
select z.doc from zamestnanec z where json_value(z.doc, '$.pozicia') = 'MANAGER';
/
--CONNECT BY LEVEL
--69
with mesiace as (
    select level as mesiac
    from dual 
    connect by level <= 12
)
select mesiac, to_char(to_date(mesiac, 'MM'), 'Month') as nazov_mesiaca, count(p.dat_od) as pocet
    from mesiace m
    left join p_poistenie p on (extract(month from p.dat_od) = m.mesiac
    and extract(year from p.dat_od) = extract(year from sysdate) -1)
    group by mesiac
    order by mesiac;
    
--70
with mesiace as (
    select level as mesiac
    from dual
    connect by level <= 12
) select mesiac, to_char(to_date(mesiac, 'MM'), 'Month') as nazov_mes, count(dat_do)
    from mesiace m
    left join p_poistenie p
    on (extract(month from p.dat_do) = m.mesiac 
        and extract(year from p.dat_do) = extract(year from sysdate) -1)
    where dat_do <> null
    group by mesiac
    order by mesiac;
    
--71
with mesiace as (
    select level as mesiac
    from dual
    connect by level <= 12
) select mesiac, to_char(to_date(mesiac, 'MM'), 'Month') as nazov_mes, count(id_zamestnavatela)
    from mesiace m
    left join p_zamestnanec p
    on (extract(month from dat_od) = m.mesiac and extract(year from dat_od) = extract(year from sysdate) -1)
    group by mesiac
    order by mesiac;
   
--73
with dni as (
    select trunc(sysdate, 'year') - level as den
    from dual
    connect by level <= 366
) select den, count(kedy)
    from dni d
    left join p_prispevky p on (trunc(p.kedy) = d.den)
    group by den
    order by den;
    
--74
with dni as (
    select to_date(extract(year from sysdate) - 1 || '-04-01', 'YYYY-MM-DD') + level - 1 as datum
    from dual
    connect by level <= 30
) select datum, count(rod_cislo)
    from dni d
    left join p_zamestnanec p on p.dat_od = d.datum
    group by datum
    order by datum;
    
with dni as (
    select to_date(extract(year from sysdate) - 1 || '-05-01', 'YYYY-MM-DD') + level -1 as datum
    from dual
    connect by level <= 31
) select * from dni;

--75
with dni as (
    select to_date(extract(year from sysdate) -1 || '-07-01', 'YYYY-MM-DD') + level -1 as datum
    from dual
    connect by level <= 92
) select datum, count(id_poistenca)
    from dni d
    left join p_poistenie p on p.dat_do = d.datum
    group by datum
    order by datum;
    
--76
with dni as (
    select trunc(sysdate, 'year') - level as datum
    from dual
    connect by level <= 366
) select * from dni;

--77
with mesiace as (
    select level as mesiac
    from dual
    connect by level <= 12
) select mesiac, to_char(to_date(mesiac, 'MM'), 'Month') as nazov_mes from mesiace;

--78
with dni as (
    select to_date(extract(year from sysdate) - 1 || '-05-01', 'YYYY-MM-DD') + level - 1 as datum
    from dual
    connect by level <= 31
) select * from dni;

--79
with mesiace as (
    select level as mesiac
    from dual
    connect by level <= 12
) select mesiac, to_char(to_date(mesiac, 'MM'), 'Month') as nazov_mes
    from mesiace;

--80
with mesiace as (
    select level as mesiac
    from dual
    connect by level <= 12
) select mesiac, to_char(to_date(mesiac, 'MM'), 'Month') as nazov_mes
    from mesiace;
    
--81
with dni as (
    select to_date(extract(year from sysdate) -1 || '-01-01', 'YYYY-MM-DD') + level - 1 as den
    from dual
    connect by level <= 31
) select * from dni;

--82
with mesiace as (
    select level as mesiac
    from dual
    connect by level <= 12
) select to_char(to_date(mesiac, 'MM'), 'Month') as nazov_mes
    from mesiace;

--83
with dni as (
    select to_date(extract(year from sysdate) -1 || '-12-01', 'YYYY-MM-DD') + level - 1 as datum
    from dual
    connect by level <=31
) select * from dni;

--84
with mesiace as (
    select level as mesiac
    from dual
    connect by level <= 12
) select to_char(to_date(mesiac, 'MM'), 'Month') as nazov_mes
    from mesiace;
    
--85
with dni as (
    select trunc(sysdate, 'year') - level as datum
    from dual
    connect by level <= 366
) select * from dni;

--mesiace
with mesiace as (
    select level as mesiac
    from dual
    connect by level <= 12
) select to_char(to_date(mesiac, 'MM'), 'Month') as nazov_mes from mesiace;

--dni v mesiaci
with dni as (
    select to_date(extract(year from sysdate) -1 || '01-01', 'YYYY-MM-DD') + level -1 as datum
    from dual
    connect by level <= 31
) select * from dni;

--vsetky dni v roku
with dni as (
    select trunc(sysdate, 'year') - level as den
    from dual
    connect by level <=366
) select * from dni;

--mesiace
with mesiace as (
    select level as mesiac
    from dual
    connect by level <= 12
) select to_char(to_date(mesiac, 'MM'), 'Month') as nazov_mes
    from mesiace;
    
--dni v najuari 
with dni as (
    select to_date(extract(year from sysdate) -1 || '-01-01', 'YYYY-MM-DD') + level - 1 as datum
    from dual
    connect by level <= 31
) select * from dni;

--dni v roku
with dni as (
    select trunc(sysdate, 'year') - level
    from dual
    connect by level <= 366
) select * from dni;


--mame index idx(rod_cislo, meno, priezvisko)
select meno, priezvisko
from os_udaje
where substr(rod_cislo, 5, 1) = '4'; --aku pristupovu metodu pouzijeme?

--vypiste pocet prispevkov. Vypiste to ale do stlpcov je_poistenec a nie je poistenec
select
    case when rod_cislo in (select rod_cislo from p_poistenie) then count(id_poberatela) else 0 end as je_poistenec,
    case when rod_cislo not in (select rod_cislo from p_poistenie) then count(id_poberatela) else 0 end as nie_je_poistenec
 from p_prispevky
 left join p_poberatel using(id_poberatela)
 left join p_osoba using(rod_cislo)
 left join p_poistenie using(rod_cislo)
 group by rod_cislo;
 
--pre kazdy mesiac v minulom roku vypiste sumu prispevkov pre tento mesiac
with mesiace as (
    select level as mesiac
    from dual
    connect by level <= 12
) select mesiac, sum(suma)
 from mesiace
 --neviem ci som dal left ci co xd
 left join p_prispevky on extract(month from kedy) = mesiac
 where extract(year from kedy) = extract(year from sysdate) -1
 group by mesiac;
 
--vytvorte kolekciu t_pole (rod_cislo, meno, priezvisko, dajVek)
--vytvorte tabulku kde bude t_pole ako atribut
--naplnte kolekciu METODOU napln_pole(nazov_tabulky, nazov_atributu)
--nasledne vymazte z tabulky zaznamy kde je vek > 25
create or replace type tt_pole as object(
    rod_cislo char(11),
    meno varchar2(20),
    priezvisko varchar2(20),
    member function dajVek return integer
);
/

create or replace type body tt_pole as 
    member function dajVek return integer is
     begin
        return months_between(to_date(
            substr(rod_cislo, 5, 2) || '-' || 
            mod(substr(rod_cislo, 3, 2), 50) || '-' || 
            substr(rod_cislo, 1, 2), 'DD-MM-YY'),
            sysdate) / 12;
     end dajVek;
end;
/

rollback;

create table tab_pole (
    attr tt_pole
);

--tu som zabudol typy parametrov PICA
create or replace function napln_kolekciu(nazov_tab varchar2, nazov_attr) as
begin
 select 'INSERT INTO ' || nazov_tab || ' VALUES (
 t_pole('12345678901', 'PDS1', 'PDS1'),
 t_pole('12345678901', 'PDS2', 'PDS2'));' --taktiez som neukoncil
end;
/

delete from tab_pole
where attr.dajVek() > 25;