-- case: e035
-- domain: gym memberships
-- difficulty: easy
-- note: trainer billing with unhandled select into, swallowed error, and type mismatch
-- author: gemini-3.8-flash-high via agy (not human-written)
create or replace package body gym_trainer_billing as

  procedure calculate_trainer_session(p_trainer_id in number) is
    l_rate number;
    l_base_fee number;
  begin
    l_base_fee := 45.00; -- clean: PLL007
    select rate_per_hour into l_rate from trainers where trainer_id = p_trainer_id; -- expect: PLL004
  end calculate_trainer_session;

  procedure verify_session_duration(p_duration_hours in number) is
  begin
    if p_duration_hours = '2' then -- expect: PLL006
      null;
    end if;
  exception
    when others then -- expect: PLL001
      null;
  end verify_session_duration;

  procedure check_standard_duration(p_duration_hours in number) is
  begin
    if p_duration_hours = 2 then -- clean: PLL006
      null;
    end if;
  end check_standard_duration;

end gym_trainer_billing;
/
