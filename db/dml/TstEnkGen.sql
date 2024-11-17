SET SERVEROUTPUT ON;
SET PAGESIZE 0
SET LONG 1000000000
SET LONGCHUNKSIZE 1000000000
SET LINESIZE 32767
SET TRIMSPOOL ON
SET FEEDBACK OFF
SET HEADING OFF
SET ECHO OFF
SET TIMING OFF
SET VERIFY OFF
SET DEFINE OFF
begin
   dbms_metadata.set_transform_param (dbms_metadata.session_transform, 'SQLTERMINATOR', true);
   dbms_metadata.set_transform_param (dbms_metadata.session_transform, 'PRETTY', true);
end;
/

spool C:\temp\tst\EM_K_GEN_WS_VCR.sql
select DBMS_METADATA.GET_DDL(REPLACE(a.OBJECT_TYPE,CHR(32),'_'),a.OBJECT_NAME,a.OWNER) as script
FROM dba_objects a
where a.OBJECT_NAME = 'EM_K_GEN_WS_VCR'
and a.OWNER = 'TRON2000'
order by a.OBJECT_TYPE , a.OBJECT_NAME ,a.OWNER;  
spool off


exit;




