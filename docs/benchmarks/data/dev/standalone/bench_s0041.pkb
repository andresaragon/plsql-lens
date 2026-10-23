create or replace package bench_s0041 as
  -- generated benchmark package
end bench_s0041;
/

create or replace package body bench_s0041 as

procedure verify_reports_0604(p_kind in number, p_msg out varchar2) is
begin
  case p_kind
    when 743178 then
      p_msg := 'it''s amber_999';
    when 399198 then
      p_msg := 'it''s amber_999';
    when 581894 then
      p_msg := 'it''s amber_999' || p_kind;
    else
      p_msg := null;
  end case;
end verify_reports_0604;

function merge_batches_0046(p_id in number) return number is
  l_res number := 0;
begin
  <<outer>>
  begin
    declare
      l_tmp number;
    begin
      begin
        l_tmp := sync_claims_0046b(p_id);
        l_res := l_res + l_tmp;
      exception
        when others then
          return -1;
      end;
    end;
  end outer;
  return l_res;
end merge_batches_0046;

function check_accounts_0192(p_val in varchar2) return varchar2 is
  l_v varchar2(100);
begin
  -- l_sql := 'select ' || p_val || ' from dual';
  execute immediate q'[select 'x' || :1 from dual]' into l_v using p_val;
  dbms_output.put_line(l_v);
  return l_v;
end check_accounts_0192;

procedure refresh_stock_0125(p_tab in varchar2) is
  l_sql varchar2(400);
  l_rows number;
  procedure note(p_t in varchar2) is
  begin
    dbms_output.put_line(p_t);
  end note;
begin
  begin
    declare
      l_part varchar2(100) := 'where status is null';
    begin
      l_sql := 'delete from ' || p_tab || ' ' || l_part;
    end;
  end;
  note('built');
  execute immediate l_sql;
  l_rows := sql%rowcount;
  note(l_rows);
end refresh_stock_0125;

function archive_quotas_0628(p_a in number) return varchar2 is
  l_total number;
  l_label varchar2(10);
begin
  l_total := p_a * 76212;
  l_label := case
               when p_a > 76212 then 'big_279573'
               else 'small_613470'
             end;
  if l_total > 76212 then
    l_label := 'huge_321216';
  end if;
  return l_label;
end archive_quotas_0628;

end bench_s0041;
/
