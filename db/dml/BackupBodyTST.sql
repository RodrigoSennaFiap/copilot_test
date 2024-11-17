set pagesize 0
set long 1000000000
set longchunksize 1000000000
set linesize 32767
set trimspool ON
set feedback off
set heading off
set echo off 
set timing off
set verify off
begin
   dbms_metadata.set_transform_param (dbms_metadata.session_transform, 'SQLTERMINATOR', true);
   dbms_metadata.set_transform_param (dbms_metadata.session_transform, 'PRETTY', true);
end;
/

spool C:\temp\tst\Types\body\O_PYO_ORI_S.sql
select DBMS_METADATA.GET_DDL(REPLACE(a.OBJECT_TYPE,CHR(32),'_'),a.OBJECT_NAME,a.OWNER) as script
FROM dba_objects a
where a.OBJECT_NAME = 'O_PYO_ORI_S'
and a.OWNER = 'TRON2000'
and a.OBJECT_TYPE = 'TYPE BODY'
order by a.OBJECT_TYPE , a.OBJECT_NAME ,a.OWNER;  
spool off

spool C:\temp\tst\Types\body\O_RCP_MTG_S.sql
select DBMS_METADATA.GET_DDL(REPLACE(a.OBJECT_TYPE,CHR(32),'_'),a.OBJECT_NAME,a.OWNER) as script
FROM dba_objects a
where a.OBJECT_NAME = 'O_RCP_MTG_S'
and a.OWNER = 'TRON2000'
and a.OBJECT_TYPE = 'TYPE BODY'
order by a.OBJECT_TYPE , a.OBJECT_NAME ,a.OWNER;  
spool off

spool C:\temp\tst\Types\body\O_PLY_GNI_S.sql
select DBMS_METADATA.GET_DDL(REPLACE(a.OBJECT_TYPE,CHR(32),'_'),a.OBJECT_NAME,a.OWNER) as script
FROM dba_objects a
where a.OBJECT_NAME = 'O_PLY_GNI_S'
and a.OWNER = 'TRON2000'
and a.OBJECT_TYPE = 'TYPE BODY'
order by a.OBJECT_TYPE , a.OBJECT_NAME ,a.OWNER;  
spool off

spool C:\temp\tst\Types\spec\O_PYO_ORI_S.sql
select DBMS_METADATA.GET_DDL(REPLACE(a.OBJECT_TYPE,CHR(32),'_'),a.OBJECT_NAME,a.OWNER) as script
FROM dba_objects a
where a.OBJECT_NAME = 'O_PYO_ORI_S'
and a.OWNER = 'TRON2000'
and a.OBJECT_TYPE = 'TYPE'
order by a.OBJECT_TYPE , a.OBJECT_NAME ,a.OWNER;  
spool off

spool C:\temp\tst\Types\spec\O_RCP_MTG_S.sql
select DBMS_METADATA.GET_DDL(REPLACE(a.OBJECT_TYPE,CHR(32),'_'),a.OBJECT_NAME,a.OWNER) as script
FROM dba_objects a
where a.OBJECT_NAME = 'O_RCP_MTG_S'
and a.OWNER = 'TRON2000'
and a.OBJECT_TYPE = 'TYPE'
order by a.OBJECT_TYPE , a.OBJECT_NAME ,a.OWNER;  
spool off

spool C:\temp\tst\Types\spec\O_PLY_GNI_S.sql
select DBMS_METADATA.GET_DDL(REPLACE(a.OBJECT_TYPE,CHR(32),'_'),a.OBJECT_NAME,a.OWNER) as script
FROM dba_objects a
where a.OBJECT_NAME = 'O_PLY_GNI_S'
and a.OWNER = 'TRON2000'
and a.OBJECT_TYPE = 'TYPE'
order by a.OBJECT_TYPE , a.OBJECT_NAME ,a.OWNER;  
spool off

spool C:\temp\tst\Triggers\SF_T_A2109482_VCR.sql
select DBMS_METADATA.GET_DDL(REPLACE(a.OBJECT_TYPE,CHR(32),'_'),a.OBJECT_NAME,a.OWNER) as script
FROM dba_objects a
where a.OBJECT_NAME = 'SF_T_A2109482_VCR'
and a.OWNER = 'TRON2000'
and a.OBJECT_TYPE = 'TRIGGER'
order by a.OBJECT_TYPE , a.OBJECT_NAME ,a.OWNER;  
spool off

spool C:\temp\tst\Triggers\GGS_DDL_TRIGGER_BEFORE.sql
select DBMS_METADATA.GET_DDL(REPLACE(a.OBJECT_TYPE,CHR(32),'_'),a.OBJECT_NAME,a.OWNER) as script
FROM dba_objects a
where a.OBJECT_NAME = 'GGS_DDL_TRIGGER_BEFORE'
and a.OWNER = 'TRON2000'
and a.OBJECT_TYPE = 'TRIGGER'
order by a.OBJECT_TYPE , a.OBJECT_NAME ,a.OWNER;  
spool off

