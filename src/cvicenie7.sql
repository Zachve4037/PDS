-- ku kazdej osobe vypiste studentske id v spolocnom atribute
select meno, priezvisko, json_arrayagg(os_cislo)
from st_os_udaje
left join st_student using(rod_cislo)
group by rod_cislo, meno, priezvisko;

-- kazdu osobu ktora nikdy nestudovala informatiku
select meno, priezvisko
from st_os_udaje
left join st_student using(rod_cislo)
where rod_cislo not in (
    select rod_cislo from st_student s
    join st_st_odbory o on(s.st_odbor = o.st_odbor and s.st_zameranie = o.st_zameranie)
    where popis_odboru = 'Informatika'
    );
-- napisat cez not exists!!!

--vypiste osoby a k nim studentske udaje ak je osoba druhakom
select * from st_os_udaje os
left join st_student st on(os.rod_cislo = st.rod_cislo) 
    and rocnik = 2;
    
-- objektovy typ - meno, priezvisko, datum narodenia, mapovacia funkcia podla roku narodenia
create or replace type t_person_obj as object (
    meno varchar2(20),
    priezvisko varchar2(20),
    datum_narodenia Date,
    map member function rok return number
);
/

create or replace type body t_person_obj as
 map member function rok return number is
 begin
    return extract(year from datum_narodenia);
 end rok;
end;
/

create table tab_t_person of t_person_obj;
drop table tab_t_person;
-- DOMACA ULOHA naplnit + prerobit do tabulky kde je objekt ako atribut

rollback;

--tu si spusti objednavky.sql a skladove_zaznamy.sql z teams/PDS/cvicenia/7
-- ANO JE TO FOKIN Z ANALYTIKY HAHA MENTAL BREAKDOWN HAHA

select * from (
    select id_prod,
            o.mnozstvo as o_qty,
            s.mnozstvo as s_qty,
            s.datum_nakupu,
            s.sklad sk,
            s.regal reg,
            s.pozicia poz,
            sum(s.mnozstvo) over (partition by s.produkt_id order by s.datum_nakupu,
                s.mnozstvo rows between unbounded preceding and current row) agg_qty
    from skladove_zasoby s join objednavky o on (id_prod = produkt_id)
) where agg_qty <= o_qty;

select nested.*, least(s_qty, o_qty - agg_qty) pick_qty, 
dense_rank() over (order by sk, reg) drank
from (
    select id_prod,
            o.mnozstvo as o_qty,
            s.mnozstvo as s_qty,
            s.datum_nakupu,
            s.sklad sk,
            s.regal reg,
            s.pozicia poz,
            nvl(sum(s.mnozstvo) over (partition by s.produkt_id order by s.datum_nakupu,
                s.mnozstvo rows between unbounded preceding and 1 preceding), 0) agg_qty
    from skladove_zasoby s join objednavky o on (id_prod = produkt_id)
) nested where agg_qty < o_qty
order by sk, reg, poz, case when mod(drank, 2) = 1 
     then poz
     else -poz
     end ;
;