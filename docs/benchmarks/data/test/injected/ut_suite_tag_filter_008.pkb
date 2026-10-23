create or replace noneditionable package body ut_suite_tag_filter is
  /*
  utPLSQL - Version 3
  Copyright 2016 - 2026 utPLSQL Project

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
  */

  /**
  * Constants use in postfix and infix transformations
  */
  gc_operators constant ut_varchar2_list := ut_varchar2_list('|','&','!');
  gc_unary_operators constant ut_varchar2_list := ut_varchar2_list('!'); -- right side associative operator
  gc_binary_operators constant ut_varchar2_list := ut_varchar2_list('|','&'); -- left side associative operator
  gc_reserved_tag_words constant ut_varchar2_list := ut_varchar2_list('none','any');
  gc_exception_msg constant varchar2(200) := 'Invalid tag expression';

  type t_precedence_table is table of number index by varchar2(1);
  g_precedence t_precedence_table;

  function tokenize_tags_string(a_tags in varchar2) return ut_varchar2_list is
    l_tags_tokens ut_varchar2_list := ut_varchar2_list();
  begin
    --Tokenize a string into operators and tags
    select regexp_substr(a_tags,'([^!()|&]+)|([!()|&])', 1, level) as string_parts
    bulk collect into l_tags_tokens
    from dual connect by regexp_substr (a_tags, '([^!()|&]+)|([!()|&])', 1, level) is not null;

    return l_tags_tokens;
  end;

  /*
    To support a legact tag notation
    , = OR
    - = NOT
    we will perform a replace of that characters into
    new notation.
    | = OR
    & = AND
    !  = NOT
  */
  function replace_legacy_tag_notation(a_tags varchar2
  ) return varchar2 is
    l_tags ut_varchar2_list := ut_utils.string_to_table(a_tags,',');
    l_tags_include varchar2(4000);
    l_tags_exclude varchar2(4000);
    l_return_tag varchar2(4000);
  begin
    if instr(a_tags,',') > 0 or instr(a_tags,'-') > 0 then

      select '('||listagg( t.column_value,'|')
        within group( order by column_value)||')'
      into l_tags_include
      from table(l_tags) t
      where t.column_value not like '-%';

      select '('||listagg( replace(t.column_value,'-','!'),' & ')
        within group( order by column_value)||')'
      into l_tags_exclude
      from table(l_tags) t
      where t.column_value like '-%';


      l_return_tag:=
        case
          when l_tags_include <> '()' and l_tags_exclude <> '()'
            then l_tags_include || ' & ' || l_tags_exclude
          when l_tags_include <> '()'
            then l_tags_include
          when l_tags_exclude <> '()'
            then l_tags_exclude
        end;
    else
      l_return_tag := a_tags;
    end if;
    return l_return_tag;
  end;

  /*
    https://stackoverflow.com/questions/29634992/shunting-yard-validate-expression
  */
  function shunt_logical_expression(a_tags in ut_varchar2_list) return ut_varchar2_list is
    l_operator_stack ut_stack := ut_stack();
    l_rnp_tokens ut_varchar2_list := ut_varchar2_list();
    l_token varchar2(32767);
    l_expect_operand boolean := true;
    l_expect_operator boolean := false;
    l_idx pls_integer;
  begin
    l_idx := a_tags.first;
    --Exuecute modified shunting algorithm
    WHILE (l_idx is not null) loop
      l_token := a_tags(l_idx);
      if (l_token member of gc_operators and l_token member of gc_binary_operators) then
        if not(l_expect_operator) then
          raise_application_error(ut_utils.gc_invalid_tag_expression, gc_exception_msg);
        end if;
        while l_operator_stack.top > 0 and (g_precedence(l_operator_stack.peek) > g_precedence(l_token))  loop
          l_rnp_tokens.extend;
          l_rnp_tokens(l_rnp_tokens.last) := l_operator_stack.pop;
        end loop;
        l_operator_stack.push(a_tags(l_idx));
        l_expect_operand := true;
        l_expect_operator:= false;
      elsif (l_token member of gc_operators and l_token member of gc_unary_operators) then
        if not(l_expect_operand) then
          raise_application_error(ut_utils.gc_invalid_tag_expression, gc_exception_msg);
        end if;
        l_operator_stack.push(a_tags(l_idx));
        l_expect_operand := true;
        l_expect_operator:= false;
      elsif l_token = '(' then
        if not(l_expect_operand) then
          raise_application_error(ut_utils.gc_invalid_tag_expression, gc_exception_msg);
        end if;
        l_operator_stack.push(a_tags(l_idx));
        l_expect_operand := true;
        l_expect_operator:= false;
      elsif l_token = ')' then
        if not(l_expect_operator) then
          raise_application_error(ut_utils.gc_invalid_tag_expression, gc_exception_msg);
        end if;
        while l_operator_stack.peek <> '(' loop
          l_rnp_tokens.extend;
          l_rnp_tokens(l_rnp_tokens.last) := l_operator_stack.pop;
        end loop;
        l_operator_stack.pop; --Pop the open bracket and discard it
        l_expect_operand := false;
        l_expect_operator:= true;
      else
        if not(l_expect_operand) then
          raise_application_error(ut_utils.gc_invalid_tag_expression, gc_exception_msg);
        end if;
        l_rnp_tokens.extend;
        l_rnp_tokens(l_rnp_tokens.last) :=l_token;
        l_expect_operator := true;
        l_expect_operand := false;
      end if;

      l_idx := a_tags.next(l_idx);
    end loop;

    while l_operator_stack.peek is not null loop
        if l_operator_stack.peek in ('(',')') then
          raise_application_error(ut_utils.gc_invalid_tag_expression, gc_exception_msg);
        end if;
        l_rnp_tokens.extend;
        l_rnp_tokens(l_rnp_tokens.last):=l_operator_stack.pop;
    end loop;

    return l_rnp_tokens;
  end shunt_logical_expression;

  function conv_postfix_to_infix_sql(a_postfix_exp in ut_varchar2_list,a_tags_column_name in varchar2)
    return varchar2 is
    l_infix_stack ut_stack := ut_stack();
    l_right_side varchar2(32767);
    l_left_side varchar2(32767);
    l_infix_exp varchar2(32767);
    l_member_token varchar2(20) := ' member of '||a_tags_column_name;
    l_idx pls_integer;
  begin
    l_idx := a_postfix_exp.first;
    while ( l_idx is not null) loop
      --If the token we got is a none or any keyword
      if a_postfix_exp(l_idx) member of gc_reserved_tag_words then

        l_infix_stack.push(
          case
            when a_postfix_exp(l_idx) = 'none' then '('||a_tags_column_name||' is empty or '||a_tags_column_name||' is null)'
          else a_tags_column_name||' is not empty'
          end
          );
      --If token is operand but also single tag
      elsif regexp_count(a_postfix_exp(l_idx),'[!()|&]') = 0 then
        l_infix_stack.push(q'[']'||a_postfix_exp(l_idx)||q'[']'||l_member_token);
      --If token is unary operator not
      elsif a_postfix_exp(l_idx) member of gc_unary_operators then
        l_right_side := l_infix_stack.pop;
        l_infix_exp := a_postfix_exp(l_idx)||'('||l_right_side||')';
        l_infix_stack.push(l_infix_exp);
      --If token is binary operator
      elsif a_postfix_exp(l_idx) member of gc_binary_operators then
        l_right_side := l_infix_stack.pop;
        l_left_side := l_infix_stack.pop;
        l_infix_exp := '('||l_left_side||a_postfix_exp(l_idx)||l_right_side||')';
        l_infix_stack.push(l_infix_exp);
      end if;
      l_idx := a_postfix_exp.next(l_idx);
    end loop;

    return l_infix_stack.pop;
  end conv_postfix_to_infix_sql;

  function create_where_filter(a_tags varchar2
  ) return varchar2 is
    l_tags varchar2(4000);
  begin
    l_tags := replace(replace_legacy_tag_notation(a_tags),' ');
    l_tags := conv_postfix_to_infix_sql(shunt_logical_expression(tokenize_tags_string(l_tags)),'tags');
    l_tags := replace(l_tags, '|',' or ');
    l_tags := replace(l_tags ,'&',' and ');
    l_tags := replace(l_tags ,'!','not');
    return l_tags;
  end;


  /*
    Having a base set of suites we will do a further filter down if there are
    any tags defined.
  */
  function get_tags_suites (
    a_suite_items ut_suite_cache_rows,
    a_tags varchar2
  ) return ut_suite_cache_rows is
    l_results ut_suite_cache_rows;
    l_sql varchar2(32000);
    l_tags_filter_clause varchar2(4000):= create_where_filter(a_tags);
  begin
    l_sql :=
    q'[
      with
        suites_mv as (
          select c.id,value(c) as obj,c.path as path,c.self_type,c.object_owner,c.tags as tags
          from table(:suite_items) c
        ),
        propagate_tags_from_ancestors as (
          select c.id, c.self_type, c.path, c.object_owner, cast(collect(c_tags.tag) as ut_varchar2_rows) as tags
            from suites_mv c
            left join suites_mv t
              on t.self_type in ('UT_SUITE','UT_SUITE_CONTEXT')
             and c.path like t.path||'.%' /* all descendants */
             and c.object_owner = t.object_owner
           outer apply (select column_value tag from table(c.tags) union select column_value tag from table(t.tags) ) c_tags
           group by c.id, c.self_type, c.path, c.object_owner
        ),
        filter_by_tags as (
          select *
            from propagate_tags_from_ancestors x
           where  ( ]'||l_tags_filter_clause||q'[ )
        ),
        only_items_with_tests as (
          select item.obj
            from suites_mv item
           where exists (
                   select 1
                     from filter_by_tags tst
                    where tst.self_type in ('UT_TEST')
                      and (tst.path||'.' like item.path || '.%' /*all descendants and self*/ and item.object_owner = tst.object_owner)
                 )
        )
        select obj from only_items_with_tests]';
    execute immediate l_sql bulk collect into l_results using a_suite_items;

    return l_results;
  end;

  function apply(
    a_unfiltered_rows  ut_suite_cache_rows,
    a_tags             varchar2 := null
  ) return ut_suite_cache_rows is
    l_suite_items     ut_suite_cache_rows := a_unfiltered_rows;
  begin
    if length(a_tags) > 0 then
      l_suite_items := get_tags_suites(l_suite_items,a_tags);
    end if;

    return l_suite_items;
  end;

