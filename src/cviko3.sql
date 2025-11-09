declare
    cursor tab_rename is
        select 'alter table ' || table_name || ' rename to st_' || table_name
        from tabs;
    text varchar2(200);
begin
    open tab_rename;
    loop
        fetch tab_rename into text;
        exit when tab_rename%NOTFOUND;
        dbms_output.put_line(text);
        execute immediate text;
    end loop;
    close tab_rename;
end;
/

rollback;

declare cursor tab_rename
    is
        select 'Alter table ' || table_name || 'rename to ' || substr(table_name, 4) from tabs;
            text varchar(200);
    begin
        open tab_rename;
        loop
            fetch tab_rename into text;
            exit when tab_rename%notfound;
            dbms_output.put_line(text);
            execute immediate text;
        end loop;
    close tab_rename;
end;
/

DESC USER_PROCEDURES; --vypise zoznam atributov z tabulky
select * from user_procedures;

select 'Alter ' || object_type || ' ' || object_name || ' compile'
    from all_procedures
    where object_type = upper('procedure') or object_type = upper('function');

rollback;

create or replace type osoba is object(
       rod_cislo char(1),
       meno varchar2(20),
       priezvisko varchar(20)
);
/

create table t_osoby_a
(
    osoba_col osoba
);
/

rollback;

create table t_osoby_o of osoba;

insert into t_osoby_a
    select osoba(rod_cislo, meno, priezvisko)
    from os_udaje;

insert into t_osoby_o
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
with duplicates as(
    select *
    from (
             select rod_cislo, row_number() over (partition by rod_cislo) as rn
             from osoby
         )
    where rn > 1
)
delete from osoby o
where exists(
    select 1
    from duplicates d
    where o.rod_cislo = d.rod_cislo
      and o.meno = d.meno
      and o.priezvisko = d.priezvisko
);

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
--zrusit order metodu a pripravit obdobny variant pre map namiesto order