-- case: e031
-- domain: logistics tracking
-- difficulty: medium
-- note: shipment manifest lookup with unhandled select and safe protected query with bind variable
-- author: gemini-3.8-flash-high via agy (not human-written)
create or replace package body log_manifest_lookup as

  procedure fetch_manifest_origin(p_trk in varchar2, p_orig out varchar2) is
    l_orig varchar2(100);
  begin
    select origin into l_orig from shipments where tracking_no = p_trk; -- expect: PLL004
    p_orig := l_orig;
  end fetch_manifest_origin;

  procedure verify_waybill_status(p_id in number, p_status out varchar2) is
    l_status varchar2(20);
  begin
    execute immediate 'select status from waybills where waybill_id = :w' into l_status using p_id; -- clean: PLL002
    p_status := l_status;
  end verify_waybill_status;

  procedure fetch_recipient_safe(p_id in number, p_recip out varchar2) is
    l_recip varchar2(100);
  begin
    select recipient into l_recip from shipments where id = p_id; -- clean: PLL004
    p_recip := l_recip;
  exception
    when others then
      logger.log_error(sqlerrm);
      p_recip := 'UNKNOWN';
  end fetch_recipient_safe;

end log_manifest_lookup;
/
