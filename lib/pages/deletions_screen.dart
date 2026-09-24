import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_toast.dart';
import '../models/receipt_model.dart';
import '../providers/auth_provider.dart';
import '../providers/receipts_provider.dart';

class DeletionsScreen extends ConsumerStatefulWidget {
  const DeletionsScreen({super.key});

  @override
  ConsumerState<DeletionsScreen> createState() => _DeletionsScreenState();
}

class _DeletionsScreenState extends ConsumerState<DeletionsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _confirmDeleteReceipt(BuildContext context, ReceiptModel receipt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.redAccent,
              size: 24,
            ),
            SizedBox(width: 10),
            Text(
              'سڕینەوەی وەسڵ لە سیستم',
              style: TextStyle(
                fontFamily: 'NRT',
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Text(
          'ئایا دڵنیایت لە سڕینەوەی بەکاتی وەسڵی #${receipt.id.substring(0, 8)}؟\nئەم کردارە ناوەڕۆکی وەسڵەکە لە بنکەی زانیاری دەسڕێتەوە.',
          style: const TextStyle(
            fontFamily: 'Rabar',
            color: Colors.white70,
            height: 1.4,
          ),
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
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(receiptsProvider.notifier)
                  .deleteReceipt(receipt.id);
              if (context.mounted) {
                AppToast.show(
                  context,
                  'وەسڵەکە بە سەرکەوتوویی سڕایەوە.',
                  type: ToastType.success,
                );
              }
            },
            child: const Text(
              'بەڵێ، بیسڕەوە',
              style: TextStyle(
                fontFamily: 'Rabar',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
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
                  color: Colors.redAccent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: Colors.redAccent,
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
                'بەشی سڕینەوە تەنها بۆ بەڕێوەبەر (Admin) بەردەستە.',
                style: TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 13,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
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

    final receiptsAsync = ref.watch(receiptsProvider);

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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'بەشی سڕینەوە ',
              style: TextStyle(
                fontFamily: 'NRT',
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              'تەنها بەڕێوەبەر دەتوانێت سڕینەوە بەئەنجام بگەیەنێت',
              style: TextStyle(
                fontFamily: 'Rabar',
                fontSize: 11,
                color: Colors.white54,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.delete_sweep_rounded,
                color: Colors.redAccent,
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: receiptsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.redAccent),
        ),
        error: (e, _) => Center(
          child: Text(
            'هەڵەیەک ڕوویدا: $e',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        data: (allReceipts) {
          final filteredReceipts = allReceipts.where((r) {
            if (_searchQuery.isEmpty) return true;
            final q = _searchQuery.toLowerCase();
            return r.customerName.toLowerCase().contains(q) ||
                r.customerPhone.contains(q) ||
                r.id.toLowerCase().contains(q);
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Warning banner ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          color: Colors.redAccent,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'بەشی سڕینەوە پارێزراوە!',
                              style: TextStyle(
                                fontFamily: 'NRT',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'تەنها بەڕێوەبەر مافی سڕینەوەی داتاکانی هەیە بۆ ڕێگریکردن لە هەڵەی سڕینەوە.',
                              style: TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Search bar ──
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (val) =>
                        setState(() => _searchQuery = val.trim()),
                    style: const TextStyle(
                      fontFamily: 'Rabar',
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'گەڕان بەپێی ناوی کڕیار، ژمارەی وەسڵ...',
                      hintStyle: const TextStyle(
                        fontFamily: 'Rabar',
                        color: Colors.white38,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
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
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Receipts Table ──
                Expanded(
                  child: filteredReceipts.isEmpty
                      ? const Center(
                          child: Text(
                            'هیچ وەسڵێک نەدۆزرایەوە',
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              color: Colors.white54,
                            ),
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppTheme.cardBg,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.09),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth:
                                      (MediaQuery.of(context).size.width - 32)
                                          .clamp(700.0, 5000.0),
                                ),
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(
                                    const Color(0xFF231649),
                                  ),
                                  dividerThickness: 0.4,
                                  columns: const [
                                    DataColumn(
                                      label: Text(
                                        '#',
                                        style: TextStyle(
                                          fontFamily: 'Rabar',
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'ژمارەی وەسڵ',
                                        style: TextStyle(
                                          fontFamily: 'Rabar',
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'ناوی کڕیار',
                                        style: TextStyle(
                                          fontFamily: 'Rabar',
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'کۆی پارە',
                                        style: TextStyle(
                                          fontFamily: 'Rabar',
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'جۆری پارەدان',
                                        style: TextStyle(
                                          fontFamily: 'Rabar',
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'کرداری سڕینەوە',
                                        style: TextStyle(
                                          fontFamily: 'Rabar',
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ),
                                  ],
                                  rows: filteredReceipts.asMap().entries.map((
                                    entry,
                                  ) {
                                    final i = entry.key;
                                    final r = entry.value;
                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Text(
                                            '${i + 1}',
                                            style: const TextStyle(
                                              fontFamily: 'NRT',
                                              color: Colors.white38,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            '#${r.id.substring(0, 8)}',
                                            style: const TextStyle(
                                              fontFamily: 'NRT',
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            r.customerName.isEmpty
                                                ? 'کڕیاری گشتی'
                                                : r.customerName,
                                            style: const TextStyle(
                                              fontFamily: 'Rabar',
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            '\$${r.grandTotal.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontFamily: 'NRT',
                                              color: Color(0xFF10B981),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            r.paymentMethod,
                                            style: const TextStyle(
                                              fontFamily: 'Rabar',
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.redAccent
                                                  .withValues(alpha: 0.2),
                                              foregroundColor: Colors.redAccent,
                                              elevation: 0,
                                              side: BorderSide(
                                                color: Colors.redAccent
                                                    .withValues(alpha: 0.4),
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                            ),
                                            onPressed: () =>
                                                _confirmDeleteReceipt(
                                                  context,
                                                  r,
                                                ),
                                            icon: const Icon(
                                              Icons.delete_forever_rounded,
                                              size: 16,
                                            ),
                                            label: const Text(
                                              'سڕینەوە',
                                              style: TextStyle(
                                                fontFamily: 'Rabar',
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
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
}

class DeletionSectionAuthDialog extends ConsumerStatefulWidget {
  const DeletionSectionAuthDialog({super.key});

  @override
  ConsumerState<DeletionSectionAuthDialog> createState() =>
      _DeletionSectionAuthDialogState();
}

class _DeletionSectionAuthDialogState
    extends ConsumerState<DeletionSectionAuthDialog> {
  final _passCtrl = TextEditingController();
  String? _errorMsg;
  bool _isLoading = false;

  @override
  void dispose() {
    _passCtrl.dispose();
    super.dispose();
  }

  void _verifyPassword() async {
    final pass = _passCtrl.text;
    if (pass.isEmpty) {
      setState(() => _errorMsg = 'تکایە وشەی نهێنی بنووسە');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    final err = await ref.read(authProvider.notifier).verifyPassword(pass);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (err == null) {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DeletionsScreen()),
      );
    } else {
      setState(() => _errorMsg = err);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    color: Colors.redAccent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'چوونەژوورەوە بۆ بەشی سڕینەوە',
                  style: TextStyle(
                    fontFamily: 'NRT',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'تکایە وشەی نهێنی بەڕێوەبەر بنووسە بۆ هەبوونی مافی سڕینەوە:',
              style: TextStyle(
                fontFamily: 'Rabar',
                fontSize: 13,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passCtrl,
              obscureText: true,
              style: const TextStyle(fontFamily: 'Rabar', color: Colors.white),
              decoration: InputDecoration(
                hintText: 'وشەی نهێنی (پاسوۆرد)',
                hintStyle: const TextStyle(
                  fontFamily: 'Rabar',
                  color: Colors.white38,
                  fontSize: 13,
                ),
                prefixIcon: const Icon(
                  Icons.lock_outline_rounded,
                  color: Colors.redAccent,
                  size: 18,
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _verifyPassword(),
            ),
            if (_errorMsg != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorMsg!,
                style: const TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 12,
                  color: Colors.redAccent,
                ),
              ),
            ],
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
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _isLoading ? null : _verifyPassword,
                  child: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'پشتڕاستکردنەوە',
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
