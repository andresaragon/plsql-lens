-- case: e039
-- domain: parking permits
-- difficulty: hard
-- note: residential permit renewal batch with cursor loop update, commit inside loop, and outer exception handler
-- author: gemini-3.8-flash-high via agy (not human-written)
create or replace package body prk_permit_workflow as

  procedure process_permit_renewals(p_zone_id in number) is
    cursor c_apps is
      select permit_id, applicant_id
      from permit_applications
      where zone_id = p_zone_id and status = 'PENDING';
    l_permit_id number;
    l_appl_id   number;
    l_applicant varchar2(100);
    l_priority  number := 0;
  begin
    open c_apps;
    loop
      fetch c_apps into l_permit_id, l_appl_id;
      exit when c_apps%notfound;
      select applicant_name into l_applicant from permit_applicants where applicant_id = l_appl_id; -- expect: PLL004
      update permit_applications set status = 'APPROVED' where permit_id = l_permit_id; -- expect: PLL005
      commit; -- expect: PLL003
    end loop;
    close c_apps;

    if p_zone_id = '12' then -- expect: PLL006
      l_priority := 1;
    end if;
  end process_permit_renewals;

  procedure verify_zone_capacity(p_zone_id in number, p_has_space out boolean) is
    l_active_permits number := 0;
    l_capacity_limit number := 100;
  begin
    select count(*) into l_active_permits from permits where zone_id = p_zone_id and active = 1; -- clean: PLL004

    if p_zone_id = 12 then -- clean: PLL006
      l_capacity_limit := 150;
    end if;

    p_has_space := (l_active_permits < l_capacity_limit);
  exception
    when no_data_found then null; -- beyond: PLL001 (named exception swallowed without logging or re-raising)
  end verify_zone_capacity;

  procedure archive_expired_permits(p_cutoff in date) is
    l_retention_days number;
    l_archive_batch  number := 100;
  begin
    l_retention_days := 365; -- clean: PLL007
    update permits
    set archived = 1
    where expiry_date < p_cutoff and active = 0 and rownum <= l_archive_batch;
    insert into permit_audit(action, executed_at) values ('ARCHIVE', sysdate);
  exception
    when others then -- clean: PLL001
      logger.log_error(sqlerrm);
      raise;
  end archive_expired_permits;

end prk_permit_workflow;
/
