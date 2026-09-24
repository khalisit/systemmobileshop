import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_toast.dart';
import '../models/receipt_model.dart';
import '../core/utils/english_digits_formatter.dart';
import '../providers/receipts_provider.dart';
import '../providers/pos_provider.dart';
import 'pos_screen.dart';

class ReceiptsScreen extends ConsumerStatefulWidget {
  const ReceiptsScreen({super.key});

  @override
  ConsumerState<ReceiptsScreen> createState() => _ReceiptsScreenState();
}

class _ReceiptsScreenState extends ConsumerState<ReceiptsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _filterType = 'all'; // 'all', 'cash', 'debt', 'unpaid'

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final receiptsAsync = ref.watch(receiptsProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Colors.white70,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: Color(0xFF818CF8),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'وەسڵەکان',
              style: TextStyle(
                fontFamily: 'Rabar',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: receiptsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF6366F1)),
        ),
        error: (err, stack) => Center(
          child: Text(
            'هەڵەیەک ڕوویدا: $err',
            style: const TextStyle(fontFamily: 'Rabar', color: Colors.white),
          ),
        ),
        data: (allReceipts) {
          // Calculations for the 4 summary cards
          final totalCount = allReceipts.length;
          final totalSales = allReceipts.fold<double>(
            0.0,
            (s, r) => s + r.grandTotal,
          );
          final totalPaid = allReceipts.fold<double>(
            0.0,
            (s, r) => s + r.paidAmount,
          );
          final totalDebt = allReceipts.fold<double>(
            0.0,
            (s, r) => s + r.remainingAmount,
          );

          // Filtering
          final filteredReceipts = allReceipts.where((r) {
            final q = _searchQuery.toLowerCase();
            final matchesQuery =
                q.isEmpty ||
                r.customerName.toLowerCase().contains(q) ||
                r.customerPhone.contains(q) ||
                r.id.toLowerCase().contains(q);

            if (!matchesQuery) return false;

            if (_filterType == 'cash') {
              return r.paymentMethod == 'نەقد';
            } else if (_filterType == 'debt') {
              return r.paymentMethod == 'قەرز';
            } else if (_filterType == 'unpaid') {
              return r.paymentMethod == 'قەرز' && r.remainingAmount > 0;
            }

            return true;
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top 4 Stat Cards Row
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'کۆی وەسڵەکان',
                        value: '$totalCount',
                        icon: Icons.receipt_long_rounded,
                        bgColor: const Color(0xFF4F46E5),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'کۆی فرۆشتن',
                        value: '\$${totalSales.toStringAsFixed(2)}',
                        icon: Icons.attach_money_rounded,
                        bgColor: const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'بڕی پێدراو',
                        value: '\$${totalPaid.toStringAsFixed(2)}',
                        icon: Icons.payments_rounded,
                        bgColor: const Color(0xFF06B6D4),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'پارەی ماوە',
                        value: '\$${totalDebt.toStringAsFixed(2)}',
                        icon: Icons.account_balance_wallet_rounded,
                        bgColor: const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 2. Filter Buttons and Search Bar Row (Matched to user screenshot)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.surfaceColor),
                  ),
                  child: Row(
                    children: [
                      // Search Bar (Right side in RTL) - expands to fill space
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            inputFormatters: const [
                              EnglishDigitsTextInputFormatter(),
                            ],
                            onChanged: (val) =>
                                setState(() => _searchQuery = val.trim()),
                            style: const TextStyle(
                              fontFamily: 'Rabar',
                              color: Colors.white,
                              fontSize: 13,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  'گەڕان بە ناو، ژمارەی موبایل یان ID وەسڵ...',
                              hintStyle: const TextStyle(
                                fontFamily: 'Rabar',
                                color: Colors.white38,
                                fontSize: 13,
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: Colors.white54,
                                size: 20,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.clear_rounded,
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
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Filter Chips (Left side in RTL)
                      _buildFilterChip('هەموو', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('نەقد', 'cash'),
                      const SizedBox(width: 8),
                      _buildFilterChip('قەرز', 'debt'),
                      const SizedBox(width: 8),
                      _buildFilterChip('قەرزی نەدراوە', 'unpaid'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Data Table Panel
                Expanded(
                  child: filteredReceipts.isEmpty
                      ? const Center(
                          child: Text(
                            'هیچ وەسڵێک نەدۆزرایەوە',
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              color: Colors.white38,
                              fontSize: 15,
                            ),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: AppTheme.cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.surfaceColor),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth:
                                        MediaQuery.of(context).size.width - 40,
                                  ),
                                  child: DataTable(
                                    headingRowColor: WidgetStateProperty.all(
                                      const Color(0xFF0F172A),
                                    ),
                                    dataRowMinHeight: 56,
                                    dataRowMaxHeight: 56,
                                    horizontalMargin: 20,
                                    columnSpacing: 24,
                                    headingTextStyle: const TextStyle(
                                      fontFamily: 'Rabar',
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                    dataTextStyle: const TextStyle(
                                      fontFamily: 'Rabar',
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                    columns: const [
                                      DataColumn(
                                        label: Text('#'),
                                        numeric: true,
                                      ),
                                      DataColumn(label: Text('ژمارەی وەسڵ')),
                                      DataColumn(label: Text('بەروار')),
                                      DataColumn(label: Text('ناوی کڕیار')),
                                      DataColumn(label: Text('ژمارەی موبایل')),
                                      DataColumn(
                                        label: Text('لایتمەکان'),
                                        numeric: true,
                                      ),
                                      DataColumn(
                                        label: Text('کۆی گشتی'),
                                        numeric: true,
                                      ),
                                      DataColumn(
                                        label: Text('بڕی دراو'),
                                        numeric: true,
                                      ),
                                      DataColumn(
                                        label: Text('قەرزی ماوە'),
                                        numeric: true,
                                      ),
                                      DataColumn(label: Text('شێواز')),
                                      DataColumn(label: Text('کردارەکان')),
                                    ],
                                    rows: filteredReceipts
                                        .asMap()
                                        .entries
                                        .map(
                                          (entry) => _buildReceiptRow(
                                            entry.key,
                                            entry.value,
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'NRT',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: bgColor, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterType == value;

    return InkWell(
      onTap: () {
        setState(() {
          _filterType = value;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFF64748B),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Rabar',
            fontSize: 13,
            color: isSelected ? Colors.white : const Color(0xFFE2E8F0),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  DataRow _buildReceiptRow(int index, ReceiptModel receipt) {
    final dateStr =
        '${receipt.date.hour.toString().padLeft(2, '0')}:${receipt.date.minute.toString().padLeft(2, '0')} ${receipt.date.year}/${receipt.date.month.toString().padLeft(2, '0')}/${receipt.date.day.toString().padLeft(2, '0')}';

    final isDebt = receipt.paymentMethod == 'قەرز';
    final hasRemainingDebt = receipt.remainingAmount > 0;

    return DataRow(
      cells: [
        // 1. # Index
        DataCell(
          Text(
            '${index + 1}',
            style: const TextStyle(
              fontFamily: 'NRT',
              color: Colors.white54,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // 2. Receipt ID
        DataCell(
          Text(
            '#${receipt.id.length >= 8 ? receipt.id.substring(0, 8).toUpperCase() : receipt.id.toUpperCase()}',
            style: const TextStyle(
              fontFamily: 'NRT',
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // 3. Date
        DataCell(
          Text(
            dateStr,
            style: const TextStyle(
              fontFamily: 'NRT',
              fontSize: 12,
              color: Colors.white54,
            ),
          ),
        ),
        // 4. Customer Name
        DataCell(
          Text(
            receipt.customerName.isNotEmpty
                ? receipt.customerName
                : 'کڕیاری گشتی',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        // 5. Mobile Number
        DataCell(
          Text(
            receipt.customerPhone.isNotEmpty ? receipt.customerPhone : '---',
            style: const TextStyle(
              fontFamily: 'NRT',
              fontSize: 13,
              color: Colors.white70,
            ),
          ),
        ),
        // 6. Items count badge
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${receipt.totalItems}',
              style: const TextStyle(
                fontFamily: 'NRT',
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ),
        ),
        // 7. Grand Total
        DataCell(
          Text(
            '\$${receipt.grandTotal.toStringAsFixed(2)}',
            style: const TextStyle(
              fontFamily: 'NRT',
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        // 8. Paid Amount
        DataCell(
          Text(
            '\$${receipt.paidAmount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontFamily: 'NRT',
              fontWeight: FontWeight.bold,
              color: Color(0xFF10B981),
            ),
          ),
        ),
        // 9. Remaining Debt
        DataCell(
          Text(
            '\$${receipt.remainingAmount.toStringAsFixed(2)}',
            style: TextStyle(
              fontFamily: 'NRT',
              fontWeight: FontWeight.bold,
              color: hasRemainingDebt
                  ? const Color(0xFFEF4444)
                  : Colors.white38,
            ),
          ),
        ),
        // 10. Payment Method Badge
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color:
                  (isDebt ? const Color(0xFFF59E0B) : const Color(0xFF10B981))
                      .withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              receipt.paymentMethod,
              style: TextStyle(
                fontFamily: 'Rabar',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDebt
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF10B981),
              ),
            ),
          ),
        ),
        // 11. Actions
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Eye Icon (View / Details / Edit)
              IconButton(
                icon: const Icon(
                  Icons.remove_red_eye_outlined,
                  color: Color(0xFF38BDF8),
                  size: 20,
                ),
                tooltip: 'بینیی وەسڵ و دەستکاریکردن',
                onPressed: () {
                  _showReceiptDetailsModal(context, ref, receipt);
                },
              ),
              // Return Item Icon
              IconButton(
                icon: const Icon(
                  Icons.assignment_return_rounded,
                  color: Colors.orangeAccent,
                  size: 20,
                ),
                tooltip: 'بەرهەمی گەڕاوە',
                onPressed: () {
                  if (receipt.totalItems > 1) {
                    ref.read(posProvider.notifier).loadReceipt(receipt);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PosScreen()),
                    );
                  } else {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppTheme.cardBg,
                        title: const Text('سڕینەوەی وەسڵ', style: TextStyle(fontFamily: 'Rabar', color: Colors.white)),
                        content: const Text('دڵنیایت لە سڕینەوەی ئەم وەسڵە؟ چونکە تەنها یەک بەرهەمی تێدایە.', style: TextStyle(fontFamily: 'Rabar', color: Colors.white70)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('نەخێر', style: TextStyle(fontFamily: 'Rabar', color: Colors.white54)),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              ref.read(receiptsProvider.notifier).deleteReceipt(receipt.id);
                            },
                            child: const Text('بەڵێ', style: TextStyle(fontFamily: 'Rabar', color: Colors.redAccent)),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
              // Add Payment Icon if Debt > 0
              if (isDebt && hasRemainingDebt)
                IconButton(
                  icon: const Icon(
                    Icons.payments_rounded,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                  tooltip: 'تۆمارکردنی پارەدان',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AddPaymentDialog(receipt: receipt),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _showReceiptDetailsModal(
    BuildContext context,
    WidgetRef ref,
    ReceiptModel receipt,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 550,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.surfaceColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Modal Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.receipt_long_rounded,
                          color: Color(0xFF818CF8),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'زانیارییەکانی وەسڵ #${receipt.id.length >= 8 ? receipt.id.substring(0, 8).toUpperCase() : receipt.id}',
                        style: const TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white54,
                    ),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(color: AppTheme.surfaceColor, height: 24),

              // Customer & Order Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ناوی کڕیار: ${receipt.customerName.isNotEmpty ? receipt.customerName : 'کڕیاری گشتی'}',
                        style: const TextStyle(
                          fontFamily: 'Rabar',
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ژمارەی تەلەفۆن: ${receipt.customerPhone.isNotEmpty ? receipt.customerPhone : '---'}',
                        style: const TextStyle(
                          fontFamily: 'NRT',
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'شێوازی پارەدان: ${receipt.paymentMethod}',
                        style: TextStyle(
                          fontFamily: 'Rabar',
                          color: receipt.paymentMethod == 'نەقد'
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ڕێکەوت: ${receipt.date.year}/${receipt.date.month.toString().padLeft(2, '0')}/${receipt.date.day.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontFamily: 'NRT',
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Items List Header
              const Text(
                'لیستی کالا / کارەکان:',
                style: TextStyle(
                  fontFamily: 'Rabar',
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),

              // Items Table / Container
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: AppTheme.darkBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.surfaceColor),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: receipt.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item.product.name,
                              style: const TextStyle(
                                fontFamily: 'Rabar',
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '\$${item.unitPrice.toStringAsFixed(2)} × ${item.quantity} = \$${item.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontFamily: 'NRT',
                                color: AppTheme.accentColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Totals summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'کۆی گشتی: \$${receipt.grandTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontFamily: 'NRT',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'بڕی دراو: \$${receipt.paidAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontFamily: 'NRT',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  Text(
                    'ماوە: \$${receipt.remainingAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontFamily: 'NRT',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: receipt.remainingAmount > 0
                          ? const Color(0xFFEF4444)
                          : Colors.white54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text(
                      'دەستکاریکردنی وەسڵ',
                      style: TextStyle(fontFamily: 'Rabar'),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ref.read(posProvider.notifier).loadReceipt(receipt);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PosScreen()),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text(
                      'داخستن',
                      style: TextStyle(fontFamily: 'Rabar'),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddPaymentDialog extends ConsumerStatefulWidget {
  final ReceiptModel receipt;
  const AddPaymentDialog({super.key, required this.receipt});

  @override
  ConsumerState<AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends ConsumerState<AddPaymentDialog> {
  final _amountCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _submitPayment() async {
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
    if (amount <= 0) {
      AppToast.show(context, 'تکایە بڕی ڕاست بنووسە', type: ToastType.error);
      return;
    }

    final newPaid = widget.receipt.paidAmount + amount;
    final updatedReceipt = widget.receipt.copyWith(paidAmount: newPaid);

    await ref.read(receiptsProvider.notifier).updateReceipt(updatedReceipt);

    if (mounted) {
      Navigator.pop(context);
      AppToast.show(
        context,
        'پارەدانەکە بە سەرکەوتوویی تۆمارکرا!',
        type: ToastType.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.receipt.remainingAmount;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.surfaceColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.payments_rounded, color: Color(0xFF10B981)),
                const SizedBox(width: 10),
                Text(
                  'تۆمارکردنی پارەدان بۆ #${widget.receipt.id.length >= 8 ? widget.receipt.id.substring(0, 8).toUpperCase() : widget.receipt.id}',
                  style: const TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'قەرزی ماوە: \$${remaining.toStringAsFixed(2)}',
              style: const TextStyle(
                fontFamily: 'NRT',
                fontSize: 15,
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amountCtrl,
                    inputFormatters: const [EnglishDigitsTextInputFormatter()],
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontFamily: 'NRT',
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: 'بڕی دانراو (\$) ...',
                      hintStyle: const TextStyle(
                        fontFamily: 'Rabar',
                        color: Colors.white38,
                      ),
                      filled: true,
                      fillColor: AppTheme.darkBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      _amountCtrl.text = remaining.toStringAsFixed(2);
                    },
                    child: const Text(
                      'کۆیی',
                      style: TextStyle(
                        fontFamily: 'Rabar',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'پاشگەزبوونەوە',
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      color: Colors.white54,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _submitPayment,
                  child: const Text(
                    'تۆمارکردن',
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
