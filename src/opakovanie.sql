create or replace view test_osoba as
    select rod_cislo, ID_POISTENCA
    from P_OSOBA
    left join p_poistenie using(rod_cislo);

select * from test_osoba;

drop view test_osoba;

create or replace view test_pocet_mesta as
    select PSC, count(rod_cislo)
    from p_mesto
    left join p_osoba using(PSC)
    group by PSC;

create or replace view test_zamestnanci as
    select rod_cislo, dat_od, nazov
    from p_zamestnanec
    join p_zamestnavatel on(p_zamestnavatel.ICO = p_zamestnanec.id_zamestnavatela);

select id_platitela, count(id_poistenca)
    from p_platitel
    left join p_poistenie using(id_platitela)
    group by id_platitela;

select id_typu, avg(suma)
    from p_prispevky
    group by id_typu;

select count(distinct ICO), PSC
    from p_mesto
    left join p_zamestnavatel using(PSC)
    group by PSC;

select *
    from p_osoba
    where exists(
        select 'X'
        from p_poistenie
        where p_osoba.rod_cislo = p_poistenie.rod_cislo
    );

select *
from p_typ_prispevku
where id_typu in (
    select id_typu
    from p_poberatel
    group by id_typu
    having count(*) >= 3
    );

create or replace function test_pocet_prispevkov(id_poberatela in Number)
    return number
    as poc number;
    begin
        select id_poberatela, count(id_poberatela)
            into poc
        from p_poberatel
            join p_prispevky using(id_poberatela)
        group by id_poberatela;

        return poc;
    end;
    /

drop function test_pocet_prispevkov;

create procedure test_info(r_cislo char)
as
    begin
        for osoba in (select * from p_osoba where rod_cislo = r_cislo) loop
            dbms_output.put_line(osoba.rod_cislo || ' ' || osoba.priezvisko);
        end loop;
    end;
    /

select rod_cislo
from p_osoba
where exists(
    select 'X' from p_poistenie
    where p_osoba.rod_cislo = p_poistenie.rod_cislo
);

select id_poistenca
from p_poistenie
where exists(
    select id_poistenca from p_odvod_platba
    where p_odvod_platba.id_poistenca = p_poistenie.id_poistenca
    group by id_poistenca
    having count(id_poistenca) >= 2
);


select * from p_typ_prispevku
where id_typu in (
    select id_typu from p_prispevky
    group by id_typu
    having count(id_typu) >= 3
    );

select rod_cislo
from p_osoba
where not exists (
    select rod_cislo from p_poistenie
                     where p_poistenie.rod_cislo = p_osoba.rod_cislo
);