--pocet jazd
select count(*) as pocet_jazd
from jazda
where dat_zaciatok between :P14_DATE_FROM and :P14_DATE_TO;

--celkovy obrat
select nvl(sum(cena), 0) as obrat
from jazda
where dat_zaciatok between :P14_DATE_FROM and :P14_DATE_TO;

--priemerna cena jazdy
select round(avg(cena), 2) as priemer
from jazda
where dat_zaciatok between :P14_DATE_FROM and :P14_DATE_TO;

--top N najziskovejsich vozidiel
select * from (
    select v.ecv, sum(j.cena) as obrat
    from jazda j
    join vozidlo v using(id_vozidlo)
    where j.dat_zaciatok < sysdate
    group by v.ecv
    order by obrat desc
) where rownum <= 5;