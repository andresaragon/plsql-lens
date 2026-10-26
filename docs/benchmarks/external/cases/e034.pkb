-- case: e034
-- domain: gym memberships
-- difficulty: medium
-- note: locker rental batch with commit in loop versus safe savepoint rollback
-- author: gemini-3.8-flash-high via agy (not human-written)
create or replace package body gym_locker_ops as

  procedure renew_locker_assignments(p_locker_id in number) is
  begin
    for r in (select rent_id from locker_rentals where locker_id = p_locker_id) loop
      commit; -- expect: PLL003
    end loop;
    delete from expired_locks where lock_id = p_locker_id; -- clean: PLL005
  end renew_locker_assignments;

  procedure safely_renew_single_locker(p_rent_id in number) is
  begin
    for r in (select rent_id from locker_rentals where rent_id = p_rent_id) loop
      savepoint before_renew;
      rollback to before_renew; -- clean: PLL003
    end loop;
  end safely_renew_single_locker;

end gym_locker_ops;
/
