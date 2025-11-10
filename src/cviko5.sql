declare
    type intTable is table of Number;
    os_cisla intTable;
    ind Number;

begin
    select os_cislo bulk collect into os_cisla from student;

    for i in os_cisla.FIRST .. os_cisla.LAST
    loop
        if mod(os_cisla(i), 2) = 0 then
            os_cisla.DELETE(i);
        end if;
    end loop;

    for i in os_cisla.FIRST .. os_cisla.LAST
        loop
        if os_cisla.EXISTS(i) then
            DBMS_OUTPUT.PUT_LINE(os_cisla(i));
        end if;
    end loop;

    ind:=os_cisla.FIRST;
    for i in 1 .. os_cisla.COUNT
    loop
        if mod(os_cisla(ind), 10) = 5 then
            DBMS_OUTPUT.PUT_LINE(os_cisla(ind));
        end if;
        ind:=os_cisla.NEXT;
    end loop;

end;
/

create or replace type t_pole is table of integer;

create table kolekcie (
    id integer,
    kolekcia t_pole
) nested table kolekcia store as t_kolekcia;
/


--skusit este cez pure sql nie cez pl/sql
declare
    os_druhaci t_pole:= t_pole();
begin
    select os_cislo bulk collect into os_druhaci from student where rocnik = 2;
    insert into kolekcie values(2, os_druhaci);
end;
/

insert into kolekcie values(2, cast(multiset(select os_cislo from student where rocnik = 2) as t_pole));

select nested.COLUMN_VALUE from table(select kolekcia from kolekcie)nested;
delete from table(select kolekcia from kolekcie)nested where nested.column_value in (
    select os_cislo from ZAP_PREDMETY where cis_predm = 'BI06'
);

--json (element: meno, priezvisko, jsonpole[os_cislo], jsonpole[json(cis_predm, vysledok)])
select json_object('meno' value meno,
                   'priezvisko' value priezvisko,
                    'os_cisla' value json_arrayagg(os_cislo),
                    'prems' value json_object(
                           'cislo_predmetu' value cis_predm,
                           'vysledok' value vysledok))
from os_udaje join ZAP_PREDMETY using(os_cislo);

select * from student;

select user from dual;
select sys_context('USERENV', 'CURRENT_USER') from dual;
select owner, table_name from all_tables where table_name = upper('student');