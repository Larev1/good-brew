GOOD BREW v3 — USERNAME + QRIS MANUAL

ISI PAKET
- Customer daftar/login hanya dengan username + password.
- Nama asli dan WhatsApp diminta saat checkout.
- Riwayat order per akun.
- QRIS statis ditampilkan setelah checkout.
- Tombol WhatsApp menyiapkan pesan agar pembeli melampirkan bukti bayar.
- Admin verifikasi manual status pembayaran, atur status pesanan, dan hapus order.

PENTING SEBELUM DEPLOY
1. Pastikan migrasi SQL v2 sebelumnya SUDAH dijalankan. Jika belum, jalankan schema.sql (hanya untuk database baru), lalu schema_v2_migration.sql, lalu schema_v3_migration.sql. Jika schema.sql sudah pernah dijalankan, JANGAN jalankan ulang schema.sql; jalankan v2 lalu v3.
2. Jalankan schema_v3_migration.sql di Supabase SQL Editor. Jika migrasi v2 belum pernah dijalankan, jalankan v2 dulu.
3. Supabase Dashboard > Authentication > Providers > Email: matikan Confirm email. Username disimpan sebagai email internal username@login.goodbrew.invalid; tidak ada email yang diminta/dikirim. Jangan pakai email sungguhan untuk pelanggan.
4. Supabase Dashboard > Authentication > URL Configuration: tambahkan URL website GitHub Pages ke Site URL dan Redirect URLs.
5. Isi config.js: SUPABASE_URL dan anon/publishable key. Jangan pernah menaruh service_role key di frontend.
6. Isi ADMIN_WHATSAPP dengan nomor WhatsApp admin format 62xxxxxxxxxxx tanpa +. Contoh format: 62812xxxxxxx.
7. Letakkan QRIS statis di assets/qris-goodbrew.png. QR tidak disertakan dalam paket.
8. Admin tetap login dengan email/password admin yang sudah ada. Pastikan user admin sudah ada di public.admin_users.
9. Upload seluruh isi folder ke repo GitHub Pages, termasuk config.js yang sudah berisi kredensial project milikmu. Jangan menimpa config.js dengan file placeholder dari ZIP.

CATATAN
- Pembayaran tidak otomatis diverifikasi. Pembeli mengirim bukti melalui WhatsApp; admin membuka dashboard dan mengubah Pembayaran menjadi Sudah dibayar setelah cek aplikasi GrabMerchant.
- Karena username menggunakan alamat email internal, fitur reset password via email tidak tersedia. Admin perlu melakukan reset password lewat Supabase Dashboard > Authentication > Users.
- Username hanya huruf kecil/angka/underscore, 3–24 karakter.
