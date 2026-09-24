import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/receipt_model.dart';
import '../core/utils/english_digits_formatter.dart';
import '../providers/receipts_provider.dart';
import 'receipts_screen.dart';
import '../providers/pos_provider.dart';
import 'pos_screen.dart';

class DebtorsScreen extends ConsumerStatefulWidget {
  const DebtorsScreen({super.key});

  @override
  ConsumerState<DebtorsScreen> createState() => _DebtorsScreenState();
}

class _DebtorsScreenState extends ConsumerState<DebtorsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final receiptsAsync = ref.watch(receiptsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF080F1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080F1E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.people_alt_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'لیستی قەرزارەکان',
                  style: TextStyle(fontFamily: 'NRT', fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                Text(
                  'Debtors Management',
                  style: TextStyle(fontFamily: 'NRT', fontSize: 11, color: Colors.white38),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              tooltip: 'نوێکردنەوە',
              onPressed: () => ref.invalidate(receiptsProvider),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: const Icon(Icons.refresh_rounded, color: Colors.white60, size: 18),
              ),
            ),
          ),
        ],
      ),
      body: receiptsAsync.when(
        loading: () => _buildLoadingView(),
        error: (err, _) => _buildErrorView(err.toString()),
        data: (allReceipts) {
          final debtReceipts = allReceipts
              .where((r) => r.paymentMethod == 'قەرز' && r.remainingAmount > 0)
              .toList();
          final filteredDebtReceipts = debtReceipts.where((r) {
            final q = _searchQuery.toLowerCase();
            return r.customerName.toLowerCase().contains(q) ||
                r.customerPhone.contains(q) ||
                r.id.toLowerCase().contains(q);
          }).toList();
          final totalDebtAmount = debtReceipts.fold<double>(0.0, (sum, r) => sum + r.remainingAmount);
          final totalPaid = debtReceipts.fold<double>(0.0, (sum, r) => sum + r.paidAmount);
          final uniqueDebtorsCount = debtReceipts.map((r) => r.customerName.trim()).where((n) => n.isNotEmpty).toSet().length;

          return Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A0A2E), Color(0xFF2D1B4E)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    _buildHeroStat(label: 'قەرزی ماوە', amount: '\$${totalDebtAmount.toStringAsFixed(2)}', icon: Icons.account_balance_wallet_rounded, gradientColors: const [Color(0xFFEF4444), Color(0xFFDC2626)]),
                    const SizedBox(width: 8),
                    _buildHeroStat(label: 'بڕی دراو', amount: '\$${totalPaid.toStringAsFixed(2)}', icon: Icons.check_circle_rounded, gradientColors: const [Color(0xFF10B981), Color(0xFF059669)]),
                    const SizedBox(width: 8),
                    _buildHeroStat(label: 'وەسڵەکان', amount: '${debtReceipts.length} وەسڵ', icon: Icons.receipt_long_rounded, gradientColors: const [Color(0xFFF59E0B), Color(0xFFD97706)]),
                    const SizedBox(width: 8),
                    _buildHeroStat(label: 'کڕیارەکان', amount: '$uniqueDebtorsCount کەس', icon: Icons.people_alt_rounded, gradientColors: const [Color(0xFF6366F1), Color(0xFF4F46E5)]),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    inputFormatters: const [EnglishDigitsTextInputFormatter()],
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    style: const TextStyle(fontFamily: 'Rabar', color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'گەڕان بەپێی ناوی کڕیار، ژمارەی تەلەفۆن...',
                      hintStyle: const TextStyle(fontFamily: 'Rabar', color: Colors.white30, fontSize: 13),
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(10),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.search_rounded, color: Color(0xFFF59E0B), size: 18),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(icon: const Icon(Icons.clear_rounded, color: Colors.white30, size: 18), onPressed: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); })
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 100.ms),

              if (filteredDebtReceipts.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 2),
                  child: Row(
                    children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text('${filteredDebtReceipts.length} قەرزار دۆزرایەوە', style: const TextStyle(fontFamily: 'Rabar', fontSize: 12, color: Colors.white38)),
                    ],
                  ),
                ),

              Expanded(
                child: filteredDebtReceipts.isEmpty
                    ? _buildEmptyView(debtReceipts.isEmpty)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: filteredDebtReceipts.length,
                        separatorBuilder: (_, idx) => const SizedBox(height: 6),
                        itemBuilder: (ctx, i) => _buildDebtorCard(ctx, i, filteredDebtReceipts[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeroStat({required String label, required String amount, required IconData icon, required List<Color> gradientColors}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradientColors),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontFamily: 'Rabar', fontSize: 9, color: Color(0x55FFFFFF)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(amount, style: const TextStyle(fontFamily: 'NRT', fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtorCard(BuildContext context, int index, ReceiptModel receipt) {
    final dateStr = '${receipt.date.year}/${receipt.date.month.toString().padLeft(2, '0')}/${receipt.date.day.toString().padLeft(2, '0')}';
    final initial = receipt.customerName.isNotEmpty ? receipt.customerName[0].toUpperCase() : '?';
    final paidPercent = receipt.grandTotal > 0 ? (receipt.paidAmount / receipt.grandTotal).clamp(0.0, 1.0) : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0E1624),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
          // # index
          SizedBox(
            width: 20,
            child: Text(
              '${index + 1}',
              style: const TextStyle(fontFamily: 'NRT', fontSize: 10, color: Colors.white30, fontWeight: FontWeight.bold),
            ),
          ),
          // Avatar
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFEF4444)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text(initial, style: const TextStyle(fontFamily: 'NRT', fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white))),
          ),
          const SizedBox(width: 10),
          // Name + Phone
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  receipt.customerName.isNotEmpty ? receipt.customerName : 'دیاری نەکراو',
                  style: const TextStyle(fontFamily: 'Rabar', fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                Text(
                  receipt.customerPhone.isNotEmpty ? receipt.customerPhone : '---',
                  style: const TextStyle(fontFamily: 'NRT', fontSize: 10, color: Colors.white30),
                ),
              ],
            ),
          ),
          // Grand Total
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('کۆی وەسڵ', style: TextStyle(fontFamily: 'Rabar', fontSize: 8, color: Colors.white24)),
                Text('\$${receipt.grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontFamily: 'NRT', fontSize: 12, color: Colors.white54, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          // Paid
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('دراو', style: TextStyle(fontFamily: 'Rabar', fontSize: 8, color: Colors.white24)),
                Text('\$${receipt.paidAmount.toStringAsFixed(0)}', style: const TextStyle(fontFamily: 'NRT', fontSize: 12, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          // Remaining (badge)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
            ),
            child: Text(
              '\$${receipt.remainingAmount.toStringAsFixed(0)}',
              style: const TextStyle(fontFamily: 'NRT', fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFFFF6B6B)),
            ),
          ),
          const SizedBox(width: 6),
          // Date
          SizedBox(
            width: 68,
            child: Text(dateStr, style: const TextStyle(fontFamily: 'NRT', fontSize: 10, color: Colors.white30), textAlign: TextAlign.center),
          ),
          const SizedBox(width: 4),
          // Actions
          _buildIconBtn(icon: Icons.receipt_rounded, color: const Color(0xFF6366F1), tooltip: 'بینینی وەسڵ', onTap: () => _showReceiptDetailsDialog(context, receipt)),
          const SizedBox(width: 4),
          _buildIconBtn(icon: Icons.payments_rounded, color: const Color(0xFF10B981), tooltip: 'تۆمارکردنی پارەدان', onTap: () { showDialog(context: context, builder: (_) => AddPaymentDialog(receipt: receipt)); }),
        ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(13)),
            child: LinearProgressIndicator(
              value: paidPercent,
              backgroundColor: Colors.white.withValues(alpha: 0.02),
              valueColor: AlwaysStoppedAnimation<Color>(
                paidPercent >= 0.75 ? const Color(0xFF10B981) : paidPercent >= 0.4 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444),
              ),
              minHeight: 3,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 30).ms);
  }

  Widget _buildIconBtn({required IconData icon, required Color color, required String tooltip, required VoidCallback onTap}) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.25))),
          child: Icon(icon, color: color, size: 16),
        ),
      ),
    );
  }

  Widget _buildEmptyView(bool noDebts) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: noDebts ? const Color(0xFF10B981).withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.04),
              shape: BoxShape.circle,
            ),
            child: Icon(
              noDebts ? Icons.check_circle_outline_rounded : Icons.search_off_rounded,
              size: 60,
              color: noDebts ? const Color(0xFF10B981).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.15),
            ),
          ),
          const SizedBox(height: 20),
          Text(noDebts ? 'هیچ قەرزێک نییە!' : 'هیچ ئەنجامێک نەدۆزرایەوە', style: const TextStyle(fontFamily: 'NRT', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70)),
          const SizedBox(height: 8),
          Text(noDebts ? 'هەموو وەسڵەکان بە نەقد تەواو کراون' : 'تکایە وشەی گەڕانەکەت بگۆڕە', style: const TextStyle(fontFamily: 'Rabar', fontSize: 13, color: Colors.white30)),
        ],
      ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9)),
    );
  }

  Widget _buildLoadingView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(height: 160, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(20)))
              .animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, color: Colors.white12),
          const SizedBox(height: 16),
          ...List.generate(4, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(height: 110, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(18)))
                .animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, color: Colors.white12),
          )),
        ],
      ),
    );
  }

  Widget _buildErrorView(String err) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 52),
          const SizedBox(height: 12),
          Text('هەڵەیەک ڕوویدا: $err', style: const TextStyle(fontFamily: 'Rabar', color: Colors.white54, fontSize: 13), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () => ref.invalidate(receiptsProvider),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('دووبارە هەوڵبدەرەوە', style: TextStyle(fontFamily: 'Rabar')),
          ),
        ],
      ),
    );
  }

  void _showReceiptDetailsDialog(BuildContext context, ReceiptModel receipt) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 560,
          decoration: BoxDecoration(
            color: const Color(0xFF0E1624),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 30, offset: const Offset(0, 12))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF080F1E),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.07))),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFEF4444)]), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('زانیارییەکانی وەسڵ', style: TextStyle(fontFamily: 'NRT', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text('#${receipt.id.length >= 8 ? receipt.id.substring(0, 8).toUpperCase() : receipt.id}', style: const TextStyle(fontFamily: 'NRT', fontSize: 11, color: Colors.white38)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.close_rounded, color: Colors.white54, size: 16)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _infoChip(Icons.person_rounded, receipt.customerName.isNotEmpty ? receipt.customerName : 'کڕیاری گشتی', const Color(0xFFF59E0B)),
                        const SizedBox(width: 8),
                        if (receipt.customerPhone.isNotEmpty) _infoChip(Icons.phone_rounded, receipt.customerPhone, const Color(0xFF6366F1)),
                        const Spacer(),
                        _infoChip(Icons.calendar_today_rounded, '${receipt.date.year}/${receipt.date.month.toString().padLeft(2, '0')}/${receipt.date.day.toString().padLeft(2, '0')}', Colors.white30),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(width: 3, height: 16, decoration: BoxDecoration(color: const Color(0xFFF59E0B), borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 8),
                        const Text('لیستی کاڵاکان', style: TextStyle(fontFamily: 'Rabar', fontWeight: FontWeight.bold, color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(color: const Color(0xFF080F1E), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: receipt.items.map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(children: [
                                  Container(width: 6, height: 6, margin: const EdgeInsets.only(right: 8), decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha: 0.7), shape: BoxShape.circle)),
                                  Text(item.product.name, style: const TextStyle(fontFamily: 'Rabar', color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                ]),
                                Text('\$${item.unitPrice.toStringAsFixed(2)} x ${item.quantity} = \$${item.total.toStringAsFixed(2)}', style: const TextStyle(fontFamily: 'NRT', color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          )).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
                      child: Row(
                        children: [
                          Expanded(child: _totalItem('کۆی گشتی', '\$${receipt.grandTotal.toStringAsFixed(2)}', Colors.white70)),
                          Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.08)),
                          Expanded(child: _totalItem('بڕی دراو', '\$${receipt.paidAmount.toStringAsFixed(2)}', const Color(0xFF10B981))),
                          Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.08)),
                          Expanded(child: _totalItem('قەرزی ماوە', '\$${receipt.remainingAmount.toStringAsFixed(2)}', const Color(0xFFEF4444))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF080F1E),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                  border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.07))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white54, side: const BorderSide(color: Colors.white12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text('داخستن', style: TextStyle(fontFamily: 'Rabar')),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), elevation: 0),
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('دەستکاریکردنی وەسڵ', style: TextStyle(fontFamily: 'Rabar', fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        ref.read(posProvider.notifier).loadReceipt(receipt);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const PosScreen()));
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.25))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontFamily: 'Rabar', fontSize: 12, color: color.withValues(alpha: 0.9))),
      ]),
    );
  }

  Widget _totalItem(String label, String value, Color color) {
    return Column(children: [
      Text(label, style: const TextStyle(fontFamily: 'Rabar', fontSize: 10, color: Colors.white30)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontFamily: 'NRT', fontSize: 14, fontWeight: FontWeight.bold, color: color)),
    ]);
  }
}
