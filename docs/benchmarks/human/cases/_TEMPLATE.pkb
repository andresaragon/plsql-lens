-- case: _TEMPLATE (example only, excluded from scoring)
-- domain: library loans
-- difficulty: medium
-- note: shows each marker once; replace with your own cases (h001.pkb, h002.pkb, ...)
create or replace package body lib_loans as

  procedure close_overdue(p_branch_id in number) is
    l_fee number;
  begin
    for r in (select loan_id, due_date from loans where branch_id = p_branch_id and returned_on is null) loop
      update loans set status = 'OVERDUE' where loan_id = r.loan_id; -- expect: PLL005
      commit; -- expect: PLL003
    end loop;
  exception
    when others then -- expect: PLL001
      null;
  end close_overdue;

  procedure archive_branch(p_table in varchar2, p_branch_id in number) is
  begin
    execute immediate 'delete from ' || dbms_assert.sql_object_name(p_table)
                   || ' where branch_id = :b' using p_branch_id; -- clean: PLL002
  end archive_branch;

  procedure renew_all(p_member_id in number) is
  begin
    for r in (select loan_id from loans where member_id = p_member_id) loop
      savepoint before_renew;
      begin
        renew_one(r.loan_id); -- beyond: PLL003 (renew_one commits)
      exception
        when dup_val_on_index then
          rollback to before_renew; -- clean: PLL003
      end;
    end loop;
  end renew_all;

end lib_loans;
/
