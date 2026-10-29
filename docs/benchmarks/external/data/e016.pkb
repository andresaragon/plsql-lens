




create or replace package body inv_audit_ops as

  procedure audit_warehouse_stock(p_warehouse_id in number) is
  begin
    for r in (select sku, qty from stock where warehouse_id = p_warehouse_id) loop
      rollback;
    end loop;
    insert into inventory_log(action) values ('AUDIT_DONE');
  end audit_warehouse_stock;

  procedure generate_stock_alerts(p_warehouse_id in number) is
  begin
    for r in (select sku from stock where warehouse_id = p_warehouse_id and qty < 5) loop
      insert into stock_alerts(sku, alert_date) values (r.sku, sysdate);
    end loop;
  end generate_stock_alerts;

end inv_audit_ops;
/
