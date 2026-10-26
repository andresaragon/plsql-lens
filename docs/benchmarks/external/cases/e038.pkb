-- case: e038
-- domain: airline baggage
-- difficulty: hard
-- note: baggage transfer conveyor dispatch repeating cargo hold category literal with loop commit and safe rollback
-- author: gemini-3.8-flash-high via agy (not human-written)
create or replace package body air_baggage_dispatch as

  procedure dispatch_transfer_baggage(p_flight_id in number) is
    cursor c_bags is
      select bag_id, weight
      from transfer_luggage
      where flight_id = p_flight_id;
    l_bag_id number;
    l_weight number;
  begin
    open c_bags;
    loop
      fetch c_bags into l_bag_id, l_weight;
      exit when c_bags%notfound;
      update baggage_manifest set hold_area = 'HEAVY_CARGO_HOLD' where bag_id = l_bag_id; -- expect: PLL007 expect: PLL005
      commit; -- expect: PLL003
    end loop;
    close c_bags;

    insert into baggage_audit_log(flight_id, target_area, logged_at)
    values (p_flight_id, 'HEAVY_CARGO_HOLD', sysdate); -- expect: PLL007
  end dispatch_transfer_baggage;

  procedure reconcile_weight_surcharge(p_bag_id in number, p_weight_kg in number, p_fee out number) is
    l_surcharge number := 0;
  begin
    update luggage_tags set category = 'HEAVY_CARGO_HOLD' where bag_id = p_bag_id; -- expect: PLL007

    if p_weight_kg = '32' then -- expect: PLL006
      l_surcharge := 75.0;
    else
      l_surcharge := 25.0;
    end if;

    p_fee := l_surcharge;
  end reconcile_weight_surcharge;

  procedure route_standby_bags(p_flight_id in number) is
    l_standby_count number := 0;
    l_scanned_count number := 0;
  begin
    for r in (select bag_id from transfer_luggage where flight_id = p_flight_id and status = 'STANDBY') loop
      savepoint sp_bag_route;
      begin
        assign_standby_tag(r.bag_id);
        l_standby_count := l_standby_count + 1;
      exception
        when others then -- expect: PLL001
          rollback to sp_bag_route; -- clean: PLL003
      end;
    end loop;

    for r in (select bag_id from transfer_luggage where flight_id = p_flight_id and status = 'TAGGED') loop
      record_baggage_scan(r.bag_id); -- beyond: PLL005 (procedure called inside cursor loop executes row-by-row DML)
      l_scanned_count := l_scanned_count + 1;
    end loop;
  end route_standby_bags;

end air_baggage_dispatch;
/
