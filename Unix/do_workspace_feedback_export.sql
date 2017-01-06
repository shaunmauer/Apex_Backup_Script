set heading off pagesize 0 feedback off verify off

conn / as sysdba

column dir_name new_value dir_name noprint
column apex_schema new_value apex_schema noprint
define WORKSPACENAME=&2
define dir=&3

select 'apex_backup_'||'&2' dir_name from dual;
select schema apex_schema from dba_registry where comp_id = 'APEX';

Prompt -- Creating Directory - &dir_name;
create or replace directory &dir_name as '&dir';
Prompt --   Done

Prompt
Prompt --Exporting workspace and feedback for workspace - &WORKSPACENAME

declare
    l_clob CLOB;
    l_file_name VARCHAR2(255);
    l_orig_sgid number := "&apex_schema".wwv_flow_security.g_security_group_id;
BEGIN
    l_file_name := '&WORKSPACENAME' || '_workspace_export'||'_'||to_char(sysdate,'YYYY_MM_DD')||'.sql';

    for c1 in (select distinct workspace_id
               from apex_applications
               where workspace = '&WORKSPACENAME') loop
        apex_util.set_security_group_id(p_security_group_id => c1.workspace_id);
    end loop;

    l_clob := "&apex_schema".wwv_flow_utilities.export_workspace_to_clob (
        p_workspace_id => "&apex_schema".wwv_flow_security.g_security_group_id,
        p_include_team_development => FALSE,
        p_minimal => FALSE
    );

    XDB.dbms_xslprocessor.clob2file(l_clob, upper('&dir_name'), l_file_name);
    SYS.dbms_lob.freetemporary(L_CLOB);
    l_file_name := '&WORKSPACENAME' || '_feedback_export'||'_'||to_char(sysdate,'YYYY_MM_DD')||'.sql';

    l_clob := "&apex_schema".wwv_flow_utilities.export_feedback_to_development(
        p_workspace_id => "&apex_schema".wwv_flow_security.g_security_group_id
    );
 
    XDB.dbms_xslprocessor.clob2file(l_clob, upper('&dir_name'), l_file_name);
    SYS.dbms_lob.freetemporary(L_CLOB);
    "&apex_schema".wwv_flow_security.g_security_group_id := l_orig_sgid;

END;
/

Prompt --   Done

Prompt
Prompt --Dropping Directory - &dir_name;
drop directory &dir_name;
Prompt --   Done
Prompt

exit
