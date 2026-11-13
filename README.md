# GOOD BREW Online Ordering v1.0

Starter web app untuk pre-order GOOD BREW. Website ini belum live sampai project Supabase dibuat dan file dipasang di hosting gratis.

## Isi paket
- `index.html`: halaman pelanggan, menu, keranjang, checkout.
- `admin.html`: dashboard admin.
- `config.js`: tempat URL dan anon key Supabase.
- `schema.sql`: tabel, akses database, dan fungsi checkout.
- `style.css`, `app.js`, `admin.js`: tampilan dan logika.

## Menu awal
- Iced Americano — Rp10.000
- Iced Cafe Latte — Rp13.000
- Iced Palm Sugar Latte — Rp14.000
- Iced Oat Latte — Rp16.000
- Iced Palm Sugar Oat Latte — Rp18.000
- Extra Shot — tambah Rp3.000/cup

Harga mengikuti daftar terakhir yang tersedia di percakapan. Pastikan kembali sebelum website dipublikasikan.

## Cara membuat online (gratis pada batas paket gratis)

### 1. Buat database Supabase
1. Buat akun di https://supabase.com dan buat project baru.
2. Buka SQL Editor, tempel seluruh isi `schema.sql`, lalu Run.
3. Buka Project Settings > API. Salin Project URL dan anon/public key.
4. Isi kedua nilai itu di `config.js`. Jangan pernah memasukkan `service_role` key ke website.

### 2. Buat akun admin
1. Di Supabase buka Authentication > Users, buat user dengan email dan password admin.
2. Salin UUID user tersebut.
3. Di SQL Editor jalankan:
   `insert into public.admin_users(user_id) values ('UUID_USER_ADMIN');`
4. Admin login di halaman `/admin.html`.

### 3. Terbitkan website
1. Buat repository GitHub baru, misalnya `good-brew-order`.
2. Upload seluruh file paket ini ke root repository.
3. Buka Settings > Pages, pilih Deploy from a branch, pilih `main` dan `/root`, lalu Save.
4. GitHub akan memberikan alamat website publik. Bagikan link itu atau buat QR Code.

## Cara kerja
- Pelanggan memilih menu dan jumlah, lalu memilih pickup atau delivery.
- Delivery hanya ke Maximart Yanglim dan gratis.
- Tanggal paling cepat yang dapat dipilih adalah besok (H+1).
- Checkout menyimpan pesanan dan item ke Supabase.
- Pembayaran berstatus `pending` sampai admin memverifikasinya.
- Admin dapat mengubah status pembayaran dan status produksi.

## Catatan penting sebelum go-live
- Pastikan harga/menu sudah final. Cold Brew Fruit belum dimasukkan karena harga jual belum ditetapkan.
- Detail rekening/QRIS belum ditampilkan karena perlu diisi dengan detail pembayaran milik GOOD BREW. Untuk MVP, admin memberikan instruksi pembayaran secara terpisah.
- Halaman admin memerlukan koneksi internet dan akun admin yang telah dimasukkan ke tabel `admin_users`.
- Simpan anon key saja di `config.js`; jangan pernah membagikan service role key.
- Paket gratis punya batas pemakaian dan dapat berubah sewaktu-waktu.
- Lakukan satu pesanan uji coba sebelum membagikan link ke pelanggan.

## Keterbatasan v1.0
Belum ada payment gateway otomatis, upload bukti transfer, notifikasi WhatsApp otomatis, pengelolaan menu dari dashboard, atau kalkulasi ongkir jarak jauh. Delivery tetap dibatasi ke Maximart Yanglim dengan biaya Rp0.
