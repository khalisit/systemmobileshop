import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../core/config/supabase_config.dart';
import '../models/app_user_model.dart';

class UsersNotifier extends StateNotifier<AsyncValue<List<AppUserModel>>> {
  final List<AppUserModel> _localUsers = [];

  UsersNotifier() : super(const AsyncValue.loading()) {
    fetch();
  }

  String _resolveEmail(String input) {
    final clean = input.trim().toLowerCase().replaceAll(' ', '_');
    if (clean.contains('@')) return clean;
    return '$clean@sinastore.com';
  }

  Future<void> fetch() async {
    if (SupabaseConfig.isConfigured()) {
      // 1. Ensure current logged-in user from Supabase Auth is in _localUsers
      try {
        final currentUser = Supabase.instance.client.auth.currentUser;
        if (currentUser != null) {
          final meta = currentUser.userMetadata;
          final username =
              meta?['username'] as String? ??
              currentUser.email?.split('@').first ??
              'admin';
          final selfUser = AppUserModel(
            id: currentUser.id,
            username: username,
            fullName: meta?['full_name'] as String? ?? username,
            email: currentUser.email,
            role: meta?['role'] as String? ?? 'admin',
            createdAt:
                DateTime.tryParse(currentUser.createdAt) ?? DateTime.now(),
          );
          final idx = _localUsers.indexWhere((u) => u.id == selfUser.id);
          if (idx >= 0) {
            _localUsers[idx] = selfUser;
          } else {
            _localUsers.insert(0, selfUser);
          }
        }
      } catch (_) {}

      // 2. Fetch from auth.users via RPC get_all_users
      try {
        final response = await Supabase.instance.client.rpc('get_all_users');
        for (final row in (response as List)) {
          final map = Map<String, dynamic>.from(row as Map);
          final fetchedUser = AppUserModel.fromJson(map);
          final idx = _localUsers.indexWhere((u) => u.id == fetchedUser.id);
          if (idx >= 0) {
            _localUsers[idx] = fetchedUser;
          } else {
            _localUsers.add(fetchedUser);
          }
        }
      } catch (e) {
        debugPrint('RPC get_all_users notice: $e');
      }
    }

    state = AsyncValue.data(List.from(_localUsers));
  }

  /// Create a new user (syncing Supabase Auth + _localUsers list)
  Future<String?> createUser({
    required String username,
    required String password,
    required String role,
    String? fullName,
    String? email,
  }) async {
    final cleanUsername = username.trim().toLowerCase().replaceAll(' ', '_');
    final resolvedEmail = email != null && email.isNotEmpty
        ? email
        : _resolveEmail(cleanUsername);
    final name = fullName != null && fullName.isNotEmpty
        ? fullName
        : cleanUsername;
    final generatedId = const Uuid().v4();
    String newId = generatedId;

    if (SupabaseConfig.isConfigured()) {
      // Register with Supabase Auth using isolated client with implicit flow to preserve Admin session
      try {
        final tempAuthClient = SupabaseClient(
          SupabaseConfig.supabaseUrl,
          SupabaseConfig.supabaseAnonKey,
          authOptions: const AuthClientOptions(
            authFlowType: AuthFlowType.implicit,
          ),
        );
        final response = await tempAuthClient.auth.signUp(
          email: resolvedEmail,
          password: password,
          data: {'full_name': name, 'username': cleanUsername, 'role': role},
        );
        if (response.user != null) {
          newId = response.user!.id;
        }
      } catch (e) {
        debugPrint('Auth signUp notice: $e');
      }
    }

    final newUser = AppUserModel(
      id: newId,
      username: cleanUsername,
      fullName: name,
      email: resolvedEmail,
      role: role,
      createdAt: DateTime.now(),
    );

    _localUsers.removeWhere((u) => u.id == newId);
    _localUsers.insert(0, newUser);
    state = AsyncValue.data(List.from(_localUsers));
    return null;
  }

  /// Update user profile (syncing _localUsers + Supabase Auth)
  Future<String?> updateUser({
    required String id,
    required String username,
    String? password,
    String? role,
  }) async {
    final cleanUsername = username.trim().toLowerCase().replaceAll(' ', '_');
    final resolvedEmail = _resolveEmail(cleanUsername);
    final fullName = cleanUsername;
    final updatedRole = role ?? 'admin';

    if (SupabaseConfig.isConfigured()) {
      final currentUser = Supabase.instance.client.auth.currentUser;
      final isSelf = currentUser != null && currentUser.id == id;

      // Update metadata (username, role, full_name) — only works for self
      if (isSelf) {
        try {
          await Supabase.instance.client.auth.updateUser(
            UserAttributes(
              data: {
                'username': cleanUsername,
                'full_name': fullName,
                'role': updatedRole,
              },
            ),
          );
        } catch (e) {
          debugPrint('Auth updateUser (self) notice: $e');
        }
      }

      // Update password via RPC for ANY user (self or other)
      if (password != null && password.trim().isNotEmpty) {
        try {
          await Supabase.instance.client.rpc(
            'update_user_password',
            params: {'user_id': id, 'new_password': password.trim()},
          );
        } catch (e) {
          debugPrint('RPC update_user_password notice: $e');
          // Return error so UI can show it
          return 'نەتوانرا پاسوۆردەکە بگۆڕدرێت: $e';
        }
      }

      // Update metadata for other users via RPC
      if (!isSelf) {
        try {
          await Supabase.instance.client.rpc(
            'update_user_info',
            params: {
              'target_user_id': id,
              'new_username': cleanUsername,
              'new_role': updatedRole,
              'new_full_name': fullName,
            },
          );
        } catch (e) {
          debugPrint('RPC update_user_info notice: $e');
        }
      }
    }


    final idx = _localUsers.indexWhere((u) => u.id == id);
    if (idx >= 0) {
      final old = _localUsers[idx];
      _localUsers[idx] = AppUserModel(
        id: id,
        username: cleanUsername,
        fullName: fullName,
        email: resolvedEmail,
        role: role ?? old.role,
        createdAt: old.createdAt,
      );
    }
    state = AsyncValue.data(List.from(_localUsers));
    return null;
  }

  /// Delete user from auth.users (via RPC) and _localUsers
  Future<String?> deleteUser(String id) async {
    if (SupabaseConfig.isConfigured()) {
      try {
        await Supabase.instance.client.rpc(
          'delete_user_by_id',
          params: {'user_id': id},
        );
      } catch (e) {
        debugPrint('RPC delete_user_by_id notice: $e');
      }
    }

    _localUsers.removeWhere((u) => u.id == id);
    state = AsyncValue.data(List.from(_localUsers));
    return null;
  }
}

final usersProvider =
    StateNotifierProvider<UsersNotifier, AsyncValue<List<AppUserModel>>>((ref) {
      return UsersNotifier();
    });
