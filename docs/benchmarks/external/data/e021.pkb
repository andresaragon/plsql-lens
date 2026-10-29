




create or replace package body htl_loyalty_ops as

  procedure reward_frequent_guests(p_min_stays in number) is
  begin
    for r in (select guest_id from guest_history where stays >= p_min_stays) loop
      update guests set points = points + 10 where guest_id = r.guest_id;
    end loop;
  end reward_frequent_guests;

  procedure batch_clean_rooms(p_floor in number) is
  begin
    for r in (select room_id from rooms where floor_no = p_floor) loop
      commit;
    end loop;
  end batch_clean_rooms;

  procedure sequence_housekeeping(p_count in number) is
  begin
    for i in 1 .. p_count loop
      update room_clean_queue set seq = i where id = i;
    end loop;
  end sequence_housekeeping;

end htl_loyalty_ops;
/
