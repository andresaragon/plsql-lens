




create or replace package body htl_amenity_mgmt as

  procedure assign_guest_amenity(p_res_id in number) is
  begin
    update reservations set package_tier = 'VIP_GOLD_SERVICE' where res_id = p_res_id;
    insert into billing_amenities(res_id, tier) values (p_res_id, 'VIP_GOLD_SERVICE');
  end assign_guest_amenity;

  procedure verify_vip_lounge_access(p_res_id in number, p_allow out boolean) is
    l_flag number;
  begin
    select case when package_tier = 'VIP_GOLD_SERVICE' then 1 else 0 end into l_flag from reservations where res_id = p_res_id;
    p_allow := (l_flag = 1);
  end verify_vip_lounge_access;

end htl_amenity_mgmt;
/
