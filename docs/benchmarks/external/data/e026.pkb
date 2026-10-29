




create or replace package body cln_specimen_mgmt as

  c_pkg_status constant varchar2(10) := 'PENDING';

  procedure archive_lab_records(p_patient_id in number) is
  begin
    insert into lab_audit(result_id, logged_at) values (p_patient_id, sysdate);
  end archive_lab_records;

  procedure check_specimen_threshold(p_patient_id in number) is
    l_unit varchar2(10);
    l_alert varchar2(10);
  begin
    l_unit := 'MG_DL';
    l_alert := c_pkg_status;
  end check_specimen_threshold;

end cln_specimen_mgmt;
/
