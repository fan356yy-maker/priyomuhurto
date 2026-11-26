-- Priyo Muhurto: customer accounts and private order history
-- Run once in Supabase Dashboard > SQL Editor.
-- This keeps the existing admin policies and adds customer-owned order access.

alter table public.orders
  add column if not exists user_id uuid references auth.users(id) on delete set null;

create index if not exists orders_user_id_created_at_idx
  on public.orders (user_id, created_at desc);

-- Authenticated customers can create an order only for their own auth user ID.
grant insert, select on table public.orders to authenticated;

drop policy if exists "pm_authenticated_insert_own_orders" on public.orders;
create policy "pm_authenticated_insert_own_orders"
  on public.orders for insert
  to authenticated
  with check (
    user_id = auth.uid()
    or (auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
  );

-- Customers can read only orders linked to their own account.
drop policy if exists "pm_customers_read_own_orders" on public.orders;
create policy "pm_customers_read_own_orders"
  on public.orders for select
  to authenticated
  using (
    user_id = auth.uid()
    or (auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
  );

-- Existing admin select/update policies from admin-setup.sql remain in place.
-- Guest/anonymous inserts remain available only if the previous anon insert policy exists.
