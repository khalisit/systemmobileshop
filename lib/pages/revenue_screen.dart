import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/receipts_provider.dart';
import '../models/receipt_model.dart';
import 'receipts_screen.dart';

class RevenueScreen extends ConsumerStatefulWidget {
  const RevenueScreen({super.key});

  @override
  ConsumerState<RevenueScreen> createState() => _RevenueScreenState();
}

class _RevenueScreenState extends ConsumerState<RevenueScreen> {
  String _selectedFilter = 'all';
  DateTimeRange? _customDateRange;
  final Set<String> _expandedReceiptIds = {};

  void _showCustomRangeDialog() async {
    DateTime? startDate =
        _customDateRange?.start ??
        DateTime.now().subtract(const Duration(days: 7));
    DateTime? endDate = _customDateRange?.end ?? DateTime.now();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: 320,
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white60,
                            size: 18,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          'دیاریکردنی بەروار',
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: AppTheme.surfaceColor, height: 16),
                    const Text(
                      'بەرواری دەستپێک:',
                      style: TextStyle(
                        fontFamily: 'Rabar',
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: startDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                          locale: const Locale('ckb'),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            startDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.darkBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.surfaceColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              color: Colors.white30,
                              size: 14,
                            ),
                            Text(
                              '${startDate!.year}/${startDate!.month.toString().padLeft(2, '0')}/${startDate!.day.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontFamily: 'NRT',
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'بەرواری کۆتایی:',
                      style: TextStyle(
                        fontFamily: 'Rabar',
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: endDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                          locale: const Locale('ckb'),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            endDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.darkBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.surfaceColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              color: Colors.white30,
                              size: 14,
                            ),
                            Text(
                              '${endDate!.year}/${endDate!.month.toString().padLeft(2, '0')}/${endDate!.day.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontFamily: 'NRT',
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 36,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          if (startDate != null && endDate != null) {
                            setState(() {
                              _customDateRange = DateTimeRange(
                                start: startDate!,
                                end: endDate!,
                              );
                              _selectedFilter = 'custom';
                            });
                            Navigator.pop(context);
                          }
                        },
                        child: const Text(
                          'جێبەجێکردن',
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Map<String, double> _getChartData(List<ReceiptModel> receipts) {
    final Map<String, double> sales = {};
    final now = DateTime.now();

    if (_selectedFilter == 'week') {
      int daysToSubtract = (now.weekday + 1) % 7; 
      final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysToSubtract));
      final dayNames = ['شەممە', 'یەکشەممە', 'دووشەممە', 'سێشەممە', 'چوارشەممە', 'پێنجشەممە', 'هەینی'];
      
      for (int i = 0; i < 7; i++) {
        final currentDay = startOfWeek.add(Duration(days: i));
        // Key: "dayName|day/month" so chart can render both lines
        final key = '${dayNames[i]}|${currentDay.day}/${currentDay.month}';
        sales[key] = 0.0;
        for (final r in receipts) {
          if (r.date.year == currentDay.year && r.date.month == currentDay.month && r.date.day == currentDay.day) {
            sales[key] = (sales[key] ?? 0) + r.grandTotal;
          }
        }
      }
    } else if (_selectedFilter == 'month') {
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      for (int i = 1; i <= daysInMonth; i++) {
        final label = '${now.month}/$i';
        sales[label] = 0.0;
        for (final r in receipts) {
          if (r.date.year == now.year && r.date.month == now.month && r.date.day == i) {
            sales[label] = (sales[label] ?? 0) + r.grandTotal;
          }
        }
      }
    } else if (_selectedFilter == 'year') {
      for (int i = 1; i <= 12; i++) {
        final label = '$i/${now.year}';
        sales[label] = 0.0;
        for (final r in receipts) {
          if (r.date.year == now.year && r.date.month == i) {
            sales[label] = (sales[label] ?? 0) + r.grandTotal;
          }
        }
      }
    } else if (_selectedFilter == 'today') {
      for (int i = 8; i <= 24; i += 2) {
        final label = '$i:00';
        sales[label] = 0.0;
        for (final r in receipts) {
          if (r.date.year == now.year && r.date.month == now.month && r.date.day == now.day) {
            if (r.date.hour >= i - 2 && r.date.hour < i) {
              sales[label] = (sales[label] ?? 0) + r.grandTotal;
            }
          }
        }
      }
    } else {
      // all or custom — group by individual date, show day name + full date
      final dayNamesAll = {
        DateTime.saturday: 'شەممە',
        DateTime.sunday: 'یەکشەممە',
        DateTime.monday: 'دووشەممە',
        DateTime.tuesday: 'سێشەممە',
        DateTime.wednesday: 'چوارشەممە',
        DateTime.thursday: 'پێنجشەممە',
        DateTime.friday: 'هەینی',
      };

      // Build a sorted list of unique dates
      final Map<String, double> byDate = {};
      for (final r in receipts) {
        final d = r.date;
        final dayName = dayNamesAll[d.weekday] ?? '';
        final key = '$dayName|${d.day}/${d.month}/${d.year}';
        byDate[key] = (byDate[key] ?? 0) + r.grandTotal;
      }

      // Sort by date ascending
      final sortedKeys = byDate.keys.toList()
        ..sort((a, b) {
          final partsA = a.split('|').last.split('/');
          final partsB = b.split('|').last.split('/');
          final dateA = DateTime(int.parse(partsA[2]), int.parse(partsA[1]), int.parse(partsA[0]));
          final dateB = DateTime(int.parse(partsB[2]), int.parse(partsB[1]), int.parse(partsB[0]));
          return dateA.compareTo(dateB);
        });

      for (final k in sortedKeys) {
        sales[k] = byDate[k]!;
      }

      if (sales.isEmpty) {
        final dayName = dayNamesAll[now.weekday] ?? '';
        sales['$dayName|${now.day}/${now.month}/${now.year}'] = 0.0;
      }
    }

    return sales;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (authState.isCashier) {
      return Scaffold(
        backgroundColor: AppTheme.darkBg,
        appBar: AppBar(
          backgroundColor: const Color(0xFF0C1A2E),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white70,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: Color(0xFF10B981),
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
                'بەشی ڕاپۆرتی داهات تەنها بۆ بەڕێوەبەر (Admin) بەردەستە.',
                style: TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 13,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final receiptsAsync = ref.watch(receiptsProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: const Color(
          0xFF0F5A47,
        ), // Green header bar from screenshot
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF14B8A6), // Cyan graph button
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.bar_chart_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ڕاپۆرتی داهات',
              style: TextStyle(
                fontFamily: 'Rabar',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              _selectedFilter == 'all'
                  ? 'هەموو تۆمارەکان'
                  : _selectedFilter == 'today'
                  ? 'ئەمڕۆ'
                  : _selectedFilter == 'week'
                  ? 'ئەم هەفتەیە'
                  : _selectedFilter == 'month'
                  ? 'ئەم مانگە'
                  : _selectedFilter == 'year'
                  ? 'ئەمساڵ'
                  : 'دیاریکراو',
              style: const TextStyle(
                fontFamily: 'Rabar',
                fontSize: 11,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
      body: receiptsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF10B981)),
        ),
        error: (err, _) => Center(
          child: Text(
            'هەڵەیەک ڕوویدا: $err',
            style: const TextStyle(fontFamily: 'Rabar', color: Colors.white),
          ),
        ),
        data: (allReceipts) {
          final now = DateTime.now();

          // Filter Logic
          List<ReceiptModel> filteredReceipts = [];
          if (_selectedFilter == 'today') {
            filteredReceipts = allReceipts
                .where(
                  (r) =>
                      r.date.year == now.year &&
                      r.date.month == now.month &&
                      r.date.day == now.day,
                )
                .toList();
          } else if (_selectedFilter == 'week') {
            final startOfWeek = DateTime(
              now.year,
              now.month,
              now.day,
            ).subtract(Duration(days: now.weekday - 1));
            filteredReceipts = allReceipts
                .where((r) => r.date.isAfter(startOfWeek))
                .toList();
          } else if (_selectedFilter == 'month') {
            filteredReceipts = allReceipts
                .where(
                  (r) => r.date.year == now.year && r.date.month == now.month,
                )
                .toList();
          } else if (_selectedFilter == 'year') {
            filteredReceipts = allReceipts
                .where((r) => r.date.year == now.year)
                .toList();
          } else if (_selectedFilter == 'custom' && _customDateRange != null) {
            filteredReceipts = allReceipts
                .where(
                  (r) =>
                      r.date.isAfter(
                        _customDateRange!.start.subtract(
                          const Duration(seconds: 1),
                        ),
                      ) &&
                      r.date.isBefore(
                        _customDateRange!.end.add(const Duration(days: 1)),
                      ),
                )
                .toList();
          } else {
            filteredReceipts = allReceipts;
          }

          // Computations
          double totalRevenue = 0.0;
          double totalCost = 0.0;
          double totalDiscount = 0.0;
          double debtAmount = 0.0;
          int debtCount = 0;
          double cashAmount = 0.0;
          int totalItemsQty = 0;

          for (final r in filteredReceipts) {
            totalRevenue += r.grandTotal;
            totalDiscount += r.discount;
            if (r.paymentMethod == 'قەرز') {
              debtAmount += r.remainingAmount;
              debtCount++;
            } else {
              cashAmount += r.grandTotal;
            }
            for (final item in r.items) {
              totalCost += (item.product.buyPrice * item.quantity);
              totalItemsQty += item.quantity;
            }
          }

          final double netProfit = totalRevenue - totalCost;
          final double profitMargin = totalRevenue > 0
              ? (netProfit / totalRevenue) * 100
              : 0.0;

          final chartData = _getChartData(filteredReceipts);

          return Directionality(
            textDirection: TextDirection.ltr,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildFilterChip(
                        'custom',
                        'دیاریکراو 📅',
                        onTap: _showCustomRangeDialog,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip('year', 'ساڵانە'),
                      const SizedBox(width: 8),
                      _buildFilterChip('month', 'مانگانە'),
                      const SizedBox(width: 8),
                      _buildFilterChip('week', 'هەفتانە'),
                      const SizedBox(width: 8),
                      _buildFilterChip('all', 'هەموو'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 2. Main Large Card: کۆیی فرۆشتن (Blue Gradient)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF3B82F6),
                          Color(0xFF1D4ED8),
                        ], // Bright blue gradient
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Cyan graph icon on left
                        Align(
                          alignment: Alignment.topLeft,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.show_chart_rounded,
                              color: Colors.cyanAccent,
                              size: 24,
                            ),
                          ),
                        ),
                        // Details on right
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'کۆیی فرۆشتن',
                              style: TextStyle(
                                fontFamily: 'Rabar',
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '\$${totalRevenue.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontFamily: 'NRT',
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${filteredReceipts.length} وەسڵ - $totalItemsQty دانە کاڵا',
                              style: const TextStyle(
                                fontFamily: 'Rabar',
                                color: Colors.white60,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3. Medium Cards Row (Net Profit & Total Buy Cost)
                  Row(
                    children: [
                      // Net Profit (Green Card)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF10B981),
                                Color(0xFF047857),
                              ], // Emerald Green gradient
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.wallet_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'قازانج',
                                    style: TextStyle(
                                      fontFamily: 'Rabar',
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\$${netProfit.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontFamily: 'NRT',
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Total Buy Cost (Orange Card)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFF59E0B),
                                Color(0xFFD97706),
                              ], // Orange gradient
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.shopping_bag_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'کۆیی کڕین',
                                    style: TextStyle(
                                      fontFamily: 'Rabar',
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\$${totalCost.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontFamily: 'NRT',
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 4. Three Small Cards Row (Discount, Debt, Cash)
                  Row(
                    children: [
                      // Cash Card (Blue)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.surfaceColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Icon(
                                    Icons.payments_rounded,
                                    color: Color(0xFF38BDF8),
                                    size: 18,
                                  ),
                                  Text(
                                    'نەقد',
                                    style: TextStyle(
                                      fontFamily: 'Rabar',
                                      color: Colors.white54,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '\$${cashAmount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontFamily: 'NRT',
                                  color: Color(0xFF38BDF8),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Debt Card (Red/Orange)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.surfaceColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Icon(
                                    Icons.assignment_turned_in_rounded,
                                    color: Color(0xFFF59E0B),
                                    size: 18,
                                  ),
                                  Text(
                                    '$debtCount وەسڵ قەرز',
                                    style: const TextStyle(
                                      fontFamily: 'Rabar',
                                      color: Colors.white54,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '\$${debtAmount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontFamily: 'NRT',
                                  color: Color(0xFFF59E0B),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Discount Card (Magenta)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.surfaceColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Icon(
                                    Icons.local_offer_rounded,
                                    color: Colors.pinkAccent,
                                    size: 18,
                                  ),
                                  Text(
                                    'داشکان',
                                    style: TextStyle(
                                      fontFamily: 'Rabar',
                                      color: Colors.white54,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '\$${totalDiscount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontFamily: 'NRT',
                                  color: Colors.pinkAccent,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 5. Chart Card "فرۆشتن"
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.surfaceColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF10B981,
                                ).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '\$${totalRevenue.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontFamily: 'NRT',
                                  color: Color(0xFF10B981),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Text(
                              'فرۆشتن',
                              style: TextStyle(
                                fontFamily: 'Rabar',
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Bar chart visualization matching screenshot / investing style
                        SizedBox(
                          height: 160,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: chartData.entries.map((entry) {
                                final double val = entry.value;
                                final double maxVal = chartData.values.fold(
                                  1.0,
                                  (m, v) => v > m ? v : m,
                                );
                                final double pct = maxVal > 0
                                    ? (val / maxVal).clamp(0.05, 1.0)
                                    : 0.05;

                                return Padding(
                                  padding: EdgeInsets.only(
                                      right: chartData.length > 7 ? 12.0 : 20.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Expanded(
                                        child: Align(
                                          alignment: Alignment.bottomCenter,
                                          child: Stack(
                                            alignment: Alignment.bottomCenter,
                                            children: [
                                              // Investing style sleek bar
                                              Container(
                                                width: chartData.length > 7 ? 12 : 24,
                                                height: 130 * pct,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                    colors: val > 0 
                                                        ? const [Color(0xFF10B981), Color(0xFF047857)] // Neon Green
                                                        : const [Color(0xFF334155), Color(0xFF1E293B)],
                                                  ),
                                                  borderRadius: BorderRadius.circular(4),
                                                  boxShadow: val > 0 ? [
                                                    BoxShadow(
                                                      color: const Color(0xFF10B981).withValues(alpha: 0.4),
                                                      blurRadius: 6,
                                                      offset: const Offset(0, 2),
                                                    )
                                                  ] : [],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      // If key has '|' it's week mode: show day name + date
                                      Builder(builder: (context) {
                                        final parts = entry.key.split('|');
                                        if (parts.length == 2) {
                                          return Column(
                                            children: [
                                              Text(
                                                parts[0],
                                                style: TextStyle(
                                                  fontFamily: 'Rabar',
                                                  color: val > 0 ? Colors.white : Colors.white54,
                                                  fontSize: 10,
                                                  fontWeight: val > 0 ? FontWeight.bold : FontWeight.normal,
                                                ),
                                              ),
                                              Text(
                                                parts[1],
                                                style: const TextStyle(
                                                  fontFamily: 'NRT',
                                                  color: Colors.white38,
                                                  fontSize: 9,
                                                ),
                                              ),
                                            ],
                                          );
                                        }
                                        return Text(
                                          entry.key,
                                          style: TextStyle(
                                            fontFamily: 'Rabar',
                                            color: val > 0 ? Colors.white : Colors.white54,
                                            fontSize: 10,
                                            fontWeight: val > 0 ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 6. Profit Margin Card "ڕێژەی قازانج" matching style
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.surfaceColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF10B981,
                                ).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${profitMargin.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontFamily: 'NRT',
                                  color: Color(0xFF10B981),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Text(
                              'ڕێژەی قازانج',
                              style: TextStyle(
                                fontFamily: 'Rabar',
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: profitMargin > 0
                                ? (profitMargin / 100).clamp(0.0, 1.0)
                                : 0.0,
                            backgroundColor: const Color(0xFF0F172A),
                            color: const Color(0xFF10B981),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              profitMargin >= 50
                                  ? 'قازانجی باشە - بەرھەمی خێرایە'
                                  : 'داواکراوی کڕین',
                              style: const TextStyle(
                                fontFamily: 'Rabar',
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.check_box_rounded,
                              color: Color(0xFF10B981),
                              size: 16,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 7. Expandable Receipts List Section "وەسڵەکان"
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${filteredReceipts.length} وەسڵ',
                        style: const TextStyle(
                          fontFamily: 'Rabar',
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                      const Text(
                        'وەسڵەکان',
                        style: TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (filteredReceipts.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.surfaceColor),
                      ),
                      child: const Center(
                        child: Text(
                          'هیچ وەسڵێک تۆمار نەکراوە.',
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredReceipts.length,
                      itemBuilder: (context, index) {
                        final r = filteredReceipts[index];
                        final isExpanded = _expandedReceiptIds.contains(r.id);
                        final dateStr =
                            '${r.date.year}/${r.date.month.toString().padLeft(2, '0')}/${r.date.day.toString().padLeft(2, '0')}';

                        // Calculate profit for this receipt
                        double rCost = 0.0;
                        int itemTypesCount = r.items.length;
                        int totalItemsCount = 0;
                        for (final item in r.items) {
                          rCost += (item.product.buyPrice * item.quantity);
                          totalItemsCount += item.quantity;
                        }
                        final double rProfit = r.grandTotal - rCost;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.surfaceColor),
                          ),
                          child: Column(
                            children: [
                              // Receipt Header click to expand
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    if (isExpanded) {
                                      _expandedReceiptIds.remove(r.id);
                                    } else {
                                      _expandedReceiptIds.add(r.id);
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      // Expand Indicator and Price on Left
                                      Row(
                                        children: [
                                          Icon(
                                            isExpanded
                                                ? Icons
                                                      .keyboard_arrow_up_rounded
                                                : Icons
                                                      .keyboard_arrow_down_rounded,
                                            color: Colors.white54,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '\$${r.grandTotal.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontFamily: 'NRT',
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                r.paymentMethod == 'قەرز'
                                                    ? 'قەرز (ماوە: \$${r.remainingAmount.toStringAsFixed(2)})'
                                                    : 'نەقد',
                                                style: TextStyle(
                                                  fontFamily: 'Rabar',
                                                  color:
                                                      r.paymentMethod == 'نەقد'
                                                      ? const Color(0xFF10B981)
                                                      : (r.remainingAmount > 0
                                                            ? Colors.redAccent
                                                            : const Color(
                                                                0xFFF59E0B,
                                                              )),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      // Info details in Middle
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            r.customerName.isEmpty
                                                ? 'کڕیاری گشتی'
                                                : r.customerName,
                                            style: const TextStyle(
                                              fontFamily: 'Rabar',
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '$dateStr  •  $itemTypesCount جۆر  •  $totalItemsCount دانە',
                                            style: const TextStyle(
                                              fontFamily: 'NRT',
                                              color: Colors.white54,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 12),
                                      // Receipt Icon on Right
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0F766E)
                                              .withValues(
                                                alpha: 0.2,
                                              ), // Teal rounded background
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.receipt_long_rounded,
                                          color: Color(0xFF0F766E),
                                          size: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Expanded Table details
                              if (isExpanded)
                                Container(
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF0F172A),
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(12),
                                      bottomRight: Radius.circular(12),
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    children: [
                                      // Table Headers
                                      const Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'قازانج',
                                              textAlign: TextAlign.right,
                                              style: TextStyle(
                                                color: Colors.white54,
                                                fontSize: 10,
                                                fontFamily: 'Rabar',
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              'فرۆشتن',
                                              textAlign: TextAlign.right,
                                              style: TextStyle(
                                                color: Colors.white54,
                                                fontSize: 10,
                                                fontFamily: 'Rabar',
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              'کڕین',
                                              textAlign: TextAlign.right,
                                              style: TextStyle(
                                                color: Colors.white54,
                                                fontSize: 10,
                                                fontFamily: 'Rabar',
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              'دانە',
                                              textAlign: TextAlign.right,
                                              style: TextStyle(
                                                color: Colors.white54,
                                                fontSize: 10,
                                                fontFamily: 'Rabar',
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              'کاڵا',
                                              textAlign: TextAlign.right,
                                              style: TextStyle(
                                                color: Colors.white54,
                                                fontSize: 10,
                                                fontFamily: 'Rabar',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(
                                        color: AppTheme.surfaceColor,
                                        height: 12,
                                      ),
                                      // Items Rows
                                      ...r.items.map((item) {
                                        final double itemCost =
                                            item.product.buyPrice;
                                        final double itemSell = item.unitPrice;
                                        final double itemProfit =
                                            (itemSell - itemCost) *
                                            item.quantity;
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  '\$${itemProfit.toStringAsFixed(2)}',
                                                  textAlign: TextAlign.right,
                                                  style: TextStyle(
                                                    color: itemProfit >= 0
                                                        ? Colors.tealAccent
                                                        : Colors.redAccent,
                                                    fontSize: 10,
                                                    fontFamily: 'NRT',
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  '\$${itemSell.toStringAsFixed(2)}',
                                                  textAlign: TextAlign.right,
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 10,
                                                    fontFamily: 'NRT',
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  '\$${itemCost.toStringAsFixed(2)}',
                                                  textAlign: TextAlign.right,
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 10,
                                                    fontFamily: 'NRT',
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  '${item.quantity}',
                                                  textAlign: TextAlign.right,
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 10,
                                                    fontFamily: 'NRT',
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  item.product.name,
                                                  textAlign: TextAlign.right,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontFamily: 'Rabar',
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                      const Divider(
                                        color: AppTheme.surfaceColor,
                                        height: 12,
                                      ),
                                      // Summaries row
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'داشکاندن: \$${r.discount.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              color: Colors.pinkAccent,
                                              fontFamily: 'NRT',
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (r.paymentMethod == 'قەرز' &&
                                              r.remainingAmount > 0)
                                            ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(
                                                  0xFF10B981,
                                                ),
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4,
                                                    ),
                                                minimumSize: Size.zero,
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                              ),
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (_) =>
                                                      AddPaymentDialog(
                                                        receipt: r,
                                                      ),
                                                );
                                              },
                                              icon: const Icon(
                                                Icons.payments_rounded,
                                                size: 12,
                                              ),
                                              label: const Text(
                                                'پارە دانەوە',
                                                style: TextStyle(
                                                  fontFamily: 'Rabar',
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          Text(
                                            'کۆیی قازانج: \$${rProfit.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              color: Colors.tealAccent,
                                              fontFamily: 'NRT',
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(
    String filterKey,
    String label, {
    VoidCallback? onTap,
  }) {
    final isSelected = _selectedFilter == filterKey;
    return InkWell(
      onTap:
          onTap ??
          () {
            setState(() {
              _selectedFilter = filterKey;
            });
          },
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Rabar',
            fontSize: 11,
            color: isSelected ? Colors.white : Colors.white60,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