spool C:\temp\tst\Triggers\TS_T_A7009132_VCR.sql
select DBMS_METADATA.GET_DDL(REPLACE(a.OBJECT_TYPE,CHR(32),'_'),a.OBJECT_NAME,a.OWNER) as script
FROM dba_objects a
where a.OBJECT_NAME = 'TS_T_A7009132_VCR'
and a.OWNER = 'TRON2000'
and a.OBJECT_TYPE = 'TRIGGER'
order by a.OBJECT_TYPE , a.OBJECT_NAME ,a.OWNER;  
spool off

spool C:\temp\tst\Triggers\APEX$_WS_ROWS_T1.sql
select DBMS_METADATA.GET_DDL(REPLACE(a.OBJECT_TYPE,CHR(32),'_'),a.OBJECT_NAME,a.OWNER) as script
FROM dba_objects a
where a.OBJECT_NAME = 'APEX$_WS_ROWS_T1'
and a.OWNER = 'TRON2000'
and a.OBJECT_TYPE = 'TRIGGER'
order by a.OBJECT_TYPE , a.OBJECT_NAME ,a.OWNER;  
spool off

spool C:\temp\tst\Tables\A2109033_VCR.sql
select DBMS_METADATA.GET_DDL(REPLACE(a.OBJECT_TYPE,CHR(32),'_'),a.OBJECT_NAME,a.OWNER) as script
FROM dba_objects a
where a.OBJECT_NAME = 'A2109033_VCR'
and a.OWNER = 'TRON2000'
and a.OBJECT_TYPE = 'TABLE'
order by a.OBJECT_TYPE , a.OBJECT_NAME ,a.OWNER;  
spool off

spool C:\temp\tst\Tables\X2109033_VCR.sql
select DBMS_METADATA.GET_DDL(REPLACE(a.OBJECT_TYPE,CHR(32),'_'),a.OBJECT_NAME,a.OWNER) as script
FROM dba_objects a
where a.OBJECT_NAME = 'X2109033_VCR'
and a.OWNER = 'TRON2000'
and a.OBJECT_TYPE = 'TABLE'
order by a.OBJECT_TYPE , a.OBJECT_NAME ,a.OWNER;  
spool off

spool C:\temp\tst\Procedures\DC_P_CALCTRIB_VCR.sql
select DBMS_METADATA.GET_DDL(REPLACE(a.OBJECT_TYPE,CHR(32),'_'),a.OBJECT_NAME,a.OWNER) as script
FROM dba_objects a
where a.OBJECT_NAME = 'DC_P_CALCTRIB_VCR'
and a.OWNER = 'TRON2000'
and a.OBJECT_TYPE = 'PROCEDURE'
order by a.OBJECT_TYPE , a.OBJECT_NAME ,a.OWNER;  
spool off


spool C:\temp\tst\Views\AQ_MEIOS_MSG_VCR.sql
select DBMS_METADATA.GET_DDL(REPLACE(a.OBJECT_TYPE,CHR(32),'_'),a.OBJECT_NAME,a.OWNER) as script
FROM dba_objects a
where a.OBJECT_NAME = 'AQ_MEIOS_MSG_VCR'
and a.OWNER = 'TRON2000'
and a.OBJECT_TYPE = 'VIEW'
order by a.OBJECT_TYPE , a.OBJECT_NAME ,a.OWNER;  
spool off


spool C:\temp\tst\Views\AQ$Q_TAB_CRE_LOCADORA.sql
select DBMS_METADATA.GET_DDL(REPLACE(a.OBJECT_TYPE,CHR(32),'_'),a.OBJECT_NAME,a.OWNER) as script
FROM dba_objects a
where a.OBJECT_NAME = 'AQ$Q_TAB_CRE_LOCADORA'
and a.OWNER = 'TRON2000'
and a.OBJECT_TYPE = 'VIEW'
order by a.OBJECT_TYPE , a.OBJECT_NAME ,a.OWNER;  
spool off


spool C:\temp\tst\Views\AQ_MEIOS_MSG_VCR.sql
select DBMS_METADATA.GET_DDL(REPLACE(a.OBJECT_TYPE,CHR(32),'_'),a.OBJECT_NAME,a.OWNER) as script
FROM dba_objects a
where a.OBJECT_NAME = 'AQ_MEIOS_MSG_VCR'
and a.OWNER = 'TRON2000'
and a.OBJECT_TYPE = 'VIEW'
order by a.OBJECT_TYPE , a.OBJECT_NAME ,a.OWNER;  
spool off


spool C:\temp\tst\Views\AQ$Q_TAB_CRE_LOCADORA.sql
select DBMS_METADATA.GET_DDL(REPLACE(a.OBJECT_TYPE,CHR(32),'_'),a.OBJECT_NAME,a.OWNER) as script
FROM dba_objects a
where a.OBJECT_NAME = 'AQ$Q_TAB_CRE_LOCADORA'
and a.OWNER = 'TRON2000'
and a.OBJECT_TYPE = 'VIEW'
order by a.OBJECT_TYPE , a.OBJECT_NAME ,a.OWNER;  
spool off

