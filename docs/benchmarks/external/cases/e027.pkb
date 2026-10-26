-- case: e027
-- domain: car rental
-- difficulty: easy
-- note: vehicle rental close with while loop commit alongside telematics dynamic sql injection
-- author: gemini-3.8-flash-high via agy (not human-written)
create or replace package body cr_rental_ops as

  procedure close_rental_agreement(p_agreement_id in number) is
    l_attempts number := 0;
  begin
    while l_attempts < 3 loop
      l_attempts := l_attempts + 1;
      commit; -- expect: PLL003
    end loop;
  end close_rental_agreement;

  procedure update_car_telematics(p_id in number, p_status in varchar2) is
  begin
    execute immediate 'update car_status set state = ''' || p_status || ''' where id = ' || p_id; -- expect: PLL002
  end update_car_telematics;

  procedure finalize_rental_invoice(p_id in number) is
  begin
    update invoices set finalized = 1 where id = p_id;
    commit; -- clean: PLL003
  end finalize_rental_invoice;

end cr_rental_ops;
/
