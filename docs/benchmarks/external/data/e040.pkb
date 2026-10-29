




create or replace package body log_telematics_stream as

  procedure ingest_telemetry_batch(p_batch_id in number, p_region in varchar2, p_data in varchar2) is
    type t_id_list is table of number;
    l_archived_ids t_id_list;
    l_target_table varchar2(60);
    l_sql          varchar2(500);
  begin
    l_target_table := 'telematics_' || p_region;
    l_sql := 'insert into ' || l_target_table || ' (batch_id, payload, recorded_at) values (:b, :p, sysdate)';
    execute immediate l_sql using p_batch_id, p_data;

    select id bulk collect into l_archived_ids
    from staging_telemetry
    where batch_id = p_batch_id;

    if l_archived_ids.count > 0 then
      forall i in 1 .. l_archived_ids.count
        insert into telemetry_history(batch_id) values (l_archived_ids(i));
    end if;

    update batch_manifest
    set processed_flag = 1, finished_at = sysdate
    where batch_id = p_batch_id;
  exception
    when others then
      null;
  end ingest_telemetry_batch;

  procedure reconcile_driver_shifts(p_hub_id in number, p_shift_count out number) is
    l_driver_name varchar2(100);
    l_count       number := 0;
    l_overdue     number := 0;
    l_query       varchar2(300);
  begin
    begin
      select driver_name into l_driver_name from fleet_drivers where hub_id = p_hub_id;
    exception
      when no_data_found then
        l_driver_name := 'UNASSIGNED';
      when others then
        logger.log_error(sqlerrm);
        raise;
    end;

    l_query := 'select count(*) from driver_shifts where hub_id = :h and shift_date = trunc(sysdate)';
    execute immediate l_query into l_count using p_hub_id;

    select count(*) into l_overdue from shipments where promised_date < '2026-10-01';
    if l_overdue > 0 then
      insert into hub_warnings(hub_id, overdue_count) values (p_hub_id, l_overdue);
    end if;

    commit;
    p_shift_count := l_count;
  end reconcile_driver_shifts;

end log_telematics_stream;
/
