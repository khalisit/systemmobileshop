import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? email;
  final String? fullName;
  final String? username;
  final String role; // 'admin' or 'cashier'
  final String? errorMessage;
  final String? successMessage;

  const AuthState({
    required this.isAuthenticated,
    this.isLoading = false,
    this.email,
    this.fullName,
    this.username,
    this.role = 'admin',
    this.errorMessage,
    this.successMessage,
  });

  bool get isAdmin => role == 'admin';
  bool get isCashier => role == 'cashier';

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? email,
    String? fullName,
    String? username,
    String? role,
    String? errorMessage,
    String? successMessage,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      role: role ?? this.role,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState(isAuthenticated: false)) {
    refreshCurrentUser();
  }

  String _resolveEmail(String usernameOrEmail) {
    final trimmed = usernameOrEmail.trim().toLowerCase().replaceAll(' ', '_');
    if (trimmed.contains('@')) {
      return trimmed;
    }
    return '$trimmed@sinastore.com';
  }

  Future<void> refreshCurrentUser() async {
    if (SupabaseConfig.isConfigured()) {
      try {
        final response = await Supabase.instance.client.auth.getUser();
        final user = response.user;
        if (user != null) {
          final userMetaData = user.userMetadata;
          final role = (userMetaData?['role'] as String?) ?? 'admin';

          state = AuthState(
            isAuthenticated: true,
            email: user.email,
            fullName:
                userMetaData?['full_name'] as String? ??
                userMetaData?['username'] as String?,
            username: userMetaData?['username'] as String?,
            role: role,
          );
        }
      } catch (_) {}
    }
  }

  Future<bool> signInWithUsernameOrEmail(
    String usernameInput,
    String password,
  ) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      successMessage: null,
    );

    final cleanInput = usernameInput.trim().toLowerCase().replaceAll(' ', '_');
    String targetEmail = _resolveEmail(usernameInput);

    if (!SupabaseConfig.isConfigured()) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'زانیارییەکانی سۆپابەیس تۆمار نەکراون.',
      );
      return false;
    }

    // Attempt to lookup exact email from auth.users via RPC if username entered
    if (!cleanInput.contains('@')) {
      try {
        final response = await Supabase.instance.client.rpc('get_all_users');
        if (response is List) {
          for (final row in response) {
            final map = Map<String, dynamic>.from(row as Map);
            final email = map['email'] as String?;
            final meta = map['raw_user_meta_data'] as Map<String, dynamic>? ?? {};
            final uName = (meta['username'] as String?)?.toLowerCase();
            final fullName = (meta['full_name'] as String?)?.toLowerCase();
            final emailPrefix = email?.split('@').first.toLowerCase();

            if (email != null &&
                (uName == cleanInput ||
                 fullName == cleanInput ||
                 emailPrefix == cleanInput)) {
              targetEmail = email;
              break;
            }
          }
        }
      } catch (e) {
        debugPrint('RPC email lookup notice: $e');
      }
    }

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: targetEmail,
        password: password,
      );

      if (response.user != null) {
        final userMetaData = response.user?.userMetadata;
        final name =
            userMetaData?['full_name'] as String? ??
            userMetaData?['username'] as String? ??
            usernameInput;
        final role = (userMetaData?['role'] as String?) ?? 'admin';

        state = AuthState(
          isAuthenticated: true,
          email: response.user?.email,
          fullName: name,
          username: usernameInput,
          role: role,
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'ناوی بەکارهێنەر یان وشەی نهێنی هەڵەیە.',
        );
        return false;
      }
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'ناوی بەکارهێنەر یان وشەی نهێنی هەڵەیە: ${e.message}',
      );
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> signUpWithUsername(
    String usernameInput,
    String password, {
    String role = 'admin',
  }) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      successMessage: null,
    );

    final resolvedEmail = _resolveEmail(usernameInput);

    if (!SupabaseConfig.isConfigured()) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'زانیارییەکانی سۆپابەیس تۆمار نەکراون.',
      );
      return false;
    }

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: resolvedEmail,
        password: password,
        data: {
          'full_name': usernameInput,
          'username': usernameInput,
          'role': role,
        },
      );

      if (response.user != null) {
        if (response.session != null) {
          state = AuthState(
            isAuthenticated: true,
            email: response.user?.email,
            fullName: usernameInput,
            username: usernameInput,
            role: role,
            isLoading: false,
          );
          return true;
        } else {
          state = state.copyWith(
            isLoading: false,
            successMessage:
                'هەژمارەکە بە سەرکەوتوویی درووستکرا! ئێستا دەتوانیت بچیتە ژوورەوە.',
          );
          return true;
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'درووستکردنی هەژمار سەرکەوتوو نەبوو.',
        );
        return false;
      }
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<String?> verifyPassword(String password) async {
    if (password.trim().isEmpty) {
      return 'تکایە وشەی نهێنی بنووسە!';
    }

    if (!SupabaseConfig.isConfigured()) {
      return 'زانیارییەکانی سۆپابەیس تۆمار نەکراون.';
    }

    final emailToVerify =
        state.email ??
        (state.username != null ? _resolveEmail(state.username!) : null);
    if (emailToVerify == null) {
      return 'هیچ هەژمارێکی چالاک نەدۆزرایەوە بۆ سەلماندنی پاسوۆرد.';
    }

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: emailToVerify,
        password: password,
      );
      return null;
    } on AuthException catch (_) {
      return 'وشەی نهێنی (پاسوۆرد) هەڵەیە!';
    } catch (e) {
      return 'هەڵەیەک ڕوویدا: ${e.toString()}';
    }
  }

  Future<String?> updateProfile({
    String? fullName,
    String? username,
    String? email,
    String? newPassword,
  }) async {
    if (!SupabaseConfig.isConfigured()) return 'سۆپابەیس تۆمار نەکراوە.';

    try {
      final metaData = <String, dynamic>{};
      if (fullName != null && fullName.isNotEmpty) metaData['full_name'] = fullName;
      if (username != null && username.isNotEmpty) metaData['username'] = username;

      final response = await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          email: email != null && email.isNotEmpty ? email : null,
          password: newPassword != null && newPassword.isNotEmpty ? newPassword : null,
          data: metaData.isNotEmpty ? metaData : null,
        ),
      );

      if (response.user != null) {
        final meta = response.user!.userMetadata;
        state = state.copyWith(
          email: response.user?.email ?? email ?? state.email,
          fullName: meta?['full_name'] as String? ?? fullName ?? state.fullName,
          username: meta?['username'] as String? ?? username ?? state.username,
        );
        return null; // success
      }
      return 'نەتوانرا گۆڕانکاری بکرێت.';
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    if (SupabaseConfig.isConfigured()) {
      await Supabase.instance.client.auth.signOut();
    }
    state = const AuthState(isAuthenticated: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
