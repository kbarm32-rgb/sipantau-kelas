// SIPANTAU KELAS v1.0 — Jembatan konfigurasi server (Vercel Function)
// Membaca Environment Variables di Vercel dan memberikannya ke aplikasi
// dalam bentuk yang aman untuk klien. Nilai variabel TIDAK PERNAH ditulis
// di dalam kode atau repo GitHub — atur di: Vercel → Project → Settings →
// Environment Variables, dengan nama persis:
//   SUPABASE_URL        = https://<project-ref>.supabase.co
//   SUPABASE_ANON_KEY   = publishable/anon key dari Supabase (sb_publishable_... / eyJ...)
export default function handler(req, res) {
  const supabaseUrl = process.env.SUPABASE_URL || '';
  const supabaseAnonKey = process.env.SUPABASE_ANON_KEY || '';
  res.setHeader('Cache-Control', 'no-store');
  res.status(200).json({
    configured: Boolean(supabaseUrl && supabaseAnonKey),
    supabaseUrl,
    supabaseAnonKey,
  });
}
