-- case: e025
-- domain: clinic appointments
-- difficulty: medium
-- note: patient triage score evaluated against string literal versus valid numeric check
-- author: gemini-3.8-flash-high via agy (not human-written)
create or replace package body cln_triage_eval as

  procedure evaluate_patient_severity(p_triage_score in number) is
  begin
    if p_triage_score = 'URGENT' then -- expect: PLL006
      insert into urgent_cases(reported_time) values (sysdate);
    end if;
  end evaluate_patient_severity;

  procedure verify_priority_code(p_triage_score in number) is
  begin
    if p_triage_score = 1 then -- clean: PLL006
      insert into standard_cases(reported_time) values (sysdate);
    end if;
  end verify_priority_code;

end cln_triage_eval;
/
