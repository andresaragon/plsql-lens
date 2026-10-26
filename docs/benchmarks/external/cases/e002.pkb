-- case: e002
-- domain: library loans
-- difficulty: medium
-- note: book reservation batch where helper executes commit inside loop and proper logging is used
-- author: gemini-3.8-flash-high via agy (not human-written)
create or replace package body lib_reserve_mgmt as

  procedure close_lost_loan(p_loan_id in number) is
  begin
    update loans set status = 'LOST' where loan_id = p_loan_id;
    commit;
  exception
    when others then -- clean: PLL001
      logger.log_error(sqlerrm);
      raise;
  end close_lost_loan;

  procedure process_hold_queue(p_book_id in number) is
    l_max_borrow number;
  begin
    l_max_borrow := 5; -- clean: PLL007
    for r in (select hold_id from book_holds where book_id = p_book_id) loop
      notify_member_reservation(r.hold_id); -- beyond: PLL003 (procedure called inside loop executes commit)
    end loop;
  end process_hold_queue;

end lib_reserve_mgmt;
/
