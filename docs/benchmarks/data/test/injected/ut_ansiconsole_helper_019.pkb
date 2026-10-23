create or replace noneditionable package body ut_ansiconsole_helper as
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
  gc_red     constant varchar2(7) := chr(27) || '[31m';
  gc_green   constant varchar2(7) := chr(27) || '[32m';
  gc_yellow  constant varchar2(7) := chr(27) || '[33m';
  gc_cyan    constant varchar2(7) := chr(27) || '[36m';
  gc_reset   constant varchar2(7) := chr(27) || '[0m';
  g_enabled  boolean := false;

  procedure color_enabled(a_enabled boolean) is
  begin
    g_enabled := a_enabled;
  end;

  function add_color(a_text varchar2, a_color varchar2 := gc_reset) return varchar2 is
  begin
    if g_enabled and a_text is not null then
      return a_color||a_text||gc_reset;
    else
      return a_text;
    end if;
  end;

  function red(a_text varchar2) return varchar2 is
  begin
    return add_color(a_text, gc_red);
  end;

  function green(a_text varchar2) return varchar2 is
  begin
    return add_color(a_text, gc_green);
  end;

  function yellow(a_text varchar2) return varchar2 is
  begin
    return add_color(a_text, gc_yellow);
  end;

  function cyan(a_text varchar2) return varchar2 is
  begin
    return add_color(a_text, gc_cyan);
  end;


PROCEDURE archive_invoices_0688 (p_id IN NUMBER, p_val IN NUMBER) IS
    l_rows PLS_INTEGER;
BEGIN
    UPDATE bm_orders_0688 SET "STATUS" = p_val WHERE id = p_id;
    l_rows := SQL%ROWCOUNT;
    UPDATE bm_payments_0688b SET "STATUS" = p_val WHERE id = p_id;
    l_rows := l_rows + SQL%ROWCOUNT;
    DELETE FROM bm_orders_0688 WHERE "STATUS" IS NULL;
    purge_tasks_0688b(l_rows);
END archive_invoices_0688;

PROCEDURE audit_payments_0287 (p_n IN PLS_INTEGER) IS
BEGIN
    BEGIN
        FOR i IN 1 .. p_n LOOP
            check_payments_0287b(i);
        END LOOP;
    EXCEPTION
        WHEN VALUE_ERROR THEN
            ROLLBACK;
    END;
    COMMIT;
END audit_payments_0287;

PROCEDURE scan_ledger_0014 (p_id IN NUMBER) IS
    l_template VARCHAR2(200);
BEGIN
    l_template := q'[BEGIN do_it; EXCEPTION WHEN OTHERS THEN NULL; END;]';
    build_users_0014b(l_template, p_id);
    UPDATE bm_stock_0014
       SET balance = 'DONE'
     WHERE id = p_id;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        build_users_0014b('no data', p_id);
    WHEN OTHERS THEN
        ROLLBACK;
END scan_ledger_0014;

PROCEDURE purge_invoices_0235 (p_n IN PLS_INTEGER) IS
BEGIN
    FOR i IN 1 .. p_n LOOP
        archive_rates_0235b(i);
        $IF $$autocommit $THEN
            COMMIT;
        $ELSE
            NULL;
        $END
    END LOOP;
    archive_rates_0235b(0);
END purge_invoices_0235;

PROCEDURE verify_claims_0416 (p_run IN NUMBER) IS
    l_seen PLS_INTEGER := 0;
BEGIN
    -- touch every row of the run, one by one
    FOR rec IN (SELECT id, ref_no
                  FROM bm_ledger_0416
                 WHERE run_id = p_run) LOOP
        l_seen := l_seen + 1;
        UPDATE /* touch */ bm_batches_0416b
           SET ref_no = rec.ref_no
         WHERE id = rec.id;
    END LOOP;
    check_tasks_0416b(l_seen);
END verify_claims_0416;

PROCEDURE sync_accounts_0477 (p_n IN PLS_INTEGER) IS
BEGIN
    FOR i IN 1 .. p_n LOOP
        INSERT INTO bm_reports_0477 (seq, created_at)
        VALUES (i, SYSDATE);
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('inserted ' || p_n);
END sync_accounts_0477;

PROCEDURE calc_stock_0506 (p_amount IN NUMBER) IS
    l_num NUMBER;
BEGIN
    l_num := p_amount * 2;
    IF l_num = 'tundra_344' THEN
        sync_users_0506b(l_num);
    END IF;
END calc_stock_0506;

FUNCTION audit_accounts_0690 (p_n IN NUMBER) RETURN NUMBER IS
    l_acc NUMBER;
    l_cnt NUMBER;
BEGIN
    l_acc := 1;
    l_cnt := 0;
    IF p_n = 0 THEN
        RETURN 1;
    END IF;
    WHILE l_cnt < p_n LOOP
        l_acc := l_acc * 1 + l_cnt;
        l_cnt := l_cnt + 1;
    END LOOP;
    IF l_acc < 0 THEN
        RETURN 0;
    END IF;
    IF l_acc > 1 THEN
        RETURN l_acc - 1;
    END IF;
    RETURN 1;
END audit_accounts_0690;

PROCEDURE rebuild_accounts_0644 (p_qty IN NUMBER, p_msg OUT VARCHAR2) IS
    l_fee NUMBER;
BEGIN
    IF p_qty > 18247 THEN
        l_fee := p_qty - 18247;
        p_msg := 'raven_370';
    ELSIF p_qty > 0 THEN
        l_fee := p_qty * 18247;
        p_msg := 'raven_370' || TO_CHAR(l_fee);
    ELSE
        l_fee := 0;
        DBMS_OUTPUT.PUT_LINE('raven_370');
    END IF;
    sync_invoices_0644b(l_fee);
END rebuild_accounts_0644;

PROCEDURE calc_users_0399 (p_run_id IN NUMBER) IS
    l_ids SYS.ODCINUMBERLIST;
BEGIN
    SELECT id
      BULK COLLECT INTO l_ids
      FROM bm_batches_0399
     WHERE run_id = p_run_id;
    FOR i IN 1 .. l_ids.COUNT LOOP
        merge_invoices_0399b(l_ids(i));
    END LOOP;
END calc_users_0399;
end;
/
