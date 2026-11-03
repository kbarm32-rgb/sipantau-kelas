-- ============================================================
-- SIPANTAU KELAS v1.0 — Skema Database Supabase (PostgreSQL)
-- Diperbarui pada paket aplikasi v1.1: kolom nisn pada tabel siswa
-- (untuk fitur Impor Peserta Didik). Bagi pemasangan yang sudah berjalan,
-- cukup jalankan: alter table public.siswa add column if not exists nisn text;
-- Cara pakai: Supabase Dashboard → SQL Editor → New query →
-- tempel SELURUH isi file ini → Run. Aman dijalankan sekali;
-- bagian CREATE memakai IF NOT EXISTS sebisa mungkin.
-- ============================================================

-- ---------- 1. TABEL PROFIL PENGGUNA & PERAN ----------
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  nama text not null,
  peran text not null check (peran in ('admin','walikelas','guru')),
  dibuat_pada timestamptz not null default now()
);

-- ---------- 2. TABEL KELAS & SISWA ----------
create table if not exists public.kelas (
  id uuid primary key default gen_random_uuid(),
  nama text not null,
  jurusan text,
  tahun text,
  dibuat_pada timestamptz not null default now()
);

create table if not exists public.siswa (
  id uuid primary key default gen_random_uuid(),
  kelas_id uuid references public.kelas (id) on delete cascade,
  nama text not null,
  nis text,
  nisn text,
  jk text check (jk in ('L','P')),
  dibuat_pada timestamptz not null default now()
);

-- ---------- 3. PRESENSI ----------
create table if not exists public.presensi (
  id uuid primary key default gen_random_uuid(),
  siswa_id uuid not null references public.siswa (id) on delete cascade,
  tanggal date not null,
  status text not null check (status in ('Hadir','Sakit','Izin','Alpa','Terlambat')),
  dicatat_oleh text,
  dibuat_pada timestamptz not null default now(),
  unique (siswa_id, tanggal)
);

-- ---------- 4. CATATAN PERKEMBANGAN (MONITORING) ----------
create table if not exists public.catatan (
  id uuid primary key default gen_random_uuid(),
  siswa_id uuid not null references public.siswa (id) on delete cascade,
  kategori text not null,
  tanggal date not null default current_date,
  oleh text,
  peran text,
  isi text not null,
  dibuat_pada timestamptz not null default now()
);

-- ---------- 5. DOKUMEN & VERIFIKASI ----------
create table if not exists public.dokumen (
  id uuid primary key default gen_random_uuid(),
  siswa_id uuid not null references public.siswa (id) on delete cascade,
  jenis text not null,
  tanggal date not null default current_date,
  keterangan text,
  status text not null default 'Menunggu' check (status in ('Menunggu','Terverifikasi','Ditolak')),
  file_nama text,
  file_path text,
  keputusan_oleh text,
  keputusan_waktu text,
  dibuat_pada timestamptz not null default now()
);

-- ---------- 6. PENDAMPINGAN & TINDAK LANJUT ----------
create table if not exists public.pendampingan (
  id uuid primary key default gen_random_uuid(),
  siswa_id uuid not null references public.siswa (id) on delete cascade,
  kebutuhan text not null,
  tindakan text,
  hasil text,
  rencana text,
  status text not null default 'Proses' check (status in ('Proses','Selesai')),
  dibuat_pada timestamptz not null default now()
);

-- ---------- 7. RIWAYAT PERUBAHAN (AUDIT LOG) ----------
create table if not exists public.riwayat (
  id bigint generated always as identity primary key,
  pengguna text,
  peran text,
  aksi text not null,
  detail text,
  dibuat_pada timestamptz not null default now()
);

-- ---------- 8. KEAMANAN BARIS (RLS) ----------
-- Prinsip v1.0: seluruh pengguna yang sudah masuk (authenticated)
-- dapat membaca & menulis data pemantauan sekolahnya sendiri.
-- Pembatasan aksi per peran ditegakkan di aplikasi (mis. keputusan
-- verifikasi hanya Administrator/Wali Kelas). Perketat kebijakan ini
-- bila aplikasi dipakai lintas sekolah.
alter table public.profiles enable row level security;
alter table public.kelas enable row level security;
alter table public.siswa enable row level security;
alter table public.presensi enable row level security;
alter table public.catatan enable row level security;
alter table public.dokumen enable row level security;
alter table public.pendampingan enable row level security;
alter table public.riwayat enable row level security;

