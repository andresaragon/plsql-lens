-- case: e015
-- domain: ticketing
-- difficulty: medium
-- note: turnstile gate threshold control repeating magic numeric literal three times
-- author: gemini-3.8-flash-high via agy (not human-written)
create or replace package body tkt_turnstile_control as

  procedure set_ticket_gate_limit(p_gate_id in number) is
    l_limit number;
  begin
    l_limit := 9999; -- expect: PLL007
    update turnstiles set max_passengers = 9999 where gate_id = p_gate_id; -- expect: PLL007
  end set_ticket_gate_limit;

  procedure reset_overflow_gate(p_gate_id in number) is
  begin
    insert into gate_limits(gate_id, threshold) values (p_gate_id, 9999); -- expect: PLL007
  end reset_overflow_gate;

end tkt_turnstile_control;
/
