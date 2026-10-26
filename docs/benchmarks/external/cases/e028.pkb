-- case: e028
-- domain: car rental
-- difficulty: medium
-- note: timestamp parsing with and without format mask plus fetch loop delete
-- author: gemini-3.8-flash-high via agy (not human-written)
create or replace package body cr_odometer_sync as

  procedure record_car_odometer_raw(p_ts_str in varchar2) is
    l_return_ts timestamp;
  begin
    l_return_ts := to_timestamp(p_ts_str); -- expect: PLL006
  end record_car_odometer_raw;

  procedure record_car_odometer_formatted(p_ts_str in varchar2) is
    l_clean_ts timestamp;
  begin
    l_clean_ts := to_timestamp(p_ts_str, 'YYYY-MM-DD HH24:MI:SS.FF'); -- clean: PLL006
  end record_car_odometer_formatted;

  procedure purge_old_holds(p_cur in sys_refcursor) is
    l_hold_id number;
  begin
    loop
      fetch p_cur into l_hold_id;
      exit when p_cur%notfound;
      delete from vehicle_holds where hold_id = l_hold_id; -- expect: PLL005
    end loop;
  end purge_old_holds;

end cr_odometer_sync;
/
