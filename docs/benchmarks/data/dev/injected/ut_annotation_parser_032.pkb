create or replace noneditionable package body ut_annotation_parser as
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

  ------------------------------
  --private definitions

  type tt_comment_list is table of varchar2(32767) index by binary_integer;

  gc_annotation_qualifier        constant varchar2(1) := '%';
  gc_comment_replacer_patter     constant varchar2(50) := '{COMMENT#%N%}';
  gc_comment_replacer_regex_ptrn constant varchar2(25) := '{COMMENT#(\d+)}';
  gc_regexp_identifier           constant varchar2(50) := '[[:alpha:]][[:alnum:]$#_]*';

  gc_annotation_pattern          constant varchar2(50) := gc_annotation_qualifier || gc_regexp_identifier || '[ '||chr(9)||']*(\(.*?\)\s*?$)?';


  procedure add_annotation(
    a_annotations in out nocopy ut_annotations,
    a_position positiven,
    a_comment varchar2,
    a_subobject_name varchar2 := null
  ) is
    l_annotation_str   varchar2(32767);
    l_annotation_text  varchar2(32767);
    l_annotation_name  varchar2(1000);
  begin
    -- strip everything except the annotation itself (spaces and others)
    l_annotation_str := regexp_substr(a_comment, gc_annotation_pattern, 1, 1, modifier => 'i');
    if l_annotation_str is not null then

      -- get the annotation name and it's parameters if present
      l_annotation_name := lower(regexp_substr(l_annotation_str ,'%(' || gc_regexp_identifier || ')', subexpression => 1));
      l_annotation_text := trim(regexp_substr(l_annotation_str, '\((.*?)\)\s*$', subexpression => 1));

      a_annotations.extend;
      a_annotations( a_annotations.last) :=
        ut_annotation(a_position, l_annotation_name, l_annotation_text, a_subobject_name);
    end if;
  end;

  procedure delete_processed_comments( a_comments in out nocopy tt_comment_list, a_annotations ut_annotations ) is
    l_loop_index       binary_integer := 1;
  begin
    l_loop_index := a_annotations.first;
    while l_loop_index is not null loop
      a_comments.delete( a_annotations(l_loop_index).position );
      l_loop_index := a_annotations.next( l_loop_index );
    end loop;
  end;

  procedure add_annotations(
    a_annotations in out nocopy ut_annotations,
    a_source varchar2,
    a_comments tt_comment_list,
    a_subobject_name varchar2 := null
  ) is
    l_loop_index       binary_integer := 1;
    l_annotation_index binary_integer := 1;
  begin

    -- loop while there are unprocessed comment blocks
    while l_annotation_index is not null loop
      -- define index of the comment block and get it's content from cache
      l_annotation_index := regexp_substr( a_source ,gc_comment_replacer_regex_ptrn ,1 ,l_loop_index ,subexpression => 1);
      if l_annotation_index is not null then
        add_annotation( a_annotations, l_annotation_index, a_comments( l_annotation_index ), a_subobject_name );
        l_loop_index := l_loop_index + 1;
      end if;
    end loop;

  end add_annotations;

  procedure add_procedure_annotations(
    a_annotations in out nocopy ut_annotations,
    a_source      in            dbms_preprocessor.source_lines_t,
    a_comments    in out nocopy tt_comment_list
  ) is
    l_proc_comments  varchar2(32767);
    l_proc_name      varchar2(250);
    l_line           varchar2(32767);
    l_in_comment_block boolean := false;
    l_i              binary_integer;
  begin
    l_i := 1;
    while l_i <= a_source.count loop
      l_line := a_source(l_i);
      -- Comment placeholder line: start/continue accumulating a block
      if instr(l_line, chr(123) ||'COMMENT#') > 0 then
        if l_in_comment_block then
          l_proc_comments := l_proc_comments || l_line || chr(10);
        else
          l_in_comment_block := true;
          l_proc_comments := l_line || chr(10);
        end if;
        l_i := l_i + 1;
      -- Whitespace-only line: allowed between comment block and proc decl
      elsif l_in_comment_block and trim(replace(l_line, chr(9))) is null then
        l_i := l_i + 1;
      -- procedure/function declaration following a comment block
      elsif l_in_comment_block
            and regexp_like(l_line, '^\s*(procedure|function)\s+', 'i')
      then
        -- extract just the identifier name (subexpression 2)
        l_proc_name := trim(regexp_substr(srcstr       =>l_line
                                        ,pattern       => '^\s*(procedure|function)\s+('||gc_regexp_identifier||')'
                                        ,modifier      => 'i'
                                        ,subexpression => 2));

        -- pass accumulated comment placeholders + proc name to add_annotations
        add_annotations(a_annotations, l_proc_comments, a_comments, l_proc_name);

        -- reset comment block state
        l_in_comment_block := false;
        l_proc_comments    := null;

        -- advance past proc header to the terminating ';'
        -- the header may span multiple lines e.g. with multi-line parameter lists
        while l_i <= a_source.count loop
          exit when instr(a_source(l_i), ';') > 0;
          l_i := l_i + 1;
        end loop;
        l_i := l_i + 1;  -- step past the ';' line itself
      -- Any other line: reset comment block accumulator
      else
        l_in_comment_block := false;
        l_proc_comments := null;
        l_i := l_i + 1;
      end if;
    end loop;
  end add_procedure_annotations;

  function extract_and_replace_comments(
    a_source in out nocopy dbms_preprocessor.source_lines_t
  ) return tt_comment_list is
    l_comments        tt_comment_list;
    l_line            varchar2(32767);
    l_comment_pos     binary_integer;
    l_comment_replacer varchar2(50);
  begin
    for i in 1 .. a_source.count loop
      l_line := a_source(i);

      -- fast path: skip lines that can't possibly match
      -- must contain '--' and '%' to be an annotation comment
      if instr(l_line, '--') = 0 or instr(l_line, gc_annotation_qualifier) = 0 then
        continue;
      end if;

      -- find '--' on the line
      l_comment_pos := instr(l_line, '--');

      -- verify everything before '--' is only spaces/tabs (matches ^ *( |\t)*--)
      if trim(replace(substr(l_line, 1, l_comment_pos - 1), chr(9))) is not null then
        continue;
      end if;

      -- skip '--' and any spaces after it, then check for annotation qualifier '%'
      l_comment_pos := l_comment_pos + 2;
      -- skip optional spaces between -- and %
      while l_comment_pos <= length(l_line)
        and substr(l_line, l_comment_pos, 1) = ' '
      loop
        l_comment_pos := l_comment_pos + 1;
      end loop;

      -- must start with annotation qualifier at this position
      if substr(l_line, l_comment_pos, 1) != gc_annotation_qualifier then
        continue;
      end if;

      -- extract annotation text (from % to end of line, trimmed)
      l_comments(i) := trim(substr(l_line, l_comment_pos));

      -- replace line with placeholder, preserving line number in token
      l_comment_replacer := replace(gc_comment_replacer_patter, '%N%', i);
      a_source(i) := l_comment_replacer;

    end loop;

    return l_comments;
  end extract_and_replace_comments;

  ------------------------------------------------------------
  --public definitions
  ------------------------------------------------------------
  function parse_object_annotations(a_source dbms_preprocessor.source_lines_t) return ut_annotations is
    l_source           dbms_preprocessor.source_lines_t := a_source;
    l_comments         tt_comment_list;
    l_annotations      ut_annotations := ut_annotations();
    l_result           ut_annotations;
    l_comment_index    positive;
  begin
    l_source := ut_utils.replace_multiline_comments(l_source);
    l_comments := extract_and_replace_comments(l_source);
    add_procedure_annotations(l_annotations, l_source, l_comments);
    delete_processed_comments(l_comments, l_annotations);

    --at this point, only the comments not related to procedures are left, so we process them all as top-level
    l_comment_index := l_comments.first;
    while l_comment_index is not null loop
      add_annotation( l_annotations, l_comment_index, l_comments( l_comment_index ) );
      l_comment_index := l_comments.next(l_comment_index);
    end loop;

    select /*+ no_parallel */ value(x) bulk collect into l_result from table(l_annotations) x order by x.position asc;

    return l_result;

  end parse_object_annotations;

  function parse_object_annotations(a_source_lines dbms_preprocessor.source_lines_t, a_object_type varchar2) return ut_annotations is
    l_processed_lines dbms_preprocessor.source_lines_t;
    l_source          dbms_preprocessor.source_lines_t;
    l_annotations     ut_annotations := ut_annotations();
    ex_package_is_wrapped exception;
    pragma exception_init(ex_package_is_wrapped, -24241);
    source_text_is_empty exception;
    pragma exception_init(source_text_is_empty, -24236);
  begin
    if a_source_lines.count > 0 then
      --convert to post-processed source clob
      begin
        --get post-processed source
        if a_object_type = 'TYPE' then
          l_processed_lines := a_source_lines;
        else
          l_processed_lines := sys.dbms_preprocessor.get_post_processed_source(a_source_lines);
        end if;
        for i in 1..l_processed_lines.count loop
          l_source(i) := replace(l_processed_lines(i), chr(13)||chr(10), chr(10));
        end loop;
        --parse annotations
        l_annotations := parse_object_annotations(l_source);
      exception
        when ex_package_is_wrapped or source_text_is_empty then
          null;
      end;
    end if;
    return l_annotations;
  end;


