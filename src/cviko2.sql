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