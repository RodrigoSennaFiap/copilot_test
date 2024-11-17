/*select * from GERA_SCRIPT_DDL_TAB t where t.sistema = 'ASC' and t.ambiente = 'PRD' for update;

begin
  for rec in (select a.*, rownum rn, a.rowid
                from GERA_SCRIPT_DDL_TAB a
               where a.sistema = 'ASC'
                 and a.arquvo is null
                 and a.ambiente = 'PRD'
                 and LINHA is null
                 and a.owner = 'ASCADM'
                 and a.object_type  not in ('TABLE PARTITION',
                                           'TABLE SUBPARTITION',
                                           'INDEX PARTITION',
                                           'INDEX SUBPARTITION',
                                           'LOB')
                                           and rownum <= 10000
               order by a.owner, a.object_type, a.object_name) loop
  
    update GERA_SCRIPT_DDL_TAB
       set LINHA = rec.rn, arquvo = '00_ASC-PRD.sql'
     where rowid = rec.rowid;
  
  end loop;

end;*/

select
      distinct 
      ('spool \\sbr001001-009\Appdeploy\C00580540\SUS\CORE-BI\'||drive.OWNER || '\'||drive.pasta||''
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
          --where OWNER not in ('NTD_BR_DL')
                   where A.OBJECT_TYPE   in ('TABLE PARTITION',
                         'TABLE SUBPARTITION',
                         'INDEX PARTITION',
                         'INDEX SUBPARTITION')
                   and trim(a.AMBIENTE) = 'SUS'
                   AND trim(A.SISTEMA) = 'CORE-BI'
                   --and a.arquvo <> '00_CORE-BI-DEV-NTD_BR_DL.sql'
           order by a.owner , a.object_type , a.object_name
          ) drive
