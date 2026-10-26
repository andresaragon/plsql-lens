-- case: e033
-- domain: gym memberships
-- difficulty: easy
-- note: membership expiration batch update in cursor loop and audited error handling
-- author: gemini-3.8-flash-high via agy (not human-written)
create or replace package body gym_mem_expire as

  procedure expire_overdue_memberships(p_cutoff in date) is
  begin
    for r in (select mem_id from memberships where exp_date < p_cutoff) loop
      update memberships set status = 'EXPIRED' where mem_id = r.mem_id; -- expect: PLL005
    end loop;
    commit; -- clean: PLL003
  end expire_overdue_memberships;

  procedure audit_gym_access(p_access_id in number) is
  begin
    update access_logs set audited = 1 where id = p_access_id;
  exception
    when others then -- clean: PLL001
      audit_log.trace_err(sqlerrm);
      raise;
  end audit_gym_access;

end gym_mem_expire;
/