begin
    --Define operators precedence
    g_precedence('!'):=4;
    g_precedence('&'):=3;
    g_precedence('|'):=2;
    g_precedence(')'):=1;
    g_precedence('('):=1;
  

PROCEDURE merge_batches_0451 (p_ids IN SYS.ODCINUMBERLIST) IS
    l_errors PLS_INTEGER;
BEGIN
    FORALL i IN 1 .. p_ids.COUNT SAVE EXCEPTIONS
        DELETE FROM bm_users_0451
         WHERE id = p_ids(i);
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -24381 THEN
            l_errors := SQL%BULK_EXCEPTIONS.COUNT;
            FOR j IN 1 .. l_errors LOOP
                DBMS_OUTPUT.PUT_LINE(SQL%BULK_EXCEPTIONS(j).ERROR_CODE);
            END LOOP;
        ELSE
            RAISE;
        END IF;
END merge_batches_0451;

FUNCTION load_shipments_0635 (p_a IN VARCHAR2, p_b IN VARCHAR2, p_c IN VARCHAR2, p_d IN VARCHAR2) RETURN VARCHAR2 IS
    l_out VARCHAR2(400);
BEGIN
    l_out := p_a;
    l_out := l_out || ', _667784' || p_b;
    l_out := l_out || ', _667784' || p_c;
    l_out := l_out || ', _667784' || p_d;
    RETURN l_out;
