import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_toast.dart';
import 'pos_screen.dart';
import 'receipts_screen.dart';
import 'inventory_screen.dart';
import 'categories_screen.dart';
import 'debtors_screen.dart';
import 'revenue_screen.dart';
import 'users_screen.dart';
import 'deletions_screen.dart';
import 'repairs_screen.dart';
import 'repair_types_screen.dart';
import '../providers/pos_provider.dart';
import '../providers/receipts_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/category_provider.dart';
import '../providers/repair_receipts_provider.dart';
import '../providers/repair_types_provider.dart';
import '../providers/users_provider.dart';
import '../models/receipt_model.dart';

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isCashier = authState.isCashier;

    final actions = [
      _QuickAction(
        label: 'فرۆشتنی نوێ',
        icon: Icons.point_of_sale_rounded,
        color: AppTheme.accentColor,
        onTap: () {
          ref.read(posProvider.notifier).clear();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PosScreen()),
          );
        },
      ),
      _QuickAction(
        label: 'بەشی چاکردنەوە',
        icon: Icons.home_repair_service_rounded,
        color: const Color(0xFF06B6D4),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RepairsScreen()),
        ),
      ),
      _QuickAction(
        label: 'وەسڵەکان',
        icon: Icons.receipt_long_rounded,
        color: const Color(0xFF6366F1),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReceiptsScreen()),
        ),
      ),
      _QuickAction(
        label: 'قەرزارەکان',
        icon: Icons.account_balance_wallet_rounded,
        color: const Color(0xFFF59E0B),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DebtorsScreen()),
        ),
      ),
      if (!isCashier)
        _QuickAction(
          label: 'کۆگا',
          icon: Icons.inventory_2_rounded,
          color: AppTheme.primaryColor,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const InventoryScreen()),
          ),
        ),
      _QuickAction(
        label: 'جۆری کاڵاکان',
        icon: Icons.category_rounded,
        color: const Color(0xFFEC4899),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CategoriesScreen()),
        ),
      ),
      _QuickAction(
        label: 'جۆری چاکردنەوە',
        icon: Icons.settings_suggest_rounded,
        color: const Color(0xFF06B6D4),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RepairTypesScreen()),
        ),
      ),
      if (!isCashier) ...[
        _QuickAction(
          label: 'داهات',
          icon: Icons.insights_rounded,
          color: const Color(0xFF10B981),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RevenueScreen()),
          ),
        ),
        _QuickAction(
          label: 'بەکارهێنەران',
          icon: Icons.manage_accounts_rounded,
          color: const Color(0xFF8B5CF6),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UsersScreen()),
          ),
        ),
        _QuickAction(
          label: 'بەشی سڕینەوە',
          icon: Icons.delete_sweep_rounded,
          color: const Color(0xFFEF4444),
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => const DeletionSectionAuthDialog(),
            );
          },
        ),
      ],
    ];

    final receiptsAsync = ref.watch(receiptsProvider);
    final inventoryAsync = ref.watch(inventoryProvider);

    final allReceipts = receiptsAsync.maybeWhen(
      data: (list) => list,
      orElse: () => <ReceiptModel>[],
    );
    final allProducts = inventoryAsync.maybeWhen(
      data: (list) => list,
      orElse: () => [],
    );

    final now = DateTime.now();

    final todayReceipts = allReceipts
        .where(
          (r) =>
              r.date.year == now.year &&
              r.date.month == now.month &&
              r.date.day == now.day,
        )
        .toList();
    final todayRevenue = todayReceipts.fold<double>(
      0.0,
      (sum, r) => sum + r.grandTotal,
    );

    final monthReceipts = allReceipts
        .where((r) => r.date.year == now.year && r.date.month == now.month)
        .toList();
    final monthRevenue = monthReceipts.fold<double>(
      0.0,
      (sum, r) => sum + r.grandTotal,
    );

    final yearReceipts = allReceipts
        .where((r) => r.date.year == now.year)
        .toList();
    final yearRevenue = yearReceipts.fold<double>(
      0.0,
      (sum, r) => sum + r.grandTotal,
    );

    final debtReceipts = allReceipts
        .where((r) => r.paymentMethod == 'قەرز' && r.remainingAmount > 0)
        .toList();
    final totalDebtAmount = debtReceipts.fold<double>(
      0.0,
      (sum, r) => sum + r.remainingAmount,
    );

    final totalStockItems = allProducts
        .fold<num>(0, (sum, p) => sum + p.stock)
        .toInt();

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF06142E),
                    Color(0xFF0F172A),
                    Color(0xFF0284C7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -30,
                    top: -40,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0284C7), Color(0xFF6366F1)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF0284C7,
                                  ).withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.storefront_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ئایتی سەنتەر',
                                style: TextStyle(
                                  fontFamily: 'NRT',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'بەخێربێتەوە، ${authState.fullName ?? 'بەڕێوەبەر'} 👋',
                                style: const TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  color: Color(0xFF38BDF8),
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                    fontFamily: 'NRT',
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF38BDF8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Refresh Button
                          InkWell(
                            onTap: () {
                              ref.read(authProvider.notifier).refreshCurrentUser();
                              ref.invalidate(receiptsProvider);
                              ref.invalidate(inventoryProvider);
                              ref.invalidate(categoryProvider);
                              ref.invalidate(repairReceiptsProvider);
                              ref.invalidate(repairTypesProvider);
                              ref.invalidate(usersProvider);
                              AppToast.show(context, 'داتا تازەکرایەوە', type: ToastType.success);
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.greenAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.greenAccent.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.refresh_rounded,
                                color: Colors.greenAccent,
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          InkWell(
                            onTap: () => _confirmLogout(context, ref),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.redAccent.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.logout_rounded,
                                color: Colors.redAccent,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(title: 'کورتەی ئەمڕۆ'),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (isCashier) ...[
                          _StatCard(
                            title: 'فرۆشتنی ئەمڕۆ',
                            value: '\$${todayRevenue.toStringAsFixed(2)}',
                            delta: '${todayReceipts.length} وەسڵ',
                            positive: true,
                            icon: Icons.attach_money_rounded,
                            color: AppTheme.accentColor,
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DebtorsScreen(),
                              ),
                            ),
                            child: _StatCard(
                              title: 'قەرزارەکان',
                              value: '\$${totalDebtAmount.toStringAsFixed(2)}',
                              delta: '${debtReceipts.length} وەسڵ',
                              positive: false,
                              icon: Icons.account_balance_wallet_rounded,
                              color: const Color(0xFFF59E0B),
                            ),
                          ),
                        ] else ...[
                          _StatCard(
                            title: 'فرۆشتنی ئەمڕۆ',
                            value: '\$${todayRevenue.toStringAsFixed(2)}',
                            delta: '${todayReceipts.length} وەسڵ',
                            positive: true,
                            icon: Icons.attach_money_rounded,
                            color: AppTheme.accentColor,
                          ),
                          const SizedBox(width: 12),
                          _StatCard(
                            title: 'فرۆشتنی ئەم مانگە',
                            value: '\$${monthRevenue.toStringAsFixed(2)}',
                            delta: '${monthReceipts.length} وەسڵ',
                            positive: true,
                            icon: Icons.calendar_month_rounded,
                            color: const Color(0xFF6366F1),
                          ),
                          const SizedBox(width: 12),
                          _StatCard(
                            title: 'فرۆشتنی ئەمساڵ',
                            value: '\$${yearRevenue.toStringAsFixed(2)}',
                            delta: '${yearReceipts.length} وەسڵ',
                            positive: true,
                            icon: Icons.trending_up_rounded,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DebtorsScreen(),
                              ),
                            ),
                            child: _StatCard(
                              title: 'قەرزارەکان',
                              value: '\$${totalDebtAmount.toStringAsFixed(2)}',
                              delta: '${debtReceipts.length} وەسڵ',
                              positive: false,
                              icon: Icons.account_balance_wallet_rounded,
                              color: const Color(0xFFF59E0B),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const InventoryScreen(),
                              ),
                            ),
                            child: _StatCard(
                              title: 'کۆی کەل و پەل',
                              value: '$totalStockItems دانە',
                              delta: '${allProducts.length} جۆر',
                              positive: true,
                              icon: Icons.inventory_rounded,
                              color: const Color(0xFF8B5CF6),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  _SectionTitle(title: 'کردارە خێراکان'),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: actions.asMap().entries.map((entry) {
                      final i = entry.key;
                      final action = entry.value;
                      return _ActionTile(action: action, index: i);
                    }).toList(),
                  ),

                  const SizedBox(height: 28),

                  _SectionTitle(title: 'فرۆشتنە دوایییەکان'),
                  const SizedBox(height: 12),
                  if (allReceipts.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.surfaceColor),
                      ),
                      child: const Center(
                        child: Text(
                          'هیچ فرۆشتنێک تۆمار نەکراوە',
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            color: Colors.white38,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  else
                    ...allReceipts
                        .take(6)
                        .map((r) => _buildRecentSaleTile(context, r)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSaleTile(BuildContext context, ReceiptModel r) {
    final isDebt = r.paymentMethod == 'قەرز';
    final itemsText = r.items.map((i) => i.product.name).join('، ');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.surfaceColor, width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: (isDebt ? const Color(0xFFF59E0B) : AppTheme.primaryColor)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isDebt
                  ? Icons.account_balance_wallet_rounded
                  : Icons.shopping_bag_rounded,
              color: isDebt ? const Color(0xFFF59E0B) : AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.customerName.isEmpty ? 'کڕیاری گشتی' : r.customerName,
                  style: const TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  itemsText.isEmpty ? '${r.totalItems} دانە کاڵا' : itemsText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${r.grandTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: 'NRT',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentColor,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${r.date.hour.toString().padLeft(2, '0')}:${r.date.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontFamily: 'NRT',
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'دەرچوون',
          style: TextStyle(
            fontFamily: 'NRT',
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        content: const Text(
          'دڵنیایت کە دەتەوێت دەربچیت؟',
          style: TextStyle(fontFamily: 'Rabar', color: Colors.white70),
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
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authProvider.notifier).signOut();
            },
            child: const Text(
              'دەرچوون',
              style: TextStyle(fontFamily: 'Rabar', color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'NRT',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String delta;
  final bool positive;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.delta,
    required this.positive,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 155,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.surfaceColor, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: positive
                      ? AppTheme.accentColor.withValues(alpha: 0.15)
                      : Colors.redAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  delta,
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: positive ? AppTheme.accentColor : Colors.redAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'NRT',
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Rabar',
              fontSize: 12,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final _QuickAction action;
  final int index;

  const _ActionTile({required this.action, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        width: 175,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.surfaceColor, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: action.color.withValues(alpha: 0.15),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(action.icon, color: action.color, size: 34),
            ),
            const SizedBox(height: 14),
            Text(
              action.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Rabar',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: index * 40)).fadeIn().scale();
  }
}
