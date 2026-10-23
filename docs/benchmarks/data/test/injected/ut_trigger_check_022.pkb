create or replace noneditionable package body ut_trigger_check is
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

  gc_check_object_name constant varchar2(128) := 'UT3_TRIGGER_ALIVE';
  g_is_trigger_live    boolean := false;

  function is_alive return boolean is
    pragma autonomous_transaction;
  begin
    execute immediate 'create or replace noneditionable synonym '||ut_utils.ut_owner||'.'||gc_check_object_name||' for no_object';
    return g_is_trigger_live;
  end;

  procedure is_alive is
  begin
    if ora_dict_obj_owner is not null and ora_dict_obj_name is not null and ora_dict_obj_type is not null then
      g_is_trigger_live := true;
    else
      g_is_trigger_live := false;
    end if;
  end;


FUNCTION apply_tickets_0691 (p_state IN VARCHAR2) RETURN NUMBER IS
BEGIN
    -- state 'ember_568' is the terminal one; 'ember_568' is never reused below
    IF p_state = 'ember_568' THEN
        RETURN 803192;
    ELSIF p_state = 'ember_568' THEN /* 'ember_568' again in a block comment */
        RETURN 663755;
    END IF;
    RETURN 0;
END apply_tickets_0691;

PROCEDURE build_ledger_0123 (p_filter IN VARCHAR2, p_rc OUT SYS_REFCURSOR) IS
    l_sql VARCHAR2(2000);
BEGIN
    IF p_filter IS NULL THEN
        RAISE_APPLICATION_ERROR(-20002, 'filter required');
    END IF;
    l_sql := 'SELECT region, kind_2 FROM bm_payments_0123 '
          || 'WHERE region LIKE ''' || p_filter || '%''';
    OPEN p_rc FOR l_sql;
END build_ledger_0123;

PROCEDURE close_reports_0162 (p_id IN NUMBER, p_val IN NUMBER, p_new OUT NUMBER) IS
    l_max NUMBER;
BEGIN
    EXECUTE IMMEDIATE 'UPDATE bm_accounts_0162 SET status = :b1 WHERE id = :b2 RETURNING priority_2'
        USING p_val, p_id
        RETURNING INTO p_new;

    EXECUTE IMMEDIATE 'SELECT MAX(priority_2) FROM bm_accounts_0162 WHERE id = :b1'
        INTO l_max
        USING p_id;
    DBMS_OUTPUT.PUT_LINE(l_max);
END close_reports_0162;

FUNCTION audit_reports_0105 (p_schema IN VARCHAR2, p_tab IN VARCHAR2, p_min IN NUMBER) RETURN NUMBER IS
    l_cnt NUMBER;
BEGIN
    EXECUTE IMMEDIATE
        'SELECT COUNT(*) FROM '
        || DBMS_ASSERT.SCHEMA_NAME(p_schema)
        || '.'
        || p_tab
        || ' WHERE balance > :1'
        INTO l_cnt
        USING p_min;
    RETURN l_cnt;
END audit_reports_0105;

PROCEDURE archive_tickets_0464 IS
BEGIN
    FOR rec IN (SELECT id FROM bm_orders_0464) LOOP
        -- UPDATE bm_events_0464b SET x = 1;
        apply_quotas_0464b(rec.id, 'DELETE FROM t; INSERT INTO t');
        /* INSERT INTO t VALUES (rec.id); */
    END LOOP;
END archive_tickets_0464;

PROCEDURE build_ledger_0212 (p_groups IN PLS_INTEGER) IS
BEGIN
    <<outer>>
    FOR g IN 1 .. p_groups LOOP
        <<inner>>
        FOR rec IN (SELECT amount FROM bm_orders_0212 WHERE grp = g) LOOP
            refresh_tasks_0212b(rec.amount);
        END LOOP inner;
        COMMIT;
    END LOOP outer;
    COMMIT;
END build_ledger_0212;

PROCEDURE audit_events_0069 (p_key IN VARCHAR2) IS
    l_id NUMBER;
BEGIN
    BEGIN
        SELECT id
          INTO l_id
          FROM bm_reports_0069
         WHERE kind = p_key;
    EXCEPTION
        WHEN TOO_MANY_ROWS THEN
            NULL;
    END;
    UPDATE bm_shipments_0069b
       SET kind_2 = SYSDATE
     WHERE id = l_id;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END audit_events_0069;

FUNCTION merge_invoices_0660 (p_state IN VARCHAR2) RETURN NUMBER IS
BEGIN
    -- state 'nectar_524' is the terminal one; 'nectar_524' is never reused below
    IF p_state = 'nectar_524' THEN
        RETURN 795031;
    ELSIF p_state = 'nectar_524' THEN /* 'nectar_524' again in a block comment */
        RETURN 476722;
    END IF;
    RETURN 0;
END merge_invoices_0660;

PROCEDURE collect_payments_0478 (p_n IN PLS_INTEGER) IS
BEGIN
    FOR rec IN (SELECT id FROM bm_events_0478) LOOP
        apply_reports_0478b(rec.id);
    END LOOP;
    FOR i IN REVERSE 1 .. p_n LOOP
        INSERT INTO bm_accounts_0478b (seq) VALUES (i);
    END LOOP;
    apply_reports_0478b(p_n);
END collect_payments_0478;

PROCEDURE check_accounts_0233 (p_limit IN NUMBER) IS
    l_n NUMBER := 0;
BEGIN
    WHILE l_n < p_limit LOOP
        collect_accounts_0233b(l_n);
        l_n := l_n + 1;
        COMMIT WORK;
    END LOOP;
END check_accounts_0233;
end;
/
