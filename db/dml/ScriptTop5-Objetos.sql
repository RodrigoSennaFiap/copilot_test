/*select drive.*, ('spool C:\temp\TST\'|| 'pasta\'
         ||'EM_K_GEN_WS_VCR1-PBDY.sql
select DBMS_METADATA.GET_DDL(REPLACE(a.OBJECT_TYPE,CHR(32),''_''),a.OBJECT_NAME,a.OWNER) as script
FROM dba_objects a
where a.OBJECT_NAME = ''EM_K_GEN_WS_VCR1''
and a.OWNER = ''TRON2000''
and a.OBJECT_TYPE = ''PACKAGE BODY''
order by a.OBJECT_TYPE , a.OBJECT_NAME ,a.OWNER;  
spool off') as script
  from (select sum(length(a.TEXT)) tamanho,
                a.NAME
           from dba_source a
          where OWNER = 'TRON2000'
            AND a.TYPE = 'PACKAGE BODY'
            and a.NAME in ('EM_K_GEN_WS_VCR',
                           'EA_K_JRP_231_EMI_VCR',
                           'EA_K_231_DV_VCR',
                           'EA_K_231_GERA_ROTEIRO_VCR',
                           'EA_K_REGRA_VALIDACAO_VCR',
                           'EA_K_REGRA_CALCULO_COT_VCR',
                           'EA_K_REGRA_CALCULO_VCR',
                           'ED_K_GEN_WS',
                           'EM_K_AP200130_VCR',
                           'EM_K_AP200984_VCR')
          group by rollup(a.NAME)
          order by sum(length(a.TEXT)) desc) drive;*/

/*select A.status, COUNT(1) TOTAL
  from all_objects a
 where a.OWNER = 'TRON2000'
 GROUP BY A.status;
 
 select A.status, COUNT(1) TOTAL
  from all_objects a
 where a.OWNER = 'TRON2000'
   and a.OBJECT_NAME in ('EM_K_GEN_WS_VCR',
                         'EA_K_JRP_231_EMI_VCR',
                         'EA_K_231_DV_VCR',
                         'EA_K_231_GERA_ROTEIRO_VCR',
                         'EA_K_REGRA_VALIDACAO_VCR',
                         'EA_K_REGRA_CALCULO_COT_VCR',
                         'EA_K_REGRA_CALCULO_VCR',
                         'ED_K_GEN_WS',
                         'EM_K_AP200130_VCR',
                         'EM_K_AP200984_VCR')
   and a.OBJECT_TYPE = 'PACKAGE BODY'
 GROUP BY A.status;
*/
/*SELECT distinct A.OBJECT_TYPE,
                CASE
                  WHEN A.OBJECT_TYPE = 'SEQUENCE' THEN-- NOK
                   'Sequences\'
                  WHEN A.OBJECT_TYPE = 'VIEW' THEN -- NOK
                   'Views\'
                  WHEN A.OBJECT_TYPE = 'FUNCTION' THEN -- OK
                   'functions\'
                  WHEN A.OBJECT_TYPE = 'PROCEDURE' THEN --OK
                   'Procedures\'
                  WHEN A.OBJECT_TYPE = 'PACKAGE' THEN -- OK
                   'Packages\'
                  WHEN A.OBJECT_TYPE = 'PACKAGE BODY' THEN -- OK
                   'PackagesBodies\'
                  WHEN A.OBJECT_TYPE IN
                       ('INDEX', 'INDEX PARTITION', 'INDEX SUBPARTITION') THEN --- NOK
                   'indexes\'
                  WHEN A.OBJECT_TYPE IN ('MATERIALIZED VIEW') THEN -- NOK
                   'MaterializedViews\'
                  WHEN A.OBJECT_TYPE IN ('SYNONYM') THEN -- NOK
                   'Synonyms\'
                  WHEN A.OBJECT_TYPE IN
                       ('TABLE', 'TABLE PARTITION', 'TABLE SUBPARTITION') THEN -- NOK
                   'Tables\'
                  WHEN A.OBJECT_TYPE IN ('TRIGGER') THEN -- OK
                   'Triggers\'
                  WHEN A.OBJECT_TYPE IN ('TYPE') THEN -- OK
                   'Types\spec\'
                  WHEN A.OBJECT_TYPE IN ('TYPE BODY') THEN -- OK
                   'Types\body\'
                  ELSE
                   'Outros\'
                END AS pasta
  FROM dbA_OBJECTS A
 where a.OWNER = 'TRON2000';*/
 
 select drive.* , 'PACKAGE' as tipo
from 
(select sum(length(a.TEXT)) tamanho,
                a.NAME
           from dba_source a
          where OWNER = 'TRON2000'
            AND a.TYPE = 'PACKAGE'
          group by rollup(a.NAME)
          order by sum(length(a.TEXT)) desc ) drive
where rownum <= 5
union ALL
select drive.* , 'PACKAGE BODY' as tipo
from 
(select sum(length(a.TEXT)) tamanho,
                a.NAME
           from dba_source a
          where OWNER = 'TRON2000'
            AND a.TYPE = 'PACKAGE BODY'
          group by rollup(a.NAME)
          order by sum(length(a.TEXT)) desc ) drive
where rownum <= 5
union ALL
select drive.* , 'PROCEDURE' as tipo
from 
(select sum(length(a.TEXT)) tamanho,
                a.NAME
           from dba_source a
          where OWNER = 'TRON2000'
            AND a.TYPE = 'PROCEDURE'
          group by rollup(a.NAME)
          order by sum(length(a.TEXT)) desc ) drive
where rownum <= 5
union ALL
select drive.* , 'FUNCTION' as tipo
from 
(select sum(length(a.TEXT)) tamanho,
                a.NAME
           from dba_source a
          where OWNER = 'TRON2000'
            AND a.TYPE = 'FUNCTION'
          group by rollup(a.NAME)
          order by sum(length(a.TEXT)) desc ) drive
where rownum <= 5
union ALL
select drive.* , 'TYPE' as tipo
from 
(select sum(length(a.TEXT)) tamanho,
                a.NAME
           from dba_source a
          where /*OWNER = 'TRON2000'
            AND */a.TYPE = 'TYPE'
          group by rollup(a.NAME)
          order by sum(length(a.TEXT)) desc ) drive
where rownum <= 5
union ALL
select drive.* , 'TYPE BODY' as tipo
from 
(select sum(length(a.TEXT)) tamanho,
                a.NAME
           from dba_source a
          where /*OWNER = 'TRON2000'
            AND */a.TYPE = 'TYPE BODY'
          group by rollup(a.NAME)
          order by sum(length(a.TEXT)) desc ) drive
where rownum <= 5
union ALL
select drive.* , 'TRIGGER' as tipo
from 
(select sum(length(a.TEXT)) tamanho,
                a.NAME
           from dba_source a
          where /*OWNER = 'TRON2000'
            AND */a.TYPE = 'TRIGGER'
          group by rollup(a.NAME)
          order by sum(length(a.TEXT)) desc ) drive
where rownum <= 5
UNION ALL
select drive.*
from 
(select 
        count(distinct COLUMN_NAME) as tamanho,
        TABLE_NAME as name,'TABLE' as tipo
  from all_tab_columns a
 where OWNER = 'TRON2000'
 group by TABLE_NAME
 order by count(COLUMN_NAME) desc) drive
where rownum <= 5;