spool C:\temp\tst\Synonyms\A2000020_102.sql
select DBMS_METADATA.GET_DDL(REPLACE(a.OBJECT_TYPE,CHR(32),'_'),a.OBJECT_NAME,a.OWNER) as script
FROM dba_objects a
where a.OBJECT_NAME = 'A2000020_102'
and a.OWNER = 'TRON2000'
and a.OBJECT_TYPE = 'SYNONYM'
order by a.OBJECT_TYPE , a.OBJECT_NAME ,a.OWNER;  
spool off

spool C:\temp\tst\Synonyms\A2000020_118.sql
select DBMS_METADATA.GET_DDL(REPLACE(a.OBJECT_TYPE,CHR(32),'_'),a.OBJECT_NAME,a.OWNER) as script
FROM dba_objects a
where a.OBJECT_NAME = 'A2000020_118'
and a.OWNER = 'TRON2000'
and a.OBJECT_TYPE = 'SYNONYM'
order by a.OBJECT_TYPE , a.OBJECT_NAME ,a.OWNER;  
spool off

spool C:\temp\tst\Sequences\DOCUM.sql
select DBMS_METADATA.GET_DDL(REPLACE(a.OBJECT_TYPE,CHR(32),'_'),a.OBJECT_NAME,a.OWNER) as script
FROM dba_objects a
where a.OBJECT_NAME = 'DOCUM'
and a.OWNER = 'TRON2000'
and a.OBJECT_TYPE = 'SEQUENCE'
order by a.OBJECT_TYPE , a.OBJECT_NAME ,a.OWNER;  
spool off

spool C:\temp\tst\Sequences\EA_S_COTACAO_VCR.sql
select DBMS_METADATA.GET_DDL(REPLACE(a.OBJECT_TYPE,CHR(32),'_'),a.OBJECT_NAME,a.OWNER) as script
FROM dba_objects a
where a.OBJECT_NAME = 'EA_S_COTACAO_VCR'
and a.OWNER = 'TRON2000'
and a.OBJECT_TYPE = 'SEQUENCE'
order by a.OBJECT_TYPE , a.OBJECT_NAME ,a.OWNER;  
spool off

spool C:\temp\tst\MaterializedViews\TW_SEGURADO.sql
select DBMS_METADATA.GET_DDL(REPLACE(a.OBJECT_TYPE,CHR(32),'_'),a.OBJECT_NAME,a.OWNER) as script
FROM dba_objects a
where a.OBJECT_NAME = 'TW_SEGURADO'
and a.OWNER = 'TRON2000'
and a.OBJECT_TYPE = 'MATERIALIZED VIEW'
order by a.OBJECT_TYPE , a.OBJECT_NAME ,a.OWNER;  
spool off

spool C:\temp\tst\MaterializedViews\TW_SINISTRO.sql
select DBMS_METADATA.GET_DDL(REPLACE(a.OBJECT_TYPE,CHR(32),'_'),a.OBJECT_NAME,a.OWNER) as script
FROM dba_objects a
where a.OBJECT_NAME = 'TW_SINISTRO'
and a.OWNER = 'TRON2000'
and a.OBJECT_TYPE = 'MATERIALIZED VIEW'
order by a.OBJECT_TYPE , a.OBJECT_NAME ,a.OWNER;  
spool off

spool C:\temp\tst\indexes\AQ$_Q_TAB_ALLRISKS_TEST2_T.sql
select DBMS_METADATA.GET_DDL(REPLACE(a.OBJECT_TYPE,CHR(32),'_'),a.OBJECT_NAME,a.OWNER) as script
FROM dba_objects a
where a.OBJECT_NAME = 'AQ$_Q_TAB_ALLRISKS_TEST2_T'
and a.OWNER = 'TRON2000'
and a.OBJECT_TYPE = 'INDEX'
order by a.OBJECT_TYPE , a.OBJECT_NAME ,a.OWNER;  
spool off

spool C:\temp\tst\functions\EM_F_RESTAURA_COTI_VCR.sql
select DBMS_METADATA.GET_DDL(REPLACE(a.OBJECT_TYPE,CHR(32),'_'),a.OBJECT_NAME,a.OWNER) as script
FROM dba_objects a
where a.OBJECT_NAME = 'EM_F_RESTAURA_COTI_VCR'
and a.OWNER = 'TRON2000'
and a.OBJECT_TYPE = 'INDEX'
order by a.OBJECT_TYPE , a.OBJECT_NAME ,a.OWNER;  
spool off

spool C:\temp\tst\functions\EV_F_CREAR_PRESUPUESTO_VCR.sql
select DBMS_METADATA.GET_DDL(REPLACE(a.OBJECT_TYPE,CHR(32),'_'),a.OBJECT_NAME,a.OWNER) as script
FROM dba_objects a
where a.OBJECT_NAME = 'EV_F_CREAR_PRESUPUESTO_VCR'
and a.OWNER = 'TRON2000'
and a.OBJECT_TYPE = 'FUNCTION'
order by a.OBJECT_TYPE , a.OBJECT_NAME ,a.OWNER;  
spool off

exit;


