-- case: e017
-- domain: inventory
-- difficulty: medium
-- note: warehouse transfer order with swallowed others exception versus audited error log handler
-- author: gemini-3.8-flash-high via agy (not human-written)
create or replace package body inv_transfer_mgmt as

  procedure transfer_stock_items(p_from in number, p_to in number, p_sku in varchar2) is
  begin
    update stock set warehouse_id = p_to where warehouse_id = p_from and sku = p_sku;
  exception
    when others then -- expect: PLL001
      null;
  end transfer_stock_items;

  procedure log_inventory_adjustment(p_sku in varchar2, p_qty in number) is
  begin
    update stock set qty = qty + p_qty where sku = p_sku;
  exception
    when others then -- clean: PLL001
      log_pkg.log_msg(sqlerrm);
      raise;
  end log_inventory_adjustment;

end inv_transfer_mgmt;
/
