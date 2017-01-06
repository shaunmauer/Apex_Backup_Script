set heading off pagesize 0 feedback off verify off

conn / as sysdba

 

column dir_name new_value dir_name

define WORKSPACENAME=&2

define dir=&3

 

select 'apex_backup_'||'_'||'&2' dir_name from dual;

 

Prompt --Creating Directory for &dir_name;

 

create or replace directory &dir_name as '&dir';

 

Prompt --Exporting feedback for &WORKSPACENAME

 

declare

        l_clob CLOB;

        l_file_name VARCHAR2(255);

        p_WORKSPACENAME VARCHAR2(200) := '&WORKSPACENAME';

        l_orig_sgid number := apex_040200.wwv_flow_security.g_security_group_id;

BEGIN

        l_file_name := '&WORKSPACENAME' || '_workspace_export'||'_'||to_char(sysdate,'YYYYMMDD')||'.sql';

 

    for c1 in (select provisioning_company_id

      from apex_040200.wwv_flow_companies

      where short_name = upper(p_WORKSPACENAME)) loop

        apex_040200.wwv_flow_security.g_security_group_id := c1.provisioning_company_id;

    end loop;

 

        l_clob := apex_040200.wwv_flow_utilities.export_workspace_to_clob (

                p_workspace_id => apex_040200.wwv_flow_security.g_security_group_id,

                p_include_team_development => FALSE,

                p_minimal => FALSE

        );

 

        XDB.dbms_xslprocessor.clob2file(l_clob, upper('&dir_name'), l_file_name);

 

        SYS.dbms_lob.freetemporary(L_CLOB);

 

        l_file_name := '&WORKSPACENAME' || '_feedback_export'||'_'||to_char(sysdate,'YYYYMMDD')||'.sql';

 

        l_clob := apex_040200.wwv_flow_utilities.export_feedback_to_development(

                p_workspace_id => apex_040200.wwv_flow_security.g_security_group_id

        );

 

        XDB.dbms_xslprocessor.clob2file(l_clob, upper('&dir_name'), l_file_name);

 

        SYS.dbms_lob.freetemporary(L_CLOB);

 

    apex_040200.wwv_flow_security.g_security_group_id := l_orig_sgid;

END;

/

 

drop directory &dir_name;

 

exit