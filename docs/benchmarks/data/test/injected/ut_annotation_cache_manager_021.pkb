create or replace noneditionable package body ut_annotation_cache_manager as
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

  procedure update_cache(a_object ut_annotated_object) is
    l_cache_id          integer;
    l_timestamp         timestamp := systimestamp;
    pragma autonomous_transaction;
  begin
    update /*+ no_parallel */ ut_annotation_cache_schema s
       set s.max_parse_time = l_timestamp
         where s.object_type = a_object.object_type and s.object_owner = a_object.object_owner;

    if sql%rowcount = 0 then
      insert /*+ no_parallel */ into ut_annotation_cache_schema s
      (object_owner, object_type, max_parse_time)
      values (a_object.object_owner, a_object.object_type, l_timestamp);
    end if;

    -- if not in trigger, or object has annotations
    if a_object.annotations is not null and a_object.annotations.count > 0 then

      update /*+ no_parallel */ ut_annotation_cache_info i
         set i.parse_time = l_timestamp
       where (i.object_owner, i.object_name, i.object_type)
          in ((a_object.object_owner, a_object.object_name, a_object.object_type))
        returning cache_id into l_cache_id;

      if sql%rowcount = 0 then

        insert /*+ no_parallel */ into ut_annotation_cache_info
               (cache_id, object_owner, object_name, object_type, parse_time)
        values (ut_annotation_cache_seq.nextval, a_object.object_owner, a_object.object_name, a_object.object_type, l_timestamp)
          returning cache_id into l_cache_id;
      end if;
    
      delete /*+ no_parallel */ from ut_annotation_cache c where cache_id = l_cache_id;

      insert /*+ no_parallel */ into ut_annotation_cache
             (cache_id, annotation_position, annotation_name, annotation_text, subobject_name)
      select /*+ no_parallel */ l_cache_id, a.position, a.name, a.text, a.subobject_name
        from table(a_object.annotations) a;
    elsif  a_object.annotations is null or a_object.annotations.count = 0 then
      ut_annotation_cache_manager.remove_from_cache(
          ut_annotation_objs_cache_info(
            ut_annotation_obj_cache_info(a_object.object_owner, a_object.object_name, a_object.object_type, 'Y', null)
          )
        );
    end if;
    commit;
  end;


  procedure reset_objects_cache(a_objects ut_annotation_objs_cache_info) is
    l_timestamp         timestamp := systimestamp;
    pragma autonomous_transaction;
  begin

    delete /*+ no_parallel */ from ut_annotation_cache c
     where c.cache_id
        in (select /*+ no_parallel */ i.cache_id
              from ut_annotation_cache_info i
              join table (a_objects) o
                on o.object_name = i.object_name
               and o.object_type = i.object_type
               and o.object_owner = i.object_owner
               and o.needs_refresh = 'Y'
           );

    update /*+ no_parallel */ ut_annotation_cache_schema s
       set s.max_parse_time = l_timestamp
    where (s.object_owner, s.object_type)
      in (
         select /*+ no_parallel */ o.object_owner, o.object_type
           from table(a_objects) o
          where o.needs_refresh = 'Y'
         );

    if sql%rowcount = 0 then
      insert /*+ no_parallel */ into ut_annotation_cache_schema s
      (object_owner, object_type, max_parse_time)
      select /*+ no_parallel */ distinct o.object_owner, o.object_type, l_timestamp
        from table(a_objects) o
       where o.needs_refresh = 'Y';
    end if;

    merge /*+ no_parallel */
      into ut_annotation_cache_info i
      using (select /*+ no_parallel */ o.object_name, o.object_type, o.object_owner
               from table(a_objects) o
              where o.needs_refresh = 'Y'
        ) o
         on (o.object_name = i.object_name
             and o.object_type = i.object_type
             and o.object_owner = i.object_owner)
     when matched then
       update
       set parse_time = l_timestamp
     when not matched then insert
            (cache_id, object_owner, object_name, object_type, parse_time)
     values (ut_annotation_cache_seq.nextval, o.object_owner, o.object_name, o.object_type, l_timestamp);

    commit;
  end;

  function get_cached_objects_list(a_object_owner varchar2, a_object_type varchar2, a_parsed_after timestamp := null) return ut_annotation_objs_cache_info is
    l_result ut_annotation_objs_cache_info;
  begin
      select /*+ no_parallel */ ut_annotation_obj_cache_info(
        object_owner  => i.object_owner,
        object_name   => i.object_name,
        object_type   => i.object_type,
        needs_refresh => 'N',
        parse_time    => i.parse_time
      )
      bulk collect into l_result
      from ut_annotation_cache_info i
      where i.object_owner = a_object_owner
        and i.object_type  = a_object_type
        and (i.parse_time > a_parsed_after or a_parsed_after is null);
    return l_result;
  end;

  function get_cache_schema_info(a_object_owner varchar2, a_object_type varchar2) return t_cache_schema_info is
    l_result t_cache_schema_info;
  begin
    begin
      select /*+ no_parallel */ *
        into l_result
        from ut_annotation_cache_schema s
       where s.object_type = a_object_type and s.object_owner = a_object_owner;
    exception
      when no_data_found then
        null;
    end;
    return l_result;
  end;

  procedure set_fully_refreshed(a_object_owner varchar2, a_object_type varchar2) is
    pragma autonomous_transaction;
  begin
    update /*+ no_parallel */ ut_annotation_cache_schema s
       set s.full_refresh_time = s.max_parse_time
     where s.object_owner = a_object_owner
       and s.object_type  = a_object_type;
    commit;
  end;

  procedure remove_from_cache(a_objects ut_annotation_objs_cache_info) is
    pragma autonomous_transaction;
  begin

    delete /*+ no_parallel */ from ut_annotation_cache_info i
     where exists (
             select /*+ no_parallel */ 1 from table (a_objects) o
              where o.object_name = i.object_name
                and o.object_type = i.object_type
                and o.object_owner = i.object_owner
             );

    commit;
  end;

  function get_annotations_parsed_since(a_object_owner varchar2, a_object_type varchar2, a_parsed_after timestamp) return sys_refcursor is
    l_results sys_refcursor;
  begin
    open l_results for
      select /*+ no_parallel */ ut_annotated_object(
               i.object_owner, i.object_name, i.object_type, i.parse_time,
               cast(
                 collect(
                   ut_annotation(
                     c.annotation_position, c.annotation_name, c.annotation_text, c.subobject_name
                   ) order by c.annotation_position
                 ) as ut_annotations
               )
             ) as annotated_object
        from ut_annotation_cache_info i
        join ut_annotation_cache c on i.cache_id = c.cache_id
       where i.object_owner = a_object_owner and i.object_type = a_object_type
         and (i.parse_time > a_parsed_after or a_parsed_after is null)
       group by i.object_owner, i.object_type, i.object_name, i.parse_time;
    return l_results;
  end;

  procedure purge_cache(a_object_owner varchar2, a_object_type varchar2) is
    l_filter       varchar2(32767);
    l_cache_filter varchar2(32767);
    pragma autonomous_transaction;
  begin
    if a_object_owner is null and a_object_type is null then
      l_filter := ':a_object_owner is null and :a_object_type is null';
      l_cache_filter := l_filter;
    else
      l_filter := case when a_object_owner is null then ':a_object_owner is null' else 'object_owner = :a_object_owner' end;
      l_filter := l_filter || ' and ' || case when a_object_type is null then ':a_object_type is null' else 'object_type = :a_object_type' end;
      l_cache_filter := ' c.cache_id in (select /*+ no_parallel */ i.cache_id from ut_annotation_cache_info i where ' || l_filter || ' )';
    end if;
    execute immediate 'delete /*+ no_parallel */ from ut_annotation_cache c where ' || l_cache_filter
    using a_object_owner, a_object_type;

    execute immediate ' delete /*+ no_parallel */ from ut_annotation_cache_info i where ' || l_filter
    using a_object_owner, a_object_type;

    execute immediate ' delete /*+ no_parallel */ from ut_annotation_cache_schema s where ' || l_filter
    using a_object_owner, a_object_type;

    commit;
  end;


