create or replace function getVek(rc char)
    return number
    is
    begin
      return months_between(
             sysdate,
             to_date(
                     substr(rc, 1,2) || '-' ||
                     mod(substr(rc, 3, 2), 50) || '-' ||
                     substr(rc, 5, 2), 'RR-MM-DD')) / 12;
    exception when others
        then return -1;
end;
    /

drop function getVek;

select * from
    (select months_between(
                            sysdate,
                            to_date(
                                    substr(rod_cislo, 1,2) || '-' ||
                                    mod(substr(rod_cislo, 3, 2), 50) || '-' ||
                                    substr(rod_cislo, 5, 2), 'RR-MM-DD')) / 12 as vek,
            meno, priezvisko, row_number() over(order by months_between(
                                                                         sysdate,
                                                                         to_date(
                                                                         substr(rod_cislo, 1,2) || '-' ||
                                                                         mod(substr(rod_cislo, 3, 2), 50) || '-' ||
                                                                         substr(rod_cislo, 5, 2), 'RR-MM-DD')) / 12 desc) as r
     from OS_UDAJE)
    where r = 2;

select * from
    (select months_between(
                            sysdate,
                            to_date(
                                    substr(rod_cislo, 1,2) || '-' ||
                                    mod(substr(rod_cislo, 3, 2), 50) || '-' ||
                                    substr(rod_cislo, 5, 2), 'RR-MM-DD')) / 12 as vek,
            meno, priezvisko, rocnik,  row_number() over(partition by rocnik
                order by months_between(
                         sysdate,
                         to_date(
                                 substr(rod_cislo, 1,2) || '-' ||
                                 mod(substr(rod_cislo, 3, 2), 50) || '-' ||
                                 substr(rod_cislo, 5, 2), 'RR-MM-DD')) / 12 desc) as r
     from OS_UDAJE
     join student using(rod_cislo))
where r = 2;

declare cursor cur_os is (select meno, priezvisko
    from os_udaje);
    data cur_os%rowtype;
begin
    open cur_os;
        loop
            fetch cur_os into data;
            exit when cur_os%notfound;
            DBMS_OUTPUT.PUT_LINE(data.meno || ' ' || data.priezvisko);
        end loop;
    close cur_os;
end;
/

set serveroutput on;

set serveroutput off;

--vypis os_cislo pre osobu
select meno, priezvisko ,cursor(select os_cislo
                                from student
                                where OS_UDAJE.ROD_CISLO = student.rod_cislo)
from os_udaje;

--listagg
--vypise vsetky osobne cisla pre osobu
select meno, priezvisko,
    listagg(os_cislo, ', ') within group (order by os_cislo)
from OS_UDAJE
left join student using(rod_cislo)
group by meno, priezvisko, rod_cislo;

declare
    i integer;
    chyba exception;
    pragma exception_init ( chyba, -20000 );
begin
    select count(*) into i
    from STUDENT
        where rod_cislo='800407/3522';
    if i > 1 then
        raise_application_error(-20000, 'osoba studovala viackrat');
    end if;
    exception when others
    then DBMS_OUTPUT.PUT_LINE(SQLcode);
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
end;
/

declare
    v_int integer:= 1;
begin
    declare
        v_char char(1):='x';
    begin
        v_int:=2;
        DBMS_OUTPUT.PUT_LINE(v_int);
        DBMS_OUTPUT.PUT_LINE(v_char);
    end;
    DBMS_OUTPUT.PUT_LINE(v_int);
end;
/

<<outer>>
    declare
    v_int integer:=1;
begin
    <<inner>>
        declare
        v_int integer:=2;
    begin
        v_int:=2;
        dbms_output.put_line(v_int); -- 2
        dbms_output.put_line(inner.v_int); -- 2
        dbms_output.put_line(outer.v_int); -- 1
    end;
    dbms_output.put_line(v_int); -- 1
end;
/