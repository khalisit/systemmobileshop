import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_toast.dart';
import '../core/utils/english_digits_formatter.dart';
import '../models/repair_receipt_model.dart';
import '../providers/repair_receipts_provider.dart';
import '../providers/repair_types_provider.dart';
import 'repair_types_screen.dart';

enum DateFilter { all, weekly, monthly, yearly }

class RepairsScreen extends ConsumerStatefulWidget {
  const RepairsScreen({super.key});

  @override
  ConsumerState<RepairsScreen> createState() => _RepairsScreenState();
}

class _RepairsScreenState extends ConsumerState<RepairsScreen> {
  DateFilter _currentFilter = DateFilter.all;

  List<RepairReceiptModel> _filterReceipts(List<RepairReceiptModel> receipts) {
    final now = DateTime.now();
    return receipts.where((r) {
      if (_currentFilter == DateFilter.weekly) {
        final weekAgo = now.subtract(const Duration(days: 7));
        return r.date.isAfter(weekAgo);
      } else if (_currentFilter == DateFilter.monthly) {
        return r.date.year == now.year && r.date.month == now.month;
      } else if (_currentFilter == DateFilter.yearly) {
        return r.date.year == now.year;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final receiptsAsync = ref.watch(repairReceiptsProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C1A2E),
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
                color: const Color(0xFF06B6D4).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.home_repair_service_rounded,
                color: Color(0xFF06B6D4),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'بەشی چاکردنەوەی ئامێرەکان',
              style: TextStyle(
                fontFamily: 'Rabar',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'ڕێکخستنی جۆرەکانی چاکردنەوە',
            icon: const Icon(
              Icons.settings_suggest_rounded,
              color: Color(0xFF06B6D4),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RepairTypesScreen()),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: receiptsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(
            'هەڵەیەک ڕوویدا: $err',
            style: const TextStyle(color: Colors.red),
          ),
        ),
        data: (allReceipts) {
          final filteredReceipts = _filterReceipts(allReceipts);

          double totalItemCost = 0;
          double totalLaborCost = 0;
          double grandTotal = 0;

          for (var r in filteredReceipts) {
            totalItemCost += r.itemCost;
            totalLaborCost += r.laborCost;
            grandTotal += r.totalPrice;
          }

          return Column(
            children: [
              _buildTopBar(),
              _buildStats(totalItemCost, totalLaborCost, grandTotal),
              Expanded(
                child: filteredReceipts.isEmpty
                    ? _buildEmptyState()
                    : SingleChildScrollView(
                        child: _buildReceiptsList(filteredReceipts),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddReceiptDialog(context),
        backgroundColor: const Color(0xFF10B981),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'وەسڵی نوێ',
          style: TextStyle(
            fontFamily: 'Rabar',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: const Color(0xFF0C1A2E),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'ئاماری چاکردنەوەکان',
            style: TextStyle(
              fontFamily: 'Rabar',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.surfaceColor),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<DateFilter>(
                value: _currentFilter,
                dropdownColor: AppTheme.cardBg,
                icon: const Icon(
                  Icons.filter_list_rounded,
                  color: Colors.white70,
                  size: 20,
                ),
                style: const TextStyle(
                  fontFamily: 'Rabar',
                  color: Colors.white,
                  fontSize: 13,
                ),
                items: const [
                  DropdownMenuItem(
                    value: DateFilter.all,
                    child: Text('هەموو کاتێک'),
                  ),
                  DropdownMenuItem(
                    value: DateFilter.weekly,
                    child: Text('ئەم هەفتەیە'),
                  ),
                  DropdownMenuItem(
                    value: DateFilter.monthly,
                    child: Text('ئەم مانگە'),
                  ),
                  DropdownMenuItem(
                    value: DateFilter.yearly,
                    child: Text('ئەم ساڵ'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _currentFilter = val);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(double items, double labor, double total) {
    final currencyFormat = NumberFormat.currency(
      symbol: '\$ ',
      decimalDigits: 2,
    );

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              title: 'تێچووی پارچەکان',
              value: currencyFormat.format(items),
              icon: Icons.memory_rounded,
              color: const Color(0xFFF59E0B),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              title: 'داهاتی حەق دەست',
              value: currencyFormat.format(labor),
              icon: Icons.build_circle_rounded,
              color: const Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              title: 'کۆی گشتی',
              value: currencyFormat.format(total),
              icon: Icons.account_balance_wallet_rounded,
              color: const Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Rabar',
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'NRT',
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 80,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          const Text(
            'هیچ وەسڵێکی چاکردنەوە نییە',
            style: TextStyle(
              fontFamily: 'Rabar',
              fontSize: 16,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptsList(List<RepairReceiptModel> receipts) {
    final currencyFormat = NumberFormat.currency(
      symbol: '\$ ',
      decimalDigits: 2,
    );

    String formatDate(DateTime d) {
      final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
      final min = d.minute.toString().padLeft(2, '0');
      final ampm = d.hour >= 12 ? 'PM' : 'AM';
      return '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}  $h:$min $ampm';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.surfaceColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width - 48,
              ),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  const Color(0xFF0C1A2E),
                ),
                dataRowMinHeight: 64,
                dataRowMaxHeight: 64,
                horizontalMargin: 20,
                columnSpacing: 24,
                headingTextStyle: const TextStyle(
                  fontFamily: 'Rabar',
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF06B6D4),
                  fontSize: 12,
                ),
                columns: const [
                  DataColumn(label: Text('#'), numeric: true),
                  DataColumn(label: Text('ناوی کڕیار')),
                  DataColumn(label: Text('مۆبایل')),
                  DataColumn(label: Text('جۆری چاکردنەوە')),
                  DataColumn(label: Text('تێچووی پارچە'), numeric: true),
                  DataColumn(label: Text('حەق دەست'), numeric: true),
                  DataColumn(label: Text('کۆی گشتی'), numeric: true),
                  DataColumn(label: Text('بەروار')),
                  DataColumn(label: Text('کردارەکان')),
                ],
                rows: receipts.asMap().entries.map((entry) {
                  final i = entry.key;
                  final r = entry.value;
                  final isEven = i % 2 == 0;
                  return DataRow(
                    color: WidgetStateProperty.all(
                      isEven
                          ? Colors.transparent
                          : Colors.white.withValues(alpha: 0.02),
                    ),
                    cells: [
                      // Row number
                      DataCell(
                        Text(
                          '${i + 1}',
                          style: const TextStyle(
                            fontFamily: 'NRT',
                            color: Colors.white38,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Customer name
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: const Color(0xFF06B6D4).withValues(alpha: 0.15),
                              child: Text(
                                r.customerName.isNotEmpty
                                    ? r.customerName[0].toUpperCase()
                                    : '؟',
                                style: const TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 12,
                                  color: Color(0xFF06B6D4),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              r.customerName.isNotEmpty ? r.customerName : 'دیاری نەکراو',
                              style: const TextStyle(
                                fontFamily: 'Rabar',
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Phone
                      DataCell(
                        Text(
                          r.customerPhone.isNotEmpty ? r.customerPhone : '---',
                          style: const TextStyle(
                            fontFamily: 'NRT',
                            color: Colors.white60,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      // Repair type
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF06B6D4).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF06B6D4).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            r.repairType,
                            style: const TextStyle(
                              fontFamily: 'Rabar',
                              color: Color(0xFF06B6D4),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      // Item cost
                      DataCell(
                        Text(
                          currencyFormat.format(r.itemCost),
                          style: const TextStyle(
                            fontFamily: 'NRT',
                            color: Color(0xFFF59E0B),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Labor cost
                      DataCell(
                        Text(
                          currencyFormat.format(r.laborCost),
                          style: const TextStyle(
                            fontFamily: 'NRT',
                            color: Color(0xFF3B82F6),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Grand total
                      DataCell(
                        Text(
                          currencyFormat.format(r.totalPrice),
                          style: const TextStyle(
                            fontFamily: 'NRT',
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      // Date
                      DataCell(
                        Text(
                          formatDate(r.date),
                          style: const TextStyle(
                            fontFamily: 'NRT',
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      // Actions
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit_rounded,
                                color: Color(0xFF06B6D4),
                                size: 20,
                              ),
                              tooltip: 'دەستکاریکردن',
                              onPressed: () =>
                                  _showAddReceiptDialog(context, editingReceipt: r),
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
      ),
    );
  }


  void _showAddReceiptDialog(
    BuildContext context, {
    RepairReceiptModel? editingReceipt,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _AddRepairReceiptDialog(editingReceipt: editingReceipt),
    );
  }
}

class _AddRepairReceiptDialog extends ConsumerStatefulWidget {
  final RepairReceiptModel? editingReceipt;

  const _AddRepairReceiptDialog({this.editingReceipt});

  @override
  ConsumerState<_AddRepairReceiptDialog> createState() =>
      _AddRepairReceiptDialogState();
}

class _AddRepairReceiptDialogState
    extends ConsumerState<_AddRepairReceiptDialog> {
  final _formKey = GlobalKey<FormState>();

  final _customerNameCtrl = TextEditingController();
  final _customerPhoneCtrl = TextEditingController();
  final _repairTypeCtrl = TextEditingController();
  final _itemCostCtrl = TextEditingController();
  final _laborCostCtrl = TextEditingController();

  final List<String> _quickSuggestions = [
    'گۆڕینی شوشەی مۆبایل',
    'چاککردنەوەی پاتری',
    'کێبل و دەرچەی شەحن',
    'بەرنامە و سۆفتوێر',
    'مایکرۆفۆن و بڵندگۆ',
    'بۆرد و ئایسی',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.editingReceipt != null) {
      final r = widget.editingReceipt!;
      _customerNameCtrl.text = r.customerName;
      _customerPhoneCtrl.text = r.customerPhone;
      _repairTypeCtrl.text = r.repairType;
      _itemCostCtrl.text = r.itemCost > 0 ? r.itemCost.toString() : '';
      _laborCostCtrl.text = r.laborCost > 0 ? r.laborCost.toString() : '';
    }
  }

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _customerPhoneCtrl.dispose();
    _repairTypeCtrl.dispose();
    _itemCostCtrl.dispose();
    _laborCostCtrl.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _customerNameCtrl.text.trim().isEmpty 
        ? 'کڕیاری گشتی' 
        : _customerNameCtrl.text.trim();
    final phone = _customerPhoneCtrl.text.trim();
    final type = _repairTypeCtrl.text.trim();
    final itemCost = double.tryParse(_itemCostCtrl.text.trim()) ?? 0.0;
    final laborCost = double.tryParse(_laborCostCtrl.text.trim()) ?? 0.0;

    if (type.isEmpty) {
      AppToast.show(
        context,
        'تکایە جۆری چاکردنەوە بنووسە',
        type: ToastType.error,
      );
      return;
    }

    final receipt = RepairReceiptModel(
      id: widget.editingReceipt?.id,
      date: widget.editingReceipt?.date,
      customerName: name,
      customerPhone: phone,
      repairType: type,
      itemCost: itemCost,
      laborCost: laborCost,
    );

    try {
      if (widget.editingReceipt != null) {
        await ref.read(repairReceiptsProvider.notifier).updateReceipt(receipt);
        if (mounted) {
          AppToast.show(context, 'وەسڵەکە نوێکرایەوە', type: ToastType.success);
        }
      } else {
        await ref.read(repairReceiptsProvider.notifier).addReceipt(receipt);
        if (mounted) {
          AppToast.show(context, 'وەسڵەکە زیادکرا', type: ToastType.success);
        }
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          'هەڵەیەک ڕوویدا لە پاشەکەوتکردن',
          type: ToastType.error,
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editingReceipt != null;
    final repairTypesAsync = ref.watch(repairTypesProvider);

    return Dialog(
      backgroundColor: AppTheme.darkBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF0C1A2E),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'دەستکاریکردنی وەسڵ' : 'وەسڵی نوێی چاکردنەوە',
                    style: const TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    children: [

                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white54,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(
                        controller: _customerNameCtrl,
                        label: 'ناوی کڕیار',
                        icon: Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _customerPhoneCtrl,
                        label: 'ژمارەی مۆبایل',
                        icon: Icons.phone_outlined,
                        isNumber: true,
                      ),
                      const SizedBox(height: 24),
                      const Divider(color: AppTheme.surfaceColor),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'جۆری چاکردنەوە',
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RepairTypesScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'زیادکردنی جۆر',
                              style: TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 11,
                                color: Color(0xFF06B6D4),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _repairTypeCtrl,
                        label: 'بۆ نموونە: گۆڕینی شاشە',
                        icon: Icons.build_outlined,
                      ),
                      const SizedBox(height: 12),
                      repairTypesAsync.when(
                        loading: () => const SizedBox(),
                        error: (_, _) => _buildChips(_quickSuggestions),
                        data: (types) {
                          if (types.isEmpty) {
                            return _buildChips(_quickSuggestions);
                          }
                          return _buildChips(types.map((e) => e.name).toList());
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _itemCostCtrl,
                              label: 'پارەی پارچەکان (\$)',
                              icon: Icons.memory_outlined,
                              isNumber: true,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _laborCostCtrl,
                              label: 'حەق دەست (\$)',
                              icon: Icons.handyman_outlined,
                              isNumber: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF0C1A2E),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppTheme.surfaceColor),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'پاشگەزبوونەوە',
                        style: TextStyle(
                          fontFamily: 'Rabar',
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _save,
                      child: Text(
                        isEditing ? 'نوێکردنەوە' : 'پاشەکەوتکردن',
                        style: const TextStyle(
                          fontFamily: 'Rabar',
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChips(List<String> suggestions) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: suggestions.map((suggestion) {
        final isSelected = _repairTypeCtrl.text == suggestion;
        return ActionChip(
          label: Text(
            suggestion,
            style: TextStyle(
              fontFamily: 'Rabar',
              fontSize: 11,
              color: isSelected ? const Color(0xFF10B981) : Colors.white70,
            ),
          ),
          backgroundColor: isSelected
              ? const Color(0xFF10B981).withValues(alpha: 0.1)
              : Colors.transparent,
          side: BorderSide(
            color: isSelected
                ? const Color(0xFF10B981)
                : const Color(0xFF334155),
            width: isSelected ? 1.5 : 1,
          ),
          onPressed: () {
            setState(() {
              _repairTypeCtrl.text = suggestion;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isNumber = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      inputFormatters: isNumber
          ? const [EnglishDigitsTextInputFormatter()]
          : null,
      style: TextStyle(
        fontFamily: isNumber ? 'NRT' : 'Rabar',
        color: Colors.white,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontFamily: 'Rabar',
          color: Colors.white54,
          fontSize: 13,
        ),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        filled: true,
        fillColor: AppTheme.cardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.surfaceColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.surfaceColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF10B981)),
        ),
      ),
    );
  }
}
