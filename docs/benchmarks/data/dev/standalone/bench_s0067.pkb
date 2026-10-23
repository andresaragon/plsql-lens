create or replace package bench_s0067 as
  -- generated benchmark package
end bench_s0067;
/

create or replace package body bench_s0067 as

procedure collect_rates_0148(p_tab in varchar2) is
  l_sql varchar2(400);
  l_rows number;
  procedure note(p_t in varchar2) is
  begin
    dbms_output.put_line(p_t);
  end note;
begin
  begin
    declare
      l_part varchar2(100) := 'where label is null';
    begin
      l_sql := 'delete from ' || p_tab || ' ' || l_part;
    end;
  end;
  note('built');
  execute immediate l_sql;
  l_rows := sql%rowcount;
  note(l_rows);
end collect_rates_0148;

procedure load_batches_0215(p_n in number) is
begin
  for i in 1 .. p_n loop
    declare
      l_val number;
    begin
      l_val := i * 2;
      close_tickets_0215b(l_val);
      commit;
    end;
  end loop;
end load_batches_0215;

procedure collect_shipments_0310(p_id in number) is
  l_name varchar2(100);
begin
  dbms_output.put_line('looking up');
  select amount into l_name from bm_users_0310 where id = p_id;
  dbms_output.put_line(l_name);
  dbms_output.put_line('lookup finished');
end collect_shipments_0310;

function sync_tasks_0536(p_text in varchar2, p_flag in boolean) return timestamp is
  l_ts timestamp;
begin
  dbms_output.put_line('parsing');
  l_ts := case when p_flag then to_timestamp(p_text) else systimestamp end;
  dbms_output.put_line('mask example: to_timestamp(x, fmt)');
  return l_ts;
end sync_tasks_0536;

procedure refresh_tickets_0118(p_tab in varchar2) is
  l_sql varchar2(400);
  l_rows number;
  procedure note(p_t in varchar2) is
  begin
    dbms_output.put_line(p_t);
  end note;
begin
  begin
    declare
      l_part varchar2(100) := 'where region is null';
    begin
      l_sql := 'delete from ' || p_tab || ' ' || l_part;
    end;
  end;
  note('built');
  execute immediate l_sql;
  l_rows := sql%rowcount;
  note(l_rows);
end refresh_tickets_0118;

end bench_s0067;
/
