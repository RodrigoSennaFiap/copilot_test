
select  
       distinct
       drive.OWNER, drive.OBJECT_TYPE, drive.OBJECT_TYPE,

      ('spool C:\temp\SGO\'||drive.OWNER || '\'||drive.pasta||''
         ||drive.OWNER ||'_' ||drive.object_NAME||'.sql
select DBMS_METADATA.GET_DDL(REPLACE(a.OBJECT_TYPE,CHR(32),''_''),a.OBJECT_NAME,a.OWNER) as script
FROM all_objects a
where a.OBJECT_NAME = '''||drive.object_NAME||'''
and a.OWNER = '''||drive.OWNER||'''
and a.OBJECT_TYPE = '''||drive.OBJECT_TYPE||'''
order by a.OBJECT_TYPE , a.OBJECT_NAME ,a.OWNER;
spool off') as script
  from (select 
                a.*,
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
           from all_objects a
          where OWNER in ('BPMAPP_BR',
                   'BPMAPPBR_APP2',
                   'BPMAPP_BR_REL',
                   'BPMAPP',
                   'BPMAPP_APP2',
                   --'WEBMETHODSADM10',
                   'BTW_APP2',
                   'BTW_APP',
                   --'WEBMETHODSADM10',
                   'WEBMETHODSUSR')

          
          ) drive
 order by 1 , 2 , 3