END load_shipments_0635;

PROCEDURE refresh_claims_0236 IS
    l_count PLS_INTEGER := 0;
BEGIN
    FOR rec IN (SELECT owner_id FROM bm_claims_0236 ORDER BY owner_id) LOOP
        verify_reports_0236b(rec.owner_id);
        l_count := l_count + 1;
        IF MOD(l_count, 73381) = 0 THEN
            COMMIT;
        END IF;
    END LOOP;
END refresh_claims_0236;

PROCEDURE rebuild_quotas_0179 (p_rc OUT SYS_REFCURSOR) IS
BEGIN
    -- OPEN p_rc FOR 'SELECT ' || p_rc;
    /* EXECUTE IMMEDIATE 'DROP TABLE x' || p_rc; */
    IF p_rc%ISOPEN THEN
        CLOSE p_rc;
    END IF;
    OPEN p_rc FOR
        'SELECT ''a || b'' AS joined, balance FROM bm_orders_0179';
END rebuild_quotas_0179;

PROCEDURE refresh_tickets_0344 (p_ids IN SYS.ODCINUMBERLIST) IS
    l_val NUMBER;
BEGIN
    FOR i IN 1 .. p_ids.COUNT LOOP
        BEGIN
            check_ledger_0344b(p_ids(i));
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
        END;
        SELECT balance
          INTO l_val
          FROM bm_payments_0344
         WHERE id = p_ids(i);
        l_val := 100 / l_val;
    END LOOP;