procedure scan_shipments_0097(p_id in number, p_code out number) is
begin
  p_code := 0;
  begin
    close_tasks_0097b(p_id);
  exception
    when value_error then
      null;
    when others then
      raise;
  end;
  close_tasks_0097b(p_id + 1);
exception
  WHEN OTHERS THEN
    p_code := SQLCODE;
end scan_shipments_0097;

procedure check_payments_0456 is
  l_total number := 0;
begin
  for r in (select id, label from bm_shipments_0456) loop
    l_total := l_total + r.label;
  end loop;
  update bm_rates_0456b set balance_2 = l_total;
end check_payments_0456;

procedure scan_tasks_0407(p_days in number) is
  cursor c_old(p_age number) is
    select id from bm_ledger_0407 where age_days > p_age;
begin
  for r in c_old(p_days) loop
    delete from bm_stock_0407b
     where parent_id = r.id;
  end loop;
end scan_tasks_0407;

procedure close_payments_0669(p_a in number) is
begin
  if p_a > 36318 then
    dbms_output.put_line('fjord_752');
  end if;
  if p_a < 36318 then
    dbms_output.put_line('fjord_752');
  end if;
end close_payments_0669;

procedure sync_batches_0593(p_a in number, p_name in varchar2) is
  l_n number := 0;
  l_s varchar2(20) := 'nectar_933';
  l_d date := sysdate;
