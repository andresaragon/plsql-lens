




create or replace package body inv_transfer_mgmt as

  procedure transfer_stock_items(p_from in number, p_to in number, p_sku in varchar2) is
  begin
    update stock set warehouse_id = p_to where warehouse_id = p_from and sku = p_sku;
  exception
    when others then
      null;
  end transfer_stock_items;

  procedure log_inventory_adjustment(p_sku in varchar2, p_qty in number) is
  begin
    update stock set qty = qty + p_qty where sku = p_sku;
  exception
    when others then
      log_pkg.log_msg(sqlerrm);
      raise;
  end log_inventory_adjustment;

end inv_transfer_mgmt;
/
