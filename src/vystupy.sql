-- top 10% najcastejsich ranked dvojic oblasti v jazdach za rovnaky kvartal minuleho roka
with pocet_jazd as (
    select nastup_oblast, vystup_oblast, count(*) as pocet_jazd
    from jazda
    where to_char(dat_zaciatok, 'Q-YYYY') = to_char(add_months(sysdate, -12), 'Q-YYYY')
    group by nastup_oblast, vystup_oblast
), ranked_pocet_jazd as (
    select nastup_oblast, vystup_oblast, pocet_jazd,
           rank() over(order by pocet_jazd desc) as poradie,
           count(*) over() as celkovy_pocet
    from pocet_jazd
)
select nastup_oblast, o1.nazov as nastup_oblast_nazov,
       vystup_oblast, o2.nazov as vystup_oblast_nazov,
       pocet_jazd
from ranked_pocet_jazd
    join oblast o1 on nastup_oblast = o1.id_oblast
    join oblast o2 on vystup_oblast = o2.id_oblast
where poradie / celkovy_pocet <= 0.1
order by pocet_jazd desc;



-- pre zvoleneho zakaznika JSON report obsahujuci info o zakaznikovi,
-- prehlad jazd a zakladne statistiky o jazde (priemerna dlzka jazdy v minutach, priemerna cena)
-- v kazdom mesiaci od jeho registracie do dnesneho datumu bez ukoncenych
with hladany_zakaznik as (
    select *
    from zakaznik
    where id_zakaznik = :P10_ID_ZAKAZNIK_JSON_REPORT
), mesiace_registracie as (
    select add_months(trunc(dat_registracie, 'MM'), level - 1) mesiac_od
    from hladany_zakaznik
    connect by months_between(least(sysdate, nvl(dat_ukoncenia, sysdate)), trunc(dat_registracie, 'MM')) >= level - 1
), jazdy_zakaznika as (
    select o1.nazov as nastupna_oblast,
        o2.nazov as vystupna_oblast,
        cena,
        dat_zaciatok,
        dat_koniec,
        (nvl(dat_koniec, sysdate) - dat_zaciatok) * 24 * 60 as dlzka_v_minutach
    from jazda
        join hladany_zakaznik using (id_zakaznik)
        join oblast o1 on nastup_oblast = o1.id_oblast
        join oblast o2 on vystup_oblast = o2.id_oblast
), jazdy_v_mesiacoch as (
    select mesiac_od,
        count(cena) as pocet,
        avg(cena) as priemerna_cena,
        avg(dlzka_v_minutach) as priemerna_dlzka_v_minutach,
        json_arrayagg(case when cena is null then null else json_object(
            'nastupna_oblast' value nastupna_oblast,
            'vystupna_oblast' value vystupna_oblast,
            'zaciatok_jazdy' value to_char(dat_zaciatok, 'YYYY-MM-DD HH:MI:DD'),
            'koniec_jazdy' value to_char(dat_koniec, 'YYYY-MM-DD HH:MI:DD'),
            'cena' value cena
        ) end
        returning clob) as jazdy_json
    from mesiace_registracie
        left join jazdy_zakaznika on mesiac_od = trunc(dat_zaciatok, 'MM')
    group by mesiac_od
), jazdy_json as (
    select json_objectagg(to_char(mesiac_od, 'YYYY-MM') value json_object(
        'pocet_jazd' value pocet,
        'priemerna_cena' value priemerna_cena,
        'priemerna_dlzka_v_minutach' value round(priemerna_dlzka_v_minutach, 2),
        'jazdy' value jazdy_json
        returning clob
    ) returning clob) as jazdy_mesiace_json
    from jazdy_v_mesiacoch
)
select json_object(
    'cele_meno' value z.os_udaje.cele_meno(),
    'email' value z.email,
    'tel_cislo' value z.os_udaje.tel_cislo,
    'dat_narodenia' value to_char(z.os_udaje.dat_narodenia, 'YYYY-MM-DD'),
    'adresa' value z.adresa.to_json() format json,
    'dat_registracie' value to_char(z.dat_registracie, 'YYYY-MM-DD HH:MI:DD'),
    'dat_ukoncenia' value to_char(z.dat_ukoncenia, 'YYYY-MM-DD HH:MI:DD'),
    'jazdy' value jazdy_mesiace_json
    returning clob
) as report
from hladany_zakaznik z, jazdy_json j;


select id_obec from obce;


-- konkretna obec, taxisluzby podla poctu jazd za posledny rok, kolacovy graf
-- Nižný Hrabovec, zlučovanie ostatných
with oblasti_v_obci as (
    select id_oblast
    from oblast
        join obec using (kod_obce)
    where kod_obce = :P15_KOD_OBCE
), jazdy_za_posledny_rok_v_obci as (
    select id_vodic, dat_zaciatok
    from v_jazda j
        join oblasti_v_obci o on j.nastup_oblast = o.id_oblast and j.vystup_oblast = o.id_oblast
    where months_between(sysdate, dat_zaciatok) <= 12
), taxisluzby_jazdy as (
    select nazov || ' (' || ico || ')' as taxisluzba, count(dat_zaciatok) as pocet_jazd
    from taxisluzba t
        join vodic v on t.ico = v.taxisluzba
        join jazdy_za_posledny_rok_v_obci j using (id_vodic)
    group by ico, nazov
), ranked_taxisluzby as (
    select taxisluzba, pocet_jazd,
           row_number() over(order by pocet_jazd desc) as r
    from taxisluzby_jazdy
), ranked_taxisluzby_grouped as (
    select case when r <= 10 then taxisluzba else 'Ostatné' end as taxisluzba, pocet_jazd
    from ranked_taxisluzby
)
select taxisluzba, sum(pocet_jazd) as pocet_jazd
from ranked_taxisluzby_grouped
group by taxisluzba
order by pocet_jazd desc, taxisluzba;


