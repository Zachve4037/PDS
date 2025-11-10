--        zeny    muzi
--odbory |       |

select popis_odboru || ' ' || popis_zamerania, 
    count(case when substr(rod_cislo, 3, 1) in (0, 1) then 1 else null end) as zeny,
    count(case when substr(rod_cislo, 3, 1) in (4, 5) then 1 else null end) as muzi
from student right join st_odbory using(st_odbor, st_zameranie)
group by popis_odboru, popis_zamerania, st_odbor, st_zameranie;

create table zamestnanec (
    oc integer primary key,
    odd integer
);

create table oddelenie (
    id_oddelenia integer primary key,
    veduci integer
);

alter table zamestnanec modify odd integer not null;
alter table oddelenie modify veduci integer not null;

alter table zamestnanec add foreign key(odd)
    references oddelenie(id_oddelenia) deferrable;
    
alter table oddelenie add foreign key(veduci)
    references zamestnanec(oc) deferrable;

alter session set constraints=deferred;    

insert into zamestnanec(oc, odd) values(1, 5);
insert into oddelenie(id_oddelenia, veduci) values(5, 2);
insert into zamestnanec(oc, odd) values(2, 5);
commit;

insert into zamestnanec(oc, odd) values(3, 7);
insert into oddelenie(id_oddelenia, veduci) values(8, 2);
commit;

--select dbms_random.string from dual;
select trunc(dbms_random.value(1, 5)) from dual;
select round(dbms_random.value(1, 5)) from dual;

select dbms_random.string('U', 5) from dual;
select dbms_random.string('L', 5) from dual;
select dbms_random.string('X', 5) from dual;
select dbms_random.string('A', 5) from dual;

-- funkcia na vygenerovanie nahodneho retazca
-- prvy znak bude vzdy velke pismeno
-- ostatne znaky budu kombinacia cisel, pismen(male aj velke)
-- dlzka bude 5 - 10 znakov;

create or replace function random_something return string 
is
    ret string(12);
    pomC char;
    pomI integer;
    len integer;
    op integer;
begin
    select dbms_random.value(4, 10) into len from dual;
    select dbms_random.string('U', 1) into fir from dual;
    
    /*
    for i in len loop
        select dbms_random.value(1, 4) into op from dual;
        case when op = 1 then select dbms_random.string('U', 1) into pomC from dual; ret:= ret || pomC; end case;
        case when op = 2 then select dbms_random.string('X', 1) into pomC from dual; ret:= ret || pomC; end case;
        case when op = 3 then select dbms_random.value(1, 400) into pomI from dual; ret:= ret || pomI; end case;
    end loop;
    */
    return ret;
end;
/

select random_something from dual;

select nazov,
    sum(case when vysledok = 'A' then 1 else 0 end) as A,
    sum(case when vysledok = 'B' then 1 else 0 end) as B,
    sum(case when vysledok = 'C' then 1 else 0 end) as C
from predmet left join zap_predmety using(cis_predm)
group by cis_predm, nazov;

select rownum, to_char(to_date(rownum, 'MM'))
 from dual
 connect by level<=12;
 
--statistika 
with mesiace as ( 
 select rownum, to_char(to_date(rownum, 'MM')) nazov_mesiaca 
  from dual connect by level<=12
),datumy_narodenia as (
    select mod(substr(rod_cislo,3, 2), 50) as dat_nar from os_udaje
) select nazov_mesiaca from mesiace;

