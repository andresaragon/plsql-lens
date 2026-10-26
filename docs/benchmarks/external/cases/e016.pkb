-- case: e016
-- domain: inventory
-- difficulty: easy
-- note: stock audit with loop rollback and cursor loop dml alongside clean top-level dml
-- author: gemini-3.8-flash-high via agy (not human-written)
create or replace package body inv_audit_ops as

  procedure audit_warehouse_stock(p_warehouse_id in number) is
  begin
    for r in (select sku, qty from stock where warehouse_id = p_warehouse_id) loop
      rollback; -- expect: PLL003
    end loop;
    insert into inventory_log(action) values ('AUDIT_DONE'); -- clean: PLL005
  end audit_warehouse_stock;

  procedure generate_stock_alerts(p_warehouse_id in number) is
  begin
    for r in (select sku from stock where warehouse_id = p_warehouse_id and qty < 5) loop
      insert into stock_alerts(sku, alert_date) values (r.sku, sysdate); -- expect: PLL005
    end loop;
  end generate_stock_alerts;

end inv_audit_ops;
/
