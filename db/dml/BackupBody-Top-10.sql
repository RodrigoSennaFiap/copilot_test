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
spool C:\temp\top100\EM_K_GEN_WS_VCR1-PBDY.sql
select DBMS_METADATA.GET_DDL(REPLACE(a.OBJECT_TYPE,CHR(32),'_'),a.OBJECT_NAME,a.OWNER) as script
FROM dba_objects a
where a.OBJECT_NAME = 'EM_K_GEN_WS_VCR1'
and a.OWNER = 'TRON2000'
and a.OBJECT_TYPE = 'PACKAGE BODY'
order by a.OBJECT_TYPE , a.OBJECT_NAME ,a.OWNER;  
spool off

spool C:\temp\top100\EM_K_GEN_WS_VCR-PBDY.sql
select DBMS_METADATA.GET_DDL(REPLACE(a.OBJECT_TYPE,CHR(32),'_'),a.OBJECT_NAME,a.OWNER) as script
FROM dba_objects a
where a.OBJECT_NAME = 'EM_K_GEN_WS_VCR'
and a.OWNER = 'TRON2000'
and a.OBJECT_TYPE = 'PACKAGE BODY'
order by a.OBJECT_TYPE , a.OBJECT_NAME ,a.OWNER;  
spool off

spool C:\temp\top100\EA_K_JRP_231_EMI_VCR-PBDY.sql
select DBMS_METADATA.GET_DDL(REPLACE(a.OBJECT_TYPE,CHR(32),'_'),a.OBJECT_NAME,a.OWNER) as script
FROM dba_objects a
where a.OBJECT_NAME = 'EA_K_JRP_231_EMI_VCR'
and a.OWNER = 'TRON2000'
and a.OBJECT_TYPE = 'PACKAGE BODY'
order by a.OBJECT_TYPE , a.OBJECT_NAME ,a.OWNER;  
spool off


spool C:\temp\top100\EA_K_231_DV_VCR-PBDY.sql
select DBMS_METADATA.GET_DDL(REPLACE(a.OBJECT_TYPE,CHR(32),'_'),a.OBJECT_NAME,a.OWNER) as script
FROM dba_objects a
where a.OBJECT_NAME = 'EA_K_231_DV_VCR'
and a.OWNER = 'TRON2000'
and a.OBJECT_TYPE = 'PACKAGE BODY'
order by a.OBJECT_TYPE , a.OBJECT_NAME ,a.OWNER;  
spool off

spool C:\temp\top100\EA_K_231_GERA_ROTEIRO_VCR-PBDY.sql
select DBMS_METADATA.GET_DDL(REPLACE(a.OBJECT_TYPE,CHR(32),'_'),a.OBJECT_NAME,a.OWNER) as script
FROM dba_objects a
where a.OBJECT_NAME = 'EA_K_231_GERA_ROTEIRO_VCR'
and a.OWNER = 'TRON2000'
and a.OBJECT_TYPE = 'PACKAGE BODY'
order by a.OBJECT_TYPE , a.OBJECT_NAME ,a.OWNER;  
spool off

spool C:\temp\top100\EA_K_REGRA_CALCULO_COT_VCR-PBDY.sql
select DBMS_METADATA.GET_DDL(REPLACE(a.OBJECT_TYPE,CHR(32),'_'),a.OBJECT_NAME,a.OWNER) as script
FROM dba_objects a
where a.OBJECT_NAME = 'EA_K_REGRA_CALCULO_COT_VCR'
and a.OWNER = 'TRON2000'
and a.OBJECT_TYPE = 'PACKAGE BODY'
order by a.OBJECT_TYPE , a.OBJECT_NAME ,a.OWNER;  
spool off

spool C:\temp\top100\EA_K_REGRA_CALCULO_VCR-PBDY.sql
select DBMS_METADATA.GET_DDL(REPLACE(a.OBJECT_TYPE,CHR(32),'_'),a.OBJECT_NAME,a.OWNER) as script
FROM dba_objects a
where a.OBJECT_NAME = 'EA_K_REGRA_CALCULO_VCR'
and a.OWNER = 'TRON2000'
and a.OBJECT_TYPE = 'PACKAGE BODY'
order by a.OBJECT_TYPE , a.OBJECT_NAME ,a.OWNER;  
spool off

spool C:\temp\top100\ED_K_GEN_WS-PBDY.sql
select DBMS_METADATA.GET_DDL(REPLACE(a.OBJECT_TYPE,CHR(32),'_'),a.OBJECT_NAME,a.OWNER) as script
FROM dba_objects a
where a.OBJECT_NAME = 'ED_K_GEN_WS'
and a.OWNER = 'TRON2000'
and a.OBJECT_TYPE = 'PACKAGE BODY'
order by a.OBJECT_TYPE , a.OBJECT_NAME ,a.OWNER;  
spool off

spool C:\temp\top100\EM_K_AP200130_VCR-PBDY.sql
select DBMS_METADATA.GET_DDL(REPLACE(a.OBJECT_TYPE,CHR(32),'_'),a.OBJECT_NAME,a.OWNER) as script
FROM dba_objects a
where a.OBJECT_NAME = 'EM_K_AP200130_VCR'
and a.OWNER = 'TRON2000'
and a.OBJECT_TYPE = 'PACKAGE BODY'
order by a.OBJECT_TYPE , a.OBJECT_NAME ,a.OWNER;  
spool off

spool C:\temp\top100\EA_K_REGRA_VALIDACAO_VCR-PBDY.sql
select DBMS_METADATA.GET_DDL(REPLACE(a.OBJECT_TYPE,CHR(32),'_'),a.OBJECT_NAME,a.OWNER) as script
FROM dba_objects a
where a.OBJECT_NAME = 'EA_K_REGRA_VALIDACAO_VCR'
and a.OWNER = 'TRON2000'
and a.OBJECT_TYPE = 'PACKAGE BODY'
order by a.OBJECT_TYPE , a.OBJECT_NAME ,a.OWNER;  
spool off

exit;


