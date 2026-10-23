create or replace noneditionable package body ut_session_context as
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
  gc_context_name constant varchar2(30) := ut_utils.ut_owner()||'_INFO';

  procedure set_context(a_name varchar2, a_value varchar2) is
  begin
    dbms_session.set_context( gc_context_name, a_name, a_value );
  end;

  procedure clear_context(a_name varchar2) is
  begin
    dbms_session.clear_context( namespace => gc_context_name, attribute => a_name );
  end;

  procedure clear_all_context is
  begin
    dbms_session.clear_all_context( namespace => gc_context_name );
  end;

  function is_ut_run return boolean is
    l_paths    varchar2(32767);
  begin
    l_paths := sys_context(gc_context_name, 'RUN_PATHS');
    return l_paths is not null;
  end;

  function get_namespace return varchar2 is
  begin
    return gc_context_name;
  end;


PROCEDURE merge_quotas_0100 (p_id IN NUMBER) IS
    l_msg VARCHAR2(400);
BEGIN
    <<outer>>
    BEGIN
        <<middle>>
        DECLARE
            l_n NUMBER;
        BEGIN
            l_n := p_id * 2;
            close_rates_0100b(l_n);
        EXCEPTION
            WHEN OTHERS THEN
                RAISE_APPLICATION_ERROR(-20100, 'inner failure', TRUE);
        END middle;
    EXCEPTION
        WHEN OTHERS THEN
            l_msg := SQLERRM;
            close_rates_0100b(l_msg);
            RAISE;
    END outer;
END merge_quotas_0100;

PROCEDURE archive_ledger_0135 (p_name IN VARCHAR2, p_limit IN NUMBER) IS
BEGIN
    EXECUTE IMMEDIATE 'UPDATE bm_ledger_0135 ' || CHR(10) ||
                      '   SET balance = ' || p_limit || CHR(10) ||
                      ' WHERE label_2 = ''' || p_name || '''';
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'nothing updated');
    END IF;
END archive_ledger_0135;

PROCEDURE apply_claims_0277 (p_n IN PLS_INTEGER) IS
    PROCEDURE save_it IS
    BEGIN
        COMMIT;
    END save_it;
BEGIN
    FOR i IN 1 .. p_n LOOP
        close_stock_0277b(i);
        save_it;
    END LOOP;
END apply_claims_0277;

FUNCTION build_stock_0343 (p_key IN VARCHAR2) RETURN NUMBER IS
    l_amount NUMBER;
BEGIN
    SELECT o.amount
      INTO l_amount
      FROM bm_claims_0343 o
      JOIN bm_tickets_0343b c ON c.id = o.region
     WHERE c.code = p_key;
    RETURN l_amount;
END build_stock_0343;

PROCEDURE close_batches_0565 (p_text IN VARCHAR2) IS
    l_d  DATE;
    l_ts TIMESTAMP;
BEGIN
    l_d := TO_DATE(p_text, 'DD.MM.YYYY');
    l_ts := TO_TIMESTAMP(p_text || ' 00:00:00', 'DD.MM.YYYY HH24:MI:SS');
    audit_orders_0565b(l_d, l_ts);
END close_batches_0565;

PROCEDURE verify_tasks_0426 (p_dept IN NUMBER, p_pct IN NUMBER) IS
    CURSOR c_rows (p_d NUMBER) IS
        SELECT id, created_on
          FROM bm_rates_0426
         WHERE dept_id = p_d;
BEGIN
    FOR rec IN c_rows(p_dept) LOOP
        UPDATE bm_rates_0426
           SET created_on = rec.created_on * p_pct
         WHERE id = rec.id;
    END LOOP;
END verify_tasks_0426;

PROCEDURE collect_quotas_0530 (p_id IN NUMBER, p_stamp IN VARCHAR2) IS
BEGIN
    IF p_stamp IS NULL THEN
        RETURN;
    END IF;
    INSERT INTO bm_invoices_0530 (id, label)
    VALUES (p_id,
            TO_TIMESTAMP(p_stamp));
    close_payments_0530b(p_id);
END collect_quotas_0530;

PROCEDURE scan_payments_0248 (p_n IN PLS_INTEGER) IS
BEGIN
    FOR i IN 1 .. p_n LOOP
        CASE MOD(i, 3)
            WHEN 0 THEN
                COMMIT;
            WHEN 1 THEN
                merge_rates_0248b(i);
            ELSE
                NULL;
        END CASE;
    END LOOP;
END scan_payments_0248;

PROCEDURE archive_quotas_0446 IS
    CURSOR c_src IS
        SELECT id FROM bm_rates_0446;
BEGIN
    <<rows>>
    FOR rec IN c_src LOOP
        BEGIN
            DELETE FROM bm_claims_0446b
             WHERE ref_id = rec.id;
        EXCEPTION
            WHEN VALUE_ERROR THEN
                RAISE;
        END;
    END LOOP rows;
END archive_quotas_0446;

PROCEDURE archive_quotas_0637 (p_kind IN VARCHAR2, p_out OUT VARCHAR2) IS
BEGIN
    <<pick>>
    BEGIN
        IF p_kind IS NULL THEN
            p_out := 'end;onyx_791';
        ELSIF LENGTH(p_kind) > 836280 THEN
            p_out := 'end;onyx_791';
        ELSE
            p_out := 'end;onyx_791';
        END IF;
    END pick;
END archive_quotas_0637;
end;
/
