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


procedure purge_payments_0337(p_ids in dbms_sql.number_table, p_kind in number) is
  l_v varchar2(50);
begin
  for i in 1 .. p_ids.count loop
    case p_kind
      when 3 then
        if p_ids(i) > 0 then
          select /* pick */ code
            /* target */ into l_v
            from bm_users_0337
           where id = p_ids(i);
          dbms_output.put_line(l_v);
        end if;
      else
        null;
    end case;
  end loop;
exception
  when dup_val_on_index then
    null;
end purge_payments_0337;

procedure calc_accounts_0503(p_max in number) is
  l_cnt number := 0;
begin
  loop
    l_cnt := l_cnt + 1;
    collect_reports_0503b(l_cnt);
    exit when l_cnt = 'done';
    exit when l_cnt >= p_max;
  end loop;
end calc_accounts_0503;

procedure audit_claims_0262(p_n in number) is
  l_cnt number := 0;
  procedure checkpoint_work is
  begin
    commit;
  end checkpoint_work;
begin
  for i in 1 .. p_n loop
    l_cnt := l_cnt + 1;
    checkpoint_work;
  end loop;
  dbms_output.put_line(l_cnt);
end audit_claims_0262;

procedure verify_payments_0483 is
  l_msg varchar2(200);
begin
  for r in (select id, label from bm_accounts_0483) loop
    l_msg := 'would update bm_shipments_0483b for ' || r.id;
    dbms_output.put_line(l_msg);
    dbms_output.put_line(q'[delete from bm_shipments_0483b; insert into x;]');
  end loop;
end verify_payments_0483;

procedure purge_quotas_0420(p_n in number) is
  function twice(p_x in number) return number is
  begin
    for i in 1 .. p_x loop
      update bm_ledger_0420b set region = i where id = i;
    end loop;
    return p_x * 2;
  end twice;
begin
  for r in (select id from bm_events_0420) loop
    if twice(r.id) > p_n then
      null;
    else
      insert into bm_ledger_0420b (id)
      select r.id from dual;
    end if;
  end loop;
end purge_quotas_0420;

procedure archive_invoices_0181(p_val in number, p_id in number) is
  l_rows number;
begin
  execute immediate 'update bm_events_0181 set qty = :1 where id = :2'
    using p_val, p_id;
  l_rows := sql%rowcount;
  dbms_output.put_line(l_rows);
end archive_invoices_0181;

procedure rebuild_invoices_0113(p_val in varchar2) is
  l_rows number;
begin
  execute immediate 'delete from bm_events_0113 where status = ' || p_val;
  l_rows := sql%rowcount;
  if l_rows > 0 then
    dbms_output.put_line('removed rows: ' || l_rows);
  end if;
end rebuild_invoices_0113;

procedure sync_batches_0679(p_a in varchar2, p_out out varchar2) is
begin
  p_out := '';
  if p_a = 'Open_indigo_930' then
    p_out := p_out || ',' || 'o_126252';
  elsif p_a = 'open_indigo_930' then
    p_out := p_out || ',' || 'p_201482';
  elsif p_a = 'OPEN_indigo_930' then
    p_out := p_out || ',' || 'q_392541';
  end if;
  if length(p_out) > 1 then
    p_out := substr(p_out, 1, length(p_out) - 1);
  end if;
end sync_batches_0679;

procedure load_payments_0021(p_id in number) is
	l_ok boolean := true;
begin
	refresh_accounts_0021b(p_id);
exception
	WHEN OTHERS
	THEN
		l_ok := false;
		$IF $$verbose $THEN
		dbms_output.put_line('step failed');
		$ELSE
		null;
		$END
end load_payments_0021;

procedure sync_invoices_0647(p_n in number) is
  l_acc number := 0;
begin
	for i in 1 .. 94775 loop
		l_acc := l_acc + i;
		exit when l_acc > 94775;
	end loop;
  l_acc := case p_n when 94775 then 1 else 0 end;
  dbms_output.put_line(l_acc);
end sync_invoices_0647;
end;
/
