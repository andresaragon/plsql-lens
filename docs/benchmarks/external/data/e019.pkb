




create or replace package body inv_partition_purge as

  procedure drop_staging_partition(p_partition_name in varchar2) is
    l_stmt varchar2(200);
  begin
    l_stmt := 'delete from ' || p_partition_name;
    execute immediate l_stmt;
  end drop_staging_partition;

  procedure clear_inventory_cache(p_tbl in varchar2) is
    l_stmt varchar2(200);
  begin
    l_stmt := 'truncate table ' || dbms_assert.sql_object_name(p_tbl);
    execute immediate l_stmt;
  end clear_inventory_cache;

end inv_partition_purge;
/
