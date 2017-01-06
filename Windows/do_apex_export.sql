set heading off pagesize 0 feedback off verify off
conn / as sysdba

column dir_name new_value dir_name
define APP_ID=&2
define WORKSPACENAME=&3
define dir=&4

select 'apex_backup_'||'&3'||'_'||'&2' dir_name from dual;

Prompt --Creating Directory &dir_name for &WORKSPACENAME (&APP_ID);
create or replace directory &dir_name as '&dir\pages';

Prompt --Exporting pages for &WORKSPACENAME (&APP_ID);

declare
  l_clob clob;
  l_file_name varchar2(255);
  L_NAME_LIST  SYS.OWA.VC_ARR;
  L_VALUE_LIST SYS.OWA.VC_ARR;
  L_HTBUF   SYS.HTP.HTBUF_ARR;
  L_ROWS_IN INTEGER := 9999999;
  L_BUFFER  VARCHAR2(32767) := NULL;
  L_COUNT NUMBER := 0;
BEGIN
  for c1 in (select workspace_id
             from apex_applications
             where application_id = &APP_ID
                   and workspace = '&WORKSPACENAME') loop
      apex_util.set_security_group_id(p_security_group_id => c1.workspace_id);
  end loop;

  for r1 in (select page_id from apex_application_pages where application_id = &APP_ID order by page_id)
  loop
    L_NAME_LIST (1) := 'REQUEST_CHARSET';
    L_VALUE_LIST(1) := 'AL32UTF8';
    L_NAME_LIST (2) := 'REQUEST_IANA_CHARSET';
    L_VALUE_LIST(2) := 'UTF-8';
    SYS.OWA.INIT_CGI_ENV(2, L_NAME_LIST, L_VALUE_LIST);
    SYS.HTP.HTBUF_LEN := 84;
    L_ROWS_IN := 9999999;
    L_BUFFER := NULL;

    apex_040200.wwv_flow_gen_api2.export(
      p_flow_id=> &APP_ID,
      p_page_id=> r1.page_id,
      p_commit=>'YES',
      p_format => 'DOS',
      p_export_comments => 'Y',
      p_export_ir_public_reports => 'Y',
      p_export_ir_private_reports => 'Y',
      p_export_ir_notifications => 'Y',
      p_export_translations => 'Y'
        );

    l_file_name := 'f' || &APP_ID || '_page' || r1.page_id || '_export.sql';

    SYS.DBMS_LOB.CREATETEMPORARY( L_CLOB, FALSE, SYS.DBMS_LOB.SESSION );

    SYS.HTP.GET_PAGE(L_HTBUF, L_ROWS_IN);

    FOR I IN 1 .. L_ROWS_IN
    LOOP
         L_BUFFER := L_BUFFER || L_HTBUF(I);
         IF MOD(I, 180) = 0 THEN
           SYS.DBMS_LOB.WRITEAPPEND(L_CLOB, LENGTH(L_BUFFER), L_BUFFER);
           L_BUFFER := NULL;
         END IF;
    END LOOP;


    IF L_BUFFER IS NOT NULL THEN
         SYS.DBMS_LOB.WRITEAPPEND(L_CLOB, LENGTH(L_BUFFER), L_BUFFER);
    END IF;

 

    XDB.dbms_xslprocessor.clob2file(l_clob, upper('&dir_name'), l_file_name);

 

    sys.dbms_lob.freetemporary(l_clob);

 

  end loop;

end;

/

 

create or replace directory &dir_name as '&dir';

 

Prompt --Exporting application &WORKSPACENAME (&APP_ID);

 

declare

  l_clob clob;

  l_file_name varchar2(255);

  L_NAME_LIST  SYS.OWA.VC_ARR;

  L_VALUE_LIST SYS.OWA.VC_ARR;

  L_HTBUF   SYS.HTP.HTBUF_ARR;

  L_ROWS_IN INTEGER := 9999999;

  L_BUFFER  VARCHAR2(32767) := NULL;

  L_COUNT NUMBER := 0;

begin

 

  l_file_name := 'f' || &APP_ID || '_export.sql';

 

  L_NAME_LIST (1) := 'REQUEST_CHARSET';

  L_VALUE_LIST(1) := 'AL32UTF8';

  L_NAME_LIST (2) := 'REQUEST_IANA_CHARSET';

  L_VALUE_LIST(2) := 'UTF-8';

  SYS.OWA.INIT_CGI_ENV(2, L_NAME_LIST, L_VALUE_LIST);

  SYS.HTP.HTBUF_LEN := 84;

  L_ROWS_IN := 9999999;

  L_BUFFER := NULL;

 

 

  apex_040200.wwv_flow_gen_api2.export(

    p_flow_id=> &APP_ID,

    p_commit=>'YES',

    p_format => 'DOS',

    p_export_comments => 'Y'

  );

 

  SYS.DBMS_LOB.CREATETEMPORARY( L_CLOB, FALSE, SYS.DBMS_LOB.SESSION );

 

  SYS.HTP.GET_PAGE(L_HTBUF, L_ROWS_IN);

  FOR I IN 1 .. L_ROWS_IN

  LOOP

     L_BUFFER := L_BUFFER || L_HTBUF(I);

     IF MOD(I, 180) = 0 THEN

       SYS.DBMS_LOB.WRITEAPPEND(L_CLOB, LENGTH(L_BUFFER), L_BUFFER);

       L_BUFFER := NULL;

     END IF;

  END LOOP;

 

  IF L_BUFFER IS NOT NULL THEN

     SYS.DBMS_LOB.WRITEAPPEND(L_CLOB, LENGTH(L_BUFFER), L_BUFFER);

  END IF;

 

  XDB.dbms_xslprocessor.clob2file(l_clob, upper('&dir_name'), l_file_name);

 

  sys.dbms_lob.freetemporary(l_clob);

