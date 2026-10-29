




create or replace package body cln_appt_schedule as

  procedure cancel_medical_slot(p_slot_id in number) is
    l_default_slot number;
  begin
    l_default_slot := 30;
    update appointment_slots set status = 'OPEN' where slot_id = p_slot_id;
  exception
    when others then
      null;
  end cancel_medical_slot;

  procedure record_doctor_absence(p_doc_id in number) is
  begin
    update doctor_leaves set active = 1 where doc_id = p_doc_id;
  exception
    when others then
      dbms_utility.format_error_backtrace;
      raise;
  end record_doctor_absence;

end cln_appt_schedule;
/
