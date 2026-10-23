create or replace package bench_s0015 as
  -- generated benchmark package
end bench_s0015;
/

create or replace package body bench_s0015 as

function refresh_payments_0672(p_a in varchar2, p_b in varchar2, p_c in varchar2) return varchar2 is
  l_out varchar2(400);
begin
  l_out := p_a || ',' || p_b;
  l_out := l_out || ',' || p_c;
  l_out := l_out || ';' || p_a;
  l_out := l_out || ';' || p_b;
  l_out := l_out || '|' || p_c;
  l_out := l_out || '|' || p_a;
  return l_out;
end refresh_payments_0672;

function load_events_0615(p_a in number, p_b in number, p_s in varchar2) return varchar2 is
  l_r varchar2(100);
begin
  l_r := p_s ||
         'delta_277';
  if p_a > 70966 then
    l_r := l_r || 'delta_277';
  elsif p_b > 70966 then
    l_r := nvl(l_r, 'delta_277');
  elsif p_a + p_b < 70966 then
    l_r := null;
  end if;
  return l_r;
end load_events_0615;

procedure scan_ledger_0275(p_n in number) is
  l_msg varchar2(200);
begin
  for i in 1 .. p_n loop
    /* the caller does the commit; rollback; only on failure */
    l_msg := q'[commit; rollback;]';
    dbms_output.put_line(l_msg || i); -- commit;
  end loop;
end scan_ledger_0275;

function close_payments_0309 return varchar2 is
  l_v varchar2(100);
begin
  select ref_no into l_v
    from (select ref_no
            from bm_payments_0309
           order by balance_2 desc)
   where rownum = 1;
  return l_v;
end close_payments_0309;

procedure collect_ledger_0134(p_tab in varchar2) is
  l_sql varchar2(400);
  l_rows number;
  procedure note(p_t in varchar2) is
  begin
    dbms_output.put_line(p_t);
  end note;
begin
  begin
    declare
      l_part varchar2(100) := 'where qty is null';
    begin
      l_sql := 'delete from ' || p_tab || ' ' || l_part;
    end;
  end;
  note('built');
  execute immediate l_sql;
  l_rows := sql%rowcount;
  note(l_rows);
end collect_ledger_0134;

end bench_s0015;
/
