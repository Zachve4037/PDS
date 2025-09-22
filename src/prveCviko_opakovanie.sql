select id_platitela, count(id_poistenca)
from soc_poistovna.p_platitel
         left join soc_poistovna.p_poistenie using(id_platitela)
group by id_platitela
order by count(id_platitela);

select n_mesta, psc, count(rod_cislo)
from soc_poistovna.p_mesto
         join soc_poistovna.p_osoba using(PSC)
group by n_mesta, psc;

select rod_cislo
from soc_poistovna.p_osoba po
where exists (
    select rod_cislo
    from soc_poistovna.p_poistenie pp
    where pp.rod_cislo = po.rod_cislo
);

select rod_cislo
from soc_poistovna.p_osoba
where rod_cislo in (
    select rod_cislo
    from soc_poistovna.p_poistenie
);

create trigger alt_dat_do
    before insert on soc_poistovna.p_zamestnanec
    for each row
begin
    :new.dat_do := NULL;
end;
/

create or replace function fun(rod_cis in char)
    return number
    is pocet number;
begin
select rod_cislo, count(distinct to_char(dat_od, 'YYYY'))
into pocet
from soc_poistovna.p_poberatel
where rod_cislo = rod_cis
group by rod_cislo;
return(pocet);
end;
/

alter table soc_poistovna.p_zamestnanec
    add constraint checking check (dat_od < dat_do);

create or replace function vek_osoby(rod_c char)
    return number
    is
begin
return months_between(
               sysdate,
               to_date(substr(rod_c, 1, 2) || '-' || mod(substr(rod_c, 3, 2), 50) || '-' || substr(rod_c, 5, 2), 'RR-MM-DD')
       ) / 12;
end;
/

select vek_osoby('0307156179') from dual;