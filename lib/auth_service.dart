import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      // ======================
      // 1️⃣ LOGIN AUTH
      // ======================
      final res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = res.user;
      if (user == null) {
        return {"error": "Login gagal. Email atau password salah."};
      }

      // ======================
      // 2️⃣ CEK PROFILES (admin / peminjam)
      // ======================
      final profile = await _supabase
          .from('profiles')
          .select('role')
          .eq('userid', user.id)
          .maybeSingle();

      if (profile != null && profile['role'] != null) {
        final role = profile['role'].toString().toLowerCase();
        return {
          "error": null,
          "role": role, // admin / peminjam
        };
      }

      // ======================
      // 3️⃣ CEK PETUGAS
      // ======================
      final petugas = await _supabase
          .from('petugas')
          .select('id')
          .eq('userid', user.id) // ⬅️ FIX
          .maybeSingle();

      if (petugas != null) {
        return {"error": null, "role": "petugas"};
      }

      // ======================
      // 4️⃣ TIDAK TERDAFTAR
      // ======================
      return {
        "error": "Akun tidak terdaftar sebagai admin, peminjam, atau petugas.",
      };
    } on AuthException catch (e) {
      return {"error": e.message};
    } catch (e) {
      return {"error": "Terjadi kesalahan: $e"};
    }
  }
}
