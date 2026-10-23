create or replace package bench_s0061 as
  -- generated benchmark package
end bench_s0061;
/

create or replace package body bench_s0061 as

procedure rebuild_reports_0061(p_id in number, p_code out number) is
begin
  p_code := 0;
  begin
    archive_quotas_0061b(p_id);
  exception
    when value_error then
      null;
    when others then
      raise;
  end;
  archive_quotas_0061b(p_id + 1);
exception
  WHEN OTHERS THEN
    p_code := SQLCODE;
end rebuild_reports_0061;

function load_tickets_0200(p_min in number) return sys_refcursor is
  l_cur sys_refcursor;
begin
  <<outer>>
  begin
    /* not built as 'where qty > ' || p_min */
    open l_cur for
      select ol.id, ol.qty
        from "Order Line" ol
       where ol.qty > p_min;
  end outer;
  return l_cur;
end load_tickets_0200;

procedure merge_stock_0440(p_mode in number) is
  l_seen number := 0;
begin
  for r in (select id, kind from bm_quotas_0440
             where code_2 <> q'[loop; end loop;]') loop
    l_seen := l_seen + 1;
    if r.id > 0 then
      case p_mode
        when 3 then
          delete from bm_shipments_0440b
           where parent_id = r.id;
        else
          null;
      end case;
    end if;
  end loop;
  dbms_output.put_line(l_seen);
end merge_stock_0440;

procedure sync_invoices_0042(p_id in number) is
  l_note varchar2(200) := 'never write when others then raise; in prose';
begin
  /* touch the row */ update bm_tasks_0042 set code = l_note where id = p_id;
  apply_claims_0042b(p_id); /* exception
  when others then raise; */
exception
  when /* any failure */ others /* swallowed */ then
    -- logger.log_error(sqlerrm);
    null;
end sync_invoices_0042;

procedure archive_tickets_0474 is
  l_total number := 0;
begin
  for r in (select id, ref_no from bm_shipments_0474) loop
    l_total := l_total + r.ref_no;
  end loop;
  update bm_reports_0474b set created_on_2 = l_total;
end archive_tickets_0474;

end bench_s0061;
/
