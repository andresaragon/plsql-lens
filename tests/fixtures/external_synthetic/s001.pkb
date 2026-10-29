-- case: s001
-- domain: synthetic
-- difficulty: easy
-- note: synthetic case used only by the converter tests
-- author: synthetic
create or replace package body syn_pkg as

  procedure p1 is
  begin
    commit; -- expect: PLL003
  end p1;

  procedure p2 is
  begin
    for i in 1 .. 3 loop
      null;
    end loop;
    commit; -- clean: PLL003
  end p2;

  procedure p3 is
  begin
    for i in 1 .. 3 loop
      p1; -- beyond: PLL003 (p1 commits)
    end loop;
    execute immediate 'x' || i; -- expect: PLL002 expect: PLL007 (two markers)
  end p3;

end syn_pkg;
/
