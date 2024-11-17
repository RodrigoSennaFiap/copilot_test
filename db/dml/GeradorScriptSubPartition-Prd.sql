select
      distinct
      ('spool \\sbr001001-009\Appdeploy\C00580540\PRD\CORE-BI\'||drive.OWNER || '\'||drive.pasta||''
         ||drive.OWNER ||'_' ||drive.object_NAME||'.sql
select DBMS_METADATA.GET_DDL(REPLACE('''||drive.tipo||''',CHR(32),''_''),a.OBJECT_NAME,a.OWNER) as script
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
                END AS pasta,
              decode(A.OBJECT_TYPE,
                       'TABLE SUBPARTITION',
                       'TABLE',
                       'TABLE PARTITION',
                       'TABLE',
                       'INDEX PARTITION',
                       'INDEX',
                       'INDEX SUBPARTITION',
                       'INDEX',
                       'PACKAGE BODY',
                       'PACKAGE_BODY',
                       'TYPE BODY',
                       'TYPE_BODY',
                       'MATERIALIZED VIEW',
                       'MATERIALIZED_VIEW',
                        A.OBJECT_TYPE
                        ) as tipo
           from GERA_SCRIPT_DDL_TAB a
          where OWNER in ('NTD_BR_DL')
                   and A.OBJECT_TYPE  not in ('TABLE PARTITION',
                         'TABLE SUBPARTITION',
                         'INDEX PARTITION',
                         'INDEX SUBPARTITION')
                   and trim(a.AMBIENTE) = 'PRD'
                   AND trim(A.SISTEMA) = 'CORE-BI'
                   --and a.arquvo <> '00_CORE-BI-DEV-NTD_BR_DL.sql'
           order by a.owner , a.object_type , a.object_name
          ) drive
