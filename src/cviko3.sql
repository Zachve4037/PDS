set serveroutput on;

declare cursor tab_rename
    is
        select 'Alter table ' || table_name || 'rename to ' || 'st_' ||  table_name from tabs;
        text varchar(200);
begin
    open tab_rename;
    loop
        fetch tab_rename into text;
        dbms_output.put_line(text);
        exit when tab_rename%notfount;
        execute immediate text;
    end loop;
    close tab_renam;
end;
/

declare cursor tab_rename
    is
select 'Alter table ' || table_name || 'rename to ' || substr(table_name, 4) from tabs;
text varchar(200);
begin
open tab_rename;
loop
fetch tab_rename into text;
        dbms_output.put_line(text);
        exit when tab_rename%notfount;
execute immediate text;
end loop;
close tab_renam;
end;
/

desc user_procedures; --vypise zoznam atributov z tabulky
select * from user_procedures;

select 'Alter ' || object_type || ' ' || object_name || ' compile'
    from all_procedures
    where object_type = upper('procedure') or object_type = upper('function');

create or replace type t_osoba is object(
       rod_cislo char(1),
       meno varchar2(20),
       priezvisko varchar(20)
);
/

create table osoby
(
    osoba t_osoba
);
/

create table osoby of t_osoba;

insert into osoby
    select t_osoba(rod_cislo, meno, priezvisko)
    from os_udaje;

insert into osoby
select rod_cislo, meno, priezvisko
from os_udaje;


select rod_cislo, rn
from (
    select rod_cislo, meno, priezvisko, row_number() over (partition by rod_cislo) as rn
        from osoby
 )
    where rn = 1;

delete from osoby
     where rowid in (
        select rowid
        from (
              select rod_cislo, row_number() over (partition by rod_cislo) as rn
              from osoby
          )
    where rn = 1
 );

-- spravit bez rowid();

alter type t_osoba add member function den_narodenia return varchar cascade;

create or replace type body t_osoba
    as member function den_narodenia return varchar
    is
        dn date;
    begin
        dn:= to_date(substr(rod_cislo, 1, 2) || '-' || mod(substr(rod_cislo, 3, 2), 50) ||  '-' || substr(rod_cislo, 5, 2), 'YY-MM-DD');
        return to_char(dn, 'DAY');

        exception when others then
        DBMS_OUTPUT.PUT_LINE('chyba');
    end;
end;
/

select meno, priezvisko, value(o).den_narodenia()
from osoby o;

select * from osoby
where priezvisko = 'Kvet'

update osoby o
set value(o) = t_osoba('rodcislo', 'meno', 'priezvisko')
    where rod_cislo = 'rod_cislo';

select * from osoby o
 order by value(o);

--pridat metodu triedenia;

alter type t_osoba
add order member function tried(druhy_t_osoba t_osoba) return integer cascade;

alter type t_osoba
add member function getVek return integer cascade;

create or replace type body t_osoba
    as member function den_narodenia return varchar
        is
        dn date;
    begin
        dn:= to_date(substr(rod_cislo, 1, 2) || '-' || mod(substr(rod_cislo, 3, 2), 50) ||  '-' || substr(rod_cislo, 5, 2), 'YY-MM-DD');
        return to_char(dn, 'DAY');

    exception when others then
        DBMS_OUTPUT.PUT_LINE('chyba');
    end;

    member function getVek return integer
        is
        dn date;
    begin
        dn:= to_date(substr(rod_cislo, 1, 2) || '-' || mod(substr(rod_cislo, 3, 2), 50) ||  '-' || substr(rod_cislo, 5, 2), 'YY-MM-DD');
        return months_between(sysdate, dn) / 12;

    exception when others then
        return -1;
    end;

    order member function tried(druhy t_osoba) return integer
    is
    begin
        if self.getVek() >= druhy.getVek then return 1;
        else if self.getVek = druhy.getVek then return 0;
        else return -1;
        end if;
    end;
end;
/

--urobit to iste, ale spravit pre tabulku kde objekt je atribut

create table osoby2(
    osoba t_osoba
);

insert into osoby2 select t_osoba(rod_cislo, meno, priezvisko) from osoby;
insert into osoby2 select value(o) from osoby;

--prerobit na tabulku kde objekt je ako atribut
--zrusit order metodu a pripravit obdony variant pre map namiesto order
