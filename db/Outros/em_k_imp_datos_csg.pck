CREATE OR REPLACE PACKAGE TRON2000.em_k_imp_datos_csg IS
  --
  /* --------------------- VERSION = 1.00 ---------------------- */
  --
  /* -------------------- DESCRIPCION -----------------------------
  || Asdruval Zacipa                                             ||
  || Agosto 15 de 2008 - Version = 1.00                          ||
  ||                                                             ||
  || Proposito: importar datos de poliza/siniestro desde         ||
  ||            produccion a bases de datos pruebas y desarrollo ||
  */---------------------------------------------------------------
  --
  /* -------------------- MODIFICACIONES---------------------------
  */---------------------------------------------------------------
  --
  --
  /* -------------------- DESCRIPCION -----------------------------
  || Declaracion de Variables GLOBALES
  */ --------------------------------------------------------------
  --
  g_genera_trazas       VARCHAR2(1) := 'S';
  --
  --
  /*-------------------- DESCRIPCION ----------------------------------
  || Procedimiento de importacion tablas de poliza
  */-------------------------------------------------------------------
  PROCEDURE p_imp_poliza(p_cod_cia              IN a2000030.cod_cia   %TYPE
                        ,p_cod_ramo             IN a2000030.cod_ramo  %TYPE
                        ,p_num_poliza_desde     IN a2000030.num_poliza%TYPE
                        ,p_num_poliza_hasta     IN a2000030.num_poliza%TYPE
                        ,p_sid_origen           IN VARCHAR2 DEFAULT 'CSG'
                        ,p_sid_destino          IN VARCHAR2 DEFAULT 'DEV'
                        ,p_mca_imp_stros        IN VARCHAR2 DEFAULT 'N'
                        ,p_mca_imp_creditos     IN VARCHAR2 DEFAULT 'N'
                        ,p_mca_imp_cobranza     IN VARCHAR2 DEFAULT 'N'
                        ,p_mca_imp_reaseguro    IN VARCHAR2 DEFAULT 'N'
                        ,p_mca_imp_inspecciones IN VARCHAR2 DEFAULT 'N'
                        ,p_num_riesgo           IN a2000031.num_riesgo%TYPE DEFAULT NULL
                        ,p_txt_observacion     OUT VARCHAR2
                        );
  --
  --
  /*-------------------- DESCRIPCION ----------------------------------
  || Procedimiento de importacion tablas de poliza
  */-------------------------------------------------------------------
  PROCEDURE p_imp_poliza(p_cod_cia              IN a2000030.cod_cia   %TYPE
                        ,p_cod_ramo             IN a2000030.cod_ramo  %TYPE
                        ,p_num_poliza_desde     IN a2000030.num_poliza%TYPE
                        ,p_num_poliza_hasta     IN a2000030.num_poliza%TYPE
                        ,p_sid_origen           IN VARCHAR2 DEFAULT 'CSG'
                        ,p_sid_destino          IN VARCHAR2 DEFAULT 'DEV'
                        ,p_mca_imp_stros        IN VARCHAR2 DEFAULT 'N'
                        ,p_mca_imp_creditos     IN VARCHAR2 DEFAULT 'N'
                        ,p_mca_imp_cobranza     IN VARCHAR2 DEFAULT 'N'
                        ,p_mca_imp_reaseguro    IN VARCHAR2 DEFAULT 'N'
                        ,p_mca_imp_inspecciones IN VARCHAR2 DEFAULT 'N'
                        ,p_txt_observacion     OUT VARCHAR2
                        );
  --
  --
  /*-------------------- DESCRIPCION ----------------------------------
  || Procedimiento de generacion tabla importacion datos de ordern de pago
  */-------------------------------------------------------------------
  PROCEDURE p_imp_orden_pago(p_cod_cia       a5021604.cod_cia     %TYPE
                            ,p_num_ord_pago  a5021604.num_ord_pago%TYPE
                            ,p_base_orig     VARCHAR2    DEFAULT 'CSG'
                            ,p_base_des      VARCHAR2    DEFAULT 'DEV');
  --
