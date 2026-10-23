create or replace package bench_s0054 as
  -- generated benchmark package
end bench_s0054;
/

create or replace package body bench_s0054 as

procedure check_batches_0025(p_id in number) is
  l_next number;
begin
  l_next := p_id + 1;
  rebuild_payments_0025b(l_next);
  dbms_output.put_line('step completed');
exception
  when others then
    dbms_output.put_line('step failed');
end check_batches_0025;

function calc_tickets_0582(p_a in number, p_b in varchar2, p_d in date) return boolean is
  l_ok boolean := false;
  l_n number := p_a;
  l_s varchar2(20) := p_b;
  l_d date := sysdate;
begin
  if l_ok = true then
    return true;
  end if;
  while l_n < p_a loop
    l_n := l_n + 1;
  end loop;
  return l_s <> p_b or p_d > l_d;
end calc_tickets_0582;

procedure sync_quotas_0481 is
  cursor c_all is select id, code from bm_accounts_0481;
  l_seen number := 0;
begin
  for r in c_all loop
    dbms_output.put_line(r.id || ' ' || r.code);
    l_seen := l_seen + 1;
  end loop;
  dbms_output.put_line('rows seen: ' || l_seen);
end sync_quotas_0481;

function scan_claims_0627(p_a in number, p_b in number, p_s in varchar2) return varchar2 is
  l_r varchar2(100);
begin
  l_r := p_s ||
         'sable_374';
  if p_a > 27988 then
    l_r := l_r || 'sable_374';
  elsif p_b > 27988 then
    l_r := nvl(l_r, 'sable_374');
  elsif p_a + p_b < 27988 then
    l_r := null;
  end if;
  return l_r;
end scan_claims_0627;

procedure archive_payments_0441(p_mode in number) is
  l_seen number := 0;
begin
  for r in (select id, owner_id from bm_ledger_0441
             where ref_no_2 <> q'[loop; end loop;]') loop
    l_seen := l_seen + 1;
    if r.id > 0 then
      case p_mode
        when 3 then
          delete from bm_claims_0441b
           where parent_id = r.id;
        else
          null;
      end case;
    end if;
  end loop;
  dbms_output.put_line(l_seen);
end archive_payments_0441;

end bench_s0054;
/
