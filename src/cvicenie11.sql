create table predmety_zapis_tab as 
select os_cislo, cis_predm, skrok
from student join zap_predmety using(os_cislo)
where skrok in (2024, 2025);

drop table predmety_zapis_tab;

select * from predmety_zapis_tab;

create table predmety_zapis (
    os_cislo Integer,
    cis_predm  char(4),
    skrok Number
    );

declare
    v_oc Number;
    v_cp char(4);
    v_sr Number;
begin 
    for ptr IN 1..20 loop
        
    end loop;
end;
/

create table pred_zap as (
    select * from (
        select os_cislo, cis_predm, 2024 as skrok 
            from student, predmet 
    union
        select os_cislo, cis_predm, 2025 
        from student, predmet) 
        order by null 
        fetch first 20 rows only);
        
select * from pred_zap;

insert into zap_predmety (
    os_cislo, cis_predm, skrok, prednasajuci, ects
)
with s_p_z as (
    select skrok, os_cislo, cis_predm 
    from pred_zap
), s_z_p as (
    select distinct prednasajuci, ects, cis_predm
    from zap_predmety
) select 
    spz.os_cislo,
    cis_predm,
    spz.skrok,
    szp.prednasajuci,
    szp.ects
    from s_p_z spz
    join s_z_p szp using(cis_predm);
    
--spravne len to dokoncit
insert into zap_predmety(os_cislo, cis_predm, skrok, garant, ects)
select os_cislo, cis_predm, skrok, garant, ects 
 from (
select os_cislo, cis_predm, skrok, garant, ects
 from predmety_zapis join predmet_bod using(cis_predm)
) where rn = 1;

--kazdy predmet max. 2krat
create or replace type t_obj as object
(os_cislo integer,
 cis_predm char(4),
 skrok integer
);
/
create or replace type t_zapis is table of t_obj;
/
create or replace package p_data
is
 zapis t_zapis;
end;
/

--------------
drop table tab_data;

create global temporary table tab_data
(os_cislo integer,
 cis_predm char(4),
 skrok integer
)
on commit delete rows;

create or replace trigger trig_zp_pocet_t1
 before insert or update on zap_predmety
  for each row
begin
 insert into tab_data values(:new.os_cislo, :new.cis_predm, :new.skrok);  
end;
/

create or replace trigger trig_zp_pocet_t2
 after insert or update on zap_predmety
declare
 pocet integer;
begin
 for i in (select * from tab_data)
  loop
   select count(*) into pocet from zap_predmety
    where cis_predm=i.cis_predm and os_cislo=i.os_cislo;
   if pocet > 2 
    then raise_application_error(-20000, 'student opakuje predmet 2. krat!!!');
   end if;
  end loop;
end;
/

-- HW
-- namiesto temporarnej tab pouzit zadefinovanu kolekciu
-- efektivita - zbavit sa selectu v cykle v t2