END em_k_imp_datos_csg;
/
CREATE OR REPLACE PACKAGE BODY TRON2000.em_k_imp_datos_csg IS

  --
  /* --------------------- VERSION = 1.04 ---------------------- */
  --                                                               
  /* -------------------- DESCRIPCION -----------------------------
  || Asdruval Zacipa                                             ||
  || Agosto 15 de 2008 - Version = 1.00                          ||
  ||                                                             ||
  || Proposito: importar datos de poliza/siniestro desde         ||
  ||            produccion a bases de datos pruebas y desarrollo ||
  || ----------------------------------------------------------- ||
  || azacipa 20100513. v1.03                                     ||
  || ajuste para leer las tablas particionadas mediante la vista ||
  || asociada a la particion                                     ||
  || ----------------------------------------------------------- ||
  || mruales 20110513. v1.04                                     ||
  || Se incluye tablas de emision y siniestros ARP.
  */ ---------------------------------------------------------------
  --
  --
  /* -------------------- DESCRIPCION -----------------------------
  || Declaracion de Variables GLOBALES                             
  */ --------------------------------------------------------------
  --
  ln_cod_sector          a2000030.cod_sector %TYPE;
  ln_cod_ramo            a2000030.cod_ramo %TYPE;
  ln_tip_gestor          a2000030.tip_gestor %TYPE;
  ln_cod_agt             a2000030.cod_agt %TYPE;
  ln_cod_asesor          a2000030.cod_asesor %TYPE;
  ln_cod_agt2            a2000030.cod_agt2 %TYPE;
  ln_cod_agt3            a2000030.cod_agt3 %TYPE;
  ln_cod_agt4            a2000030.cod_agt4 %TYPE;
  ln_cod_org             a2000030.cod_org %TYPE;
  lv_num_poliza_cliente  a2000030.num_poliza_cliente%TYPE;
  lv_num_poliza_grupo    a2000030.num_poliza_grupo %TYPE;
  ln_num_contrato        a2000030.num_contrato %TYPE;
  lv_num_poliza          a2000030.num_poliza %TYPE;
  lv_cod_tratamiento     a1001800.cod_tratamiento %TYPE;
  lv_mca_tratamiento_arp a1001800_csg.mca_tratamiento_arp%TYPE;
  gc_sid_produccion      VARCHAR2(3) := 'CSG';
  gv_nom_fic_traza       VARCHAR2(100);
  --
  TYPE c_poliza IS REF CURSOR; -- define weak REF CURSOR type  
  --
  gc_max_linesize CONSTANT BINARY_INTEGER := 32767;
  gc_dir          CONSTANT VARCHAR2(100) := '/ap/lis/';
  lf_fichero           utl_file.file_type;
  lv_mca_genera_script VARCHAR2(1) := 'N';
  --
  TYPE gt_ref_cursor IS REF CURSOR;
  gr_tbl_columnas_bd all_tab_columns%ROWTYPE;
  TYPE gt_columnas_bd IS TABLE OF gr_tbl_columnas_bd%TYPE INDEX BY BINARY_INTEGER;
  gtb_columnas_bd gt_columnas_bd;
  --
  CURSOR gc_tratamiento(p_cod_cia    a1001800.cod_cia    %TYPE
                       ,p_cod_ramo    a1001800.cod_ramo  %TYPE) IS
    SELECT a.cod_tratamiento, b.mca_tratamiento_arp
      FROM a1001800 a
      LEFT OUTER JOIN a1001800_csg b
                   ON (a.cod_cia  = b.cod_cia
                   AND a.cod_ramo = b.cod_ramo)
     WHERE a.cod_cia  = p_cod_cia
       AND a.cod_ramo = p_cod_ramo;
    --
  lv_where                  VARCHAR2(1000);
  lv_where1                 VARCHAR2(1000);
  lv_where2                 VARCHAR2(1000);
  lv_where_contrato         VARCHAR2(1000);
  lv_where_poliza           VARCHAR2(1000);
  lv_where_poliza_2         VARCHAR2(1000);
  lv_where_poliza_ramo      VARCHAR2(1000);
  lv_where_poliza_rg        VARCHAR2(1000);
  lv_where_poliza_rg_0      VARCHAR2(1000);
  lv_where_poliza_ramo_rg   VARCHAR2(1000);
  lv_where_poliza_ramo_rg_0 VARCHAR2(1000);
  lv_where_pol_contrato     VARCHAR2(1000);
  lv_where_pol_contrato2    VARCHAR2(1000);
  lv_where_afiliacion_arl   VARCHAR2(1000);
  lv_where_poliza_cliente   VARCHAR2(1000);
  lv_where_poliza_grupo     VARCHAR2(1000);
  lv_where_poliza_grupo2    VARCHAR2(1000);
  lv_where_stro             VARCHAR2(1000);
  lv_where_op               VARCHAR2(1000);
  lv_where_anticipo         VARCHAR2(1000);
  lv_sentence               VARCHAR2(1000) := ' ';
  lv_delete                 VARCHAR2(32767) := ' ';
  --
  gv_sid_origen      VARCHAR2(20);
  gv_sid_destino     VARCHAR2(20);
  lv_esquema_default VARCHAR2(20) := 'TRON2000';
  g_nom_tabla        all_tab_columns.table_name%TYPE;
  --
  --
  /* -------------------- DESCRIPCION -----------------------------
  || Carga la global con el valor a asignar                      ||
  */ --------------------------------------------------------------
  PROCEDURE p_asigna_global(p_nom_global IN VARCHAR2,
                            p_vlr_global IN VARCHAR2) IS
  BEGIN
    --
    trn_k_global.asigna(p_nom_global, p_vlr_global);
    --
  END p_asigna_global;
  --
  --
  /* -----------------------------------------------------------------
  || f_dev_global_c :                                               ||
  || Llama a trn_k_global.ref_f_global                              ||
  */ -----------------------------------------------------------------
  FUNCTION f_ref_global_c(p_nom_global VARCHAR2) RETURN VARCHAR2 IS
    --
    lv_val_global VARCHAR2(2000);
    --
  BEGIN
    --
    lv_val_global := trn_k_global.ref_f_global(p_nom_global);
    --@ev_k_traza.mx('N', p_nom_global, lv_val_global);
    --
    RETURN lv_val_global;
    --
  END f_ref_global_c;
  --
  /* -------------------- DESCRIPCION -------------------------------
  || Determina el tipo de seguro por el cual es emitido el producto
  */ -----------------------------------------------------------------
  FUNCTION f_tip_seguro(p_cod_cia  IN a1001800.cod_cia %TYPE,
                        p_cod_ramo IN a1001800.cod_ramo%TYPE)
    RETURN a1001800_csg.tip_seguro%TYPE IS
    --
    lr_1800     a1001800 %ROWTYPE;
    lr_1800_csg a1001800_csg %ROWTYPE;
    --
  BEGIN
    --
    lr_1800 := ev_k_gen_colectivo_csg.f_lee_a1001800(p_cod_cia => p_cod_cia, p_cod_ramo => p_cod_ramo);
    --
    lr_1800_csg := dv_f_a1001800_csg(p_cod_cia => lr_1800.cod_cia, p_cod_sector => lr_1800.cod_sector, p_cod_subsector => lr_1800.cod_subsector, p_cod_ramo => lr_1800.cod_ramo);
    --
    RETURN lr_1800_csg.tip_seguro;
    --
  END f_tip_seguro;
  --
  --
  --
  /* -------------------- DESCRIPCION ---------------------------
  || Inicializa el archivo de trazas                             
  */ ------------------------------------------------------------
  PROCEDURE p_ini_traza(p_estado VARCHAR2,
                        p_prg    VARCHAR2) IS
    --
    greg g0000000%ROWTYPE;
    --
  BEGIN
    --
    IF trn_k_global.ref_f_global('sql_dir') IS NULL
    THEN
      --
      p_asigna_global('sql_dir', trn_k_g0000000.f_txt_sql_dir);
      --
    END IF;
    --
    IF NVL(g_genera_trazas, 'N') = 'S'
    THEN
      --
      gv_nom_fic_traza := 'sacapol_';
      --
      IF lv_num_poliza IS NOT NULL
      THEN
        --
        gv_nom_fic_traza := gv_nom_fic_traza || lv_num_poliza;
        --
        p_asigna_global('nom_fic_traza', gv_nom_fic_traza);
        --
      END IF;
      --
      ev_k_traza.p_ini_traza(p_nom_traza => NVL(gv_nom_fic_traza, 'sacapol'), p_nom_objeto => 'em_k_imp_datos_csg', p_mca_genera_traza => g_genera_trazas);
      --
      ev_k_traza.mx(p_estado, p_prg);
      --
    ELSE
      --
      ev_k_traza.g_genera_trazas := 'N';
      --
    END IF;
    --
  EXCEPTION
    WHEN OTHERS THEN
      --
      NULL;
      --
  END p_ini_traza;
  --
  --
  PROCEDURE p_imprime_linea(p_linea IN VARCHAR2) IS
    --
    ln_i PLS_INTEGER := 0;
    --
  BEGIN
    --
    WHILE ln_i < LENGTH(p_linea)
    LOOP
      --
      --@ev_k_traza.mx('N', TO_CHAR(ln_i), SUBSTR(p_linea, ln_i, 100));
      ln_i := ln_i + 100;
      --
    END LOOP;
    --
  END;
  --
  --
  PROCEDURE p_abre_cur_cols_plano(p_nom_tabla      IN all_tab_columns.table_name%TYPE,
                                  p_esquema        IN all_tab_columns.owner %TYPE,
                                  p_dblink_origen  IN VARCHAR2,
                                  p_dblink_destino IN VARCHAR2,
                                  p_ini            IN OUT BINARY_INTEGER,
                                  p_fin            IN OUT BINARY_INTEGER) IS
    --
    lcur_cols_tabla_bd gt_ref_cursor;
    lv_query           VARCHAR2(1000);
    lv_nom_tabla       VARCHAR2(100) := UPPER(p_nom_tabla);
    lv_esquema         VARCHAR2(100) := UPPER(p_esquema);
    i                  BINARY_INTEGER;
    li_ini             BINARY_INTEGER := 0;
    li_fin             BINARY_INTEGER := 0;
    --
  BEGIN
    --
    p_ini_traza('I', 'p_abre_cur_cols_plano');
    --
    i := gtb_columnas_bd.first;
    --
    --@ev_k_traza.mx('N', 'i', i);
    --@ev_k_traza.mx('N', 'lv_nom_tabla', lv_nom_tabla);
    --@ev_k_traza.mx('N', 'lv_esquema', lv_esquema);
    --
    WHILE i IS NOT NULL
    LOOP
      --
      --@ev_k_traza.mx( 'N', 'i', i );
      --@ev_k_traza.mx( 'N', 'gtb_columnas_bd(i).table_name', gtb_columnas_bd(i).table_name );
      --@ev_k_traza.mx( 'N', 'gtb_columnas_bd(i).owner', gtb_columnas_bd(i).owner );
      --
      IF gtb_columnas_bd(i).table_name = lv_nom_tabla
          AND gtb_columnas_bd(i).owner = lv_esquema
      THEN
        --
        IF li_ini = 0
        THEN
          --
          li_ini := i;
          --
        END IF;
        --
        li_fin := i;
        --
      ELSE
        --
        IF li_ini > 0
        THEN
          --
          EXIT;
          --
        END IF;
        --
      END IF;
      --
      i := gtb_columnas_bd.next(i);
      --
    END LOOP;
    --
    --@ev_k_traza.mx('N', 'li_ini', li_ini);
    --
    IF li_ini = 0
    THEN
      --
      --@ev_k_traza.mx('no encuentra columna de tabla en cache ' || lv_nom_tabla);
      --
      lv_query := 'SELECT o.* ';
      lv_query := lv_query || '  FROM all_tab_columns' || p_dblink_destino || ' o';
      lv_query := lv_query || ' WHERE o.table_name   = ''' || lv_nom_tabla || '''';
      lv_query := lv_query || '   AND o.owner        = ''' || lv_esquema || '''';
      lv_query := lv_query ||
                  '   AND EXISTS (SELECT 0 FROM all_tab_columns' ||
                  p_dblink_origen || ' d ';
      lv_query := lv_query ||
                  '                WHERE d.table_name   = o.table_name ';
      lv_query := lv_query ||
                  '                  AND d.owner        = o.owner ';
      lv_query := lv_query ||
                  '                  AND d.column_name  = o.column_name )';
      lv_query := lv_query || ' ORDER BY column_id ';
      --
      --@ev_k_traza.mx('N', 'lv_query', lv_query);
      --
      IF lcur_cols_tabla_bd%ISOPEN
      THEN
        --
        CLOSE lcur_cols_tabla_bd;
        --
      END IF;
      --
      OPEN lcur_cols_tabla_bd FOR lv_query;
      FETCH lcur_cols_tabla_bd
        INTO gr_tbl_columnas_bd;
      --
      WHILE lcur_cols_tabla_bd%FOUND
      LOOP
        --
        i := NVL(gtb_columnas_bd.last, 0) + 1;
        --
        gtb_columnas_bd(i) := gr_tbl_columnas_bd;
        --
        IF li_ini = 0
        THEN
          --
          li_ini := i;
          --
        END IF;
        --
        li_fin := i;
        --
        FETCH lcur_cols_tabla_bd
          INTO gr_tbl_columnas_bd;
        --
      END LOOP;
      --
      CLOSE lcur_cols_tabla_bd;
      --
    END IF;
    --
    p_ini := li_ini;
    p_fin := li_fin;
    --
    p_ini_traza('F', 'p_abre_cur_cols_plano');
    --
  EXCEPTION
    WHEN OTHERS THEN
      --
      raise_application_error(-20001, SQLERRM);
      --
  END p_abre_cur_cols_plano;
  --
  --
  PROCEDURE p_abre_cur_cols_plano_vista(p_nom_vista      IN all_tab_columns.table_name%TYPE,
                                        p_nom_tabla      IN all_tab_columns.table_name%TYPE,
                                        p_esquema        IN all_tab_columns.owner %TYPE,
                                        p_dblink_origen  IN VARCHAR2,
                                        p_dblink_destino IN VARCHAR2,
                                        p_ini            IN OUT BINARY_INTEGER,
                                        p_fin            IN OUT BINARY_INTEGER) IS
    --
    lcur_cols_tabla_bd gt_ref_cursor;
    lv_query           VARCHAR2(1000);
    lv_nom_tabla       VARCHAR2(100) := UPPER(p_nom_tabla);
    lv_esquema         VARCHAR2(100) := UPPER(p_esquema);
    i                  BINARY_INTEGER;
    li_ini             BINARY_INTEGER := 0;
    li_fin             BINARY_INTEGER := 0;
    --
  BEGIN
    --
    p_ini_traza('I', 'p_abre_cur_cols_plano_vista');
    --
    i := gtb_columnas_bd.first;
    --
    --@ev_k_traza.mx('N', 'i', i);
    --@ev_k_traza.mx('N', 'lv_nom_tabla', lv_nom_tabla);
    --@ev_k_traza.mx('N', 'lv_esquema', lv_esquema);
    --
    WHILE i IS NOT NULL
    LOOP
      --
      --@ev_k_traza.mx( 'N', 'i', i );
      --@ev_k_traza.mx( 'N', 'gtb_columnas_bd(i).table_name', gtb_columnas_bd(i).table_name );
      --@ev_k_traza.mx( 'N', 'gtb_columnas_bd(i).owner', gtb_columnas_bd(i).owner );
      --
      IF gtb_columnas_bd(i).table_name = lv_nom_tabla
          AND gtb_columnas_bd(i).owner = lv_esquema
      THEN
        --
        IF li_ini = 0
        THEN
          --
          li_ini := i;
          --
        END IF;
        --
        li_fin := i;
        --
      ELSE
        --
        IF li_ini > 0
        THEN
          --
          EXIT;
          --
        END IF;
        --
      END IF;
      --
      i := gtb_columnas_bd.next(i);
      --
    END LOOP;
    --
    --@ev_k_traza.mx('N', 'li_ini', li_ini);
    --
    IF li_ini = 0
    THEN
      --
      --@ev_k_traza.mx('no encuentra columna de tabla en cache ' || lv_nom_tabla);
      --
      lv_query := 'SELECT o.* ';
      lv_query := lv_query || '  FROM all_tab_columns' || p_dblink_destino || ' o';
      lv_query := lv_query || ' WHERE o.table_name   = ''' || p_nom_tabla || '''';
      lv_query := lv_query || '   AND o.owner        = ''' || lv_esquema || '''';
      lv_query := lv_query ||
                  '   AND EXISTS (SELECT 0 FROM all_tab_columns' ||
                  p_dblink_origen || ' d ';
      lv_query := lv_query ||
                  '                WHERE d.table_name   = ''' || p_nom_vista || '''';
      lv_query := lv_query ||
                  '                  AND d.owner        = o.owner ';
      lv_query := lv_query ||
                  '                  AND d.column_name  = o.column_name )';
      lv_query := lv_query || ' ORDER BY column_id ';
      --
      --@ev_k_traza.mx('N', 'lv_query', lv_query);
      --
      IF lcur_cols_tabla_bd%ISOPEN
      THEN
        --
        CLOSE lcur_cols_tabla_bd;
        --
      END IF;
      --
      OPEN lcur_cols_tabla_bd FOR lv_query;
      FETCH lcur_cols_tabla_bd
        INTO gr_tbl_columnas_bd;
      --
      WHILE lcur_cols_tabla_bd%FOUND
      LOOP
        --
        i := NVL(gtb_columnas_bd.last, 0) + 1;
        --
        gtb_columnas_bd(i) := gr_tbl_columnas_bd;
        --
        IF li_ini = 0
        THEN
          --
          li_ini := i;
          --
        END IF;
        --
        li_fin := i;
        --
        FETCH lcur_cols_tabla_bd
          INTO gr_tbl_columnas_bd;
        --
      END LOOP;
      --
      CLOSE lcur_cols_tabla_bd;
      --
    END IF;
    --
    p_ini := li_ini;
    p_fin := li_fin;
    --
    p_ini_traza('F', 'p_abre_cur_cols_plano_vista');
    --
  EXCEPTION
    WHEN OTHERS THEN
      --
      raise_application_error(-20001, SQLERRM);
      --
  END p_abre_cur_cols_plano_vista;
  --
  --
  PROCEDURE p_ejecuta_dml(p_sentence VARCHAR2) IS
  BEGIN
    --
    p_ini_traza('I', 'p_ejecuta_dml');
    --
    lv_sentence := p_sentence;
    --
    --@ev_k_traza.mx('N', 'lv_sentence', SUBSTR(lv_sentence, 1, 500));
    --
    EXECUTE IMMEDIATE lv_sentence;
    --
    p_ini_traza('F', 'p_ejecuta_dml');
    --
  END;
  --
  /*
  FUNCTION f_nom_tabla (p_esquema   IN all_tab_columns.owner     %TYPE
                       ,p_nom_tabla IN all_tab_columns.table_name%TYPE
                       ,p_part_key  IN VARCHAR2) RETURN VARCHAR2 IS
    --
    CURSOR c_partitions IS
      SELECT a.partition_name
            ,a.high_value
            ,a.high_value_length
            ,b.column_name
        FROM all_tab_partitions a JOIN all_part_key_columns b ON (b.owner = a.table_owner
                                                              AND b.name  = a.table_name)
       WHERE a.table_owner = UPPER(p_esquema)
         AND a.table_name  = UPPER(p_nom_tabla);
    --
    lv_partition_name     all_tab_partitions.partition_name   %TYPE;
    ll_high_value         all_tab_partitions.high_value       %TYPE;
    ln_high_value_length  all_tab_partitions.high_value_length%TYPE;
    lv_column_name        all_part_key_columns.column_name    %TYPE;
    lv_part_value         VARCHAR2(4000);
    lv_nom_tabla          VARCHAR2(100);
    --
  BEGIN
    --
    OPEN  c_partitions;
    FETCH c_partitions INTO lv_partition_name
                           ,ll_high_value
                           ,ln_high_value_length
                           ,lv_column_name;
    --
    --@ev_k_traza.mx( 'N', 'p_esquema         ', p_esquema         );
    --@ev_k_traza.mx( 'N', 'p_nom_tabla       ', p_nom_tabla       );
    --@ev_k_traza.mx( 'N', 'p_part_key        ', p_part_key        );
    --@ev_k_traza.mx( 'N', 'c_partitions%FOUND', c_partitions%FOUND);    
    --@ev_k_traza.mx( 'N', 'lv_partition_name ', lv_partition_name );
    --
    WHILE c_partitions%FOUND LOOP
      --
      lv_part_value := SUBSTR(ll_high_value, 1, ln_high_value_length);
      --
      --@ev_k_traza.mx( 'N', 'lv_part_value ', lv_part_value );      
      --
      IF lv_part_value = p_part_key THEN
        EXIT;
      END IF;
      --
      FETCH c_partitions INTO lv_partition_name
                             ,ll_high_value
                             ,ln_high_value_length
                             ,lv_column_name;
      --
    END LOOP;
    --
    CLOSE c_partitions;
    --
    lv_nom_tabla := p_nom_tabla;
    --
    IF lv_partition_name IS NOT NULL THEN
      --
      lv_nom_tabla := p_nom_tabla||' partition ('||lv_partition_name||')';
      --
    END IF;
    --
    --@ev_k_traza.mx( 'N', 'lv_nom_tabla ', lv_nom_tabla );
    --
    RETURN lv_nom_tabla;
    --
  END f_nom_tabla;
  */
  --
  PROCEDURE p_inserta(p_nom_tabla      IN all_tab_columns.table_name%TYPE,
                      p_where          IN VARCHAR2,
                      p_esquema        IN all_tab_columns.owner %TYPE DEFAULT 'TRON2000',
                      p_dblink_origen  IN VARCHAR2 DEFAULT NULL,
                      p_dblink_destino IN VARCHAR2 DEFAULT NULL,
                      p_mca_delete     IN VARCHAR2 DEFAULT NULL -- [S]Incluye delete de la tabla
                     ,
                      p_part_key       IN VARCHAR2 DEFAULT NULL) IS
    --
    lv_esquema         VARCHAR2(15) := LOWER(NVL(p_esquema, lv_esquema_default));
    lv_dblink_origen   VARCHAR2(15) := '@' ||
                                       NVL(p_dblink_origen, gv_sid_origen);
    lv_dblink_destino  VARCHAR2(15) := '@' ||
                                       NVL(p_dblink_destino, gv_sid_destino);
    lv_mca_delete      VARCHAR2(1) := NVL(p_mca_delete, 'S');
    lcur_cols_tabla_bd gt_ref_cursor;
    lcur_values        gt_ref_cursor;
    lv_query           VARCHAR2(32767) := 'SELECT ';
    lv_columnas        VARCHAR2(32767) := ' ';
    lv_values          VARCHAR2(32767) := ' ';
    lv_coma            VARCHAR2(1);
    lv_chr44           VARCHAR2(15);
    lv_insert          VARCHAR2(32767) := ' ';
    lv_nom_tabla       VARCHAR2(100);
    lv_nom_tabla_ori   VARCHAR2(100);
    --
    i      BINARY_INTEGER;
    li_ini BINARY_INTEGER := 0;
    li_fin BINARY_INTEGER := 0;
    --
  BEGIN
    --
    p_ini_traza('I', 'p_inserta');
    --
    --@ev_k_traza.mx('N', 'p_nom_tabla', p_nom_tabla);
    --@ev_k_traza.mx('N', 'p_where    ', p_where);
    --
    --lv_nom_tabla := f_nom_tabla(p_esquema => p_esquema, p_nom_tabla => p_nom_tabla, p_part_key => p_part_key);
    lv_nom_tabla := p_nom_tabla;
    g_nom_tabla  := p_nom_tabla;
    --
    IF p_part_key IS NOT NULL
    THEN
      --
      lv_nom_tabla := p_nom_tabla || '_' || p_part_key;
      --
    END IF;
    --
    --@ev_k_traza.mx('N', 'p_nom_tabla', p_nom_tabla);
    --@ev_k_traza.mx('N', 'lv_nom_tabla', lv_nom_tabla);
    --
    -- obtener el listado de columnas de la tabla...
    lv_nom_tabla_ori   := p_nom_tabla;
    --
    --Aqui se planillan las tablas que se acceden por vista
    IF LOWER(p_nom_tabla) IN ('a1001332','a8001000_sls') 
      AND LOWER(lv_dblink_origen) LIKE '%csg' THEN
      --
      lv_nom_tabla_ori  := 'V'||SUBSTR(p_nom_tabla,2);
      --
      p_abre_cur_cols_plano_vista(UPPER('V'||SUBSTR(p_nom_tabla,2)), UPPER(p_nom_tabla), lv_esquema, lv_dblink_origen, lv_dblink_destino, li_ini, li_fin);
      --
    ELSE
      --
      p_abre_cur_cols_plano(p_nom_tabla, lv_esquema, lv_dblink_origen, lv_dblink_destino, li_ini, li_fin);
      --
    END IF;
    --
    --@ev_k_traza.mx('N', 'li_ini', li_ini);
    --@ev_k_traza.mx('N', 'li_fin', li_fin);
    --
    FOR i IN li_ini .. li_fin
    LOOP
      --
      gr_tbl_columnas_bd := gtb_columnas_bd(i);
      --
      IF gr_tbl_columnas_bd.data_type IN
         ('VARCHAR2', 'VARCHAR', 'CHARACTER', 'CHAR', 'NCHAR', 'NVARCHAR2', 'LONG', 'CLOB', 'ROWID')
      THEN
        --
        lv_columnas := lv_columnas || lv_coma ||
                       LOWER(gr_tbl_columnas_bd.column_name);
        lv_query    := lv_query || lv_chr44 ||
                       'CHR(39)||NVL(REPLACE(REPLACE(' ||
                       gr_tbl_columnas_bd.column_name || ',''' || CHR(44) ||
                       ''',''#|#''),' || CHR(39) || CHR(39) || '''' ||
                       CHR(39) || ',''''),' || '''NULL''' || ')||CHR(39)';
        --
      ELSIF gr_tbl_columnas_bd.data_type IN
            ('NUMBER', 'FLOAT', 'DECIMAL', 'DOUBLE PRECISION', 'INTEGER', 'INT', 'SMALLINT', 'REAL')
      THEN
        --
        lv_columnas := lv_columnas || lv_coma ||
                       LOWER(gr_tbl_columnas_bd.column_name);
        lv_query    := lv_query || lv_chr44 || 'NVL(REPLACE(TO_CHAR(' ||
                       gr_tbl_columnas_bd.column_name ||
                       '),'','',''.''),''NULL'')';
        --
      ELSIF gr_tbl_columnas_bd.data_type = 'DATE'
      THEN
        --
        lv_columnas := lv_columnas || lv_coma ||
                       LOWER(gr_tbl_columnas_bd.column_name);
        lv_query    := lv_query || lv_chr44 || 'DECODE(' ||
                       gr_tbl_columnas_bd.column_name ||
                       ',NULL,''NULL'',''TO_DATE(''||CHR(39)||TO_CHAR(' ||
                       gr_tbl_columnas_bd.column_name ||
                       ',''YYYYMMDDHH24MISS'')||CHR(39)||'',''''YYYYMMDDHH24MISS'''')'')';
        --
      END IF;
      --
      lv_coma  := ',';
      lv_chr44 := '||CHR(44)||';
      --
    END LOOP;
    --
    --    lv_query := lv_query||' FROM '||lv_esquema||'.'||p_nom_tabla||lv_dblink_origen||' WHERE '||p_where;
    lv_query := lv_query || ' FROM ' || lv_esquema || '.' || lv_nom_tabla_ori ||
                lv_dblink_origen || ' WHERE ' || p_where;
    --
    IF lv_mca_delete = 'S'
    THEN
      --
      --      lv_delete  := 'DELETE FROM '||lv_esquema||'.'||RPAD(LOWER(p_nom_tabla),12,' ')||lv_dblink_destino||' WHERE '||p_where;
      lv_delete := 'DELETE FROM ' || lv_esquema || '.' ||
                   RPAD(LOWER(lv_nom_tabla), 12, ' ') || lv_dblink_destino ||
                   ' WHERE ' || p_where;
      --
      --@ev_k_traza.mx('N', 'lv_delete', lv_delete);
      --
      EXECUTE IMMEDIATE lv_delete;
      --
    END IF;
    --
    --p_imprime_linea(p_linea => lv_delete);
    --
    --@ev_k_traza.mx( '----------lv_query');    
    --
    --p_imprime_linea(p_linea => lv_query);
    --
    --@ev_k_traza.mx( '----------lv_insert');
    --
    OPEN lcur_values FOR lv_query;
    FETCH lcur_values
      INTO lv_values;
    --
    WHILE lcur_values%FOUND
    LOOP
      --
      lv_values := REPLACE(lv_values, '''NULL''', 'NULL');
      lv_values := REPLACE(lv_values, '#|#', CHR(44));
      --
      lv_insert := 'INSERT INTO ' || lv_esquema || '.' ||
                   RPAD(LOWER(p_nom_tabla), 12, ' ') || lv_dblink_destino || '(' ||
                   lv_columnas || ') VALUES (' || lv_values || ')';
      --
      --@ev_k_traza.mx( '----------lv_insert'||lv_insert);
      --p_imprime_linea(p_linea => lv_insert);
      --
      EXECUTE IMMEDIATE lv_insert;
      --
      FETCH lcur_values
        INTO lv_values;
      --
    END LOOP;
    --
    p_ini_traza('F', 'p_inserta');
    --
  EXCEPTION
    WHEN OTHERS THEN
      --
      --@ev_k_traza.mx('errr', SQLERRM);
      raise_application_error(-20001, SQLERRM);
      --
  END p_inserta;
  --
  --
  PROCEDURE p_inserta_a1001332_of0(p_cod_cia        IN a1001332.cod_cia       %TYPE
                                  ,p_tip_docum      IN a1001332.tip_docum     %TYPE
                                  ,p_cod_docum      IN a1001332.cod_docum     %TYPE
                                  ,p_mca_delete     IN VARCHAR2 DEFAULT NULL) IS
    --
  BEGIN
    --
    p_ini_traza('I', 'p_inserta_a1001332_of0');
    --
    --@ev_k_traza.mx('N', 'p_nom_tabla', p_nom_tabla);
    --@ev_k_traza.mx('N', 'p_where    ', p_where);
    --
    IF p_mca_delete = 'S'
    THEN
      --
      DELETE FROM a1001332@of0
      WHERE cod_cia   = p_cod_cia 
        AND cod_docum = p_cod_docum 
        AND tip_docum = p_tip_docum;
      --
    END IF;
    --
    INSERT INTO a1001332@of0
    SELECT cod_cia, 
        tip_docum, 
        cod_docum, 
        cod_act_tercero, 
        cod_agt, 
        decode(cod_ejecutivo,999999,99999), 
        tip_domicilio, 
        nom_domicilio1, 
        nom_domicilio2, 
        nom_domicilio3, 
        nom_localidad, 
        cod_pais, 
        substr(cod_prov,1,5), 
        cod_postal, 
        num_apartado, 
        tlf_pais, 
        tlf_zona, 
        tlf_numero, 
        email, 
        fax_numero, 
        tlf_pais_com, 
        tlf_zona_com, 
        tlf_numero_com, 
        fax_numero_com, 
        substr(email_com,1,60), 
        txt_etiqueta1, 
        txt_etiqueta2, 
        txt_etiqueta3, 
        txt_etiqueta4, 
        txt_etiqueta5, 
        substr(nom_contacto,1,60), 
        tip_cargo, 
        tip_act_economica, 
        cod_nivel3, 
        for_actuacion, 
        mca_agt_dir, 
        tip_agt, 
        cod_reten, 
        decode(cod_org,999999,99999),
        decode(cod_asesor,999999,99999), 
        cod_compensacion, 
        '0051' cod_entidad, 
        '0051' cod_oficina, 
        '99988877766' cta_cte, 
        cta_dc, 
        cod_agt_colegio, 
        num_contrato, 
        fec_alta_contrato, 
        fec_baja_contrato, 
        cod_calidad, 
        cod_envio, 
        cod_idioma, 
        cod_grp_tercero, 
        substr(obs_agt,1,60), 
        txt_aux1, 
        txt_aux2, 
        txt_aux3, 
        txt_aux4, 
        txt_aux5, 
        txt_aux6, 
        '2' txt_aux7, 
        txt_aux8, 
        txt_aux9, 
        mca_inh, 
        fec_validez, 
        cod_usr, 
        fec_actu, 
        cod_estado, 
        substr(txt_email,1,60), 
        cod_pais_etiqueta, 
        substr(cod_estado_etiqueta,1,2), 
        substr(cod_prov_etiqueta,1,5), 
        cod_postal_etiqueta, 
        substr(num_apartado_etiqueta,1,10), 
        fec_credencial, 
        substr(cod_localidad,1,5), 
        tip_situacion, 
        fec_vcto_credencial, 
        fec_nacimiento, 
        cod_clase_benef, 
        cod_causa_inh_trc, 
        atr_domicilio1, 
        atr_domicilio2, 
        atr_domicilio3, 
        atr_domicilio4, 
        atr_domicilio5, 
        anx_domicilio, 
        ext_cod_postal, 
        tlf_extension, 
        tlf_extension_com, 
        cod_localidad_etiqueta, 
        ext_cod_postal_etiqueta, 
        tip_proc_inh, 
        cod_canal3
      FROM v1001332@csg 
     WHERE cod_cia = p_cod_cia 
       AND cod_docum = p_cod_docum 
       AND tip_docum = p_tip_docum;
    --
    p_ini_traza('F', 'p_inserta_a1001332_of0');
    --
  EXCEPTION
    WHEN OTHERS THEN
      --
      --@ev_k_traza.mx('errr', SQLERRM);
      raise_application_error(-20001, SQLERRM);
      --
  END p_inserta_a1001332_of0;
  --
  --
  PROCEDURE p_imp_tablas_poliza(p_cod_cia          IN a2000030.cod_cia %TYPE,
                                p_cod_sector       IN a2000030.cod_sector %TYPE,
                                p_cod_ramo         IN a2000030.cod_ramo %TYPE,
                                p_num_poliza       IN a2000030.num_poliza %TYPE,
                                p_num_contrato     IN a2000030.num_contrato %TYPE,
                                p_num_poliza_grupo IN a2000030.num_poliza_grupo %TYPE,
                                p_num_riesgo       IN a2000031.num_riesgo %TYPE) IS
    --
    lv_cod_usr             a2000030.cod_usr %TYPE;
    --
  BEGIN
    --
    p_ini_traza('I', 'p_imp_tablas_poliza');
    --
    --@ev_k_traza.mx('N', 'p_cod_cia           ', p_cod_cia);
    --@ev_k_traza.mx('N', 'p_cod_ramo          ', p_cod_ramo);
    --@ev_k_traza.mx('N', 'p_num_poliza        ', p_num_poliza);
    --@ev_k_traza.mx('N', 'p_num_contrato      ', p_num_contrato);
    --@ev_k_traza.mx('N', 'p_num_poliza_grupo  ', p_num_poliza_grupo);
    --
    -- determinar el tratamiento del ramo
     OPEN gc_tratamiento(p_cod_cia,p_cod_ramo);
    FETCH gc_tratamiento
     INTO lv_cod_tratamiento, lv_mca_tratamiento_arp;
    CLOSE gc_tratamiento;
    --
    lv_where_poliza         := 'cod_cia = ' || TO_CHAR(p_cod_cia) ||
                               ' AND num_poliza = ''' || p_num_poliza || '''';
    lv_where_poliza_2       := 'cod_cia = ' || TO_CHAR(p_cod_cia) ||
                               ' AND num_poliza_tronweb = ''' ||
                               p_num_poliza || '''';
    lv_where_poliza_ramo    := 'cod_cia = ' || TO_CHAR(p_cod_cia) ||
                               ' AND num_poliza = ''' || p_num_poliza || '''' ||
                               ' AND cod_ramo = ' || p_cod_ramo;
    lv_where_poliza_cliente := 'cod_cia = ' || TO_CHAR(p_cod_cia) ||
                               ' AND num_poliza_cliente = ''' ||
                               p_num_poliza || '''';
    lv_where_op             := 'cod_cia = ' || TO_CHAR(p_cod_cia) ||
                               ' AND num_ord_pago in (select x.num_ord_pago from a2300333 x where x.cod_cia = ' ||
                               TO_CHAR(p_cod_cia) || ' AND num_poliza = ''' ||
                               p_num_poliza || '''' || ')';
    lv_where_anticipo       := 'cod_cia = ' || TO_CHAR(p_cod_cia) ||
                               ' AND num_anticipo in (select x.num_anticipo from a5029070 x where x.cod_cia = ' ||
                               TO_CHAR(p_cod_cia) || ' AND num_poliza = ''' ||
                               p_num_poliza || '''' || ')';
    --
    lv_where_poliza_rg        := lv_where_poliza;
    lv_where_poliza_rg_0      := lv_where_poliza;
    lv_where_poliza_ramo_rg   := lv_where_poliza_ramo;
    lv_where_poliza_ramo_rg_0 := lv_where_poliza_ramo;
    --
    IF p_num_riesgo IS NOT NULL
    THEN
      --
      lv_where_poliza_rg        := lv_where_poliza_rg ||
                                   ' AND num_riesgo = ' || p_num_riesgo;
      lv_where_poliza_rg_0      := lv_where_poliza_rg_0 ||
                                   ' AND num_riesgo in (0,' || p_num_riesgo || ')';
      lv_where_poliza_ramo_rg   := lv_where_poliza_ramo_rg ||
                                   ' AND num_riesgo = ' || p_num_riesgo;
      lv_where_poliza_ramo_rg_0 := lv_where_poliza_ramo_rg_0 ||
                                   ' AND num_riesgo in (0,' || p_num_riesgo || ')';
      --
    END IF;
    --
    --@ev_k_traza.mx('N', 'lv_where_poliza          ', lv_where_poliza);
    --@ev_k_traza.mx('N', 'lv_where_poliza_2        ', lv_where_poliza_2);
    --@ev_k_traza.mx('N', 'lv_where_poliza_cliente  ', lv_where_poliza_cliente);
    --@ev_k_traza.mx('N', 'lv_where_poliza_ramo     ', lv_where_poliza_ramo);
    --@ev_k_traza.mx('N', 'lv_where_poliza_rg       ', lv_where_poliza_rg);
    --@ev_k_traza.mx('N', 'lv_where_poliza_ramo_rg  ', lv_where_poliza_ramo_rg);
    --@ev_k_traza.mx('N', 'lv_where_poliza_ramo_rg_0', lv_where_poliza_ramo_rg_0);
    --
    p_inserta(p_nom_tabla => 'a2000030', p_where => lv_where_poliza, p_mca_delete => 'S'); --
    p_inserta(p_nom_tabla => 'a2000032', p_where => lv_where_poliza, p_mca_delete => 'S'); --
    --    p_inserta( p_nom_tabla => 'a2000020', p_where => lv_where_poliza_ramo, p_mca_delete => 'S' );--, p_part_key => TO_CHAR(p_cod_ramo));--
    p_inserta(p_nom_tabla => 'a2000020', p_where => lv_where_poliza_ramo_rg_0, p_mca_delete => 'S'); --, p_part_key => TO_CHAR(p_cod_ramo));--
    --    p_inserta( p_nom_tabla => 'a2000025', p_where => lv_where_poliza     , p_mca_delete => 'S' );--
    p_inserta(p_nom_tabla => 'a2000025', p_where => lv_where_poliza_rg_0, p_mca_delete => 'S'); --
    --    p_inserta( p_nom_tabla => 'a2000040', p_where => lv_where_poliza_ramo, p_mca_delete => 'S' );--, p_part_key => TO_CHAR(p_cod_ramo));--
    p_inserta(p_nom_tabla => 'a2000040', p_where => lv_where_poliza_ramo_rg_0, p_mca_delete => 'S'); --, p_part_key => TO_CHAR(p_cod_ramo));--
    --    p_inserta( p_nom_tabla => 'a2100170', p_where => lv_where_poliza_ramo, p_mca_delete => 'S'); --, p_part_key => TO_CHAR(p_cod_ramo));--
    p_inserta(p_nom_tabla => 'a2100170', p_where => lv_where_poliza_ramo_rg_0, p_mca_delete => 'S'); --, p_part_key => TO_CHAR(p_cod_ramo));--
    p_inserta(p_nom_tabla => 'a2000161', p_where => lv_where_poliza_ramo, p_mca_delete => 'S'); --, p_part_key => TO_CHAR(p_cod_ramo));--
    p_inserta(p_nom_tabla => 'a2000251', p_where => lv_where_poliza_ramo, p_mca_delete => 'S'); --, p_part_key => TO_CHAR(p_cod_ramo));--
    p_inserta(p_nom_tabla => 'a2301751', p_where => lv_where_poliza_ramo, p_mca_delete => 'S'); --
    p_inserta(p_nom_tabla => 'a2990700', p_where => lv_where_poliza, p_mca_delete => 'S'); --
    p_inserta(p_nom_tabla => 'a2990701', p_where => lv_where_poliza, p_mca_delete => 'S'); --
    --    p_inserta( p_nom_tabla => 'a5020301', p_where => lv_where_poliza, p_mca_delete => 'S' );        -- se pasa para p_imp_cobranza
    --    p_inserta( p_nom_tabla => 'a1000802', p_where => lv_where_poliza, p_mca_delete => 'S' );        --
    p_inserta(p_nom_tabla => 'a1000802', p_where => lv_where_poliza_rg_0, p_mca_delete => 'S'); --
    --p_inserta(p_nom_tabla => 'a1009802', p_where => lv_where_poliza, p_mca_delete => 'S'); --
    --    p_inserta( p_nom_tabla => 'a2000031', p_where => lv_where_poliza, p_mca_delete => 'S' );        --
    p_inserta(p_nom_tabla => 'a2000031', p_where => lv_where_poliza_rg, p_mca_delete => 'S'); --
    --    p_inserta( p_nom_tabla => 'a2000060', p_where => lv_where_poliza, p_mca_delete => 'S' );        --
    p_inserta(p_nom_tabla => 'a2000060', p_where => lv_where_poliza_rg, p_mca_delete => 'S'); --
    p_inserta(p_nom_tabla => 'a2000260', p_where => lv_where_poliza, p_mca_delete => 'S'); --
    p_inserta(p_nom_tabla => 'a2000265', p_where => lv_where_poliza, p_mca_delete => 'S'); --
    p_inserta(p_nom_tabla => 'a2990320', p_where => lv_where_poliza, p_mca_delete => 'S'); --
    p_inserta(p_nom_tabla => 'a2000221', p_where => lv_where_poliza, p_mca_delete => 'S'); --
    p_inserta(p_nom_tabla => 'a2990015', p_where => lv_where_poliza, p_mca_delete => 'S'); --
    p_inserta(p_nom_tabla => 'a2990016', p_where => lv_where_poliza, p_mca_delete => 'S'); --
    p_inserta(p_nom_tabla => 'a2990017', p_where => lv_where_poliza, p_mca_delete => 'S'); --
    --    p_inserta( p_nom_tabla => 'a2000510', p_where => lv_where_poliza, p_mca_delete => 'S' );      --
    p_inserta(p_nom_tabla => 'g8000006_csg', p_where => lv_where_poliza, p_mca_delete => 'S'); --
    p_inserta(p_nom_tabla => 'g8000007', p_where => lv_where_poliza, p_mca_delete => 'S'); --
    p_inserta(p_nom_tabla => 'g8000002_csg', p_where => lv_where_poliza, p_mca_delete => 'S'); --
    p_inserta(p_nom_tabla => 'g8000004_csg', p_where => lv_where_poliza_2, p_mca_delete => 'S'); --
    p_inserta(p_nom_tabla => 'g2990002', p_where => lv_where_poliza_cliente, p_mca_delete => 'S'); --
    --    p_inserta( p_nom_tabla => 'a5029070', p_where => lv_where_poliza, p_mca_delete => 'S' );      -- se pasa para p_imp_tablas_vidaind
    --    p_inserta( p_nom_tabla => 'a5029071', p_where => lv_where_anticipo, p_mca_delete => 'S' );      -- se pasa para p_imp_tablas_vidaind
    --    p_inserta( p_nom_tabla => 'a5021604', p_where => lv_where_op, p_mca_delete => 'S' );            -- se pasa para p_imp_tablas_vidaind
    --    p_inserta( p_nom_tabla => 'a5021608', p_where => lv_where_op, p_mca_delete => 'S' );            -- se pasa para p_imp_tablas_vidaind
    --
    --[azacipa-20120927> trucho mientras se prueba lo de BPM
    --<azacipa-20130207> quito esto en dev
    /*
    IF p_cod_sector = 1 THEN
      --
      lv_cod_usr := 'ACARDEN';
      --
    ELSIF p_cod_sector IN (4,5,6,7) THEN
      --
      lv_cod_usr := 'LARASAN';
      --
    ELSIF p_cod_sector IN (2,3) THEN
      --
      lv_cod_usr := 'AFTENOR';
      --
    ELSE
      --
      lv_cod_usr := NULL;
      --
    END IF;
    --
    IF lv_cod_usr IS NOT NULL THEN
      --
      UPDATE a2000030 SET cod_usr = lv_cod_usr
       WHERE cod_cia    = p_cod_cia
         AND num_poliza = p_num_poliza;
      --
      UPDATE a2000221 SET cod_usr_autorizacion = lv_cod_usr
       WHERE cod_cia = p_cod_cia
         AND num_poliza = p_num_poliza;
      --
    END IF;
    */
    --<azacipa-20120927]
    --
    -- pasar datos de la poliza grupo
    IF p_num_poliza_grupo IS NOT NULL
    THEN
      --
      lv_where_contrato       := 'cod_cia = ' || TO_CHAR(p_cod_cia) ||
                                 ' AND num_contrato = ' || p_num_contrato;
      lv_where_poliza_grupo   := 'cod_cia = ' || TO_CHAR(p_cod_cia) ||
                                 ' AND num_poliza_grupo = ''' ||
                                 p_num_poliza_grupo || '''';
      lv_where_poliza_grupo2  := 'cod_cia = ' || TO_CHAR(p_cod_cia) ||
                                 ' AND num_poliza = ''' ||
                                 p_num_poliza_grupo || '''';
      lv_where_pol_contrato   := 'cod_cia = ' || TO_CHAR(p_cod_cia) ||
                                 ' AND num_contrato = ' || p_num_contrato ||
                                 ' AND num_poliza = ''' ||
                                 p_num_poliza_grupo || '''';
      lv_where_pol_contrato2  := 'cod_cia = ' || TO_CHAR(p_cod_cia) ||
                                 ' AND num_contrato = ' || p_num_contrato ||
                                 ' AND num_poliza_grupo = ''' ||
                                 p_num_poliza_grupo || '''';
      lv_where_afiliacion_arl := 'cod_cia = ' || TO_CHAR(p_cod_cia) ||
                                 ' AND num_afiliacion in (select TO_NUMBER(x.val_campo) from G2999020 x ' ||
                                 ' where x.cod_cia  = ' ||
                                 TO_CHAR(p_cod_cia) ||
                                 ' AND num_poliza = ''' ||
                                 p_num_poliza_grupo || '''' ||
                                 ' AND cod_campo  =''NUM_FORMULARIO_AFILIACION''' ||
                                 ' AND mca_vigente = ''S'' AND cod_ramo = ' ||
                                 p_cod_ramo || ') ';
      --@ev_k_traza.mx('N', 'lv_where_contrato     ', lv_where_contrato);
      --@ev_k_traza.mx('N', 'lv_where_poliza_grupo ', lv_where_poliza_grupo);
      --@ev_k_traza.mx('N', 'lv_where_poliza_grupo2', lv_where_poliza_grupo2);
      --@ev_k_traza.mx('N', 'lv_where_pol_contrato ', lv_where_pol_contrato);
      --@ev_k_traza.mx('N', 'lv_where_pol_contrato2', lv_where_pol_contrato2);
      --
      p_inserta(p_nom_tabla => 'G2990001', p_where => lv_where_contrato); --
      p_inserta(p_nom_tabla => 'G2990000', p_where => lv_where_contrato); --
      p_inserta(p_nom_tabla => 'G2990027', p_where => lv_where_contrato); --
      p_inserta(p_nom_tabla => 'G2990000_CSG', p_where => lv_where_contrato); --
