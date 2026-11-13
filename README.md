# GOOD BREW Online Ordering v2

Fitur v2:
- Registrasi akun pelanggan mandiri (nama, WhatsApp, email, password).
- Login/logout pelanggan.
- Checkout hanya untuk pelanggan yang login.
- Riwayat pesanan pribadi dengan detail item, total, jadwal, dan status.
- Reset password melalui email.
- Dashboard admin tetap memakai akun admin yang sudah ada.
- Admin dapat mengubah status pembayaran/produksi dan menghapus pesanan permanen.
- RLS Supabase memastikan pelanggan hanya membaca pesanan miliknya.

## PENTING SEBELUM UPLOAD

1. Backup file website dan database sebelum perubahan.
2. Buka `schema_v2_migration.sql`, jalankan seluruh isinya SATU KALI di Supabase Dashboard > SQL Editor > New query.
3. Jika SQL berhasil, upload file website v2 ke root repository GitHub Pages: `index.html`, `account.html`, `account.js`, `app.js`, `admin.html`, `admin.js`, `style.css`.
4. **JANGAN menimpa `config.js` yang sudah aktif.** Pertahankan URL dan publishable/anon key yang sekarang dipakai website.
5. Jangan hapus `schema.sql`; file itu adalah setup awal. Untuk upgrade database yang sudah berjalan, gunakan `schema_v2_migration.sql` saja.
6. Tunggu GitHub Pages selesai deploy, lalu tes di browser dengan Ctrl+Shift+R.

## Alur pelanggan

- Buka `account.html`, daftar akun, dan verifikasi email jika Supabase meminta verifikasi.
- Login, kemudian buka toko (`index.html`) dan checkout.
- Riwayat bisa dibuka dari tautan `Akun & Riwayat`.
- Jika lupa password, masukkan email pada form login lalu klik `Kirim link reset password`.

## Alur admin

- Login melalui `admin.html` memakai akun admin yang sudah terdaftar di tabel `admin_users`.
- Status pembayaran dan produksi bisa diubah langsung.
- Tombol `Hapus pesanan` menghapus baris order dan seluruh `order_items` terkait melalui foreign key `ON DELETE CASCADE`. Penghapusan permanen dan tidak bisa dibatalkan.
- Jangan hapus akun admin dari Supabase Auth atau tabel `admin_users`.

## Catatan data lama

Pesanan yang dibuat sebelum migrasi v2 tetap tersimpan dan tetap terlihat admin. Karena pesanan lama tidak memiliki `user_id`, pesanan tersebut tidak otomatis muncul pada riwayat akun pelanggan. Pesanan baru setelah migrasi akan otomatis terkait dengan akun yang sedang login.

## Catatan keamanan

- Frontend hanya menggunakan Supabase publishable key atau legacy anon key. Jangan pernah memasukkan `service_role` key ke `config.js`.
- Pendaftaran pelanggan menggunakan Supabase Auth. Pelanggan tidak diberi hak admin.
- Database RLS membatasi pelanggan ke `orders.user_id = auth.uid()` dan item pesanan terkait.
- Admin delete hanya diizinkan untuk user ID yang terdaftar di `public.admin_users`.

## Konfigurasi email Supabase

Jika verifikasi email aktif, pelanggan harus klik link verifikasi yang dikirim Supabase sebelum login. Pastikan URL website GitHub Pages diizinkan pada Supabase Authentication > URL Configuration > Redirect URLs, misalnya:
`https://larev1.github.io/good-brew/**`

Jika link reset password kembali ke alamat yang salah, periksa juga Site URL dan Redirect URLs di halaman yang sama.
