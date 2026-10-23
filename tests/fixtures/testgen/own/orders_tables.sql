-- Written for this repo. Tables used by pkg_orders.
create sequence tg_order_seq;

create table tg_orders (
  order_id   number primary key,
  customer   varchar2(50) not null,
  status     varchar2(10) default 'NEW' not null
             check (status in ('NEW', 'PAID', 'CANCELLED')),
  created_at date default sysdate not null
);

create table tg_order_items (
  item_id    number generated always as identity primary key,
  order_id   number not null references tg_orders (order_id),
  sku        varchar2(20) not null,
  qty        number(6) not null check (qty > 0),
  unit_price number(10, 2) not null check (unit_price >= 0)
);
