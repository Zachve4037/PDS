select 'drop table' || table_name || ';'
from user_tables
where upper(table_name) like '%ZALOHA%';

select 'alter table' table_name || ' drop constraint ' || constraint_name || ';' as drop fk
from user_contraints
where table_name = 'p_prispevky'
and constraint type = 'R';

declare
    type t_map is table of number index by varchar2(20);
    m t_map;
    k varchar2(20);
begin
    m('010101/0001'):=3;
    m('990101/1234'):0;
    
    k:=m.first;
    while k is not null loop
        dbms_output.put_line(k || '=>' || m(k));
        k:=m.next(k);
    end loop;
end;
/

declare
 type t_tab is table of varchar2(50);
 t t_tab := t_tab('A','B','C','D','E');
 idx pls_integer;
begin
 t.delete(2); t.delete(4);
 idx := t.first;
 while idx is not null loop
 dbms_output.put_line(t(idx));
 idx := t.next(idx);
 end loop;
end;
/

set serveroutput on;

select * from user_tables;

--GENEROVANIE PRIKAZOV
select 'DROP TABLE ' || table_name || ' CASCADE CONSTRAINTS;'
from user_tables
where upper(table_name) like '%ZALOHA%';

select 'alter table st_p_prispevky drop constraint ' || constraint_name || ';'
from st_p_prispevky
where constraint_name like 'FK%';


rollback;

--KURZORY
begin 
    for res in (
        select meno, priezvisko, count(id_poistenca) as rec
        from st_p_osoba join st_p_poistenie using(rod_cislo)
        group by meno, priezvisko
    )
    loop 
        dbms_output.put_line(res.meno || ' ' || res.rec);
    end loop;
end;
/

declare
    c1_id st_p_poistenie.id_poistenca%type;
    c1_dat st_p_poistenie.dat_od%type;
    res integer;
    cursor c1 is select id_poistenca, dat_od from st_p_poistenie;
begin
    open c1;
    res:= 0;
    loop
        fetch c1 into c1_id, c1_dat;
        exit when c1%notfound;
        dbms_output.put_line(c1_id || ' ' || c1_dat);
        res:= res + 1;
    end loop;
    close c1;
    dbms_output.put_line(res);
end;
/

select ICO from st_p_zamestnavatel;

declare 
    c1_cp st_p_odvod_platba.cis_platby%type;
    c1_sum st_p_odvod_platba.suma%type;
    cursor c1 (p_ico st_p_zamestnavatel.ICO%type) 
        is select cis_platby, suma
        from st_p_zamestnavatel zam join st_p_zamestnanec on (zam.ICO = st_p_zamestnanec.id_zamestnavatela)
        join st_p_poistenie using(rod_cislo)
        join st_p_odvod_platba on(st_p_poistenie.id_poistenca = st_p_odvod_platba.id_poistenca)
        where zam.ICO = p_ico;
begin
    open c1 (12345678);
    loop
        fetch c1 into c1_cp, c1_sum;
        exit when c1%notfound;
        dbms_output.put_line(c1_cp || ' ' || c1_sum);
    end loop;
    close c1;
end;
/

declare
    cur_dat st_p_poberatel.dat_do%type;
    cursor cur is select dat_do from st_p_poberatel
        where extract(month from dat_do) = extract(month from sysdate) for update of oslobodeny;
begin
    open cur;
    loop 
        fetch cur into cur_dat;
        exit when cur%notfound;
        update st_p_poistenie
        set oslobodeny = 'A'
        where current of cur;
    end loop;
    close cur;
end;
/

--IN / EXISTS

select distinct meno, priezvisko, count(*) from st_p_poistenie
left join st_p_osoba using(rod_cislo)
group by meno, priezvisko;

select meno, priezvisko from st_p_osoba o
where exists (
    select * from st_p_poistenie p
    where o.rod_cislo = p.rod_cislo
    );    
    
select distinct meno, priezvisko from st_p_osoba
join st_p_poistenie using(rod_cislo)
where dat_do is null;
    
select id_poistenca from st_p_poistenie
join st_p_odvod_platba using(id_poistenca)
group by id_poistenca
having count(cis_platby) = 0;

select meno, priezvisko from st_p_osoba
join st_p_poistenie p using(rod_cislo)
join st_p_zamestnanec z using(rod_cislo)
where exists (
    select * from st_p_poistenie
    where p.rod_cislo = z.rod_cislo
    );
    
select distinct meno, priezvisko from st_p_osoba
join st_p_poistenie using(rod_cislo)
join st_p_zamestnanec using(rod_cislo)
where rod_cislo in (
    select rod_cislo from st_p_zamestnanec
);

select n_mesta from st_p_mesto
join st_p_osoba using(PSC)
join st_p_ZTP using(rod_cislo)
join st_p_typ_postihnutia using(id_postihnutia)
where nazov_postihnutia <> 'zrakove postihnutie';

--OUTER JOIN
select meno, priezvisko, count(id_poistenca)
from st_p_osoba
outer join st_p_poistenie using(rod_cislo)
group by meno, priezvisko;

select meno, priezvisko, case when dat_platby is not null then 'nezaplatene' end as stav
from st_p_osoba 
join st_p_poistenie using(rod_cislo)
join st_p_odvod_platba using(id_poistenca);
