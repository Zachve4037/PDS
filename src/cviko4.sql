select xmlroot (
        xmlelement("osoba",
            xmlattributes (rod_cislo as rc),
        xmlelement ("meno", meno),
        xmlelement ("priezvisko", priezvisko),
        xmlelement ("datum_zapisu", dat_zapisu)
        ),
   version no value
) as xml
    from os_udaje join student using(rod_cislo);

select xmlroot (
   xmlelement("osoba",
      xmlattributes (rod_cislo as rc),
      xmlforest (meno as "meno",
                priezvisko as "priezvisko",
                to_char(dat_zapisu, 'DD:MM:YYY') as "datum_zapisu"
                )
      ),
      version no value
) as xml
    from os_udaje join student using(rod_cislo);

select xmlroot (
               xmlelement("osoba",
                          xmlattributes (rod_cislo as rc),
                          xmlforest (meno as "meno",
                                     priezvisko as "priezvisko",
                                     to_char(dat_zapisu, 'DD:MM:YYY') as "datum_zapisu"
                          ),
               XMLAGG(xmlelement("Predmety",nazov))
               ),
               version no value
       ) as xml
from os_udaje join student using(rod_cislo)
    join zap_predmety using(os_cislo)
    join predmet using(cis_predm)
    group by rod_cislo, meno, priezvisko, dat_zapisu;

drop table poberatelia_xml;
create table poberatelia_xml of xmltype;
select * from poberatelia_xml;
insert into poberatelia_xml values (
    xmlroot(
        xmlelement("poberatel",
            xmlattributes('1' as "id", '005523/7894' as "rod_cislo"),
        xmlelement("meno", 'Andrej'),
        xmlelement("priezvisko", 'VelmiMudry')
    ),
    version '1.0'
    )
);

create table stud_xml of xmltype;
insert into stud_xml select xmlroot (
                                    xmlelement("osoba",
                                               xmlattributes (rod_cislo as rc),
                                               xmlforest (meno as "meno",
                                                          priezvisko as "priezvisko",
                                                          to_char(dat_zapisu, 'DD:MM:YYY') as "datum_zapisu"
                                               )
                                    ),
                                    version no value
                            ) as xml
from os_udaje join student using(rod_cislo);

drop table predmet_xml;

create table predmet_xml
(
    PREDMET_ID int primary key,
    nazov varchar2(100),
    ucitel_xml XMLTYPE,
    constraint ucitel_xml check ( ucitel_xml is not null )
);

insert into predmet_xml (predmet_id, nazov, ucitel_xml) values (
(1, 'Programovanie',
    xmlroot(
         xmlelement("ucitel",
         xmlattributes('1' as "id"),
         xmlelement("meno", 'Jozef'),
         xmlelement("priezvisko", 'Kvet')
    ),
     version '1.0'
 )));

select value(x) from stud_xml x;

select x.getClobVal() from stud_xml x;

select value(x) from stud_xml x order by 1;

--extract/extractValue a xmltable
--xml fragment -- xml typu
--extract value -- text


select x.krstne_meno from predmet_xml p,
    xmltable (
    '/ucitel' passing p.ucitel_xml
             columns krstne_meno varchar2(50) path 'meno'
             ) x
    where predmet_id = 1;


select x.id from predmet_xml p,
                 xmltable ( '/ucitel'
                 passing p.ucitel_xml
                 columns id varchar2(50) path '@id'
                 ) x
where PREDMET_ID = 1;

select extractValue(ucitel_xml, '/ucitel/meno') as krstne_meno from predmet_xml;

--xpath
--// - v celom hladam
--@ atribut

select extractvalue(value(x), '//MenoPriezvisko/@PZ') from nazov_tab_xml x;
--kdekolvek v celom xml ci existuje element MenoPriezvisko a ma atribut PZ

select extractvalue(value(x), 'osoby/osoba/@RC[12345678]') from stud_xml x;
select extractvalue(value(x), '//osoba/@RC') from stud_xml x;

update predmet_xml set ucitel_xml = updatexml(ucitel_xml, 'ucitel/meno/text()', 'Kvet')
where predmet_id = 1;

select extractvalue(ucitel_xml, '//ucitel/meno/text()')
from ucitel_xml;

update stud_xml set object_value = updatexml(object_value, '//osoba/meno/text()', 'KvetKvet')
where extractvalue(object_value, '//osoba/meno')= 'Rastislav';

--cyklicku referenciu
--zamestnancov - id_katedry
--katedry - id_veduceho katedry
--deferrable constraint
create table zamestannecCON
(
    zamestnanec_id int primary key,
    meno varchar2(50),
    priezvisko varchar2(50),
    katedra_id int --neskor pridame constraint
);

create table katedraCON
(
    katedra_id int primary key,
    nazov      varchar2(50),
    veduci_id  int,
    constraint fk_veduci_katedry foreign key (veduci_id)
        references zamestannecCON (zamestnanec_id)
            deferrable initially deferred
);

alter table
    add constraint fk_katedra_zamestnancov foreign key (katedra_id_)
        references katedraCON (katedra_id)
        deferrable initially deferred;

select xmlroot(
    xmlelement("osoby",
        xmlagg(
                xmlelement("osoba",
                           xmlattributes(ROD_CISLO as "RC"),
                           xmlelement("meno", meno),
                           xmlelement("priezvisko", priezvisko),
                           xmlelement("ulica",
                                      xmlattributes(PSC as "psc")
                           ),
                           xmlelement("datum_zapisu" as to_char(dat_zapisu, 'DD:MM:YYY'))
                )
        )
    ),
    version no value
) as xml from OS_UDAJE join student using(rod_cislo);