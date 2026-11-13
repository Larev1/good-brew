-- GOOD BREW: customer accounts + private order history
-- Run this migration ONCE in Supabase SQL Editor after the original schema.sql.
-- Safe for existing orders: old guest orders remain visible to admins only.

-- Keep database prices synchronized with the current customer menu.
update public.products set price = case id
  when 'americano' then 10000
  when 'cafe-latte' then 13000
  when 'palm-sugar-latte' then 15000
  when 'oat-latte' then 16000
  when 'palm-sugar-oat-latte' then 18000
  else price end
where id in ('americano','cafe-latte','palm-sugar-latte','oat-latte','palm-sugar-oat-latte');

-- 1) Attach new orders to the authenticated customer. Old rows remain NULL.
alter table public.orders
  add column if not exists user_id uuid references auth.users(id) on delete set null;
create index if not exists orders_user_id_created_at_idx
  on public.orders(user_id, created_at desc);

-- 2) Customers may read only their own orders. Existing admin read policy remains.
drop policy if exists "Customers can read own orders" on public.orders;
create policy "Customers can read own orders"
  on public.orders for select to authenticated
  using (user_id = (select auth.uid()));

-- Customers may read line items only when the parent order belongs to them.
drop policy if exists "Customers can read own order items" on public.order_items;
create policy "Customers can read own order items"
  on public.order_items for select to authenticated
  using (
    exists (
      select 1 from public.orders o
      where o.id = order_items.order_id
        and o.user_id = (select auth.uid())
    )
  );

-- 3) Replace checkout RPC. Identity comes from Supabase Auth, never from browser input.
create or replace function public.place_good_brew_order(
  p_customer_name text,
  p_whatsapp text,
  p_fulfillment text,
  p_destination text,
  p_ready_date date,
  p_ready_time time,
  p_notes text,
  p_items jsonb
) returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order_id uuid;
  v_total integer := 0;
  v_item jsonb;
  v_product public.products%rowtype;
  v_qty integer;
  v_extra boolean;
  v_extra_price integer := 3000;
  v_unit integer;
  v_line integer;
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then raise exception 'Silakan login terlebih dahulu untuk memesan.'; end if;
  if length(trim(coalesce(p_customer_name,''))) < 2 then raise exception 'Nama pemesan wajib diisi.'; end if;
  if length(trim(coalesce(p_whatsapp,''))) < 8 then raise exception 'Nomor WhatsApp tidak valid.'; end if;
  if p_fulfillment not in ('pickup','delivery') then raise exception 'Metode penerimaan tidak valid.'; end if;
  if p_fulfillment = 'delivery' and p_destination <> 'Maximart Yanglim' then raise exception 'Delivery hanya tersedia ke Maximart Yanglim.'; end if;
  if p_ready_date < (now() at time zone 'Asia/Jakarta')::date + 1 then raise exception 'Pesanan minimal untuk besok (H+1).'; end if;
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then raise exception 'Keranjang kosong.'; end if;

  insert into public.orders(user_id,customer_name,whatsapp,fulfillment,destination,ready_date,ready_time,notes)
  values(v_user_id,trim(p_customer_name),trim(p_whatsapp),p_fulfillment,
    case when p_fulfillment='delivery' then 'Maximart Yanglim' else 'Pickup' end,
    p_ready_date,p_ready_time,left(coalesce(p_notes,''),300))
  returning id into v_order_id;

  for v_item in select * from jsonb_array_elements(p_items) loop
    select * into v_product from public.products where id = v_item->>'product_id' and active = true;
    if not found then raise exception 'Menu tidak tersedia.'; end if;
    v_qty := (v_item->>'quantity')::integer;
    v_extra := coalesce((v_item->>'extra_shot')::boolean,false);
    if v_qty < 1 or v_qty > 50 then raise exception 'Jumlah cup tidak valid.'; end if;
    v_unit := v_product.price;
    v_line := (v_unit + case when v_extra then v_extra_price else 0 end) * v_qty;
    v_total := v_total + v_line;
    insert into public.order_items(order_id,product_id,product_name,quantity,extra_shot,unit_price,extra_shot_price,line_total)
    values(v_order_id,v_product.id,v_product.name,v_qty,v_extra,v_unit,case when v_extra then v_extra_price else 0 end,v_line);
  end loop;
  update public.orders set total=v_total where id=v_order_id;
  return v_order_id;
end;
$$;

-- Remove public/anonymous access to the new authenticated-only checkout.
revoke all on function public.place_good_brew_order(text,text,text,text,date,time,text,jsonb) from public;
revoke execute on function public.place_good_brew_order(text,text,text,text,date,time,text,jsonb) from anon;
grant execute on function public.place_good_brew_order(text,text,text,text,date,time,text,jsonb) to authenticated;

-- No direct customer INSERT/UPDATE/DELETE policies are added. Orders can only be created
-- through the security-definer RPC, which binds user_id to auth.uid(). Admin policies
-- from the original schema remain in force.
