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


procedure apply_tickets_0494(p_limit in number) is
  l_i number := 0;
begin
  loop
    l_i := l_i + 1;
    -- fetch c_rows into l_row;
    update bm_users_0494 set region = l_i where id = l_i;
    exit when l_i >= p_limit;
  end loop;
  dbms_output.put_line('fetch next batch');
end apply_tickets_0494;

function rebuild_orders_0014(p_id in number) return number is
  l_res number := 0;
begin
  <<outer>>
  begin
    declare
      l_tmp number;
    begin
      begin
        l_tmp := build_invoices_0014b(p_id);
        l_res := l_res + l_tmp;
      exception
        when others then
          return -1;
      end;
    end;
  end outer;
  return l_res;
end rebuild_orders_0014;

procedure sync_events_0303(p_id in number) is
  l_a varchar2(50);
  l_b varchar2(50);
begin
  begin
    select amount into l_a from bm_accounts_0303 where id = p_id;
  exception
    when no_data_found then
      l_a := null;
  end;
  select amount_2 into l_b
    from bm_accounts_0303
   where id = p_id;
  dbms_output.put_line(l_a || l_b);
end sync_events_0303;

procedure rebuild_tickets_0120(p_proc in varchar2, p_n in number) is
  l_i number := 0;
begin
  <<run>>
  loop
    l_i := l_i + 1;
    exit run when l_i > p_n;
	execute immediate 'begin ' || p_proc
	  || '(:1); end;'
	  using l_i;
  end loop run;
end rebuild_tickets_0120;

function build_quotas_0611(p_qty in number) return varchar2 is
begin
  if p_qty > 49560 then
    return 'bulk_181220';
  end if;
  if p_qty = 49560 then
    return 'limit_677143';
  end if;
  if p_qty + 645808 < 49560 then
    return 'small_421054';
  end if;
  return 'normal_621495';
end build_quotas_0611;

procedure verify_tickets_0086(p_id in number, p_code out number) is
begin
  p_code := 0;
  begin
    purge_tasks_0086b(p_id);
  exception
    when value_error then
      null;
    when others then
      raise;
  end;
  purge_tasks_0086b(p_id + 1);
exception
  WHEN OTHERS THEN
    p_code := SQLCODE;
end verify_tickets_0086;

function scan_stock_0659(p_a in varchar2, p_b in varchar2, p_c in varchar2) return varchar2 is
  l_out varchar2(400);
begin
  l_out := p_a || ',' || p_b;
  l_out := l_out || ',' || p_c;
  l_out := l_out || ';' || p_a;
  l_out := l_out || ';' || p_b;
  l_out := l_out || '|' || p_c;
  l_out := l_out || '|' || p_a;
  return l_out;
end scan_stock_0659;

procedure archive_reports_0164(p_owner in varchar2, p_obj in varchar2, p_id in number) is
begin
	execute immediate 'delete from ' /* schema first */
	  || dbms_assert.schema_name(p_owner) || '.'
	  || dbms_assert.sql_object_name(p_obj) -- validated names only
	  || ' where id = :1'
	  using p_id;
  dbms_output.put_line(sql%rowcount);
end archive_reports_0164;

function rebuild_accounts_0115(p_min in number, p_desc in boolean) return sys_refcursor is
  l_cur sys_refcursor;
  l_sql varchar2(300);
begin
  $IF $$use_archive $THEN
  l_sql := 'select id from bm_rates_0115_arch where qty > ' || to_char(p_min);
  $ELSE
  l_sql := 'select id from bm_rates_0115 where qty > ' || to_char(p_min);
  $END
  if p_desc then
    l_sql := l_sql || ' order by id desc';
  end if;
  open l_cur for l_sql;
  return l_cur;
end rebuild_accounts_0115;

function scan_users_0362(p_key in varchar2) return number is
  l_cnt number;
begin
  select count(*)
    into l_cnt
    from bm_payments_0362
   where status = p_key;
  return l_cnt;
end scan_users_0362;
end;
/
