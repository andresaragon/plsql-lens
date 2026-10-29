




create or replace package body log_route_migration as

  procedure migrate_tracking_partition(p_target_tbl in varchar2) is
    l_sql varchar2(500);
  begin
    l_sql := 'insert into ' || p_target_tbl || ' select * from staging';
    execute immediate l_sql;
  end migrate_tracking_partition;

  procedure prune_archived_telemetry(p_date in date) is
    l_sql varchar2(500);
  begin
    l_sql := 'delete from logs where created < :d';
    execute immediate l_sql using p_date;
  end prune_archived_telemetry;

end log_route_migration;
/
