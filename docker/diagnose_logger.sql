-- Diagnostic for the logger_log_error failures (F3): why does logger.log_error insert no row?
set serveroutput on size unlimited
set linesize 200
prompt == prefs
select pref_type || '/' || pref_name || '=' || pref_value from logger_prefs;
prompt == context level before
select 'ctx_level=' || nvl(sys_context('logger_context', 'level'), 'NULL') from dual;
declare
  l_n number;
begin
  dbms_output.put_line('ok_to_log(error)=' || case when logger.ok_to_log(logger.g_error) then 'TRUE' else 'FALSE' end);
  dbms_output.put_line('ok_to_log(debug)=' || case when logger.ok_to_log(logger.g_debug) then 'TRUE' else 'FALSE' end);
  logger.log_error('diag text', 'diag_scope');
  select count(*) into l_n from logger_logs where scope = 'diag_scope';
  dbms_output.put_line('rows_after_log_error=' || l_n);
  logger.log('diag debug text', 'diag_scope2');
  select count(*) into l_n from logger_logs where scope = 'diag_scope2';
  dbms_output.put_line('rows_after_log_debug=' || l_n);
  select count(*) into l_n from logger_logs;
  dbms_output.put_line('rows_total=' || l_n);
end;
/
prompt == invalid objects
select object_type || ' ' || object_name || ' ' || status from user_objects where status <> 'VALID';
