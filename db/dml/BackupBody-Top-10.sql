set pagesize 0 -- Define o número de linhas por página de saída. '0' significa que não há quebras de página.
set long 1000000000 -- Define o comprimento máximo de uma coluna LONG. -- '1000000000' é um valor muito grande para garantir que todo o conteúdo seja exibido.
set longchunksize 1000000000 -- Define o tamanho máximo de um pedaço de dados LONG.
set linesize 32767 -- Define o comprimento máximo de uma linha de saída. -- '32767' é o valor máximo permitido, garantindo que linhas longas não sejam truncadas.
set trimspool ON -- Remove espaços em branco à direita de cada linha de saída.
set feedback off -- Desativa a exibição de mensagens de feedback, como o número de linhas selecionadas.
set heading off -- Desativa a exibição de cabeçalhos de coluna na saída.
set echo off -- Desativa a exibição de comandos SQL antes de serem executados.
set timing off -- Desativa a exibição de informações de tempo de execução.
set verify off -- Desativa a verificação de substituições de variáveis.

declare
    cursor c_objects is
        select a.OBJECT_NAME, a.OWNER
        from dba_objects a
        where a.OWNER = 'TRON2000'
        and a.OBJECT_TYPE = 'PACKAGE BODY'
        and upper(a.OBJECT_NAME) in (
             'EM_K_GEN_WS_VCR',
             'EM_K_GEN_WS_VCR1',
             'EA_K_JRP_231_EMI_VCR',
             'EA_K_231_DV_VCR',
             'EA_K_231_GERA_ROTEIRO_VCR',
             'EA_K_REGRA_CALCULO_COT_VCR',
             'EA_K_REGRA_CALCULO_VCR',
             'ED_K_GEN_WS',
             'EM_K_AP200130_VCR',
             'EA_K_REGRA_VALIDACAO_VCR'
        )
        order by a.OBJECT_TYPE, a.OBJECT_NAME, a.OWNER;
begin
    dbms_metadata.set_transform_param (dbms_metadata.session_transform, 'SQLTERMINATOR', true);
    dbms_metadata.set_transform_param (dbms_metadata.session_transform, 'PRETTY', true);

    for r_object in c_objects loop
        dbms_output.put_line('Spooling ' || r_object.OBJECT_NAME || '...');
        execute immediate 'spool C:\temp\top100\' || r_object.OBJECT_NAME || '-PBDY.sql';
        execute immediate 'select DBMS_METADATA.GET_DDL(REPLACE(a.OBJECT_TYPE,CHR(32),''_''),a.OBJECT_NAME,a.OWNER) as script
                           FROM dba_objects a
                           where a.OBJECT_NAME = :1
                           and a.OWNER = :2
                           and a.OBJECT_TYPE = ''PACKAGE BODY'''
        using r_object.OBJECT_NAME, r_object.OWNER;
        execute immediate 'spool off';
    end loop;
end;
/
exit;