-- Profil: pengguna yang sudah masuk dapat membaca profil (aplikasi hanya
-- memakai profil miliknya sendiri); penambahan/pengubahan profil dilakukan
-- administrator lewat SQL Editor (peran layanan Supabase melewati RLS),
-- sesuai langkah pembuatan akun di bagian 11. Kebijakan sengaja TIDAK
-- menanyakan tabel profiles dari dalam kebijakannya sendiri agar tidak
-- menimbulkan rekursi kebijakan PostgreSQL.
drop policy if exists "profil_baca_masuk" on public.profiles;
create policy "profil_baca_masuk" on public.profiles
  for select to authenticated using (true);
drop policy if exists "profil_ubah_sendiri" on public.profiles;
create policy "profil_ubah_sendiri" on public.profiles
  for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);

-- Data pemantauan: baca/tulis untuk pengguna yang sudah masuk.
do $$
declare t text;
begin
  foreach t in array array['kelas','siswa','presensi','catatan','dokumen','pendampingan','riwayat']
  loop
    execute format('drop policy if exists "akses_masuk_%s" on public.%I', t, t);
    execute format('create policy "akses_masuk_%s" on public.%I for all to authenticated using (true) with check (true)', t, t);
  end loop;
end $$;

-- ---------- 9. PENYIMPANAN BERKAS DOKUMEN (STORAGE) ----------
insert into storage.buckets (id, name, public)
values ('dokumen', 'dokumen', false)
on conflict (id) do nothing;

drop policy if exists "dokumen_file_baca" on storage.objects;
create policy "dokumen_file_baca" on storage.objects
  for select to authenticated using (bucket_id = 'dokumen');
drop policy if exists "dokumen_file_unggah" on storage.objects;
create policy "dokumen_file_unggah" on storage.objects
  for insert to authenticated with check (bucket_id = 'dokumen');
drop policy if exists "dokumen_file_ubah" on storage.objects;
create policy "dokumen_file_ubah" on storage.objects
  for update to authenticated using (bucket_id = 'dokumen');

-- ---------- 10. DATA CONTOH (KELAS PERCONTOHAN + 15 SISWA FIKSI) ----------
-- Boleh dihapus setelah data asli dimasukkan. Nama seluruhnya fiktif.
insert into public.kelas (nama, jurusan, tahun)
select 'X RPL 1', 'Rekayasa Perangkat Lunak', '2026/2027'
where not exists (select 1 from public.kelas where nama = 'X RPL 1');

insert into public.siswa (kelas_id, nama, nis, jk)
select k.id, v.nama, v.nis, v.jk
from public.kelas k
join (values
  ('Andi Pratama','26001','L'),('Siti Rahmawati','26002','P'),('Budi Hartono','26003','L'),
  ('Nur Aisyah','26004','P'),('Rizky Ramadhan','26005','L'),('Dewi Anggraini','26006','P'),
  ('Fajar Nugroho','26007','L'),('Intan Permata','26008','P'),('Hendra Wijaya','26009','L'),
  ('Maya Kusuma','26010','P'),('Rian Saputra','26011','L'),('Fitri Handayani','26012','P'),
  ('Agus Salim','26013','L'),('Rina Marlina','26014','P'),('Dedi Kurniawan','26015','L')
) as v(nama, nis, jk) on true
where k.nama = 'X RPL 1'
  and not exists (select 1 from public.siswa s where s.nis = v.nis);

-- ============================================================
-- 11. MEMBUAT AKUN PENGGUNA (dilakukan SETELAH langkah di atas)
-- ============================================================
-- a) Supabase Dashboard → Authentication → Users → Add user:
--    buat akun email+kata sandi untuk setiap pengguna, mis.:
--      admin@smkn1maros.sch.id      (Administrator)
--      walikelas@smkn1maros.sch.id  (Wali Kelas)
--      guru@smkn1maros.sch.id       (Guru Mata Pelajaran)
--    Centang "Auto Confirm User" agar akun langsung aktif.
-- b) Salin UUID masing-masing user dari daftar Users, lalu
--    jalankan SQL berikut dengan UUID yang sesuai:
--
-- insert into public.profiles (id, nama, peran) values
--   ('<UUID-ADMIN>', 'Nama Administrator', 'admin'),
--   ('<UUID-WALI>',  'Nama Wali Kelas', 'walikelas'),
--   ('<UUID-GURU>',  'Nama Guru', 'guru')
-- on conflict (id) do update set nama = excluded.nama, peran = excluded.peran;
-- ============================================================
