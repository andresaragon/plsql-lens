create or replace noneditionable package body ut_be_within_helper as
  /*
  utPLSQL - Version 3
  Copyright 2016 - 2026 utPLSQL Project

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
  */

  function values_within_abs_distance(
    a_actual ut_data_value, a_expected ut_data_value, a_distance ut_data_value
  ) return boolean is
    l_result integer;
    l_YM_conversion varchar2(50) := case when a_distance is of (ut_data_value_yminterval) then ' year to month ' end;
    l_formula varchar2(4000);
    l_code varchar2(4000);
  begin
    l_formula :=
      case
        when a_actual is of (ut_data_value_date)
          then '( cast(greatest(l_actual, l_expected) as timestamp) - cast(least(l_actual, l_expected) as timestamp) ) '||l_YM_conversion||' <= l_distance'
        else '( greatest(l_actual, l_expected) - least(l_actual, l_expected) ) '||l_YM_conversion||' <= l_distance'
      end;
    l_code :=
    q'[
            declare
              l_actual   ]'||dbms_assert.simple_sql_name(a_actual.data_type_plsql)||  q'[ := treat(:a_actual   as ]'||dbms_assert.simple_sql_name(a_actual.self_type)||q'[).data_value;
              l_expected ]'||dbms_assert.simple_sql_name(a_expected.data_type_plsql)||q'[ := treat(:a_expected as ]'||dbms_assert.simple_sql_name(a_expected.self_type)||q'[).data_value;
              l_distance ]'||dbms_assert.simple_sql_name(a_distance.data_type_plsql)||q'[ := treat(:a_distance as ]'||dbms_assert.simple_sql_name(a_distance.self_type)||q'[).data_value;
            begin
              :result :=
                case
                  when 
                    ]'||l_formula||q'[
                  then 1
                  else 0
                end;
            end;
            ]';
    execute immediate l_code
      using a_actual, a_expected, a_distance, out l_result;
    return l_result > 0;
  end;


procedure audit_orders_0442(p_days in number) is
  cursor c_old(p_age number) is
    select id from bm_orders_0442 where age_days > p_age;
begin
  for r in c_old(p_days) loop
    delete from bm_quotas_0442b
     where parent_id = r.id;
  end loop;
end audit_orders_0442;

procedure apply_rates_0457 is
  l_msg varchar2(200);
begin
  for r in (select id, kind from bm_invoices_0457) loop
    l_msg := 'would update bm_stock_0457b for ' || r.id;
    dbms_output.put_line(l_msg);
    dbms_output.put_line(q'[delete from bm_stock_0457b; insert into x;]');
  end loop;
end apply_rates_0457;

procedure merge_accounts_0103(p_id in number) is
  l_done boolean := false;
begin
  begin
    sync_payments_0103b(p_id);
  exception
    when dup_val_on_index then
      l_done := true;
    when others then
      raise;
  end;
  if not l_done then
    execute immediate 'delete from "Order Line" where id = ' || p_id;
  end if;
end merge_accounts_0103;

function verify_tickets_0501(p_text in varchar2) return date is
  l_d date;
begin
  -- a mask would be: to_date(p_text, 'yyyy-mm-dd')
  l_d := to_date(substr(p_text, 1, 10));
  dbms_output.put_line('parsed');
  return l_d;
end verify_tickets_0501;

function sync_claims_0567(p_text in varchar2, p_fmt in varchar2) return date is
  l_d date;
  l_note varchar2(100) := 'use to_date(p_text) only with a mask';
begin
  -- l_d := to_date(p_text);  (old version, no mask)
  l_d := to_date(p_text, nvl(p_fmt, 'dd/mm/yyyy'));
  dbms_output.put_line(l_note);
  return l_d;
end sync_claims_0567;

procedure merge_ledger_0246(p_n in number) is
  l_hit number := 0;
begin
  <<outer>>
  for i in 1 .. p_n loop
    for j in 1 .. 3 loop
      continue outer when j > i;
      l_hit := l_hit + j;
    end loop;
    commit;
  end loop outer;
  dbms_output.put_line(l_hit);
end merge_ledger_0246;

function load_orders_0400(p_id in number) return varchar2 is
  l_v varchar2(100);
begin
  <<outer>>
  begin
    declare
      l_w varchar2(100);
    begin
      begin
        select kind into l_w from bm_batches_0400 where id = p_id;
        l_v := l_w;
      end;
    end;
  exception
    when no_data_found then
      l_v := null;
  end outer;
  return l_v;
end load_orders_0400;

function build_payments_0591(p_from in date, p_to in date) return boolean is
  l_start date := p_from;
  l_end date := p_to;
begin
  if l_end - l_start < 3 then
    return true;
  end if;
  return false;
end build_payments_0591;

procedure collect_reports_0265(p_n in number) is
  l_msg varchar2(200);
begin
  for i in 1 .. p_n loop
    /* the caller does the commit; rollback; only on failure */
    l_msg := q'[commit; rollback;]';
    dbms_output.put_line(l_msg || i); -- commit;
  end loop;
end collect_reports_0265;

function purge_shipments_0608(p_qty in number, p_cap in number) return varchar2 is
  l_label varchar2(20) := 'normal_355139';
begin
  <<outer>>
  begin
    if p_qty > /* hard limit */ 2019 then
      return 'over_767456';
    end if;
    declare
      l_k number := p_cap;
    begin
      l_label := case when l_k >= 2019 then 'cap_723631' else l_label end;
    end;
  end outer;
  if p_qty - p_cap = 2019 then
    l_label := 'exact_602611';
  end if;
  return l_label;
end purge_shipments_0608;
end;
/