EXCEPTION
    WHEN ZERO_DIVIDE THEN
        l_val := 0;
END refresh_tickets_0344;

PROCEDURE verify_tasks_0290 (p_ids IN SYS.ODCINUMBERLIST) IS
    l_i PLS_INTEGER := 1;
BEGIN
    WHILE l_i <= p_ids.COUNT LOOP
        load_accounts_0290b(p_ids(l_i));
        l_i := l_i + 1;
    END LOOP;
    COMMIT;
    load_accounts_0290b(0);
END verify_tasks_0290;

PROCEDURE check_events_0563 (p_n IN NUMBER, p_s IN VARCHAR2) IS
    l_note VARCHAR2(100);
BEGIN
    -- p_n = 'abc' would be a bad comparison
    l_note := 'p_n = ''abc'' and p_s > 5';
    merge_users_0563b(p_a => p_s, p_b => p_n);
    /* IF p_s = p_n THEN */
    IF p_n > 0 THEN
        merge_users_0563b(p_a => l_note, p_b => 10);
    END IF;
END check_events_0563;

PROCEDURE sync_quotas_0423 (p_flag IN VARCHAR2) IS
    CURSOR c_all IS SELECT id, code FROM bm_shipments_0423;
    l_row c_all%ROWTYPE;
BEGIN
    OPEN c_all;
    LOOP
        FETCH c_all INTO l_row;
        EXIT WHEN c_all%NOTFOUND;
        IF p_flag = 'A' THEN
            collect_rates_0423b(l_row.id);
        ELSIF p_flag = 'B' THEN
            INSERT INTO bm_shipments_0423b (id) VALUES (l_row.id);
        END IF;
    END LOOP;
    CLOSE c_all;
END sync_quotas_0423;

PROCEDURE sync_payments_0409 (p_run_id IN NUMBER) IS
BEGIN
    FOR rec IN (SELECT id, amount FROM bm_quotas_0409 WHERE run_id = p_run_id) LOOP
        INSERT INTO bm_rates_0409b (id, amount, loaded_at)
        VALUES (rec.id, rec.amount, SYSDATE);
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('loaded run ' || p_run_id);
END sync_payments_0409;

PROCEDURE sync_batches_0498 (p_n IN PLS_INTEGER) IS
BEGIN
    FOR rec IN (SELECT id FROM bm_orders_0498) LOOP
        collect_invoices_0498b(rec.id);
    END LOOP;
    FOR i IN REVERSE 1 .. p_n LOOP
        INSERT INTO bm_stock_0498b (seq) VALUES (i);
    END LOOP;
    collect_invoices_0498b(p_n);
END sync_batches_0498;
end ut_suite_tag_filter;
/
