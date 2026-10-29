




create or replace package body lib_loan_ops as

  procedure check_out_book(p_loan_id in number) is
    l_member_id number;
  begin
    select member_id into l_member_id from loans where loan_id = p_loan_id;
    update loans set status = 'BORROWED' where loan_id = p_loan_id;
    commit;
  end check_out_book;

  procedure log_loan_issue(p_loan_id in number) is
  begin
    for r in (select loan_id from loans where loan_id = p_loan_id) loop
      commit;
    end loop;
  exception
    when others then
      null;
  end log_loan_issue;

end lib_loan_ops;
/
