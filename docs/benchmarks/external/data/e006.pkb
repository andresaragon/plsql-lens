




create or replace package body ret_promo_eval as

  procedure reconcile_inventory_shift(p_store_id in number) is
  begin
    update store_shifts set closed = 1 where store_id = p_store_id;
  exception
    when others then
      audit_pkg.record(sqlcode, sqlerrm);
      raise;
  end reconcile_inventory_shift;

  function build_promo_query(p_code in varchar2) return varchar2 is
  begin
    return 'select count(*) from active_promos where code = ''' || p_code || '''';
  end build_promo_query;

  procedure evaluate_promo_discount(p_code in varchar2, p_out out number) is
  begin
    execute immediate build_promo_query(p_code) into p_out;
  end evaluate_promo_discount;

end ret_promo_eval;
/