-- konkretna obec, top 5 taxisluzieb podla celkoveho profitu za posledny rok, stlpcovy graf
with oblasti_v_obci as (
    select id_oblast
    from oblast
        join obec using (kod_obce)
    where kod_obce = :P15_KOD_OBCE
), jazdy_v_obci as (
    select id_vodic, cena
    from v_jazda j
        join oblasti_v_obci o on j.nastup_oblast = o.id_oblast and j.vystup_oblast = o.id_oblast
    where months_between(sysdate, dat_zaciatok) <= 12
), taxisluzby_jazdy as (
    select nazov || ' (' || ico || ')' as taxisluzba, sum(cena) as celkova_cena
    from taxisluzba t
        join vodic v on t.ico = v.taxisluzba
        join jazdy_v_obci using (id_vodic)
    group by ico, nazov
), taxisluzby_ranked as (
    select taxisluzba, celkova_cena, row_number() over(order by celkova_cena desc) as rn
    from taxisluzby_jazdy
)
select taxisluzba, celkova_cena
from taxisluzby_ranked
where rn <= 5;

-- historicky vyvin priemernych (normovanych v ramci taxisluzieb)
-- cien tarify iba v ramci tejto obce za poslednych 5 rokov v obci
with roky as (
    select 2025 - level as rok
    from dual
    connect by level <= 5
), oblasti_v_obci as (
    select id_oblast
    from oblast
        join obec using (kod_obce)
    where kod_obce = :P15_KOD_OBCE
), tarifa_v_obci as (
    select taxisluzba, cena, dat_platnost_od, nvl(dat_platnost_do, sysdate) as dat_platnost_do
    from tarifa t
        join oblasti_v_obci o on t.nastup_oblast = o.id_oblast and t.vystup_oblast = o.id_oblast
), tarifa_per_rok as (
    select rok, taxisluzba, cena,
           greatest(dat_platnost_od, trunc(to_date(rok, 'YYYY'), 'YYYY')) as platnost_od_v_roku,
           least(dat_platnost_do, trunc(to_date(rok + 1, 'YYYY'), 'YYYY')) as platnost_do_v_roku
    from roky
        left join tarifa_v_obci on rok between
            extract(year from dat_platnost_od) and extract(year from dat_platnost_do)
), tarifa_per_rok_s_dlzkou as (
    select rok, taxisluzba, cena, platnost_od_v_roku, platnost_do_v_roku,
           platnost_do_v_roku - platnost_od_v_roku as dlzka_tarify_v_roku
    from tarifa_per_rok
), tarifa_per_rok_per_taxisluzba as (
    select rok, taxisluzba, sum(dlzka_tarify_v_roku * cena) / sum(dlzka_tarify_v_roku) as vazeny_priemer_cena
    from tarifa_per_rok_s_dlzkou
    group by rok, taxisluzba
)
select rok, avg(vazeny_priemer_cena) as priemerna_cena
from tarifa_per_rok_per_taxisluzba
group by rok
order by rok;


-- neregistrovany a registrovany zakaznici pocty jazd za roky + kolko ich je

with roky as (
    select 2025 - level as rok
    from dual
    connect by level <= 5
), oblasti_v_obci as (
    select id_oblast
    from oblast
        join obec using (kod_obce)
    where kod_obce = :P15_KOD_OBCE
), jazdy_v_obci as (
    select case when id_zakaznik is null then 0 else 1 end as registrovany, extract(year from dat_zaciatok) as rok
    from v_jazda j
        join oblasti_v_obci o on j.nastup_oblast = o.id_oblast and j.vystup_oblast = o.id_oblast
), pocty as (
    select /*+ materialize */ rok,
           nvl(sum(1 - registrovany), 0) as pocet_neregistrovanych_jazd,
           nvl(sum(registrovany), 0) as pocet_registrovanych_jazd
    from roky
        left join jazdy_v_obci using (rok)
    group by rok
), skupiny as (
    select rok, 0 as reg, 'nezaregistrovaný' as registrovany, pocet_neregistrovanych_jazd as pocet
    from pocty
    union all
    select rok, 1 as reg, 'zaregistrovaný' as registrovany, pocet_registrovanych_jazd as pocet
    from pocty
)
select rok, registrovany, pocet
from skupiny
order by rok, reg;



-- Všetky oblasti, v ktorých nie je momentálne žiadna aktívna taxislužba.
with oblasti_s_tarifou as (
    select nastup_oblast as id_oblast, dat_platnost_od, dat_platnost_do from tarifa
    union all
    select vystup_oblast, dat_platnost_od, dat_platnost_do from tarifa
), sucasne_oblasti as (
    select distinct id_oblast
    from oblasti_s_tarifou
    where dat_platnost_do is null or dat_platnost_do >= sysdate
)
select id_oblast, oblast.nazov as nazov_oblasti, kod_obce, obec.nazov as nazov_obce
from oblast
    join obec using (kod_obce)
where id_oblast not in (select * from sucasne_oblasti);

