create database link dblink
connect to student05
  identified by student05
   using '(DESCRIPTION =(ADDRESS = (PROTOCOL = TCP)
           (HOST = obelix.fri.uniza.sk)(PORT = 1522))
             (CONNECT_DATA =(SERVER = DEDICATED)
               (SERVICE_NAME = orcladm.fri.uniza.sk)  ) )';
            
create table del_tab (
    os_cislo varchar2(20)
);

select * from student05.del_tab@dblink;

insert into student05.del_tab@dblink
select os_cislo from student s join st_odbory st on(s.st_odbor = st.st_odbor and s.st_zameranie = st.st_zameranie) where rocnik = 2 and popis_odboru = 'Informatika';

commit;

delete from zap_predmety
    where os_cislo in (
        select os_cislo from student05.del_tab@dblink
    );

delete from student 
    where os_cislo in (
        select os_cislo from student05.del_tab@dblink
    );

commit;

create table kontakty
(id_kontaktu integer, 
 rod_cislo char(11), 
 typ char(1) check (typ in ('E', 'M')),
 hodnota varchar(50));

exec kvet3.vloz_kontakty;

create table rodokmen
(id integer primary key, 
 meno varchar(50), 
 priezvisko varchar(50), 
 id_matky integer, 
 id_otca integer, 
 foreign key(id_matky) references rodokmen(id),
 foreign key(id_otca) references rodokmen(id)
); 

insert into rodokmen values(1, 'Peter', 'Marko', null, null);
insert into rodokmen values(2, 'Jana', 'Ozová', null, null);
insert into rodokmen values(3, 'Miroslava', 'Marková', 2,1);
insert into rodokmen values(4, 'Peter', 'Marko', 2,1);
insert into rodokmen values(5, 'Juraj', 'Marko', 2,1);
insert into rodokmen values(6, 'Stanislava', 'Marková', 2,1);
insert into rodokmen values(7, 'Daniela', 'Draškovičová', null,null);
insert into rodokmen values(8, 'Melánia', 'Marková', 7,4);
insert into rodokmen values(9, 'Jozefína', 'Marková', 7,4);
insert into rodokmen values(10, 'Vlasta', 'Marková', 7,4);
insert into rodokmen values(11, 'Stanislav', 'Šedivý', null, null);
insert into rodokmen values(12, 'Karol', 'Šedivý', 6, 11);
insert into rodokmen values(13, 'Karolína', 'Šedivá', 6, 11);
insert into rodokmen values(14, 'Marek', 'Šedivý', 6, 11);
insert into rodokmen values(15, 'Tomáš', 'Šedivý', 6, 11);
insert into rodokmen values(16, 'Emil', 'Káčer', null, null);
insert into rodokmen values(17, 'Anna', 'Káčerová', 3, 16);
insert into rodokmen values(18, 'Mikuláš', 'Káčer', 3, 16);
insert into rodokmen values(19, 'Alexej', 'Káčer', 3, 16);
insert into rodokmen values(20, 'Jozef', 'Mak', 9, 20);
insert into rodokmen values(21, 'Terézia', 'Maková', 9, 20);
insert into rodokmen values(22, 'Ján', 'Maková', 9, 20);
insert into rodokmen values(23, 'Jana', 'Maková', 9, 20);
insert into rodokmen values(24, 'Ctibor', 'Bralo', null, null);
insert into rodokmen values(25, 'Jana', 'Bralová', 10, 24);
insert into rodokmen values(26, 'Ctibor', 'Bralo', 10, 24);
insert into rodokmen values(27, 'Martina', 'Moková', null, null);
insert into rodokmen values(28, 'Michal', 'Moko', 27, 20);
insert into rodokmen values(29, 'Marian', 'Moko', 27, 20);

select * from rodokmen;

commit;

select meno, priezvisko 
 from os_udaje 
  where rod_cislo not in(
    select 'X' from kontakty
  );
  
select meno, priezvisko
 from os_udaje
 where not exists (
    select 'X' from kontakty
    where os_udaje.rod_cislo = kontakty.rod_cislo
);

select d1.meno, d1.priezvisko, d2.meno, d2.priezvisko
 from rodokmen d1 join rodokmen d2 on (d1.id_matky = d2.id_matky)
 where d1.id > d2.id; -- '>' aby som to nemal symetricky
 
--ku kzadej osobe vypisat matku
select d1.meno, d1.priezvisko, d2.meno, d2.priezvisko
 from rodokmen d1 left join rodokmen d2 on(d1.id_matky = d2.id);
 
select meno || ' ' || priezvisko
 from rodokmen
  connect by prior id = id_matky;

--anticykliace podmienky
select meno || ' ' || priezvisko
 from rodokmen
  connect by prior id = case when id=id_matky then null
                    else id_matky
                end
    start with id=2;

create table osoba_tab as select * from kvet3.osoba_tab;

select * from osoba_tab
where meno = 'Michal';