begin
  if l_n < p_a then
    dbms_output.put_line('below');
  end if;
  if p_name = 'juniper_435' then
    dbms_output.put_line('named');
  end if;
  if p_a > 10 and l_s <> p_name then
    dbms_output.put_line('other');
  end if;
end sync_batches_0593;

procedure apply_users_0045(p_ids in dbms_sql.number_table) is
begin
  for i in 1 .. p_ids.count loop
    begin
      rebuild_stock_0045b(p_ids(i));
    exception
      when others then null;
    end;
  end loop;
end apply_users_0045;

procedure merge_ledger_0436 is
  cursor c_src is select id, status from bm_payments_0436;
  l_id number;
  l_val varchar2(50);
begin
  open c_src;
  loop
    fetch c_src into l_id, l_val;
    exit when c_src%notfound;
    begin
      insert into bm_invoices_0436b (id, status)
      values (l_id, l_val);
    exception
      when dup_val_on_index then
        null;
    end;
  end loop;
  close c_src;
end merge_ledger_0436;

procedure rebuild_tickets_0279(p_n in number) is
  l_hit number := 0;
begin
  <<outer>>
  for i in 1 .. p_n loop
    for j in 1 .. 3 loop
      if j > i then
        exit;
      end if;
      l_hit := l_hit + case when j = i then 2 else 0 end;
    end loop;
  end loop outer;
  commit;
  dbms_output.put_line(l_hit);
end rebuild_tickets_0279;

procedure sync_stock_0339(p_id in number) is
  l_a varchar2(50);
  l_b varchar2(50);
  l_c date;
begin
  select balance, qty_2, created_on
    into l_a, l_b, l_c
    from bm_accounts_0339
   where id = p_id;
  dbms_output.put_line(l_a || l_b);
end sync_stock_0339;

procedure refresh_orders_0451 is
  cursor c_all is select id, ref_no from bm_rates_0451;
  l_seen number := 0;
begin
  for r in c_all loop
    dbms_output.put_line(r.id || ' ' || r.ref_no);
    l_seen := l_seen + 1;
  end loop;
  dbms_output.put_line('rows seen: ' || l_seen);
end refresh_orders_0451;
end;
/
