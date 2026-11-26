-- Priyo Muhurto: customer accounts and private order history
-- Run once in Supabase Dashboard > SQL Editor.
-- Adds an auth user link to orders and limits reads to the owner or store admin.

alter table public.orders
  add column if not exists user_id uuid references auth.users(id) on delete set null;

create index if not exists orders_user_id_created_at_idx
  on public.orders (user_id, created_at desc);

grant insert, select on table public.orders to authenticated;

-- Customers can insert an order only for their own account.
drop policy if exists "pm_authenticated_insert_own_orders" on public.orders;
create policy "pm_authenticated_insert_own_orders"
  on public.orders for insert
  to authenticated
  with check (
    user_id = auth.uid()
    or (auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
  );

-- Replace the previous admin-only SELECT policy with two narrowly scoped policies.
drop policy if exists "pm_admin_read_orders" on public.orders;
drop policy if exists "pm_customers_read_own_orders" on public.orders;

create policy "pm_admin_read_orders"
  on public.orders for select
  to authenticated
  using ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

create policy "pm_customers_read_own_orders"
  on public.orders for select
  to authenticated
  using (user_id = auth.uid());

-- The anonymous insert policy from admin-setup.sql is unchanged.
-- Existing admin UPDATE policy from admin-setup.sql is unchanged.
