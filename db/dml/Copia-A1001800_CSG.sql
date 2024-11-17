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
spool C:\temp\a1001800_csg.sql
select DBMS_METADATA.GET_DDL(a.OBJECT_TYPE,a.OBJECT_NAME,a.OWNER) as script
FROM dba_objects a
where a.OBJECT_NAME = 'A1001800_CSG'
and a.OWNER = 'TRON2000'
and a.OBJECT_TYPE = 'TABLE'
order by a.OBJECT_TYPE , a.OBJECT_NAME ,a.OWNER;  
spool off
exit;