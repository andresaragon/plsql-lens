




create or replace package body cln_triage_eval as

  procedure evaluate_patient_severity(p_triage_score in number) is
  begin
    if p_triage_score = 'URGENT' then
      insert into urgent_cases(reported_time) values (sysdate);
    end if;
  end evaluate_patient_severity;

  procedure verify_priority_code(p_triage_score in number) is
  begin
    if p_triage_score = 1 then
      insert into standard_cases(reported_time) values (sysdate);
    end if;
  end verify_priority_code;

end cln_triage_eval;
/