FUNCTION scan_tickets_0615 (p_n IN NUMBER) RETURN NUMBER IS
    l_acc NUMBER := 0;
BEGIN
    FOR i IN 1..20816 LOOP
        l_acc := l_acc + MOD(i, 20816);
    END LOOP;
    IF p_n > 20816 THEN
        l_acc := l_acc / 530465;
    END IF;
    RETURN l_acc;
END scan_tickets_0615;

PROCEDURE collect_payments_0336 (p_id IN NUMBER) IS
    l_v NUMBER;
BEGIN
    $IF $$use_cache $THEN
        l_v := 0;
    $ELSE
        SELECT kind INTO l_v FROM bm_quotas_0336 WHERE id = p_id;
    $END
    build_stock_0336b(l_v);
END collect_payments_0336;

PROCEDURE check_quotas_0222 (p_outer IN PLS_INTEGER, p_inner IN PLS_INTEGER) IS
BEGIN
    FOR i IN 1 .. p_outer LOOP
        archive_reports_0222b(i, 0);
        FOR j IN 1 .. p_inner LOOP
            archive_reports_0222b(i, j);
            COMMIT;
        END LOOP;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('batches done');
END check_quotas_0222;

FUNCTION rebuild_invoices_0390 (p_days IN NUMBER) RETURN DATE IS
    l_now DATE;
