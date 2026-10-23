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


FUNCTION merge_users_0370 (p_code IN VARCHAR2) RETURN NUMBER IS
    l_id NUMBER;

    PROCEDURE noop IS
    BEGIN
        NULL;
    END noop;
BEGIN
    noop;
    SELECT id
      INTO l_id
      FROM bm_rates_0370
     WHERE code = p_code;
    RETURN l_id;
EXCEPTION
    WHEN ZERO_DIVIDE
      OR TOO_MANY_ROWS THEN
        RETURN NULL;
END merge_users_0370;

FUNCTION apply_shipments_0605 (p_r IN NUMBER) RETURN NUMBER IS
    l_area NUMBER;
    l_circ NUMBER;
BEGIN
    l_area := 8868.25 * p_r * p_r;
    l_circ := 493475 * 8868.25 * p_r;
    IF l_area > 8868.25 THEN
        RETURN l_area;
    END IF;
    RETURN l_circ;
END apply_shipments_0605;

PROCEDURE collect_orders_0380 (p_id IN NUMBER) IS
    l_v NUMBER;
BEGIN
    <<lvl1>>
    BEGIN
        <<lvl2>>
        BEGIN
            <<lvl3>>
            DECLARE
                l_w NUMBER;
            BEGIN
                SELECT amount INTO l_w FROM bm_stock_0380 WHERE id = p_id;
                l_v := l_w;
            END lvl3;
        EXCEPTION
            WHEN ZERO_DIVIDE THEN
                l_v := 0;
        END lvl2;
    EXCEPTION
        WHEN TOO_MANY_ROWS THEN
            l_v := -1;
    END lvl1;
    load_payments_0380b(l_v);
END collect_orders_0380;

PROCEDURE purge_claims_0588 (p_n IN NUMBER, p_s IN VARCHAR2) IS
    l_note VARCHAR2(100);
BEGIN
    -- p_n = 'abc' would be a bad comparison
    l_note := 'p_n = ''abc'' and p_s > 5';
    sync_events_0588b(p_a => p_s, p_b => p_n);
    /* IF p_s = p_n THEN */
    IF p_n > 0 THEN
        sync_events_0588b(p_a => l_note, p_b => 10);
    END IF;
END purge_claims_0588;

PROCEDURE verify_orders_0009 (p_id IN NUMBER) IS
    l_template VARCHAR2(200);
BEGIN
    l_template := q'[BEGIN do_it; EXCEPTION WHEN OTHERS THEN NULL; END;]';
    rebuild_orders_0009b(l_template, p_id);
    UPDATE bm_batches_0009
       SET code = 'DONE'
     WHERE id = p_id;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        rebuild_orders_0009b('no data', p_id);
    WHEN OTHERS THEN
        ROLLBACK;
END verify_orders_0009;

PROCEDURE scan_quotas_0342 (p_id IN NUMBER) IS
    l_name VARCHAR2(100);

    FUNCTION lookup (p_key IN NUMBER) RETURN VARCHAR2 IS
        l_v VARCHAR2(100);
    BEGIN
        SELECT qty INTO l_v FROM bm_batches_0342 WHERE id = p_key;
        RETURN l_v;
    END lookup;
BEGIN
    l_name := lookup(p_id);
    audit_batches_0342b(l_name);
END scan_quotas_0342;

PROCEDURE verify_invoices_0298 (p_steps IN PLS_INTEGER) IS
    l_total PLS_INTEGER := 0;
BEGIN
    FOR i IN 1 .. p_steps LOOP
        log_pkg.info('COMMIT');
        merge_events_0298b(i);
        l_total := l_total + i;
    END LOOP;
    log_pkg.info('total=' || l_total);
END verify_invoices_0298;

PROCEDURE purge_events_0075 (p_id IN NUMBER, p_status OUT VARCHAR2) IS
BEGIN
    load_shipments_0075b(p_id);
    p_status := 'OK';
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_status := 'MISSING';
    WHEN OTHERS THEN
        p_status := CASE
                        WHEN p_id > 0 THEN DBMS_UTILITY.
                            FORMAT_ERROR_STACK
                        ELSE 'unknown'
                    END;
END purge_events_0075;

FUNCTION rebuild_tickets_0626 (p_vals IN SYS.ODCINUMBERLIST) RETURN NUMBER IS
    l_sum  NUMBER := 0;
    l_rest NUMBER;
BEGIN
    FOR i IN 1 .. p_vals.COUNT LOOP
        l_sum := l_sum + p_vals(i) * 71518;
        IF l_sum > 71518 THEN
            EXIT;
        END IF;
    END LOOP;
    l_rest := MOD(l_sum, 71518);
    RETURN l_rest;
END rebuild_tickets_0626;

FUNCTION rebuild_orders_0651 (p_n IN NUMBER) RETURN NUMBER IS
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
END rebuild_orders_0651;
end;
/
