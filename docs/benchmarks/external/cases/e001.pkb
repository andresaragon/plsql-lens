-- case: e001
-- domain: library loans
-- difficulty: easy
-- note: basic overdue loans processing with exception swallowing and unhandled select into
-- author: gemini-3.8-flash-high via agy (not human-written)
create or replace package body lib_loan_ops as

  procedure check_out_book(p_loan_id in number) is
    l_member_id number;
  begin
    select member_id into l_member_id from loans where loan_id = p_loan_id; -- expect: PLL004
    update loans set status = 'BORROWED' where loan_id = p_loan_id;
    commit; -- clean: PLL003
  end check_out_book;

  procedure log_loan_issue(p_loan_id in number) is
  begin
    for r in (select loan_id from loans where loan_id = p_loan_id) loop
      commit; -- expect: PLL003
    end loop;
  exception
    when others then -- expect: PLL001
      null;
  end log_loan_issue;

end lib_loan_ops;
/
