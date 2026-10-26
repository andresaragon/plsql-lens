-- case: e004
-- domain: retail store
-- difficulty: easy
-- note: bulk discount update in cursor loop alongside simple type comparison mismatch
-- author: gemini-3.8-flash-high via agy (not human-written)
create or replace package body ret_discount_calc as

  procedure apply_bulk_discount(p_category_id in number, p_pct in number) is
  begin
    for r in (select item_id from store_items where category_id = p_category_id) loop
      update store_items set discount_pct = p_pct where item_id = r.item_id; -- expect: PLL005
    end loop;
  end apply_bulk_discount;

  procedure verify_store_code(p_store_id in number) is
  begin
    if p_store_id = '101' then -- expect: PLL006
      update store_metrics set flagged = 1 where store_id = p_store_id;
    end if;
  end verify_store_code;

  procedure check_valid_store(p_store_id in number) is
  begin
    if p_store_id = 101 then -- clean: PLL006
      update store_metrics set valid = 1 where store_id = p_store_id;
    end if;
  end check_valid_store;

end ret_discount_calc;
/
