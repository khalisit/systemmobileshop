import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_toast.dart';
import '../providers/auth_provider.dart';
import '../providers/users_provider.dart';
import '../models/app_user_model.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String? _currentUid() {
    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  void _showCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CreateUserDialog(ref: ref),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    if (authState.isCashier) {
      return Scaffold(
        backgroundColor: AppTheme.darkBg,
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E293B),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: Color(0xFFEF4444),
                  size: 54,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'دەسەڵاتی بینینی ئەم پەڕەیەت نییە',
                style: TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'بەشی بەکارهێنەران تەنها بۆ بەڕێوەبەر (Admin) بەردەستە.',
                style: TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 13,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text(
                  'گەڕانەوە',
                  style: TextStyle(fontFamily: 'Rabar'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final usersAsync = ref.watch(usersProvider);
    final currentUid = _currentUid();

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
        title: usersAsync.when(
          data: (users) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'بەڕێوەبردنی بەکارهێنەران و رۆڵەکان',
                style: TextStyle(
                  fontFamily: 'NRT',
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                '${users.length} هەژماری تۆمارکراو',
                style: const TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 11,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
          loading: () => const Text(
            'بەڕێوەبردنی بەکارهێنەران',
            style: TextStyle(
              fontFamily: 'NRT',
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          error: (_, _) => const Text(
            'بەڕێوەبردنی بەکارهێنەران',
            style: TextStyle(
              fontFamily: 'NRT',
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(usersProvider),
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white60,
              size: 22,
            ),
            tooltip: 'نوێکردنەوە',
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.manage_accounts_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
        elevation: 6,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text(
          'هەژمارێکی نوێ',
          style: TextStyle(
            fontFamily: 'Rabar',
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: usersAsync.when(
        loading: () => _UsersTableLoading(),
        error: (e, _) =>
            _ErrorView(onRetry: () => ref.invalidate(usersProvider)),
        data: (allUsers) {
          final adminCount = allUsers.where((u) => u.isAdmin).length;
          final cashierCount = allUsers.where((u) => u.isCashier).length;

          final filteredUsers = allUsers.where((u) {
            if (_searchQuery.trim().isEmpty) return true;
            final q = _searchQuery.trim().toLowerCase();
            return u.fullName.toLowerCase().contains(q) ||
                u.username.toLowerCase().contains(q) ||
                (u.email != null && u.email!.toLowerCase().contains(q));
          }).toList();

          return RefreshIndicator(
            color: const Color(0xFF8B5CF6),
            backgroundColor: AppTheme.cardBg,
            onRefresh: () async => ref.invalidate(usersProvider),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 650;
                      return Flex(
                        direction: isWide ? Axis.horizontal : Axis.vertical,
                        children: [
                          Expanded(
                            flex: isWide ? 1 : 0,
                            child: _StatCard(
                              title: 'کۆی هەژمارەکان',
                              value: '${allUsers.length} بەکارهێنەر',
                              icon: Icons.people_alt_rounded,
                              color: const Color(0xFF8B5CF6),
                            ),
                          ),
                          SizedBox(
                            width: isWide ? 12 : 0,
                            height: isWide ? 0 : 10,
                          ),
                          Expanded(
                            flex: isWide ? 1 : 0,
                            child: _StatCard(
                              title: 'بەڕێوەبەران (Admins)',
                              value: '$adminCount بەکارهێنەر',
                              icon: Icons.admin_panel_settings_rounded,
                              color: const Color(0xFF0284C7),
                            ),
                          ),
                          SizedBox(
                            width: isWide ? 12 : 0,
                            height: isWide ? 0 : 10,
                          ),
                          Expanded(
                            flex: isWide ? 1 : 0,
                            child: _StatCard(
                              title: 'کاشێرەکان (Cashiers)',
                              value: '$cashierCount کاشێر',
                              icon: Icons.point_of_sale_rounded,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 18),

                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: const TextStyle(
                        fontFamily: 'Rabar',
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'گەڕان بە ناو، یوزەرنەیم، ئیمەیل یان رۆڵ...',
                        hintStyle: const TextStyle(
                          fontFamily: 'Rabar',
                          color: Colors.white38,
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF8B5CF6),
                          size: 22,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white38,
                                  size: 18,
                                ),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  if (filteredUsers.isEmpty && _searchQuery.isNotEmpty)
                    const _EmptySearchResultView()
                  else if (allUsers.isEmpty)
                    const _EmptyView()
                  else
                    _UsersTable(
                      users: filteredUsers,
                      currentUid: currentUid,
                      ref: ref,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 11.5,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'NRT',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.03);
  }
}

class _UsersTable extends StatelessWidget {
  final List<AppUserModel> users;
  final String? currentUid;
  final WidgetRef ref;

  const _UsersTable({
    required this.users,
    required this.currentUid,
    required this.ref,
  });

  static const TextStyle _hStyle = TextStyle(
    fontFamily: 'Rabar',
    fontWeight: FontWeight.bold,
    color: Colors.white70,
    fontSize: 13,
  );

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.09),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: (screenWidth - 32).clamp(700.0, 5000.0),
            ),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFF231649)),
              dataRowColor: WidgetStateProperty.resolveWith(
                (_) => Colors.white.withValues(alpha: 0.015),
              ),
              dividerThickness: 0.4,
              columnSpacing: 28,
              headingRowHeight: 52,
              dataRowMinHeight: 62,
              dataRowMaxHeight: 72,
              columns: const [
                DataColumn(label: Text('#', style: _hStyle)),
                DataColumn(label: Text('ناو و ئەڤەتار', style: _hStyle)),
                DataColumn(label: Text('یوزەرنەیم', style: _hStyle)),
                DataColumn(label: Text('ئیمەیل', style: _hStyle)),
                DataColumn(label: Text('رۆڵ / دەسەڵات', style: _hStyle)),
                DataColumn(label: Text('بەرواری تۆمار', style: _hStyle)),
                DataColumn(label: Text('کردارەکان', style: _hStyle)),
              ],
              rows: users.asMap().entries.map((entry) {
                final i = entry.key;
                final u = entry.value;
                final isSelf = u.id == currentUid;
                final isCashier = u.isCashier;
                final initial = u.fullName.isNotEmpty
                    ? u.fullName[0].toUpperCase()
                    : (u.username.isNotEmpty
                          ? u.username[0].toUpperCase()
                          : '?');
                final date =
                    '${u.createdAt.year}/${u.createdAt.month.toString().padLeft(2, '0')}/${u.createdAt.day.toString().padLeft(2, '0')}';

                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        '${i + 1}',
                        style: const TextStyle(
                          fontFamily: 'NRT',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white38,
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isCashier
                                    ? [
                                        const Color(0xFF10B981),
                                        const Color(0xFF059669),
                                      ]
                                    : [
                                        const Color(0xFF8B5CF6),
                                        const Color(0xFF6366F1),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(11),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      (isCashier
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFF8B5CF6))
                                          .withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  fontFamily: 'NRT',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                u.fullName.isNotEmpty ? u.fullName : u.username,
                                style: const TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (isSelf)
                                Container(
                                  margin: const EdgeInsets.only(top: 3),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF10B981,
                                    ).withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF10B981,
                                      ).withValues(alpha: 0.4),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: const Text(
                                    'هەژماری تۆ',
                                    style: TextStyle(
                                      fontFamily: 'Rabar',
                                      fontSize: 9.5,
                                      color: Color(0xFF10B981),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF8B5CF6,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(
                              0xFF8B5CF6,
                            ).withValues(alpha: 0.25),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          '@${u.username}',
                          style: const TextStyle(
                            fontFamily: 'NRT',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFA78BFA),
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.email_outlined,
                            size: 14,
                            color: Colors.white38,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            u.email ?? '—',
                            style: const TextStyle(
                              fontFamily: 'NRT',
                              fontSize: 12.5,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (isCashier
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF0284C7))
                                  .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                (isCashier
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFF0284C7))
                                    .withValues(alpha: 0.4),
                            width: 0.9,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isCashier
                                  ? Icons.point_of_sale_rounded
                                  : Icons.admin_panel_settings_rounded,
                              size: 14,
                              color: isCashier
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF38BDF8),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isCashier ? 'کاشێر' : 'بەڕێوەبەر',
                              style: TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isCashier
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF38BDF8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 13,
                            color: Colors.white38,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            date,
                            style: const TextStyle(
                              fontFamily: 'NRT',
                              fontSize: 12,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ActionBtn(
                            icon: Icons.edit_rounded,
                            color: const Color(0xFF38BDF8),
                            tooltip: 'ئیدیت کردنی زانیاری و رۆڵ',
                            onTap: () => _showEditDialog(context, u, ref),
                          ),
                          const SizedBox(width: 8),
                          if (!isSelf)
                            _ActionBtn(
                              icon: Icons.delete_outline_rounded,
                              color: const Color(0xFFEF4444),
                              tooltip: 'سڕینەوەی هەژمار',
                              onTap: () => _confirmDelete(context, u, ref),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.04, end: 0);
  }

  void _showEditDialog(BuildContext context, AppUserModel user, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _EditUserDialog(user: user, ref: ref),
    );
  }

  void _confirmDelete(BuildContext context, AppUserModel user, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'سڕینەوەی هەژمار',
          style: TextStyle(
            fontFamily: 'NRT',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        content: Text(
          'ئایا دڵنیایت لە سڕینەوەی بەکارهێنەر (${user.fullName})؟',
          style: const TextStyle(fontFamily: 'Rabar', color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'پاشگەزبوونەوە',
              style: TextStyle(fontFamily: 'Rabar', color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(usersProvider.notifier).deleteUser(user.id);
              if (context.mounted) {
                AppToast.show(
                  context,
                  'هەژمارەکە بە سەرکەوتوویی سڕایەوە.',
                  type: ToastType.success,
                );
              }
            },
            child: const Text('سڕینەوە', style: TextStyle(fontFamily: 'Rabar')),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
          ),
          child: Icon(icon, color: color, size: 17),
        ),
      ),
    );
  }
}

class _UsersTableLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: List.generate(
              3,
              (i) => Expanded(
                child:
                    Container(
                          margin: EdgeInsets.only(right: i < 2 ? 12 : 0),
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat())
                        .shimmer(duration: 1200.ms, color: Colors.white12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: List.generate(
                  5,
                  (_) =>
                      Container(
                            margin: const EdgeInsets.all(16),
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          )
                          .animate(onPlay: (c) => c.repeat())
                          .shimmer(duration: 1200.ms, color: Colors.white12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline_rounded,
                color: Color(0xFF8B5CF6),
                size: 54,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'هیچ هەژمارێک لە سیستمەکەدا نییە',
              style: TextStyle(
                fontFamily: 'NRT',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'دەتوانیت یەکەم بەکارهێنەر درووستبکەیت بە داگرتنی دوگمەی خوارەوە.',
              style: TextStyle(
                fontFamily: 'Rabar',
                fontSize: 12.5,
                color: Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySearchResultView extends StatelessWidget {
  const _EmptySearchResultView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 50),
        child: Column(
          children: [
            const Icon(
              Icons.search_off_rounded,
              color: Colors.white30,
              size: 48,
            ),
            const SizedBox(height: 12),
            const Text(
              'هیچ هەژمارێک نەدۆزرایەوە!',
              style: TextStyle(
                fontFamily: 'NRT',
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'تکایە وشەی گەڕانەکەت بگۆڕە یان تاقیبکەرەوە.',
              style: TextStyle(
                fontFamily: 'Rabar',
                fontSize: 12,
                color: Colors.white38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFEF4444),
              size: 48,
            ),
            const SizedBox(height: 14),
            const Text(
              'نەتوانرا لیستی بەکارهێنەران بهێنرێتەوە',
              style: TextStyle(
                fontFamily: 'NRT',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
              ),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(
                'دووبارە تاقیبکەرەوە',
                style: TextStyle(fontFamily: 'Rabar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateUserDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _CreateUserDialog({required this.ref});

  @override
  ConsumerState<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends ConsumerState<_CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  String _selectedRole = 'admin'; // 'admin' or 'cashier'
  bool _isLoading = false;
  bool _obscurePass = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final err = await widget.ref
        .read(usersProvider.notifier)
        .createUser(
          username: _usernameCtrl.text.trim(),
          password: _passwordCtrl.text,
          role: _selectedRole,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (err == null) {
      Navigator.pop(context);
      AppToast.show(
        context,
        'هەژماری نوێ بە سەرکەوتوویی لەگەڵ سۆپابەیس تۆمارکرا!',
        type: ToastType.success,
      );
    } else {
      AppToast.show(context, err, type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 480,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172A),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(23),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.person_add_rounded,
                          color: Color(0xFF8B5CF6),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'درووستکردنی هەژماری نوێ',
                            style: TextStyle(
                              fontFamily: 'NRT',
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'زانیارییەکان لەگەڵ Supabase Auth پاشەکەوت دەبن',
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 11,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DialogInput(
                        controller: _usernameCtrl,
                        label: 'ناوی بەکارهێنەر (یوزەرنەیم)',
                        hint: 'نمونە: karzan',
                        icon: Icons.alternate_email_rounded,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'تکایە ناوی بەکارهێنەر بنووسە';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      _DialogInput(
                        controller: _passwordCtrl,
                        label: 'وشەی نهێنی (پاسوۆرد)',
                        hint: 'لانیکەم ٦ پیت یان ژمارە',
                        icon: Icons.lock_outline_rounded,
                        obscure: _obscurePass,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePass
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.white54,
                            size: 18,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePass = !_obscurePass),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'تکایە پاسوۆرد بنووسە';
                          }
                          if (v.length < 6) {
                            return 'پاسوۆرد پێویستە لانیکەم ٦ پیت بێت';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'دیاریکردنی ڕۆڵ / دەسەڵاتی بەکارهێنەر',
                        style: TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 12.5,
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: _RoleChoiceCard(
                              title: 'بەڕێوەبەر',
                              subtitle: 'دەسەڵاتی تەواوی بەسەر سیستمدا هەیە',
                              icon: Icons.admin_panel_settings_rounded,
                              color: const Color(0xFF0284C7),
                              isSelected: _selectedRole == 'admin',
                              onTap: () =>
                                  setState(() => _selectedRole = 'admin'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _RoleChoiceCard(
                              title: 'کاشێر',
                              subtitle: 'تەنها دەسەڵاتی فرۆشتن و وەسڵی هەیە',
                              icon: Icons.point_of_sale_rounded,
                              color: const Color(0xFF10B981),
                              isSelected: _selectedRole == 'cashier',
                              onTap: () =>
                                  setState(() => _selectedRole = 'cashier'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 16,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172A),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(23),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text(
                          'پاشگەزبوونەوە',
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            color: Colors.white54,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isLoading ? null : _submit,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check_circle_rounded, size: 18),
                        label: Text(
                          _isLoading ? 'لە پرۆسەدایە...' : 'درووستکردنی هەژمار',
                          style: const TextStyle(
                            fontFamily: 'Rabar',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditUserDialog extends ConsumerStatefulWidget {
  final AppUserModel user;
  final WidgetRef ref;

  const _EditUserDialog({required this.user, required this.ref});

  @override
  ConsumerState<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends ConsumerState<_EditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameCtrl;
  late TextEditingController _passwordCtrl;
  late String _selectedRole;
  bool _isLoading = false;
  bool _obscurePass = true;

  @override
  void initState() {
    super.initState();
    _usernameCtrl = TextEditingController(text: widget.user.username);
    _passwordCtrl = TextEditingController();
    _selectedRole = widget.user.role;
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final err = await widget.ref
        .read(usersProvider.notifier)
        .updateUser(
          id: widget.user.id,
          username: _usernameCtrl.text.trim(),
          password: _passwordCtrl.text.trim().isEmpty ? null : _passwordCtrl.text.trim(),
          role: _selectedRole,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (err == null) {
      Navigator.pop(context);
      AppToast.show(
        context,
        'گۆڕانکارییەکان بە سەرکەوتوویی پاشەکەوت کران.',
        type: ToastType.success,
      );
    } else {
      AppToast.show(context, err, type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 480,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172A),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(23),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          color: Color(0xFF38BDF8),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ئیدیتکردنی بەکارهێنەر',
                            style: TextStyle(
                              fontFamily: 'NRT',
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'گۆڕینی یوزەرنەیم یان رۆڵی بەکارهێنەر',
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 11,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DialogInput(
                        controller: _usernameCtrl,
                        label: 'ناوی بەکارهێنەر (یوزەرنەیم)',
                        hint: 'ناوی بەکارهێنەر',
                        icon: Icons.alternate_email_rounded,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'تکایە ناوی بەکارهێنەر بنووسە';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Password change field
                      _DialogInput(
                        controller: _passwordCtrl,
                        label: 'وشەی نهێنی نوێ (ئارەزوومەندانە)',
                        hint: 'بەتاڵی جێبهێڵە ئەگەر نایگۆڕیت',
                        icon: Icons.lock_outline_rounded,
                        obscure: _obscurePass,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePass
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.white54,
                            size: 18,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePass = !_obscurePass),
                        ),
                        validator: (v) {
                          if (v != null && v.isNotEmpty && v.length < 6) {
                            return 'پاسوۆرد پێویستە لانیکەم ٦ پیت بێت';
                          }
                          return null;
                        },
                      ),

                      // Show role section only for other users
                      if (Supabase.instance.client.auth.currentUser?.id !=
                          widget.user.id) ...[  
                        const SizedBox(height: 20),

                        const Text(
                          'گۆڕینی ڕۆڵ / دەسەڵات',
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 12.5,
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Expanded(
                              child: _RoleChoiceCard(
                                title: 'بەڕێوەبەر',
                                subtitle: 'دەسەڵاتی تەواوی بەسەر سیستمدا هەیە',
                                icon: Icons.admin_panel_settings_rounded,
                                color: const Color(0xFF0284C7),
                                isSelected: _selectedRole == 'admin',
                                onTap: () =>
                                    setState(() => _selectedRole = 'admin'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _RoleChoiceCard(
                                title: 'کاشێر',
                                subtitle: 'تەنها دەسەڵاتی فرۆشتن و وەسڵی هەیە',
                                icon: Icons.point_of_sale_rounded,
                                color: const Color(0xFF10B981),
                                isSelected: _selectedRole == 'cashier',
                                onTap: () =>
                                    setState(() => _selectedRole = 'cashier'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 16,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172A),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(23),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text(
                          'پاشگەزبوونەوە',
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            color: Colors.white54,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF38BDF8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isLoading ? null : _submit,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check_circle_rounded, size: 18),
                        label: Text(
                          _isLoading
                              ? 'لە پاشەکەوتکردندایە...'
                              : 'هەڵگرتنی گۆڕانکارییەکان',
                          style: const TextStyle(
                            fontFamily: 'Rabar',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleChoiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleChoiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.16)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? color : Colors.white54,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'NRT',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isSelected ? Colors.white : Colors.white70,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontFamily: 'Rabar',
                fontSize: 10.5,
                color: Colors.white54,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffixIcon;
  final FormFieldValidator<String>? validator;

  const _DialogInput({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Rabar',
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          style: const TextStyle(
            fontFamily: 'Rabar',
            color: Colors.white,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontFamily: 'Rabar',
              color: Colors.white24,
              fontSize: 13,
            ),
            prefixIcon: Icon(icon, color: const Color(0xFF8B5CF6), size: 18),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF8B5CF6),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
