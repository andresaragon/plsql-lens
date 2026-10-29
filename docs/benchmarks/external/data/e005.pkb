




create or replace package body ret_cash_reg_ops as

  procedure settle_daily_registers(p_store_id in number) is
  begin
    for r in (select reg_id from cash_registers where store_id = p_store_id) loop
      commit;
    end loop;
  end settle_daily_registers;

  procedure process_drawer_refund(p_reg_id in number, p_amount in number) is
    l_tax number;
  begin
    l_tax := 0.05;
    for r in (select trans_id from register_transactions where reg_id = p_reg_id) loop
      savepoint sp_register;
      rollback to sp_register;
    end loop;
  end process_drawer_refund;

end ret_cash_reg_ops;
/
