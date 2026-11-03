# SIPANTAU KELAS v1.0 — Jalur B (GitHub + Supabase + Vercel)

Sistem Informasi Pemantauan Kehadiran dan Perkembangan Peserta Didik.
Karya Digital: **Muhammad Akbar. M — SMKN 1 Maros** (Informatika / Fase E),
untuk Gerakan 10.000 Karya Digital Guru Tahun 2026 (LK-1 s.d. LK-6).

## Cara kerja paket ini (dual-mode)

- **Mode Supabase (server)** aktif otomatis bila Vercel menyediakan
  `SUPABASE_URL` dan `SUPABASE_ANON_KEY` lewat `/api/config`:
  login email asli, data terpusat di Supabase (PostgreSQL),
  berkas dokumen tersimpan di Supabase Storage, riwayat tercatat di server.
- **Mode Demo (lokal)** aktif bila konfigurasi server belum ada:
  akun demo (admin / walikelas / guru) dan data contoh fiktif di peramban.
  Mode ini untuk uji coba LK-3/LK-4 dan sebagai cadangan presentasi.

## Isi paket

| Berkas | Fungsi |
| --- | --- |
| `index.html` | Seluruh aplikasi (8 bagian sesuai LK-2) |
| `api/config.js` | Vercel Function pembaca Environment Variables |
| `supabase/schema.sql` | Skema tabel, RLS, bucket storage, data contoh, template akun |
| `VERSION.txt` | Penanda versi paket |

## Langkah penerapan (ringkas — rincian di Panduan Deploy)

1. **Supabase** (akun pemilik karya): buat proyek `sipantau-kelas` →
   SQL Editor → jalankan `supabase/schema.sql` sampai selesai →
   Authentication → Users: buat akun admin/walikelas/guru →
   jalankan SQL `profiles` di akhir `schema.sql` dengan UUID masing-masing.
2. **GitHub**: buat repo `sipantau-kelas` → unggah seluruh isi paket ini.
3. **Vercel**: Add New → Project → impor repo → Framework Preset: **Other**
   (tanpa build command) → Environment Variables:
   `SUPABASE_URL` dan `SUPABASE_ANON_KEY` (dari Supabase → Settings → API) → Deploy.
4. **Verifikasi**: buka URL produksi → halaman login harus menampilkan
   "Mode: Server (Supabase)" → masuk sebagai walikelas → simpan presensi →
   ajukan dokumen contoh → verifikasi → periksa Riwayat Perubahan →
   uji ulang dengan Ctrl+F5 dan jendela penyamaran (incognito).

## Catatan keamanan

- Nilai env hanya dimasukkan di Vercel, tidak pernah di repo GitHub.
- Bucket `dokumen` bersifat privat; berkas dibuka lewat tautan bertanda
  tangan sementara dari aplikasi.
- Data contoh pada skema (Kelas X RPL 1, 15 nama fiktif) boleh dihapus
  setelah data asli dimasukkan.
