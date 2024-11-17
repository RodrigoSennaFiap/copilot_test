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
spool C:\temp\top100\EM_K_GEN_WS_VCR-PBODY.sql
select DBMS_METADATA.GET_DDL('PACKAGE_BODY',a.OBJECT_NAME,a.OWNER) as script
FROM all_objects a
where a.OBJECT_NAME = 'EM_K_GEN_WS_VCR'
and a.OWNER = 'TRON2000'
and a.OBJECT_TYPE = 'PACKAGE BODY'
order by a.OBJECT_TYPE , a.OBJECT_NAME ,a.OWNER;  
spool off
exit;