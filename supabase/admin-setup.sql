-- Priyo Muhurto: secure admin order management
-- Run this file in Supabase Dashboard > SQL Editor as project owner.

alter table public.orders
  add column if not exists status text not null default 'Pending';

alter table public.orders
  drop constraint if exists orders_status_allowed;

alter table public.orders
  add constraint orders_status_allowed
  check (status in ('Pending', 'Confirmed', 'Processing', 'Shipped', 'Delivered', 'Cancelled'));

alter table public.orders enable row level security;

-- Customers may submit orders, but cannot read or update them.
grant insert on table public.orders to anon;
drop policy if exists "pm_customers_insert_orders" on public.orders;
create policy "pm_customers_insert_orders"
  on public.orders for insert
  to anon
  with check (true);

-- Only authenticated users with the server-managed app_metadata role=admin
-- may read or update orders. Do not use user-editable user_metadata for this.
grant select, update on table public.orders to authenticated;

drop policy if exists "pm_admin_read_orders" on public.orders;
create policy "pm_admin_read_orders"
  on public.orders for select
  to authenticated
  using ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

drop policy if exists "pm_admin_update_orders" on public.orders;
create policy "pm_admin_update_orders"
  on public.orders for update
  to authenticated
  using ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin')
  with check ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');