--      p_inserta(p_nom_tabla => 'A2000010', p_where => lv_where_pol_contrato); --
      IF upper(gv_sid_origen) IN ('OF0') THEN
        p_inserta(p_nom_tabla => 'A2000010', p_where => lv_where_pol_contrato);
      ELSE
        --
        BEGIN
        EXECUTE IMMEDIATE ' Delete from a2000010@'||gv_sid_destino
         ||' Where cod_cia = '||TO_CHAR(p_cod_cia)||' and num_poliza = '||CHR(39)||p_num_poliza_grupo||CHR(39)
         ||  ' and num_contrato = '||TO_CHAR(p_num_contrato) ;
        --
        EXECUTE IMMEDIATE ' INSERT INTO A2000010@'||gv_sid_destino
        ||' SELECT cod_cia, num_poliza, num_contrato, tip_poliza, mca_riesgos,fec_vcto_poliza, cod_usr, fec_actu, nom_poliza '
        ||  ' FROM A2000010@'||gv_sid_origen
        || ' Where cod_cia = '||TO_CHAR(p_cod_cia)||' and num_poliza = '||CHR(39)||p_num_poliza_grupo||CHR(39)
        ||   ' and num_contrato = '||TO_CHAR(p_num_contrato) ;
        EXCEPTION WHEN OTHERS THEN NULL;
        END;
        --
      END IF;
      --
      p_inserta(p_nom_tabla => 'G2990017', p_where => lv_where_poliza_grupo2); --
      p_inserta(p_nom_tabla => 'A2019034', p_where => lv_where_pol_contrato2); --
      p_inserta(p_nom_tabla => 'A2009125', p_where => lv_where_pol_contrato); --
      p_inserta(p_nom_tabla => 'H2019034', p_where => lv_where_pol_contrato2); --
      p_inserta(p_nom_tabla => 'H2009125', p_where => lv_where_pol_contrato); --
      p_inserta(p_nom_tabla => 'A2000260_CSG', p_where => lv_where_contrato); --
      p_inserta(p_nom_tabla => 'TAVID103', p_where => lv_where_pol_contrato2); --
      p_inserta(p_nom_tabla => 'TAVID104', p_where => lv_where_pol_contrato2); --
      p_inserta(p_nom_tabla => 'TAVID105', p_where => lv_where_pol_contrato2); --
      p_inserta(p_nom_tabla => 'TAVID200', p_where => lv_where_pol_contrato2); --
      p_inserta(p_nom_tabla => 'TAVID004', p_where => lv_where_poliza_grupo); --
      p_inserta(p_nom_tabla => 'G2999020', p_where => lv_where_pol_contrato); --
      p_inserta(p_nom_tabla => 'A9990015_CSG', p_where => lv_where_pol_contrato2); --
      p_inserta(p_nom_tabla => 'A1001751', p_where => lv_where_poliza_grupo2); --
      p_inserta(p_nom_tabla => 'A2301751', p_where => lv_where_poliza_grupo2); --
      --
      em_k_g2999020_csg.p_lee_vigente(p_cod_cia => p_cod_cia, p_num_poliza => p_num_poliza_grupo, p_num_contrato => p_num_contrato, p_cod_campo => 'MCA_EMITE_NOMINADO', p_cod_ramo => p_cod_ramo);
      --
      -- si el dv no existe se asume nominacion
      --SE QUITA TEMPORALMENT POR CAMBIO EN ESTRUCUTRA DE TABLAS BASE DE RIESGOS
      /*IF NVL(em_k_g2999020_csg.f_val_campo, 'S') = 'B'
      THEN
        --
        p_inserta(p_nom_tabla => 'a2999080', p_where => lv_where_poliza); --
        p_inserta(p_nom_tabla => 'a2999085', p_where => lv_where_poliza); --
        p_inserta(p_nom_tabla => 'a2999090', p_where => lv_where_poliza); --
        p_inserta(p_nom_tabla => 'a2999095', p_where => lv_where_poliza); --
        --
      END IF;*/
      --
      IF lv_mca_tratamiento_arp = 'S'
      THEN
        --
        p_inserta(p_nom_tabla => 'a2209005', p_where => lv_where_pol_contrato2); --
        --p_inserta( p_nom_tabla => 'a2209006'     , p_where => lv_where_pol_contrato2 );--
        p_inserta(p_nom_tabla => 'a2309710', p_where => lv_where_afiliacion_arl);
        p_inserta(p_nom_tabla => 'a2309720', p_where => lv_where_afiliacion_arl);
        p_inserta(p_nom_tabla => 'a2309730', p_where => lv_where_afiliacion_arl);
        p_inserta(p_nom_tabla => 'a2309740', p_where => lv_where_afiliacion_arl);
        p_inserta(p_nom_tabla => 'a2309750', p_where => lv_where_afiliacion_arl);
        --
      END IF;
      --
    END IF;
    --
    CASE lv_cod_tratamiento
    --
      WHEN 'V' THEN
        --
        p_inserta(p_nom_tabla => 'a2300333', p_where => lv_where_poliza, p_mca_delete => 'S'); --
        p_inserta(p_nom_tabla => 'a2300333_csg', p_where => lv_where_poliza, p_mca_delete => 'S'); --
        p_inserta(p_nom_tabla => 'a2300334', p_where => lv_where_poliza, p_mca_delete => 'S'); --
        p_inserta(p_nom_tabla => 'a2300334_csg', p_where => lv_where_poliza, p_mca_delete => 'S'); --
        p_inserta(p_nom_tabla => 'A2301751', p_where => lv_where_poliza); --
    --
      WHEN 'A' THEN
        --
        p_inserta(p_nom_tabla => 'a2100610', p_where => lv_where_poliza, p_mca_delete => 'S'); --
        p_inserta(p_nom_tabla => 'A1001751', p_where => lv_where_poliza); --
    --
      ELSE
        --
        p_inserta(p_nom_tabla => 'A1001751', p_where => lv_where_poliza); --
    --
    END CASE;
    --
    IF lv_mca_tratamiento_arp = 'S'
    THEN
      --
      --      p_inserta( p_nom_tabla => 'a2209023'    , p_where => lv_where_poliza, p_mca_delete => 'S' );--
      p_inserta(p_nom_tabla => 'a2209023', p_where => lv_where_poliza_rg, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a2209010', p_where => lv_where_poliza, p_mca_delete => 'S'); --
      --      p_inserta( p_nom_tabla => 'a2209011'    , p_where => lv_where_poliza, p_mca_delete => 'S' );--
      p_inserta(p_nom_tabla => 'a2209011', p_where => lv_where_poliza_rg, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a2209012', p_where => lv_where_poliza, p_mca_delete => 'S'); --
      --      p_inserta( p_nom_tabla => 'a2209040'    , p_where => lv_where_poliza, p_mca_delete => 'S' );--
      p_inserta(p_nom_tabla => 'a2209040', p_where => lv_where_poliza_rg, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a2209090', p_where => lv_where_poliza, p_mca_delete => 'S'); --
      --
    END IF;
    --
    p_ini_traza('F', 'p_imp_tablas_poliza');
    --
  END p_imp_tablas_poliza;

  --
  PROCEDURE p_imp_terceros(p_cod_cia    IN a2000030.cod_cia %TYPE,
                           p_cod_agt    IN a2000030.cod_agt %TYPE,
                           p_cod_asesor IN a2000030.cod_asesor%TYPE,
                           p_cod_agt2   IN a2000030.cod_agt2 %TYPE,
                           p_cod_agt3   IN a2000030.cod_agt3 %TYPE,
                           p_cod_agt4   IN a2000030.cod_agt4 %TYPE,
                           p_cod_org    IN a2000030.cod_org %TYPE,
                           p_num_poliza IN a2000030.num_poliza%TYPE,
                           p_num_riesgo IN a2000031.num_riesgo%TYPE) IS
    --
    CURSOR c_a2000060(p_tip_docum IN a2000060.tip_docum%TYPE,
                      p_cod_docum IN a2000060.cod_docum%TYPE) IS
      SELECT DISTINCT num_riesgo
        FROM a2000060
       WHERE cod_cia = p_cod_cia
         AND num_poliza = p_num_poliza
         AND tip_benef = '2' -- asegurados
         AND tip_docum = p_tip_docum
         AND cod_docum = p_cod_docum;
    --
    TYPE c_terceros IS REF CURSOR; -- define weak REF CURSOR type
    cv_terceros c_terceros; -- declare cursor variable    
    --
    lv_tip_docum       a2000030.tip_docum %TYPE;
    lv_cod_docum       a2000030.cod_docum %TYPE;
    ln_cod_agt         a1001332.cod_agt   %TYPE;
    ln_cod_act_tercero a1001331.cod_act_tercero%TYPE;
    lv_nom_tercero     v1001390.nom_completo %TYPE;
    ln_cod_tercero     v1001390.cod_tercero %TYPE;
    ln_num_riesgo      a2000060.num_riesgo %TYPE;
    --
  BEGIN
    --
    p_ini_traza('I', 'p_imp_terceros');
    --
    IF p_num_riesgo IS NULL
    THEN
      --
      OPEN cv_terceros FOR ' SELECT DISTINCT tip_docum, cod_docum' || '   FROM a2000060@' || gv_sid_origen || '  WHERE cod_cia = :codcia' || '    and num_poliza = :npoliza' || '  UNION' || ' SELECT DISTINCT tip_docum, cod_docum' || '   FROM p2000060@' || gv_sid_origen || '  WHERE cod_cia = :codcia' || '    and num_poliza = :npoliza' || '  UNION' || ' SELECT DISTINCT tip_docum, cod_docum' || '   FROM a2000030@' || gv_sid_origen || '  WHERE cod_cia = :codcia' || '    and num_poliza = :npoliza'
        USING p_cod_cia, p_num_poliza, p_cod_cia, p_num_poliza, p_cod_cia, p_num_poliza;
      --
    ELSE
      --
      OPEN cv_terceros FOR ' SELECT DISTINCT tip_docum, cod_docum' || '   FROM a2000060@' || gv_sid_origen || '  WHERE cod_cia = :codcia' || '    AND num_poliza = :npoliza' || '    AND num_riesgo = :nriesgo' || '  UNION' || ' SELECT DISTINCT tip_docum, cod_docum' || '   FROM p2000060@' || gv_sid_origen || '  WHERE cod_cia = :codcia' || '    AND num_poliza = :npoliza' || '    AND num_riesgo = :nriesgo' || '  UNION' || ' SELECT DISTINCT tip_docum, cod_docum' || '   FROM a2000030@' || gv_sid_origen || '  WHERE cod_cia = :codcia' || '    and num_poliza = :npoliza'
        USING p_cod_cia, p_num_poliza, p_num_riesgo, p_cod_cia, p_num_poliza, p_num_riesgo, p_cod_cia, p_num_poliza;
      --
    END IF;
    --
    ln_cod_act_tercero := 2;
    --
    FETCH cv_terceros
      INTO lv_tip_docum, lv_cod_docum;
    --
    WHILE cv_terceros%FOUND
    LOOP
      --
      lv_where := 'cod_cia   = ' || TO_CHAR(p_cod_cia) ||
                  ' AND tip_docum = ''' || lv_tip_docum ||
                  ''' AND cod_docum = ''' || lv_cod_docum ||
                  ''' AND cod_act_tercero = ' ||
                  TO_CHAR(ln_cod_act_tercero);
      --
      lv_where2 := 'cod_cia   = ' || TO_CHAR(p_cod_cia) ||
                   ' AND tip_docum = ''' || lv_tip_docum ||
                   ''' AND cod_docum = ''' || lv_cod_docum || '''';
      --
      p_inserta(p_nom_tabla => 'a1001390', p_where => lv_where2, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a1001399', p_where => lv_where2, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a1001331', p_where => lv_where2, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a1001331_csg', p_where => lv_where2, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a1001300', p_where => lv_where2, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a1001300_csg', p_where => lv_where2, p_mca_delete => 'S'); --
      --
      OPEN c_a2000060(p_tip_docum => lv_tip_docum, p_cod_docum => lv_cod_docum);
      --
      FETCH c_a2000060
        INTO ln_num_riesgo;
      --
      WHILE c_a2000060%FOUND
      LOOP
        --
        BEGIN
          --
          dc_p_nom_ape_completo(p_cod_cia => p_cod_cia, p_tip_docum => lv_tip_docum, p_cod_docum => lv_cod_docum, p_cod_act_tercero => 1 -- asegurados
                               , p_nom_completo => lv_nom_tercero, p_cod_tercero => ln_cod_tercero);
          --
          UPDATE a2000031
             SET nom_riesgo = SUBSTR(lv_nom_tercero, 1, 80)
           WHERE cod_cia = p_cod_cia
             AND num_poliza = p_num_poliza
             AND num_riesgo = ln_num_riesgo;
          --
        EXCEPTION
          WHEN OTHERS THEN
            ROLLBACK;
            raise_application_error(-20010, SQLERRM);
        END;
        --
        FETCH c_a2000060
          INTO ln_num_riesgo;
        --
      END LOOP;
      --
      CLOSE c_a2000060;
      --
      FETCH cv_terceros
        INTO lv_tip_docum, lv_cod_docum;
      --
    END LOOP;
    --
    CLOSE cv_terceros;
    --
    -- pasar datos del intermediario y asesor
    OPEN cv_terceros FOR ' SELECT DISTINCT tip_docum, cod_docum, cod_agt' || '   FROM v1001332@' || gv_sid_origen ||
                         '  WHERE cod_cia    = :codcia' ||
                         '    AND cod_agt    = :codagt' ||
                         '  UNION'                      ||
                         ' SELECT DISTINCT tip_docum, cod_docum, cod_agt' ||
                         '   FROM v1001332@' || gv_sid_origen ||
                         '  WHERE cod_cia    = :codcia' ||
                         '    and cod_agt    = :codasesor' ||
                         '  UNION'                      ||
                         ' SELECT DISTINCT tip_docum, cod_docum, cod_agt' ||
                         '   FROM v1001332@' || gv_sid_origen ||
                         '  WHERE cod_cia    = :codcia' ||
                         '    and cod_agt    = :codagt2' ||
                         '  UNION' || ' SELECT DISTINCT tip_docum, cod_docum, cod_agt' ||
                         '   FROM v1001332@' || gv_sid_origen ||
                         '  WHERE cod_cia    = :codcia' ||
                         '    and cod_agt    = :codagt3' ||
                         '  UNION' || ' SELECT DISTINCT tip_docum, cod_docum, cod_agt' ||
                         '   FROM v1001332@' || gv_sid_origen ||
                         '  WHERE cod_cia    = :codcia' ||
                         '    and cod_agt    = :codagt4' ||
                         '  UNION' || ' SELECT DISTINCT tip_docum, cod_docum, cod_agt' ||
                         '   FROM v1001332@' || gv_sid_origen ||
                         '  WHERE cod_cia    = :codcia' ||
                         '    and cod_agt    = :codorg'
      USING p_cod_cia, p_cod_agt, p_cod_cia, p_cod_asesor, p_cod_cia, p_cod_agt2, p_cod_cia, p_cod_agt3, p_cod_cia, p_cod_agt4, p_cod_cia, p_cod_org;
    --
    FETCH cv_terceros
      INTO lv_tip_docum, lv_cod_docum, ln_cod_agt;
    --
    WHILE cv_terceros%FOUND
    LOOP
      --
      lv_where  := 'cod_cia   = ' || TO_CHAR(p_cod_cia) ||
                   ' AND cod_agt = ' || TO_CHAR(ln_cod_agt); --
      --
      lv_where2 := 'cod_cia   = ' || TO_CHAR(p_cod_cia) ||
                   ' AND tip_docum = ''' || lv_tip_docum ||
                   ''' AND cod_docum = ''' || lv_cod_docum || ''''; --
      --
      p_inserta(p_nom_tabla => 'a1001390', p_where => lv_where2, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a1001331', p_where => lv_where2, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a1001342', p_where => lv_where , p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a1009332', p_where => lv_where , p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a1001399', p_where => lv_where2, p_mca_delete => 'S'); --
      --
      IF gv_sid_destino = 'OF0' THEN
        --
        p_inserta_a1001332_of0(p_cod_cia => p_cod_cia, p_tip_docum => lv_tip_docum, p_cod_docum => lv_cod_docum, p_mca_delete => 'S');
        --
      ELSE
        --
        p_inserta(p_nom_tabla => 'a1001332', p_where => lv_where2, p_mca_delete => 'S'); --
        --
      END IF;
      --
      p_inserta(p_nom_tabla => 'a1001332_csg', p_where => lv_where2, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a1001300', p_where => lv_where2, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a1001300_csg', p_where => lv_where2, p_mca_delete => 'S'); --
      --
      FETCH cv_terceros
        INTO lv_tip_docum, lv_cod_docum, ln_cod_agt;
      --
    END LOOP;
    --
    CLOSE cv_terceros;
    --
    p_ini_traza('F', 'p_imp_terceros');
    --
  END p_imp_terceros;

  --
  PROCEDURE p_imp_stros(p_cod_cia    IN a2000030.cod_cia %TYPE,
                        p_num_poliza IN a2000030.num_poliza%TYPE,
                        p_num_riesgo IN a2000031.num_riesgo%TYPE) IS
    --
    ln_num_sini      a7001000.num_sini %TYPE;
    ln_num_exp       a7001000.num_exp %TYPE;
    lv_tip_exp       a7001000.tip_exp %TYPE;
    ld_fec_sini      a7000900.fec_sini %TYPE;
    ld_fec_actu      a7000900.fec_actu %TYPE;
    lv_cod_usr       a7000900.cod_usr %TYPE;
    ln_tip_coaseguro a7000900.tip_coaseguro%TYPE;
    lv_tip_est_sini  a7000900.tip_est_sini %TYPE;
    cv_stro          c_poliza; -- declare cursor variable
    --
  BEGIN
    --
    p_ini_traza('I', 'p_imp_stros');
    --
    --@ev_k_traza.mx('N', 'p_cod_cia   ', p_cod_cia);
    --@ev_k_traza.mx('N', 'p_num_poliza', p_num_poliza);
    --
    IF p_num_riesgo IS NULL
    THEN
      --
      OPEN cv_stro FOR 'SELECT num_sini, cod_ramo, fec_sini, fec_actu , cod_usr, tip_coaseguro, tip_est_sini' || ' FROM a7000900@' || gv_sid_origen || ' WHERE cod_cia = :codcia AND num_poliza = :numpoliza'
        USING p_cod_cia, p_num_poliza;
      --
    ELSE
      --
      OPEN cv_stro FOR 'SELECT num_sini, cod_ramo, fec_sini, fec_actu , cod_usr, tip_coaseguro, tip_est_sini' || ' FROM a7000900@' || gv_sid_origen || ' WHERE cod_cia = :codcia AND num_poliza = :numpoliza AND num_riesgo = :numriesgo'
        USING p_cod_cia, p_num_poliza, p_num_riesgo;
      --
    END IF;
    --
    --@ev_k_traza.mx('after open');
    --
    FETCH cv_stro
      INTO ln_num_sini,
           ln_cod_ramo,
           ld_fec_sini,
           ld_fec_actu,
           lv_cod_usr,
           ln_tip_coaseguro,
           lv_tip_est_sini;
    --
    --@ev_k_traza.mx('N', 'ln_num_sini', ln_num_sini);
    --@ev_k_traza.mx('N', 'ln_cod_ramo', ln_cod_ramo);
    --
    WHILE cv_stro%FOUND
    LOOP
      --
      lv_where_stro := 'cod_cia = ' || TO_CHAR(p_cod_cia) ||
                       ' AND num_sini = ' || TO_CHAR(ln_num_sini);
      --
      p_inserta(p_nom_tabla => 'a2000220', p_where => lv_where_stro, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a7990010', p_where => lv_where_stro, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a7000900', p_where => lv_where_stro, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a7000930', p_where => lv_where_stro, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a7000905', p_where => lv_where_stro, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a7000940_csg', p_where => lv_where_stro, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a7000950_csg', p_where => lv_where_stro, p_mca_delete => 'S'); --
      --p_inserta(p_nom_tabla => 'a7000955_csg', p_where => lv_where_stro, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a7000960_csg', p_where => lv_where_stro, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a7000965_csg', p_where => lv_where_stro, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a7000973_csg', p_where => lv_where_stro, p_mca_delete => 'S'); --
      --  Datvar siniestro ARP      
      -- Exped ARP
      p_inserta(p_nom_tabla => 'a7000970_CSG', p_where => lv_where_stro, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a7000971_CSG', p_where => lv_where_stro, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a7001091_csg', p_where => lv_where_stro, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a7001092_csg', p_where => lv_where_stro, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a7001093_csg', p_where => lv_where_stro, p_mca_delete => 'S'); --
      --  delete a7001094_csg where cod_cia = g_cod_cia AND num_sini = g_num_sini;
      --  delete a7007098_csg where cod_cia = g_cod_cia AND num_sini = g_num_sini;
      --
      --  Datvar siniestro si24
      p_inserta(p_nom_tabla => 'a7000970', p_where => lv_where_stro, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a7000971', p_where => lv_where_stro, p_mca_delete => 'S'); --
      --
      -- datos expediente y reserva
      p_inserta(p_nom_tabla => 'a7001000', p_where => lv_where_stro, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a7001010', p_where => lv_where_stro, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a7001020', p_where => lv_where_stro, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a7001030', p_where => lv_where_stro, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'h7001200', p_where => lv_where_stro, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'h7001200_CSG', p_where => lv_where_stro, p_mca_delete => 'S'); --
      --
      -- plan de renta
      p_inserta(p_nom_tabla => 'a3000500', p_where => lv_where_stro, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a3000510', p_where => lv_where_stro, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a3000520', p_where => lv_where_stro, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a3000530', p_where => lv_where_stro, p_mca_delete => 'S'); --
      --
      -- inventario
      p_inserta(p_nom_tabla => 'b7007000', p_where => lv_where_stro, p_mca_delete => 'S'); --
      --
      -- subasta
      lv_sentence := 'DELETE FROM a7007030@' || gv_sid_destino ||
                     ' WHERE cod_cia  =   ' || TO_CHAR(p_cod_cia) ||
                     '   AND cod_subasta IN (SELECT cod_inventario ' ||
                     '                         FROM a7007000@' ||
                     gv_sid_origen ||
                     '                        WHERE cod_inventario IN (SELECT cod_inventario ' ||
                     '                         FROM a7007000@' ||
                     gv_sid_origen ||
                     '                        WHERE cod_cia  = ' ||
                     TO_CHAR(p_cod_cia) ||
                     '                          AND num_sini = ' ||
                     TO_CHAR(ln_num_sini) || '))';
      --
      --@ev_k_traza.mx('N', 'lv_sentence', SUBSTR(lv_sentence, 1, 500));
      --
      p_ejecuta_dml(p_sentence => lv_sentence);
      --
      lv_sentence := 'DELETE FROM a7007010@' || gv_sid_destino ||
                     ' WHERE cod_cia = ' || TO_CHAR(p_cod_cia) ||
                     '   AND cod_inventario IN (SELECT cod_inventario ' ||
                     '                            FROM a7007000@' ||
                     gv_sid_origen ||
                     '                           WHERE cod_cia  = ' ||
                     TO_CHAR(p_cod_cia) ||
                     '                             AND num_sini = ' ||
                     TO_CHAR(ln_num_sini) || ')';
      --
      p_ejecuta_dml(p_sentence => lv_sentence);
      --
      lv_sentence := 'DELETE FROM a7007020@' || gv_sid_destino ||
                     ' WHERE cod_cia = ' || TO_CHAR(p_cod_cia) ||
                     '   AND cod_inventario IN (SELECT cod_inventario ' ||
                     '                            FROM a7007000@' ||
                     gv_sid_origen ||
                     '                           WHERE cod_cia  = ' ||
                     TO_CHAR(p_cod_cia) ||
                     '                             AND num_sini = ' ||
                     TO_CHAR(ln_num_sini) || ')';
      --
      p_ejecuta_dml(p_sentence => lv_sentence);
      --
      lv_sentence := 'DELETE FROM a7007000@' || gv_sid_destino ||
                     ' WHERE cod_cia = ' || TO_CHAR(p_cod_cia) ||
                     '   AND num_sini = ' || TO_CHAR(ln_num_sini);
      --
      p_ejecuta_dml(p_sentence => lv_sentence);
      --
      -- interface
      lv_sentence := 'DELETE FROM a7009000@' || gv_sid_destino ||
                     ' WHERE cod_cia = ' || TO_CHAR(p_cod_cia) ||
                     '   AND num_sini = ' || TO_CHAR(ln_num_sini);
      --
      p_ejecuta_dml(p_sentence => lv_sentence);
      --
      lv_sentence := 'DELETE FROM a7009001@' || gv_sid_destino ||
                     ' WHERE cod_cia = ' || TO_CHAR(p_cod_cia) ||
                     '   AND num_sini = ' || TO_CHAR(ln_num_sini);
      --
      p_ejecuta_dml(p_sentence => lv_sentence);
      --
      -- liquidacion
      lv_sentence := 'DELETE FROM a5021604@' || gv_sid_destino ||
                     ' WHERE num_ord_pago IN (SELECT num_ord_pago ' ||
                     '                          FROM a3001700@' ||
                     gv_sid_origen ||
                     '                         WHERE cod_cia  = ' ||
                     TO_CHAR(p_cod_cia) ||
                     '                           AND num_sini = ' ||
                     TO_CHAR(ln_num_sini) || ')';
      --
      p_ejecuta_dml(p_sentence => lv_sentence);
      --
      lv_sentence := 'DELETE FROM a5021605@' || gv_sid_destino ||
                     ' WHERE num_ord_pago IN (SELECT num_ord_pago ' ||
                     '                          FROM a3001700@' ||
                     gv_sid_origen ||
                     '                         WHERE cod_cia  = ' ||
                     TO_CHAR(p_cod_cia) ||
                     '                           AND num_sini = ' ||
                     TO_CHAR(ln_num_sini) || ')';
      --
      p_ejecuta_dml(p_sentence => lv_sentence);
      --
      lv_sentence := 'DELETE FROM a5021608@' || gv_sid_destino ||
                     ' WHERE num_ord_pago IN (SELECT num_ord_pago ' ||
                     '                          FROM a3001700@' ||
                     gv_sid_origen ||
                     '                         WHERE cod_cia  = ' ||
                     TO_CHAR(p_cod_cia) ||
                     '                           AND num_sini = ' ||
                     TO_CHAR(ln_num_sini) || ')';
      --
      p_ejecuta_dml(p_sentence => lv_sentence);
      --
      -- liquidacion
      p_inserta(p_nom_tabla => 'a3001700', p_where => lv_where_stro, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a3001800', p_where => lv_where_stro, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a3001701_csg', p_where => lv_where_stro, p_mca_delete => 'S'); --
      -- RB y Pre-liquidacion
      p_inserta(p_nom_tabla => 'a3001702_csg', p_where => lv_where_stro, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'x3001701_csg', p_where => lv_where_stro, p_mca_delete => 'S'); --
      -- impuestos
      p_inserta(p_nom_tabla => 'a3009001', p_where => lv_where_stro, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a1001304_csg', p_where => lv_where_stro, p_mca_delete => 'S'); --
      -- cambio expediente
      p_inserta(p_nom_tabla => 'a7009010', p_where => lv_where_stro, p_mca_delete => 'S'); --
      -- estruc. expedientes
      p_inserta(p_nom_tabla => 'a7001040_csg', p_where => lv_where_stro, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a7001050_csg', p_where => lv_where_stro, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a7001051_csg', p_where => lv_where_stro, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a7001052_csg', p_where => lv_where_stro, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a7001053_csg', p_where => lv_where_stro, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a7001081_csg', p_where => lv_where_stro, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a7001082_csg', p_where => lv_where_stro, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a7001083_csg', p_where => lv_where_stro, p_mca_delete => 'S'); --
      -- Exped Grales
      p_inserta(p_nom_tabla => 'a7001085_csg', p_where => lv_where_stro, p_mca_delete => 'S'); --
      -- Exped Vida
      p_inserta(p_nom_tabla => 'a7001060_csg', p_where => lv_where_stro, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a7001065_csg', p_where => lv_where_stro, p_mca_delete => 'S'); --
      -- Exped Grales y Patrimoniales
      p_inserta(p_nom_tabla => 'a7001070_csg', p_where => lv_where_stro, p_mca_delete => 'S'); --
      -- Exped SECUNDARIOS
      p_inserta(p_nom_tabla => 'a7007090_CSG', p_where => lv_where_stro, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a7007092_csg', p_where => lv_where_stro, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a7007093_csg', p_where => lv_where_stro, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a7007094_csg', p_where => lv_where_stro, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a7007095_csg', p_where => lv_where_stro, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a7007096_csg', p_where => lv_where_stro, p_mca_delete => 'S'); --
      -- plan de tramitacion
      p_inserta(p_nom_tabla => 'a7500000', p_where => lv_where_stro, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a7500010', p_where => lv_where_stro, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a9970002', p_where => lv_where_stro, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a9970003', p_where => lv_where_stro, p_mca_delete => 'S'); --
      -- asistencia
      p_inserta(p_nom_tabla => 'b7009010', p_where => lv_where_stro, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'b7000900', p_where => lv_where_stro, p_mca_delete => 'S'); --
      --
      lv_sentence := 'DELETE FROM b7000910@' || gv_sid_destino ||
                     ' WHERE num_sini_ref IN (SELECT num_sini_ref ' ||
                     '                          FROM b7000900@' ||
                     gv_sid_origen ||
                     '                         WHERE cod_cia  = ' ||
                     TO_CHAR(p_cod_cia) ||
                     '                           AND num_sini = ' ||
                     TO_CHAR(ln_num_sini) || ')';
      --
      p_ejecuta_dml(p_sentence => lv_sentence);
      --
      lv_sentence := 'DELETE FROM b7000950_csg@' || gv_sid_destino ||
                     ' WHERE num_sini_ref IN (SELECT num_sini_ref ' ||
                     '                          FROM b7000900@' ||
                     gv_sid_origen ||
                     '                         WHERE cod_cia  = ' ||
                     TO_CHAR(p_cod_cia) ||
                     '                           AND num_sini = ' ||
                     TO_CHAR(ln_num_sini) || ')';
      --
      p_ejecuta_dml(p_sentence => lv_sentence);
      -- Peritaciones de Siniestros
      p_inserta(p_nom_tabla => 'a7009090', p_where => lv_where_stro, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a7009091', p_where => lv_where_stro, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a7009092', p_where => lv_where_stro, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a7009093', p_where => lv_where_stro, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a7009010', p_where => lv_where_stro, p_mca_delete => 'S'); --
      --interface
      p_inserta(p_nom_tabla => 'a7009000', p_where => lv_where_stro, p_mca_delete => 'S'); --
      --
      lv_sentence := 'UPDATE a7000900@' || gv_sid_destino ||
                     '   SET mca_exclusivo = ' || '''' || 'N' || '''' ||
                     '      ,cod_usr_exclusivo = NULL ' ||
                     ' WHERE cod_cia  = ' || TO_CHAR(p_cod_cia) ||
                     '   AND num_sini = ' || TO_CHAR(ln_num_sini);
      --
      p_ejecuta_dml(p_sentence => lv_sentence);
      --
      lv_sentence := 'UPDATE a7001020@' || gv_sid_destino ||
                     '   SET COD_SUPERVISOR = 1002 ' ||
                     '      ,COD_TRAMITADOR = 2364 ' ||
                     ' WHERE cod_cia  = ' || TO_CHAR(p_cod_cia) ||
                     '   AND num_sini = ' || TO_CHAR(ln_num_sini);
      --
      p_ejecuta_dml(p_sentence => lv_sentence);
      --
      lv_sentence := 'INSERT INTO a5021604@' || gv_sid_destino ||
                     ' select * ' || '   from a5021604@' || gv_sid_origen ||
                     ' WHERE cod_cia  = ' || TO_CHAR(p_cod_cia) ||
                     '   AND num_ord_pago in (select num_ord_pago ' ||
                     '                          from a3001700@' ||
                     gv_sid_destino ||
                     '                         where num_sini = ' ||
                     TO_CHAR(ln_num_sini) || ')';
      --
      p_ejecuta_dml(p_sentence => lv_sentence);
      --
      lv_sentence := 'INSERT INTO a5021605@' || gv_sid_destino ||
                     ' select * ' || '   from a5021605@' || gv_sid_origen ||
                     ' WHERE cod_cia  = ' || TO_CHAR(p_cod_cia) ||
                     '   AND num_ord_pago in (select num_ord_pago ' ||
                     '                          from a3001700@' ||
                     gv_sid_destino ||
                     '                         where num_sini = ' ||
                     TO_CHAR(ln_num_sini) || ')';
      --
      p_ejecuta_dml(p_sentence => lv_sentence);
      --
      lv_sentence := 'INSERT INTO a5021608@' || gv_sid_destino ||
                     ' select * ' || '   from a5021608@' || gv_sid_origen ||
                     ' WHERE cod_cia  = ' || TO_CHAR(p_cod_cia) ||
                     '   AND num_ord_pago in (select num_ord_pago ' ||
                     '                          from a3001700@' ||
                     gv_sid_destino ||
                     '                         where num_sini = ' ||
                     TO_CHAR(ln_num_sini) || ')';
      --
      p_ejecuta_dml(p_sentence => lv_sentence);
      --
      ------------------------------------
      -- RENOMBRA INFORMACION CLASIFICADA
      ------------------------------------
      UPDATE a7000900
         SET nom_contacto        = dc_k_descarga_util_csg.f_ofusca_nombre(nom_contacto),
             ape_contacto        = dc_k_descarga_util_csg.f_ofusca_apellido(ape_contacto),
             tel_pais_contacto   = dc_k_descarga_util_csg.f_ofusca_cadena_num(tel_pais_contacto),
             tel_numero_contacto = dc_k_descarga_util_csg.f_ofusca_cadena_num(tel_numero_contacto),
             email_contacto      = dc_k_descarga_util_csg.f_ofusca_cadena_num(email_contacto)
       WHERE cod_cia = p_cod_cia
         AND num_sini = ln_num_sini;
      --<azacipa-20120918> se aqui hasta el final de este procedimiento se comenta la ofuscacion de codigos de documento
      -- ya que esto causa problemas cuando se estan realizando pruebas debido a que los datos no quedan consistentes.
      --      UPDATE a7000940_csg SET cod_docum_testigo  = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum_testigo)
      UPDATE a7000940_csg
         SET nom_testigo   = dc_k_descarga_util_csg.f_ofusca_nombre(nom_testigo),
             dir_testigo   = dc_k_descarga_util_csg.f_ofusca_cadena_num(dir_testigo),
             tlf_testigo   = dc_k_descarga_util_csg.f_ofusca_cadena_num(tlf_testigo),
             cargo_testigo = dc_k_descarga_util_csg.f_ofusca_cadena_num(cargo_testigo)
       WHERE cod_cia = p_cod_cia
         AND num_sini = ln_num_sini;
      --
      --      UPDATE a7000950_csg SET cod_docum_conduct     = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum_conduct)
      UPDATE a7000950_csg
         SET cel_asegurado = dc_k_descarga_util_csg.f_ofusca_cadena_num(cel_asegurado),
             nom_conductor = dc_k_descarga_util_csg.f_ofusca_nombre(nom_conductor),
             dir_conductor = dc_k_descarga_util_csg.f_ofusca_cadena_num(dir_conductor),
             tlf_conductor = dc_k_descarga_util_csg.f_ofusca_cadena_num(tlf_conductor),
             cel_conductor = dc_k_descarga_util_csg.f_ofusca_cadena_num(cel_conductor)
       WHERE cod_cia = p_cod_cia
         AND num_sini = ln_num_sini;
      --
      --      UPDATE a7000955_csg SET cod_docum_aseg        = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum_aseg)
      UPDATE a7000955_csg
         SET dir_accidente = dc_k_descarga_util_csg.f_ofusca_cadena_num(dir_accidente)
       WHERE cod_cia = p_cod_cia
         AND num_sini = ln_num_sini;
      --
      --      UPDATE a7000960_csg SET cod_docum_aseg        = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum_aseg)
      UPDATE a7000960_csg
         SET dir_accidente = dc_k_descarga_util_csg.f_ofusca_cadena_num(dir_accidente)
             --                            , cod_docum_demandante  = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum_demandante)
            ,
             nom_demandante = dc_k_descarga_util_csg.f_ofusca_nombre(nom_demandante)
       WHERE cod_cia = p_cod_cia
         AND num_sini = ln_num_sini;
      --
      --      UPDATE a7000965_csg SET cod_docum_aseg        = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum_aseg)
      --                            , tip_docum_aseg        = dc_k_descarga_util_csg.f_ofusca_cadena_num(tip_docum_aseg)
      UPDATE a7000965_csg
         SET dir_accidente = dc_k_descarga_util_csg.f_ofusca_cadena_num(dir_accidente)
       WHERE cod_cia = p_cod_cia
         AND num_sini = ln_num_sini;
      --
      --      UPDATE a7000973_csg SET cod_docum_propie      = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum_propie)
      UPDATE a7000973_csg
         SET nom_propietario = dc_k_descarga_util_csg.f_ofusca_nombre(nom_propietario),
             dir_propietario = dc_k_descarga_util_csg.f_ofusca_cadena_num(dir_propietario),
             tel_propietario = dc_k_descarga_util_csg.f_ofusca_cadena_num(tel_propietario),
             cel_propietario = dc_k_descarga_util_csg.f_ofusca_cadena_num(cel_propietario)
       WHERE cod_cia = p_cod_cia
         AND num_sini = ln_num_sini;
      --
      --      UPDATE a5021604     SET cod_docum           = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum)
      UPDATE a5021604
         SET nom_tercero_cheque = dc_k_descarga_util_csg.f_ofusca_nombre(nom_tercero_cheque)
      --                            , num_docto_modifica  = dc_k_descarga_util_csg.f_ofusca_cadena_num(num_docto_modifica)
      --                            , cod_docum_prv       = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum_prv)
       WHERE cod_cia = p_cod_cia
         AND num_ord_pago IN
             (SELECT num_ord_pago
                FROM a3001700
               WHERE cod_cia = p_cod_cia
                 AND num_sini = ln_num_sini);
      --
      --      UPDATE a5021608     SET cod_docum           = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum)
      --         where cod_cia  = p_cod_cia AND  num_ord_pago IN (SELECT num_ord_pago
      --                                                            FROM a3001700
      --                                                           WHERE cod_cia = p_cod_cia AND num_sini = ln_num_sini
      --                                                         );  
      --
      --      UPDATE a1001304_csg SET cod_docum           = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum)
      --       WHERE cod_cia = p_cod_cia AND num_sini = ln_num_sini;
      --
      --      UPDATE a7001040_csg SET cod_docum_danio     = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum_danio)
      --                            , cod_docum_perito    = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum_perito)
      --                            , cod_docum_taller    = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum_taller)
      --       WHERE cod_cia = p_cod_cia AND num_sini = ln_num_sini;
      --
      --      UPDATE a7001050_csg SET cod_docum_lesionado = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum_lesionado)
      UPDATE a7001050_csg
         SET txt_nom_lesionado = dc_k_descarga_util_csg.f_ofusca_nombre(txt_nom_lesionado),
             txt_ape_lesionado = dc_k_descarga_util_csg.f_ofusca_nombre(txt_ape_lesionado),
             dir_domicilio     = dc_k_descarga_util_csg.f_ofusca_cadena_num(dir_domicilio),
             tlf_domicilio     = dc_k_descarga_util_csg.f_ofusca_cadena_num(tlf_domicilio)
             --                            , cod_docum_clinica   = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum_clinica)
             --                            , cod_docum_abogado   = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum_abogado)
            ,
             txt_abogado = dc_k_descarga_util_csg.f_ofusca_nombre(txt_abogado)
       WHERE cod_cia = p_cod_cia
         AND num_sini = ln_num_sini;
      --
      --      UPDATE a7001040_csg SET cod_docum_danio     = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum_danio)
      --                            , cod_docum_perito    = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum_perito)
      --                            , cod_docum_taller    = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum_taller)
      --       WHERE cod_cia = p_cod_cia AND num_sini = ln_num_sini;
      --
      --      UPDATE a7001051_csg SET cod_docum_lesionado  = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum_lesionado)
      UPDATE a7001051_csg
         SET nom_lesionado = dc_k_descarga_util_csg.f_ofusca_nombre(nom_lesionado)
             --                            , cod_docum_reclamante = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum_reclamante)
            ,
             nom_reclamante = dc_k_descarga_util_csg.f_ofusca_nombre(nom_reclamante),
             dir_reclamante = dc_k_descarga_util_csg.f_ofusca_cadena_num(dir_reclamante),
             tlf_reclamante = dc_k_descarga_util_csg.f_ofusca_cadena_num(tlf_reclamante)
      --                            , cod_docum_clinica    = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum_clinica)
       WHERE cod_cia = p_cod_cia
         AND num_sini = ln_num_sini;
      --
      --      UPDATE a7001052_csg SET cod_docum_hijo       = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum_hijo)
      UPDATE a7001052_csg
         SET nom_hijo = dc_k_descarga_util_csg.f_ofusca_nombre(nom_hijo)
             --                            , cod_docum_repr       = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum_repr)
            ,
             nom_repr = dc_k_descarga_util_csg.f_ofusca_nombre(nom_repr)
       WHERE cod_cia = p_cod_cia
         AND num_sini = ln_num_sini;
      --
      --      UPDATE a7001053_csg SET cod_docum_lesionado  = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum_lesionado)
      UPDATE a7001053_csg
         SET nom_lesionado = dc_k_descarga_util_csg.f_ofusca_nombre(nom_lesionado)
      --                            , cod_docum_aseg       = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum_aseg)
      --                            , cod_docum_clinica    = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum_clinica)
       WHERE cod_cia = p_cod_cia
         AND num_sini = ln_num_sini;
      --
      --      UPDATE a7001081_csg SET cod_docum_abogado    = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum_abogado)
      UPDATE a7001081_csg
         SET txt_abogado = dc_k_descarga_util_csg.f_ofusca_nombre(txt_abogado)
             --                            , tip_docum_proveedor  = dc_k_descarga_util_csg.f_ofusca_cadena_num(tip_docum_proveedor)
             --                            , cod_docum_proveedor  = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum_proveedor)
            ,
             txt_proveedor = dc_k_descarga_util_csg.f_ofusca_nombre(txt_proveedor)
      --                            , cod_docum_acreedor   = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum_acreedor)
      --                            , cod_docum_perito     = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum_perito)
      --                            , cod_docum_taller     = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum_taller)
       WHERE cod_cia = p_cod_cia
         AND num_sini = ln_num_sini;
      --
      --      UPDATE a7001082_csg SET cod_docum_proveedor  = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum_proveedor)
      UPDATE a7001082_csg
         SET txt_proveedor = dc_k_descarga_util_csg.f_ofusca_nombre(txt_proveedor)
      --                            , cod_docum_acreedor   = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum_acreedor)
      --                            , cod_docum_perito     = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum_perito)
      --                            , cod_docum_taller     = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum_taller)
       WHERE cod_cia = p_cod_cia
         AND num_sini = ln_num_sini;
      --
      --      UPDATE a7001085_csg SET cod_docum_ajustador   = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum_ajustador)
      UPDATE a7001085_csg
         SET nom_ajustador = dc_k_descarga_util_csg.f_ofusca_nombre(nom_ajustador)
             --                            , cod_docum_conductor   = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum_conductor)
            ,
             nom_conductor = dc_k_descarga_util_csg.f_ofusca_nombre(nom_conductor)
       WHERE cod_cia = p_cod_cia
         AND num_sini = ln_num_sini;
      --
      --      UPDATE a7001060_csg SET cod_docum_sd          = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum_sd)
      --                            , cod_docum_afect       = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum_afect)
      UPDATE a7001060_csg
         SET nom_afectado = dc_k_descarga_util_csg.f_ofusca_nombre(nom_afectado),
             dir_afectado = dc_k_descarga_util_csg.f_ofusca_cadena_num(dir_afectado),
             tel_afectado = dc_k_descarga_util_csg.f_ofusca_cadena_num(tel_afectado)
             --                            , cod_docum_funeraria   = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum_funeraria)
            ,
             nom_funeraria = dc_k_descarga_util_csg.f_ofusca_nombre(nom_funeraria)
       WHERE cod_cia = p_cod_cia
         AND num_sini = ln_num_sini;
      --
      --      UPDATE a7001065_csg SET cod_docum_hijo        = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum_hijo)
      UPDATE a7001065_csg
         SET nom_hijo = dc_k_descarga_util_csg.f_ofusca_nombre(nom_hijo)
             --                            , cod_docum_repr        = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum_repr)
            ,
             nom_repr = dc_k_descarga_util_csg.f_ofusca_nombre(nom_repr)
       WHERE cod_cia = p_cod_cia
         AND num_sini = ln_num_sini;
      --
      UPDATE a7007090_CSG
         SET bodega_taller = dc_k_descarga_util_csg.f_ofusca_nombre(bodega_taller)
       WHERE cod_cia = p_cod_cia
         AND num_sini = ln_num_sini;
      --
      --      UPDATE a7007092_csg SET cod_docum_perito      = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum_perito)
      UPDATE a7007092_csg
         SET nom_contacto  = dc_k_descarga_util_csg.f_ofusca_nombre(nom_contacto),
             bodega_taller = dc_k_descarga_util_csg.f_ofusca_nombre(bodega_taller)
       WHERE cod_cia = p_cod_cia
         AND num_sini = ln_num_sini;
      --
      UPDATE a7007093_csg
         SET dir_ubicac = dc_k_descarga_util_csg.f_ofusca_cadena_num(dir_ubicac),
             tel_ubicac = dc_k_descarga_util_csg.f_ofusca_cadena_num(tel_ubicac)
             --                            , cod_docum_oferente    = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum_oferente)
            ,
             nom_oferente = dc_k_descarga_util_csg.f_ofusca_nombre(nom_oferente),
             dir_oferente = dc_k_descarga_util_csg.f_ofusca_cadena_num(dir_oferente),
             tel_oferente = dc_k_descarga_util_csg.f_ofusca_cadena_num(tel_oferente)
       WHERE cod_cia = p_cod_cia
         AND num_sini = ln_num_sini;
      --
      --      UPDATE a7007094_csg SET cod_docum_respon      = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum_respon)
      UPDATE a7007094_csg
         SET nom_responsable   = dc_k_descarga_util_csg.f_ofusca_nombre(nom_responsable),
             tel_responsable   = dc_k_descarga_util_csg.f_ofusca_cadena_num(tel_responsable),
             dir_responsable   = dc_k_descarga_util_csg.f_ofusca_cadena_num(dir_responsable),
             email_responsable = dc_k_descarga_util_csg.f_ofusca_cadena_num(email_responsable),
             num_cuenta_banc   = dc_k_descarga_util_csg.f_ofusca_cadena_num(num_cuenta_banc)
       WHERE cod_cia = p_cod_cia
         AND num_sini = ln_num_sini;
      --
      --      UPDATE a7007095_csg SET cod_docum_emp         = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum_emp)
      UPDATE a7007095_csg
         SET nom_emp = dc_k_descarga_util_csg.f_ofusca_nombre(nom_emp)
             --                            , cod_docum_abogado     = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum_abogado)
            ,
             nom_abogado = dc_k_descarga_util_csg.f_ofusca_nombre(nom_abogado)
             --                            , cod_docum_persrecob   = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum_persrecob)
            ,
             nom_persrecob   = dc_k_descarga_util_csg.f_ofusca_nombre(nom_persrecob),
             dir_persrecob   = dc_k_descarga_util_csg.f_ofusca_cadena_num(dir_persrecob),
             tel_persrecob   = dc_k_descarga_util_csg.f_ofusca_cadena_num(tel_persrecob),
             email_persrecob = dc_k_descarga_util_csg.f_ofusca_cadena_num(email_persrecob)
       WHERE cod_cia = p_cod_cia
         AND num_sini = ln_num_sini;
      --
      -------------
      -- Peritaciones de Siniestros
      --      UPDATE a7009090     SET cod_docum_ter_asign   = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum_ter_asign)
      --       WHERE cod_cia = p_cod_cia AND num_sini = ln_num_sini;
      --
      UPDATE a7009091
         SET dir_ubica_vehi = dc_k_descarga_util_csg.f_ofusca_cadena_num(dir_ubica_vehi),
             tel_ubica_vehi = dc_k_descarga_util_csg.f_ofusca_cadena_num(tel_ubica_vehi),
             nom_contacto   = dc_k_descarga_util_csg.f_ofusca_nombre(nom_contacto)
       WHERE cod_cia = p_cod_cia
         AND num_sini = ln_num_sini;
      ------------
      -- Plan de Renta
      --      UPDATE a3000510     SET cod_docum_benef       = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum_benef)
      --       WHERE cod_cia = p_cod_cia AND num_sini = ln_num_sini;
      ------------
      -- Inventario
      /*
      UPDATE a7007030     SET cod_docum             = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum)
         where cod_cia  = p_cod_cia AND cod_subasta IN  (SELECT cod_inventario
                                           FROM a7007000
                                          where cod_inventario IN (
                                                 SELECT cod_inventario
                                                   FROM a7007000
                                                  WHERE cod_cia = p_cod_cia AND num_sini = ln_num_sini
                                               )
                                        );
                                        */
      --
      /*
      UPDATE a7007010     SET cod_docum             = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum)
         where cod_cia  = p_cod_cia AND cod_inventario IN (SELECT cod_inventario
                                                             FROM a7007000
                                                            WHERE cod_cia = p_cod_cia AND num_sini = ln_num_sini
                                                           );
                                                           */
      --
      /*
      UPDATE a7007000     SET cod_docum             = dc_k_descarga_util_csg.f_ofusca_cadena_num(cod_docum)
         where cod_cia  = p_cod_cia AND cod_inventario IN (SELECT cod_inventario
                                                             FROM a7007000
                                                            WHERE cod_cia = p_cod_cia AND num_sini = ln_num_sini
                                                           );
                                                           */
      --
      FETCH cv_stro
        INTO ln_num_sini,
             ln_cod_ramo,
             ld_fec_sini,
             ld_fec_actu,
             lv_cod_usr,
             ln_tip_coaseguro,
             lv_tip_est_sini;
      --
    END LOOP;
    --
    CLOSE cv_stro;
    --
    p_ini_traza('F', 'p_imp_stros');
    --
  END p_imp_stros;

  --
  PROCEDURE p_imp_creditos(p_cod_cia    IN a2000030.cod_cia %TYPE,
                           p_num_poliza IN a2000030.num_poliza%TYPE) IS
    --
    TYPE c_financiera IS REF CURSOR; -- define weak REF CURSOR type
    cv_financiera c_financiera; -- declare cursor variable    
    --
    lv_num_fncmto a8001010_sls.num_fncmto%TYPE;
    --
  BEGIN
    --
    p_ini_traza('I', 'p_imp_creditos');
    --
    OPEN cv_financiera FOR ' SELECT DISTINCT num_fncmto' || ' FROM a8001010_sls@' || gv_sid_origen || '  WHERE num_poliza = :npoliza'
      USING p_num_poliza;
    --
    FETCH cv_financiera
      INTO lv_num_fncmto;
    --
    WHILE cv_financiera%FOUND
    LOOP
      --
      lv_where1 := 'num_fncmto = ''' || lv_num_fncmto || ''''; --
      --
      p_inserta(p_nom_tabla => 'a8001000_sls', p_where => lv_where1, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a8001030_sls', p_where => lv_where1, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a8001031_csg', p_where => lv_where1, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a8001041_csg', p_where => lv_where1, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a8001042_csg', p_where => lv_where1, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a8001010_sls', p_where => lv_where1, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a8001050_sls', p_where => lv_where1, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a8001060_sls', p_where => lv_where1, p_mca_delete => 'S'); --
      --
      FETCH cv_financiera
        INTO lv_num_fncmto;
      --
    END LOOP;
    --
    CLOSE cv_financiera;
    --
    p_ini_traza('F', 'p_imp_creditos');
    --
  END p_imp_creditos;

  --
  --
  PROCEDURE p_imp_cobranza(p_cod_cia    IN a2000030.cod_cia %TYPE,
                           p_num_poliza IN a2000030.num_poliza%TYPE) IS
    --
    TYPE c_recaudos IS REF CURSOR; -- define weak REF CURSOR type
    cv_recaudos c_recaudos; -- declare cursor variable    
    --
    ln_num_recibo a2990700.num_recibo %TYPE;
    --
  BEGIN
    --
    p_ini_traza('I', 'p_imp_cobranza');
    --
    OPEN cv_recaudos FOR ' SELECT DISTINCT num_recibo' || '   FROM a2990700@' || gv_sid_origen || '  WHERE cod_cia = :codcia and num_poliza = :npoliza'
      USING p_cod_cia, p_num_poliza;
    --
    FETCH cv_recaudos
      INTO ln_num_recibo;
    --
    WHILE cv_recaudos%FOUND
    LOOP
      --
      lv_where1       := 'num_recibo = ' || TO_CHAR(ln_num_recibo) ||
                         ' and cod_cia = ' || TO_CHAR(p_cod_cia); --
      lv_where_poliza := 'cod_cia = ' || TO_CHAR(p_cod_cia) ||
                         ' AND num_poliza = ''' || p_num_poliza || '''';
      --
      p_inserta(p_nom_tabla => 'a5020301', p_where => lv_where_poliza, p_mca_delete => 'S'); --      
      p_inserta(p_nom_tabla => 'a5021600', p_where => lv_where1, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a5021800', p_where => lv_where1, p_mca_delete => 'S'); --
      --
      --@ev_k_traza.mx('N', 'ln_num_recibo', ln_num_recibo);
      --@ev_k_traza.mx('before delete a5021801');
      --
      EXECUTE IMMEDIATE 'DELETE FROM a5021801@' || gv_sid_destino ||
                        ' WHERE (cod_cia, num_cruce, tip_anticipo, num_secu) IN (' ||
                        ' SELECT cod_cia, num_cruce, tip_anticipo, num_secu ' ||
                        ' FROM a5021800@' || gv_sid_destino ||
                        ' WHERE num_recibo = :nrecibo and cod_cia = :codcia)'
        USING ln_num_recibo, p_cod_cia;
      --
      --@ev_k_traza.mx('before insert a5021801');
      --
      EXECUTE IMMEDIATE 'insert into a5021801@' || gv_sid_destino ||
                        ' select * from a5021801@' || gv_sid_origen ||
                        ' WHERE (cod_cia, num_cruce, tip_anticipo, num_secu) IN (' ||
                        ' SELECT cod_cia, num_cruce, tip_anticipo, num_secu ' ||
                        ' FROM a5021800@' || gv_sid_destino ||
                        ' WHERE num_recibo = :nrecibo and cod_cia = :codcia)'
        USING ln_num_recibo, p_cod_cia;
      --
      --[azacipa-20070320> se comenta por lentitud. esto mientras se revisa con atencion
      /*
      EXECUTE IMMEDIATE 'DELETE FROM a5029003@'||p_sid_destino
                      ||' where cod_cia = :codcia and num_poliza = :npoliza and num_recibo = :nrecibo'
        USING p_cod_cia, p_num_poliza, lv_num_recibo;
      */
      --
      /*
      EXECUTE IMMEDIATE 'insert into a5029003@'||p_sid_destino
                      ||' select * from a5029003@'||p_sid_origen
                      ||' where cod_cia = :codcia and num_poliza = :npoliza and num_recibo = :nrecibo'
        USING p_cod_cia, p_num_poliza, lv_num_recibo;
      */
      --
      /*
      EXECUTE IMMEDIATE 'DELETE FROM a5029004@'||p_sid_destino
                      ||' where (num_bloque_tes, consec_cheque) IN ('
                      ||' SELECT num_bloque_tes, consec_cheque '
                      ||' FROM a5029003@'||p_sid_destino
                      ||' where cod_cia = :codcia and num_poliza = :npoliza and num_recibo = :nrecibo)'
        USING p_cod_cia, p_num_poliza, lv_num_recibo;
      */
      --
      /*
      EXECUTE IMMEDIATE 'insert into a5029004@'||p_sid_destino
                      ||' select * from a5029004@'||p_sid_origen
                      ||' where (num_bloque_tes, consec_cheque) IN ('
                      ||' SELECT num_bloque_tes, consec_cheque '
                      ||' FROM a5029003@'||p_sid_destino
                      ||' where cod_cia = :codcia and num_poliza = :npoliza and num_recibo = :nrecibo)'
        USING p_cod_cia, p_num_poliza, lv_num_recibo;
      */
      --<azacipa-20070320]
      --
      FETCH cv_recaudos
        INTO ln_num_recibo;
      --
    END LOOP;
    --
    CLOSE cv_recaudos;
    --
    --@ev_k_traza.mx('sale de p_imp_cobranza');
    --
    p_ini_traza('F', 'p_imp_cobranza');
    --
  END p_imp_cobranza;

  --
  PROCEDURE p_imp_reaseguro(p_cod_cia    IN a2000030.cod_cia %TYPE,
                            p_cod_ramo   IN a2000030.cod_ramo %TYPE,
                            p_num_poliza IN a2000030.num_poliza%TYPE) IS
  BEGIN
    --
    p_ini_traza('I', 'p_imp_reaseguro');
    --
    lv_where1 := 'num_poliza = ''' || p_num_poliza || ''' and cod_cia = ' ||
                 TO_CHAR(p_cod_cia); --
    --
    --@ev_k_traza.mx('N', 'lv_where1', lv_where1);
    --
    p_inserta(p_nom_tabla => 'a2501600', p_where => lv_where1, p_mca_delete => 'S'); --
    p_inserta(p_nom_tabla => 'a2990131', p_where => lv_where1, p_mca_delete => 'S'); --
    p_inserta(p_nom_tabla => 'a2990131', p_where => lv_where1, p_mca_delete => 'S'); --
    p_inserta(p_nom_tabla => 'a2501500', p_where => lv_where1, p_mca_delete => 'S'); --
    --p_inserta( p_nom_tabla => 'a2501000_'||TO_CHAR(p_cod_ramo), p_where => lv_where1 , p_mca_delete => 'S' );--
    --
    p_ini_traza('F', 'p_imp_reaseguro');
    --
  END p_imp_reaseguro;

  --
  PROCEDURE p_imp_inspecciones(p_cod_cia    IN a2000030.cod_cia %TYPE,
                               p_num_poliza IN a2000030.num_poliza%TYPE) IS
  BEGIN
    --
    NULL;
    --
  END p_imp_inspecciones;

  --
  --
  PROCEDURE p_imp_tablas_vidaind(p_cod_cia    IN a2000030.cod_cia    %TYPE
                                ,p_cod_ramo   IN a2000030.cod_ramo   %TYPE
                                ,p_num_poliza IN a2000030.num_poliza %TYPE) IS
    --
    lc_unit_linked CONSTANT a2000030.cod_ramo%TYPE := 805;
    lv_where_ulk            VARCHAR2(1000);
    --
  BEGIN
    --
    p_ini_traza('I', 'p_imp_tablas_vidaind');
    --
    --@ev_k_traza.mx('N', 'p_cod_cia           ', p_cod_cia);
    --@ev_k_traza.mx('N', 'p_cod_ramo          ', p_cod_ramo);
    --@ev_k_traza.mx('N', 'p_num_poliza        ', p_num_poliza);
    --
    lv_where_poliza   := 'cod_cia = ' || TO_CHAR(p_cod_cia) ||
                         ' AND num_poliza = ''' || p_num_poliza || '''';
    lv_where_op       := 'cod_cia = ' || TO_CHAR(p_cod_cia) ||
                         ' AND num_ord_pago in (select x.num_ord_pago from a2300333@'||gv_sid_origen||' x where x.cod_cia = ' ||
                         TO_CHAR(p_cod_cia) || ' AND num_poliza = ''' ||
                         p_num_poliza || '''' || ')';
    lv_where_anticipo := 'cod_cia = ' || TO_CHAR(p_cod_cia) ||
                         ' AND num_anticipo in (select x.num_anticipo from a5029070@'||gv_sid_origen||' x where x.cod_cia = ' ||
                         TO_CHAR(p_cod_cia) || ' AND num_poliza = ''' ||
                         p_num_poliza || '''' || ')';
    --
    --@ev_k_traza.mx('N', 'lv_where_poliza        ', lv_where_poliza);
    --
    p_inserta(p_nom_tabla => 'a5029070', p_where => lv_where_poliza, p_mca_delete => 'S'); --
    p_inserta(p_nom_tabla => 'a5029071', p_where => lv_where_anticipo, p_mca_delete => 'S'); --
    p_inserta(p_nom_tabla => 'a5021604', p_where => lv_where_op, p_mca_delete => 'S'); --
    p_inserta(p_nom_tabla => 'a5021608', p_where => lv_where_op, p_mca_delete => 'S'); --    
    p_inserta(p_nom_tabla => 'a5020120_csg', p_where => lv_where_poliza, p_mca_delete => 'S'); --
    p_inserta(p_nom_tabla => 'a2300337', p_where => lv_where_poliza, p_mca_delete => 'S'); --
    p_inserta(p_nom_tabla => 'a2309337', p_where => lv_where_poliza, p_mca_delete => 'S'); --
    p_inserta(p_nom_tabla => 'a2309338', p_where => lv_where_poliza, p_mca_delete => 'S'); --
    p_inserta(p_nom_tabla => 'a2300401', p_where => lv_where_poliza, p_mca_delete => 'S'); --
    p_inserta(p_nom_tabla => 'a2300402', p_where => lv_where_poliza, p_mca_delete => 'S'); --
    p_inserta(p_nom_tabla => 'a2300402_csg', p_where => lv_where_poliza, p_mca_delete => 'S'); --
    p_inserta(p_nom_tabla => 'a2309402', p_where => lv_where_poliza, p_mca_delete => 'S'); --
    p_inserta(p_nom_tabla => 'a2309121', p_where => lv_where_poliza, p_mca_delete => 'S'); --
    p_inserta(p_nom_tabla => 'a2309334_csg', p_where => lv_where_poliza, p_mca_delete => 'S'); --
    --
    -- pasar tablas de planillas para BT
    lv_where_poliza := 'cod_cia = ' || TO_CHAR(p_cod_cia) ||
                       ' AND num_planilla in (select num_planilla from a2309106 where cod_cia = ' ||
                       TO_CHAR(p_cod_cia) || ' AND num_poliza = ''' ||
                       p_num_poliza || '''' || ')';
    p_inserta(p_nom_tabla => 'a2309106', p_where => lv_where_poliza, p_mca_delete => 'S');
    p_inserta(p_nom_tabla => 'a2309105', p_where => lv_where_poliza, p_mca_delete => 'S');
    --
    IF p_cod_ramo = lc_unit_linked THEN
      --
      lv_where_poliza   := 'cod_cia = ' || TO_CHAR(p_cod_cia) ||
                           ' AND num_poliza = ''' || p_num_poliza || '''';
      -- tablas unit linked
      p_inserta(p_nom_tabla => 'a2309340', p_where => lv_where_poliza, p_mca_delete => 'S'); --
      p_inserta(p_nom_tabla => 'a2309341', p_where => lv_where_poliza, p_mca_delete => 'S'); --
      --
      -- monedas unit linked
      lv_where_ulk := 'cod_cia = ' || TO_CHAR(p_cod_cia);
      p_inserta(p_nom_tabla => 'a2309345', p_where => lv_where_ulk, p_mca_delete => 'S'); --
      --
--      lv_where_ulk   := 'cod_mon in (40, 41, 42) and cod_cia=5';
--      p_inserta(p_nom_tabla => 'a1000500', p_where => lv_where_ulk, p_mca_delete => 'S'); --
      --
    END IF;
    --
    p_ini_traza('F', 'p_imp_tablas_vidaind');
    --
  END p_imp_tablas_vidaind;
  --
  --
  /*-------------------- DESCRIPCION ----------------------------------
  || Procedimiento de generacion tabla importacion datos de poliza
  */ -------------------------------------------------------------------
  PROCEDURE p_imp_poliza(p_cod_cia              IN a2000030.cod_cia %TYPE,
                         p_cod_ramo             IN a2000030.cod_ramo %TYPE,
                         p_num_poliza_desde     IN a2000030.num_poliza%TYPE,
                         p_num_poliza_hasta     IN a2000030.num_poliza%TYPE,
                         p_sid_origen           IN VARCHAR2 DEFAULT 'CSG',
                         p_sid_destino          IN VARCHAR2 DEFAULT 'DEV',
                         p_mca_imp_stros        IN VARCHAR2 DEFAULT 'N',
                         p_mca_imp_creditos     IN VARCHAR2 DEFAULT 'N',
                         p_mca_imp_cobranza     IN VARCHAR2 DEFAULT 'N',
                         p_mca_imp_reaseguro    IN VARCHAR2 DEFAULT 'N',
                         p_mca_imp_inspecciones IN VARCHAR2 DEFAULT 'N',
                         p_num_riesgo           IN a2000031.num_riesgo%TYPE DEFAULT NULL,
                         p_txt_observacion      OUT VARCHAR2) IS
    --
    CURSOR c_a2000030_relac(p_cod_cia            IN a2000030.cod_cia %TYPE,
                            p_num_poliza         IN a2000030.num_poliza %TYPE,
                            p_num_poliza_cliente IN a2000030.num_poliza_cliente%TYPE) IS
      SELECT num_poliza
        FROM a2000030
       WHERE cod_cia = p_cod_cia
         AND num_poliza_cliente = p_num_poliza_cliente
         AND num_poliza != p_num_poliza
         AND num_spto = 0
         AND num_apli = 0
         AND num_spto_apli = 0;
    --
    TYPE c_cursor IS REF CURSOR; -- define weak REF CURSOR type
    cv_cursor           c_cursor;
    cv_poliza           c_poliza; -- declare cursor variable
    lv_num_poliza_hasta a2000030.num_poliza  %TYPE;
    ln_num_riesgos      a2000030.num_riesgos %TYPE;
    lc_num_polizas      CONSTANT NUMBER := 10;
    ln_cont             PLS_INTEGER := 0;
    lv_num_poliza_relac a2000030.num_poliza%TYPE;
    ln_limite_riesgos   CONSTANT a2000030.num_riesgos %TYPE := 40;
    lv_error            VARCHAR2(1000);
    --
  BEGIN
    --
    lv_num_poliza := p_num_poliza_desde;
    --
    p_ini_traza('I', 'p_imp_poliza');
    --
    gv_sid_origen  := p_sid_origen;
    gv_sid_destino := p_sid_destino;
    --
    -- cargo global que permite que triggers sobre tablas no hagan acciones cuando se ejecutan desde el sacapol
    p_asigna_global('gbl_saca_pol', 'S');
    p_asigna_global('mca_act_fec_ctable_csg', 'N');
    --
    gtb_columnas_bd.delete;
    --
    BEGIN
      --
      IF UPPER(p_sid_destino) = gc_sid_produccion
      THEN
        --
        p_txt_observacion := 'Pilas, no puede escoger como destino a csg';
        --
      ELSE
        --
        --@ev_k_traza.mx('N', 'gv_sid_origen', gv_sid_origen);
        --@ev_k_traza.mx('N', 'gv_sid_destino', gv_sid_destino);
        --@ev_k_traza.mx('N', 'p_num_poliza_desde', p_num_poliza_desde);
        --@ev_k_traza.mx('N', 'p_num_poliza_hasta', p_num_poliza_hasta);
        --@ev_k_traza.mx('N', 'p_cod_ramo        ', p_cod_ramo);
        --
        IF p_cod_ramo IS NULL
        THEN
          --
          OPEN cv_poliza FOR 'SELECT cod_sector, cod_ramo, tip_gestor, cod_agt, cod_asesor, cod_agt2, cod_agt3, cod_agt4, cod_org, num_poliza_cliente, num_poliza_grupo, num_contrato, num_poliza FROM a2000030@' || gv_sid_origen || ' WHERE cod_cia = :codcia AND num_poliza = :numpoliza' || '   AND num_spto = 0 AND num_apli = 0 AND num_spto_apli = 0'
            USING p_cod_cia, p_num_poliza_desde;
          --
        ELSIF p_num_poliza_desde =
              NVL(p_num_poliza_hasta, p_num_poliza_desde)
        THEN
          --
          OPEN cv_poliza FOR 'SELECT cod_sector, cod_ramo, tip_gestor, cod_agt, cod_asesor, cod_agt2, cod_agt3, cod_agt4, cod_org, num_poliza_cliente, num_poliza_grupo, num_contrato, num_poliza FROM a2000030@' || gv_sid_origen || ' WHERE cod_cia = :codcia AND num_poliza = :numpoliza and cod_ramo = :codramo' || '   AND num_spto = 0 AND num_apli = 0 AND num_spto_apli = 0'
            USING p_cod_cia, p_num_poliza_desde, p_cod_ramo;
          --
        ELSIF p_cod_ramo = 999
              AND p_num_poliza_desde IS NULL
              AND p_num_poliza_hasta IS NULL
        THEN
          --
          OPEN cv_poliza FOR 'WITH polizas AS ( SELECT m.cod_cia, m.cod_ramo, m.num_poliza FROM a2999999@dev m WHERE m.cod_cia = :cod_cia AND m.mca_proceso = ' || '''' || 'N' || '''' || ')' || ' SELECT /*+DRIVING_SITE(a)*/ a.cod_sector, a.cod_ramo, a.tip_gestor, a.cod_agt, a.cod_asesor, a.cod_agt2, a.cod_agt3, a.cod_agt4, a.cod_org, a.num_poliza_cliente, a.num_poliza_grupo, a.num_contrato, a.num_poliza' || '   FROM a2000030@' || gv_sid_origen || ' a JOIN polizas b ON (a.cod_cia = b.cod_cia' || ' AND a.num_poliza = b.num_poliza AND a.cod_ramo = b.cod_ramo AND a.num_spto = 0 AND a.num_apli = 0 AND a.num_spto_apli = 0)'
            USING p_cod_cia;
          --
        ELSIF p_cod_ramo IS NOT NULL
              AND p_num_poliza_desde = '0'
              AND p_num_poliza_hasta = '0'
        THEN
          --
          OPEN cv_poliza FOR 'WITH polizas AS ( SELECT m.cod_cia, m.cod_ramo, m.num_poliza FROM a2999999@dev m WHERE m.cod_cia = :cod_cia AND m.cod_ramo = :cod_ramo AND m.mca_proceso = ' || '''' || 'N' || '''' || ')' || ' SELECT /*+DRIVING_SITE(a)*/ a.cod_sector, a.cod_ramo, a.tip_gestor, a.cod_agt, a.cod_asesor, a.cod_agt2, a.cod_agt3, a.cod_agt4, a.cod_org, a.num_poliza_cliente, a.num_poliza_grupo, a.num_contrato, a.num_poliza' || '   FROM a2000030@' || gv_sid_origen || ' a JOIN polizas b ON (a.cod_cia = b.cod_cia' || ' AND a.num_poliza = b.num_poliza AND a.cod_ramo = b.cod_ramo AND a.num_spto = 0 AND a.num_apli = 0 AND a.num_spto_apli = 0)'
            USING p_cod_cia, p_cod_ramo;
          --
        ELSE
          --
          lv_num_poliza_hasta := TO_CHAR(TO_NUMBER(p_num_poliza_desde) +
                                         lc_num_polizas);
          --
          IF TO_NUMBER(lv_num_poliza_hasta) > TO_NUMBER(p_num_poliza_hasta)
          THEN
            --
            lv_num_poliza_hasta := p_num_poliza_hasta;
            --
          END IF;
          --
          --@ev_k_traza.mx('N', 'lv_num_poliza_hasta', lv_num_poliza_hasta);
          --
          OPEN cv_poliza FOR 'SELECT cod_sector, cod_ramo, tip_gestor, cod_agt, cod_asesor, cod_agt2, cod_agt3, cod_agt4, cod_org, num_poliza_cliente, num_poliza_grupo, num_contrato, num_poliza FROM a2000030@' || gv_sid_origen || ' WHERE cod_cia = :codcia AND num_poliza between :numpoliza1 and :numpoliza2 and cod_ramo = :codramo' || '   AND num_spto = 0 AND num_apli = 0 AND num_spto_apli = 0'
            USING p_cod_cia, p_num_poliza_desde, lv_num_poliza_hasta, p_cod_ramo;
          --
        END IF;
        --
        FETCH cv_poliza
          INTO ln_cod_sector,
               ln_cod_ramo,
               ln_tip_gestor,
               ln_cod_agt,
               ln_cod_asesor,
               ln_cod_agt2,
               ln_cod_agt3,
               ln_cod_agt4,
               ln_cod_org,
               lv_num_poliza_cliente,
               lv_num_poliza_grupo,
               ln_num_contrato,
               lv_num_poliza;
        --
        WHILE cv_poliza%FOUND
        LOOP
          --
          BEGIN
            --
            ln_cont := 0;
            --
            --@ev_k_traza.mx('N', 'ln_cont(1)', ln_cont);
            --@ev_k_traza.mx('N', 'lv_num_poliza', lv_num_poliza);
            --@ev_k_traza.mx('N', 'ln_cod_ramo', ln_cod_ramo);
            --
             OPEN gc_tratamiento(p_cod_cia,ln_cod_ramo);
            FETCH gc_tratamiento
             INTO lv_cod_tratamiento, lv_mca_tratamiento_arp;
            CLOSE gc_tratamiento;
            --
            /*IF lv_mca_tratamiento_arp = 'S' AND p_num_riesgo IS NULL THEN
              --
              OPEN  cv_cursor FOR  'SELECT MAX(num_riesgos) '
                                 ||'  FROM a2000030@' || gv_sid_origen
                                 ||' WHERE cod_cia     = :codcia'
                                 ||'   AND num_poliza  = :numpoliza'
                                 ||'   AND cod_ramo    = :codramo'
              USING p_cod_cia, lv_num_poliza,ln_cod_ramo;
              --
              FETCH cv_cursor INTO ln_num_riesgos;
              CLOSE cv_cursor;
              --
              IF ln_num_riesgos >= ln_limite_riesgos THEN
                --
                RAISE_APPLICATION_ERROR(-20000,'NO PERMITIDO TRASLADO DE POLIZAS CON MAS DE '||ln_limite_riesgos||'RIESGOS'); 
                --
              END IF;
              --
            END IF;*/
            --
            p_imp_tablas_poliza(p_cod_cia => p_cod_cia, p_cod_sector => ln_cod_sector, p_cod_ramo => ln_cod_ramo, p_num_poliza => lv_num_poliza, p_num_contrato => ln_num_contrato, p_num_poliza_grupo => lv_num_poliza_grupo, p_num_riesgo => p_num_riesgo);
            --
            --@ev_k_traza.mx('sale de p_imp_tablas_poliza');
            --
            IF lv_num_poliza != NVL(lv_num_poliza_cliente, lv_num_poliza)
            THEN
              --
              OPEN c_a2000030_relac(p_cod_cia => p_cod_cia, p_num_poliza => lv_num_poliza, p_num_poliza_cliente => lv_num_poliza_cliente);
              --
              FETCH c_a2000030_relac
                INTO lv_num_poliza_relac;
              --
              --@ev_k_traza_csg.mx('N', 'lv_num_poliza_relac', lv_num_poliza_relac);
              --
              IF c_a2000030_relac%FOUND
              THEN
                --
                p_imp_tablas_poliza(p_cod_cia => p_cod_cia, p_cod_sector => ln_cod_sector, p_cod_ramo => ln_cod_ramo, p_num_poliza => lv_num_poliza_cliente, p_num_contrato => NULL, p_num_poliza_grupo => NULL, p_num_riesgo => p_num_riesgo);
                --
                --@ev_k_traza.mx('sale de p_imp_tablas_poliza relac');
                --
              END IF;
              --
              CLOSE c_a2000030_relac;
              --
            END IF;
            --
            p_imp_terceros(p_cod_cia => p_cod_cia, p_cod_agt => ln_cod_agt, p_cod_asesor => ln_cod_asesor, p_cod_agt2 => ln_cod_agt2, p_cod_agt3 => ln_cod_agt3, p_cod_agt4 => ln_cod_agt4, p_cod_org => ln_cod_org, p_num_poliza => lv_num_poliza, p_num_riesgo => p_num_riesgo);
            --
            --@ev_k_traza.mx('sale de p_imp_terceros');
            --
            -- pasar tablas de siniestros
            IF p_mca_imp_stros = 'S'
            THEN
              --
              p_imp_stros(p_cod_cia => p_cod_cia, p_num_poliza => lv_num_poliza, p_num_riesgo => p_num_riesgo);
              --
              --@ev_k_traza.mx('sale de p_imp_stros');
              --
            END IF;
            --
            -- pasar las tablas de la financiera cuando el gestor es credimapfre
            IF p_mca_imp_creditos = 'S'
            THEN
              --
              p_imp_creditos(p_cod_cia    => p_cod_cia
                            ,p_num_poliza => lv_num_poliza);
              
              --gc_k_descarga_credito_csg.p_pasa_fncmto_pol(p_cod_cia => p_cod_cia, p_num_poliza => lv_num_poliza, p_base_orig => gv_sid_origen, p_base_des => gv_sid_destino);
              --
              --@ev_k_traza.mx('sale de p_pasa_fncmto_pol');
              --
            END IF;
            --
            -- pasar las tablas de cobranza
            IF p_mca_imp_cobranza = 'S'
            THEN
              --
              p_imp_cobranza(p_cod_cia => p_cod_cia, p_num_poliza => lv_num_poliza);
              --
              --@ev_k_traza.mx('sale de p_imp_cobranza');
              --
            END IF;
            --
            -- pasar las tablas de reaseguro
            IF p_mca_imp_reaseguro = 'S'
            THEN
              --
              p_imp_reaseguro(p_cod_cia => p_cod_cia, p_cod_ramo => ln_cod_ramo, p_num_poliza => lv_num_poliza);
              --
              --@ev_k_traza.mx('sale de p_imp_reaseguro');
              --
            END IF;
            --
            -- pasar las tablas de inspecciones
            IF p_mca_imp_inspecciones = 'S'
            THEN
              --
              p_imp_inspecciones(p_cod_cia => p_cod_cia, p_num_poliza => lv_num_poliza);
              --
            END IF;
            --
            -- pasar tablas de cierre vida individual
            --
            IF f_tip_seguro(p_cod_cia => p_cod_cia, p_cod_ramo => ln_cod_ramo) = 5
            THEN
              --
              p_imp_tablas_vidaind(p_cod_cia => p_cod_cia, p_cod_ramo => ln_cod_ramo, p_num_poliza => lv_num_poliza);
              --
            END IF;
            --
            --@ev_k_traza.mx('sale de p_imp_inspecciones');
            --
            ln_cont := ln_cont + 1;
            --@ev_k_traza.mx('N', 'ln_cont(2)', ln_cont);
            --
            lv_sentence := 'UPDATE a2999999@dev' ||
                           '   SET mca_proceso    = ' || '''' || 'S' || '''' ||
                           '      ,txt_error      = NULL' ||
                           '      ,txt_ruta_error = NULL' ||
                           ' WHERE cod_cia    = ' || TO_CHAR(p_cod_cia) ||
                           '   AND cod_ramo   = ' || TO_CHAR(ln_cod_ramo) ||
                           '   AND num_poliza = ' || lv_num_poliza;
            --
            p_ejecuta_dml(p_sentence => lv_sentence);
            --
            --@ev_k_traza.mx('actualiza la a2999999');
            --
            COMMIT;
            --
            FETCH cv_poliza
              INTO ln_cod_sector,
                   ln_cod_ramo,
                   ln_tip_gestor,
                   ln_cod_agt,
                   ln_cod_asesor,
                   ln_cod_agt2,
                   ln_cod_agt3,
                   ln_cod_agt4,
                   ln_cod_org,
                   lv_num_poliza_cliente,
                   lv_num_poliza_grupo,
                   ln_num_contrato,
                   lv_num_poliza;
            --
            --@ev_k_traza.mx('a otro loop');
            --
          EXCEPTION
            WHEN OTHERS THEN
              --
              ROLLBACK;
              --
              lv_error := TO_CHAR(p_cod_cia) || '-' ||
                          NVL(TO_CHAR(p_cod_ramo), '999') || '-' ||
                          NVL(p_num_poliza_desde, 'null') || '-' ||
                          NVL(p_num_poliza_hasta, 'null') || '-' ||
                          g_nom_tabla || '-' || p_sid_origen || '-' ||
                          NVL(p_sid_destino, 'N') || '-' ||
                          NVL(p_mca_imp_stros, 'N') || '-' ||
                          NVL(p_mca_imp_creditos, 'N') || '-' ||
                          NVL(p_mca_imp_cobranza, 'N') || '-' ||
                          NVL(p_mca_imp_reaseguro, 'N') || '-' ||
                          NVL(p_mca_imp_inspecciones, 'N') || '*' ||
                          SQLERRM;
              --
              p_txt_observacion := SUBSTR(lv_error || '-' || SQLERRM, 1, 900);
              --
              --@ev_k_traza.mx(lv_error);
              --
              BEGIN
                --
                UPDATE a2999999@dev
                   SET txt_error      = p_txt_observacion,
                       txt_ruta_error = SUBSTR(dbms_utility.format_call_stack, 1, 2000),
                       mca_proceso    = 'E'
                 WHERE cod_cia = p_cod_cia
                   AND num_poliza = lv_num_poliza;
                EXCEPTION WHEN OTHERS THEN NULL;   
                --   
              END;     
              --
              COMMIT;
              --
              IF cv_poliza%ISOPEN
              THEN
                --
                FETCH cv_poliza
                  INTO ln_cod_sector,
                       ln_cod_ramo,
                       ln_tip_gestor,
                       ln_cod_agt,
                       ln_cod_asesor,
                       ln_cod_agt2,
                       ln_cod_agt3,
                       ln_cod_agt4,
                       ln_cod_org,
                       lv_num_poliza_cliente,
                       lv_num_poliza_grupo,
                       ln_num_contrato,
                       lv_num_poliza;
                --
              END IF;
              --
          END;
          --
        END LOOP;
        --
        --@ev_k_traza.mx('sale del loop');
        --
        CLOSE cv_poliza;
        --
        COMMIT;
        --
        --@ev_k_traza.mx('after commit');
        --
        --@ev_k_traza.mx('N', 'ln_cont(3)', ln_cont);
        --
        IF ln_cont = 1
        THEN
          --
          p_txt_observacion := 'Paso de poliza ' || lv_num_poliza || ' ok';
          --
        ELSIF ln_cont > 1
        THEN
          --
          p_txt_observacion := 'Proceso ok, pase ' || ln_cont || ' polizas';
          --
        END IF;
        --
      END IF;
      --
      --@ev_k_traza.mx('finished');
      --
      /*
      EXCEPTION
          WHEN OTHERS THEN
            --
            ROLLBACK;
            --
            lv_error := TO_CHAR(p_cod_cia)
                 ||'-'||NVL(TO_CHAR(p_cod_ramo), '999')
                 ||'-'||NVL(p_num_poliza_desde, 'null')
                 ||'-'||NVL(p_num_poliza_hasta, 'null')
                 ||'-'||g_nom_tabla
                 ||'-'||p_sid_origen
                 ||'-'||NVL(p_sid_destino         ,'N')
                 ||'-'||NVL(p_mca_imp_stros       ,'N')
                 ||'-'||NVL(p_mca_imp_creditos    ,'N')
                 ||'-'||NVL(p_mca_imp_cobranza    ,'N')
                 ||'-'||NVL(p_mca_imp_reaseguro   ,'N') 
                 ||'-'||NVL(p_mca_imp_inspecciones,'N')
                 ||'*'||SQLERRM;
            --
            p_txt_observacion := SUBSTR(lv_error||'-'||SQLERRM, 1, 100);
            --
            UPDATE a2999999
               SET txt_error      = SQLERRM
                  ,txt_ruta_error = SUBSTR(dbms_utility.format_call_stack,1,2000)
                  ,mca_proceso    = 'E'
             WHERE cod_cia = p_cod_cia
               AND num_poliza = 
            --raise_application_error(-20020, SQLERRM (SQLCODE));
            --
            */
    END;
    --
    p_ini_traza('F', 'p_imp_poliza');
    --
  END p_imp_poliza;

  --
  --
  /*-------------------- DESCRIPCION ----------------------------------
  || Procedimiento de generacion tabla importacion datos de poliza
  */ -------------------------------------------------------------------
  PROCEDURE p_imp_poliza(p_cod_cia              IN a2000030.cod_cia %TYPE,
                         p_cod_ramo             IN a2000030.cod_ramo %TYPE,
                         p_num_poliza_desde     IN a2000030.num_poliza%TYPE,
                         p_num_poliza_hasta     IN a2000030.num_poliza%TYPE,
                         p_sid_origen           IN VARCHAR2 DEFAULT 'CSG',
                         p_sid_destino          IN VARCHAR2 DEFAULT 'DEV',
                         p_mca_imp_stros        IN VARCHAR2 DEFAULT 'N',
                         p_mca_imp_creditos     IN VARCHAR2 DEFAULT 'N',
                         p_mca_imp_cobranza     IN VARCHAR2 DEFAULT 'N',
                         p_mca_imp_reaseguro    IN VARCHAR2 DEFAULT 'N',
                         p_mca_imp_inspecciones IN VARCHAR2 DEFAULT 'N',
                         p_txt_observacion      OUT VARCHAR2) IS
  BEGIN
    --
    p_ini_traza('I', 'p_imp_poliza');
    --
    p_imp_poliza(p_cod_cia => p_cod_cia, p_cod_ramo => p_cod_ramo, p_num_poliza_desde => p_num_poliza_desde, p_num_poliza_hasta => p_num_poliza_hasta, p_sid_origen => p_sid_origen, p_sid_destino => p_sid_destino, p_mca_imp_stros => p_mca_imp_stros, p_mca_imp_creditos => p_mca_imp_creditos, p_mca_imp_cobranza => p_mca_imp_cobranza, p_mca_imp_reaseguro => p_mca_imp_reaseguro, p_mca_imp_inspecciones => p_mca_imp_inspecciones, p_num_riesgo => NULL, p_txt_observacion => p_txt_observacion);
    --
    p_ini_traza('F', 'p_imp_poliza');
    --
  END p_imp_poliza;

  --
  --
  /*-------------------- DESCRIPCION ------------------------------------
  || Procedimiento de generacion tabla importacion datos de orden de pago
  */ ---------------------------------------------------------------------
  PROCEDURE p_imp_orden_pago(p_cod_cia      a5021604.cod_cia %TYPE,
                             p_num_ord_pago a5021604.num_ord_pago%TYPE,
                             p_base_orig    VARCHAR2 DEFAULT 'CSG',
                             p_base_des     VARCHAR2 DEFAULT 'DEV') IS
  BEGIN
    --
    gc_k_descarga_credito_csg.p_pasa_orden_pago(p_cod_cia => p_cod_cia, p_num_ord_pago => p_num_ord_pago, p_base_orig => p_base_orig, p_base_des => p_base_des);
    --
  END p_imp_orden_pago;

  --
END em_k_imp_datos_csg;
/
