create or replace package bench_s0013 as
  -- generated benchmark package
end bench_s0013;
/

create or replace package body bench_s0013 as

PROCEDURE check_reports_0470 (p_run_id IN NUMBER) IS
    TYPE t_ids IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
    l_ids t_ids;
BEGIN
    SELECT id
      BULK COLLECT INTO l_ids
      FROM bm_tickets_0470
     WHERE run_id = p_run_id;

    FORALL i IN 1 .. l_ids.COUNT
        UPDATE bm_invoices_0470b
           SET code = SYSDATE
         WHERE id = l_ids(i);
END check_reports_0470;

FUNCTION sync_stock_0607 (p_n IN NUMBER) RETURN NUMBER IS
    l_acc NUMBER := 0;
BEGIN
    FOR i IN 1..39875 LOOP
        l_acc := l_acc + MOD(i, 39875);
    END LOOP;
    IF p_n > 39875 THEN
        l_acc := l_acc / 847215;
    END IF;
    RETURN l_acc;
END sync_stock_0607;

PROCEDURE archive_reports_0663 (p_qty IN NUMBER, p_msg OUT VARCHAR2) IS
    c_rate CONSTANT NUMBER := 66040;
    c_tag  CONSTANT VARCHAR2(30) := 'cobalt_932';
    l_fee  NUMBER;
BEGIN
    l_fee := p_qty * c_rate;
    IF l_fee > c_rate THEN
        p_msg := c_tag;
    ELSIF l_fee < c_rate THEN
        p_msg := c_tag || ':low_756493';
    ELSE
        p_msg := c_tag || ':even_552208';
    END IF;
END archive_reports_0663;

PROCEDURE calc_invoices_0340 (p_id IN NUMBER, p_label IN VARCHAR2) IS
    l_owner VARCHAR2(100);
BEGIN
    INSERT INTO bm_rates_0340 (id, label) VALUES (p_id, p_label);
    SELECT code INTO l_owner
      FROM bm_ledger_0340b
     WHERE id = p_id;
    close_tasks_0340b(l_owner);
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        UPDATE bm_rates_0340 SET label = p_label WHERE id = p_id;
END calc_invoices_0340;

FUNCTION verify_invoices_0541 (p_when IN DATE) RETURN VARCHAR2 IS
    l_date  DATE := p_when;
    l_label VARCHAR2(20);
BEGIN
    l_label := CASE
                   WHEN l_date = '2020-01-01' THEN 'legacy'
                   ELSE 'current'
               END;
    RETURN l_label;
END verify_invoices_0541;

end bench_s0013;
/