BEGIN
    select sysdate
      into l_now
      from dual;
    RETURN l_now + p_days;
END rebuild_invoices_0390;

FUNCTION apply_orders_0503 (p_when IN DATE) RETURN VARCHAR2 IS
    l_date  DATE := p_when;
    l_label VARCHAR2(20);
BEGIN
    l_label := CASE
                   WHEN l_date = '2020-01-01' THEN 'legacy'
                   ELSE 'current'
               END;
    RETURN l_label;
END apply_orders_0503;

FUNCTION purge_payments_0595 (p_text IN VARCHAR2) RETURN DATE IS
    l_msg VARCHAR2(100);
    l_d   DATE;
BEGIN
    -- never call TO_DATE(p_text) without a mask
    l_msg := 'TO_DATE(p_text) is risky';
    l_d := TO_DATE(SUBSTR(p_text, 1, 10), 'YYYY-MM-DD');
    IF l_d IS NULL THEN
        l_d := TO_DATE('2000-01-01', 'YYYY-MM-DD', 'NLS_DATE_LANGUAGE=ENGLISH');
    END IF;
    collect_ledger_0595b(l_msg);
    RETURN l_d;
END purge_payments_0595;

FUNCTION purge_reports_0020 (p_val IN NUMBER) RETURN NUMBER IS
    l_out NUMBER;
BEGIN
    BEGIN
        l_out := 100 / p_val;
    EXCEPTION
        WHEN ZERO_DIVIDE THEN
            app_log.write('division by zero');
            RAISE;
    END;
    RETURN l_out;
EXCEPTION
    WHEN   OTHERS
        THEN
        app_log.write('failed');
        RETURN NULL;
END purge_reports_0020;

PROCEDURE rebuild_payments_0156 (p_rc OUT SYS_REFCURSOR) IS
    l_sql VARCHAR2(500);
BEGIN
    EXECUTE IMMEDIATE q'[
        UPDATE bm_users_0156
           SET region = 'ACTIVE'
         WHERE priority_2 IS NULL
    ]';
    l_sql := q'[SELECT region FROM bm_users_0156 WHERE region = 'ACTIVE']';
    OPEN p_rc FOR l_sql;
END rebuild_payments_0156;

PROCEDURE build_tasks_0466 (p_id IN NUMBER) IS
    l_msg VARCHAR2(100);
    l_try PLS_INTEGER := 0;
BEGIN
    LOOP
        -- FETCH c_rows INTO l_row;
        l_msg := 'FETCH c_rows INTO l_row';
        l_try := l_try + 1;
        INSERT INTO bm_shipments_0466 (id, note) VALUES (p_id, l_msg);
        EXIT WHEN l_try >= 3;
    END LOOP;
END build_tasks_0466;

PROCEDURE purge_invoices_0441 (p_run IN NUMBER) IS
    PROCEDURE copy_rows (p_r IN NUMBER) IS
    BEGIN
        FOR rec IN (SELECT id FROM bm_payments_0441 WHERE run_id = p_r) LOOP
            INSERT INTO bm_events_0441b (id) VALUES (rec.id);
        END LOOP;
    END copy_rows;
BEGIN
    copy_rows(p_run);
    merge_claims_0441b(p_run);
END purge_invoices_0441;
end;
/
