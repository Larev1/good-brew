-- GOOD BREW v2 CUSTOMER ACCOUNTS + ORDER HISTORY + ADMIN DELETE
-- Jalankan SATU KALI di Supabase Dashboard > SQL Editor.
-- Migration ini mempertahankan tabel dan pesanan lama; pesanan lama tetap ada tetapi tidak otomatis masuk ke riwayat akun.

create extension if not exists pgcrypto;

-- Hubungkan pesanan baru ke akun Supabase Auth. Nullable agar data pesanan lama tetap aman.
alter table public.orders
  add column if not exists user_id uuid references auth.users(id) on delete set null;
create index if not exists orders_user_id_created_at_idx
  on public.orders(user_id, created_at desc);

-- Sinkronkan harga database dengan menu website v2 (termasuk Palm Sugar Latte Rp15.000).
update public.products set price = case id
  when 'americano' then 10000
  when 'cafe-latte' then 13000
  when 'palm-sugar-latte' then 15000
  when 'oat-latte' then 16000
  when 'palm-sugar-oat-latte' then 18000
  else price end
where id in ('americano','cafe-latte','palm-sugar-latte','oat-latte','palm-sugar-oat-latte');

-- Function helper: hanya admin yang terdaftar di admin_users.
create or replace function public.good_brew_is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists(select 1 from public.admin_users a where a.user_id = auth.uid());
$$;
revoke all on function public.good_brew_is_admin() from public;
grant execute on function public.good_brew_is_admin() to authenticated;

-- RLS: admin tetap dapat melihat/mengelola semua order; pelanggan hanya order miliknya.
drop policy if exists "Admins can read orders" on public.orders;
drop policy if exists "Admins can update orders" on public.orders;
drop policy if exists "Customers can read own orders" on public.orders;
drop policy if exists "Admins can delete orders" on public.orders;
create policy "Admins can read orders" on public.orders for select to authenticated
  using (public.good_brew_is_admin());
create policy "Customers can read own orders" on public.orders for select to authenticated
  using (user_id = auth.uid());
create policy "Admins can update orders" on public.orders for update to authenticated
  using (public.good_brew_is_admin()) with check (public.good_brew_is_admin());
create policy "Admins can delete orders" on public.orders for delete to authenticated
  using (public.good_brew_is_admin());

-- Item pesanan: admin bisa melihat semua; pelanggan hanya item dari order miliknya.
drop policy if exists "Admins can read order items" on public.order_items;
drop policy if exists "Customers can read own order items" on public.order_items;
create policy "Admins can read order items" on public.order_items for select to authenticated
  using (public.good_brew_is_admin());
create policy "Customers can read own order items" on public.order_items for select to authenticated
  using (exists(select 1 from public.orders o where o.id = order_items.order_id and o.user_id = auth.uid()));

-- Hak akses tabel: tidak ada insert langsung dari browser; checkout hanya lewat RPC.
revoke insert on public.orders from anon, authenticated;
revoke delete on public.orders from anon;
grant select, update, delete on public.orders to authenticated;
grant select on public.order_items to authenticated;
revoke insert, update, delete on public.order_items from anon, authenticated;

-- Ganti RPC lama dengan versi yang mewajibkan login dan mengambil nama/WA dari metadata akun,
-- bukan dari data yang bisa dimanipulasi pada form checkout.
drop function if exists public.place_good_brew_order(text,text,text,text,date,time,text,jsonb);
create or replace function public.place_good_brew_order(
  p_fulfillment text,
  p_destination text,
  p_ready_date date,
  p_ready_time time,
  p_notes text,
  p_items jsonb
) returns uuid
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_order_id uuid;
  v_user_id uuid := auth.uid();
  v_customer_name text;
  v_whatsapp text;
  v_total integer := 0;
  v_item jsonb;
  v_product public.products%rowtype;
  v_qty integer;
  v_extra boolean;
  v_extra_price integer := 3000;
  v_unit integer;
  v_line integer;
begin
  if v_user_id is null then raise exception 'Silakan masuk ke akun GOOD BREW sebelum checkout.'; end if;
  select nullif(trim(u.raw_user_meta_data->>'full_name'),''), nullif(trim(u.raw_user_meta_data->>'phone'),'')
    into v_customer_name, v_whatsapp
    from auth.users u where u.id = v_user_id;
  if length(coalesce(v_customer_name,'')) < 2 then raise exception 'Nama akun belum lengkap. Perbarui profil akun.'; end if;
  if length(coalesce(v_whatsapp,'')) < 8 then raise exception 'Nomor WhatsApp akun belum valid. Perbarui profil akun.'; end if;
  if p_fulfillment not in ('pickup','delivery') then raise exception 'Metode penerimaan tidak valid.'; end if;
  if p_fulfillment = 'delivery' and p_destination <> 'Maximart Yanglim' then raise exception 'Delivery hanya tersedia ke Maximart Yanglim.'; end if;
  if p_ready_date < (now() at time zone 'Asia/Jakarta')::date + 1 then raise exception 'Pesanan minimal untuk besok (H+1).'; end if;
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then raise exception 'Keranjang kosong.'; end if;

  insert into public.orders(user_id,customer_name,whatsapp,fulfillment,destination,ready_date,ready_time,notes)
  values(v_user_id,v_customer_name,v_whatsapp,p_fulfillment,
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
revoke all on function public.place_good_brew_order(text,text,date,time,text,jsonb) from public, anon;
grant execute on function public.place_good_brew_order(text,text,date,time,text,jsonb) to authenticated;

-- Catatan: user_id untuk pesanan lama tetap NULL. Jangan menghapus data lama.
