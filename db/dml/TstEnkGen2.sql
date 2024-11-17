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

spool C:\temp\tst\EM_K_GEN_WS_VCR2.sql

SELECT a.text , LINE FROM dba_source a WHERE a.NAME = 'EM_K_GEN_WS_VCR' and a.owner = 'TRON2000' order by name ,TYPE,LINE;  

spool off

exit;