end;

/

 

Prompt --Exporting themesfor &WORKSPACENAME (&APP_ID);

 

declare

  l_clob clob;

  l_file_name varchar2(255);

  L_NAME_LIST  SYS.OWA.VC_ARR;

  L_VALUE_LIST SYS.OWA.VC_ARR;

  L_HTBUF   SYS.HTP.HTBUF_ARR;

  L_ROWS_IN INTEGER := 9999999;

  L_BUFFER  VARCHAR2(32767) := NULL;

  L_COUNT NUMBER := 0;

begin

  for r1 in (select theme_id from apex_040200.wwv_flow_themes where flow_id = &APP_ID order by theme_id)

  loop

 

    L_NAME_LIST (1) := 'REQUEST_CHARSET';

    L_VALUE_LIST(1) := 'AL32UTF8';

    L_NAME_LIST (2) := 'REQUEST_IANA_CHARSET';

    L_VALUE_LIST(2) := 'UTF-8';

    SYS.OWA.INIT_CGI_ENV(2, L_NAME_LIST, L_VALUE_LIST);

    SYS.HTP.HTBUF_LEN := 84;

    L_ROWS_IN := 9999999;

    L_BUFFER := NULL;

 

    apex_040200.wwv_flow_gen_api2.export_theme(

      p_flow_id=>&APP_ID,

      p_commit=>'YES',

      p_format => 'DOS',

      p_theme_id => r1.theme_id);

 

    l_file_name := 'f' || &APP_ID || '_theme' || r1.theme_id || '_export.sql';

 

    SYS.DBMS_LOB.CREATETEMPORARY( L_CLOB, FALSE, SYS.DBMS_LOB.SESSION );

 

    SYS.HTP.GET_PAGE(L_HTBUF, L_ROWS_IN);

    FOR I IN 1 .. L_ROWS_IN

    LOOP

       L_BUFFER := L_BUFFER || L_HTBUF(I);

       IF MOD(I, 180) = 0 THEN

         SYS.DBMS_LOB.WRITEAPPEND(L_CLOB, LENGTH(L_BUFFER), L_BUFFER);

         L_BUFFER := NULL;

       END IF;

    END LOOP;

 

    IF L_BUFFER IS NOT NULL THEN

       SYS.DBMS_LOB.WRITEAPPEND(L_CLOB, LENGTH(L_BUFFER), L_BUFFER);

    END IF;

 

    XDB.dbms_xslprocessor.clob2file(l_clob, upper('&dir_name'), l_file_name);

 

    sys.dbms_lob.freetemporary(l_clob);

 

  end loop;

end;

/

 

Prompt --Exporting application processes for &WORKSPACENAME (&APP_ID);

 

declare

  l_clob clob;

  l_file_name varchar2(255);

  L_NAME_LIST  SYS.OWA.VC_ARR;

  L_VALUE_LIST SYS.OWA.VC_ARR;

  L_HTBUF   SYS.HTP.HTBUF_ARR;

  L_ROWS_IN INTEGER := 9999999;

  L_BUFFER  VARCHAR2(32767) := NULL;

  L_COUNT NUMBER := 0;

begin

  L_NAME_LIST (1) := 'REQUEST_CHARSET';

  L_VALUE_LIST(1) := 'AL32UTF8';

  L_NAME_LIST (2) := 'REQUEST_IANA_CHARSET';

  L_VALUE_LIST(2) := 'UTF-8';

  SYS.OWA.INIT_CGI_ENV(2, L_NAME_LIST, L_VALUE_LIST);

  SYS.HTP.HTBUF_LEN := 84;

  L_ROWS_IN := 9999999;

  L_BUFFER := NULL;

 

  for r1 in (select ID, PROCESS_NAME name from apex_040200.WWV_FLOW_PROCESSING where flow_id = &APP_ID)

  loop

 

    apex_040200.wwv_flow_gen_api2.export(

      p_flow_id=> &APP_ID,

      p_page_id=>null,

      p_commit=>'YES',

      p_format => 'DOS',

      p_component => 'APP PROCESS',

      p_component_id => r1.id,

      p_export_comments => 'Y'

    );

 

  end loop;

 

  l_file_name := 'f' || &APP_ID || '_processes_export.sql';

 

  SYS.DBMS_LOB.CREATETEMPORARY( L_CLOB, FALSE, SYS.DBMS_LOB.SESSION );

 

  SYS.HTP.GET_PAGE(L_HTBUF, L_ROWS_IN);

  FOR I IN 1 .. L_ROWS_IN

  LOOP

     L_BUFFER := L_BUFFER || L_HTBUF(I);

     IF MOD(I, 180) = 0 THEN

       SYS.DBMS_LOB.WRITEAPPEND(L_CLOB, LENGTH(L_BUFFER), L_BUFFER);

       L_BUFFER := NULL;

     END IF;

  END LOOP;

 

  IF L_BUFFER IS NOT NULL THEN

     SYS.DBMS_LOB.WRITEAPPEND(L_CLOB, LENGTH(L_BUFFER), L_BUFFER);

  END IF;

 

  XDB.dbms_xslprocessor.clob2file(l_clob, upper('&dir_name'), l_file_name);

 

  sys.dbms_lob.freetemporary(l_clob);

 

end;

/

 

drop directory &dir_name;

 

exit