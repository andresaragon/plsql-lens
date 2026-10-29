




create or replace package body log_milestone_ops as

  procedure record_waypoint_event(p_waypoint_id in number) is
  begin
    update waypoints set logged = 1 where id = p_waypoint_id;
  exception
    when others then
      null;
  end record_waypoint_event;

  procedure notify_hub_operator(p_hub_id in number) is
  begin
    update hub_notices set seen = 1 where hub_id = p_hub_id;
  exception
    when others then
      raise_application_error(-20001, sqlerrm);
  end notify_hub_operator;

end log_milestone_ops;
/
