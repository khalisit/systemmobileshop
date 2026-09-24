import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_toast.dart';
import '../models/repair_type_model.dart';
import '../providers/repair_types_provider.dart';

class RepairTypesScreen extends ConsumerStatefulWidget {
  const RepairTypesScreen({super.key});

  @override
  ConsumerState<RepairTypesScreen> createState() => _RepairTypesScreenState();
}

class _RepairTypesScreenState extends ConsumerState<RepairTypesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repairTypesAsync = ref.watch(repairTypesProvider);

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
                Icons.settings_suggest_rounded,
                color: Color(0xFF06B6D4),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'ڕێکخستنی جۆری چاکردنەوەکان',
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
            tooltip: 'نوێکردنەوە',
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: () {
              ref.read(repairTypesProvider.notifier).refreshRepairTypes();
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF06B6D4),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'زیادکردنی جۆری کار',
                style: TextStyle(
                  fontFamily: 'Rabar',
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () => _showRepairTypeDialog(context, ref),
            ),
          ),
        ],
      ),
      body: repairTypesAsync.when(
        loading: () => _buildContent(isLoading: true, items: []),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(
                'کێشەیەک ڕوویدا: $err',
                style: const TextStyle(fontFamily: 'Rabar', color: Colors.white70),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(repairTypesProvider.notifier).refreshRepairTypes(),
                child: const Text('دووبارە هەوڵبدەرەوە', style: TextStyle(fontFamily: 'Rabar')),
              ),
            ],
          ),
        ),
        data: (allItems) => _buildContent(isLoading: false, items: allItems),
      ),
    );
  }

  Widget _buildContent({required bool isLoading, required List<RepairTypeModel> items}) {
    final searchQuery = _searchCtrl.text.trim().toLowerCase();
    final filteredItems = items.where((c) {
      return searchQuery.isEmpty || c.name.toLowerCase().contains(searchQuery);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.surfaceColor),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF06B6D4).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.build_circle_rounded, color: Color(0xFF06B6D4), size: 24),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'سەرجەم جۆرەکانی چاکردنەوە (Repair Types)',
                      style: TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 13,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    isLoading
                        ? Container(
                            width: 60,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          )
                            .animate(onPlay: (c) => c.repeat())
                            .shimmer(duration: 1200.ms, color: Colors.white24)
                        : Text(
                            '${items.length} جۆر',
                            style: const TextStyle(
                              fontFamily: 'NRT',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ],
                ),
              ],
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.surfaceColor),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontFamily: 'Rabar', color: Colors.white),
              decoration: InputDecoration(
                hintText: 'گەڕان بەدوای جۆری چاککردنەوەدا...',
                hintStyle: const TextStyle(fontFamily: 'Rabar', color: Colors.white38),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: Colors.white38),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.darkBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Container(
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
                        minWidth: MediaQuery.of(context).size.width - 32,
                      ),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(AppTheme.darkBg),
                        dataRowMinHeight: 60,
                        dataRowMaxHeight: 60,
                        headingTextStyle: const TextStyle(
                          fontFamily: 'Rabar',
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        dataTextStyle: const TextStyle(
                          fontFamily: 'Rabar',
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        columns: const [
                          DataColumn(label: Text('#'), numeric: true),
                          DataColumn(label: Text('ناوی جۆری کار')),
                          DataColumn(label: Text('کردارەکان')),
                        ],
                        rows: filteredItems.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final model = entry.value;
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  '${idx + 1}',
                                  style: const TextStyle(
                                    fontFamily: 'NRT',
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white60,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  model.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_rounded, color: Colors.orange, size: 20),
                                      onPressed: () => _showRepairTypeDialog(context, ref, existingItem: model),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 20),
                                      onPressed: () => _confirmDelete(context, ref, model),
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
            ),
          ),
        ),
      ],
    );
  }

  void _showRepairTypeDialog(BuildContext context, WidgetRef ref, {RepairTypeModel? existingItem}) {
    final nameCtrl = TextEditingController(text: existingItem?.name ?? '');

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.surfaceColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    existingItem != null ? Icons.edit_note_rounded : Icons.add_circle_rounded,
                    color: const Color(0xFF06B6D4),
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    existingItem != null ? 'تەندروستکردنی جۆری کار' : 'زیادکردنی جۆری کاری نوێ',
                    style: const TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'ناوی جۆری چاککردنەوە:',
                style: TextStyle(fontFamily: 'Rabar', fontSize: 13, color: Colors.white70),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(fontFamily: 'Rabar', color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'بۆ نموونە: گۆڕینی پاتری، پاککردنەوە لە ئاو...',
                  hintStyle: const TextStyle(fontFamily: 'Rabar', color: Colors.white30),
                  filled: true,
                  fillColor: AppTheme.darkBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.surfaceColor),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('پاشگەزبوونەوە', style: TextStyle(fontFamily: 'Rabar', color: Colors.white60)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF06B6D4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) {
                        AppToast.show(context, 'ناوی جۆرەکە بنووسە', type: ToastType.error);
                        return;
                      }

                      if (existingItem != null) {
                        final updated = RepairTypeModel(id: existingItem.id, name: name);
                        await ref.read(repairTypesProvider.notifier).updateRepairType(updated);
                        if (context.mounted) {
                          AppToast.show(context, 'بە سەرکەوتوویی نوێکرایەوە', type: ToastType.success);
                        }
                      } else {
                        final item = RepairTypeModel(id: const Uuid().v4(), name: name);
                        await ref.read(repairTypesProvider.notifier).addRepairType(item);
                        if (context.mounted) {
                          AppToast.show(context, 'بە سەرکەوتوویی زیادکرا', type: ToastType.success);
                        }
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: Text(
                      existingItem != null ? 'پاشەکەوتکردن' : 'تۆمارکردن',
                      style: const TextStyle(fontFamily: 'Rabar', fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, RepairTypeModel model) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text(
          'دڵنیایی لە سڕینەوە؟',
          style: TextStyle(fontFamily: 'Rabar', color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'دەتەوێت جۆری کاری "${model.name}" بسڕیتەوە؟',
          style: const TextStyle(fontFamily: 'Rabar', color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('پاشگەزبوونەوە', style: TextStyle(fontFamily: 'Rabar', color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await ref.read(repairTypesProvider.notifier).deleteRepairType(model.id);
              if (context.mounted) {
                AppToast.show(context, 'بە سەرکەوتوویی سڕایەوە', type: ToastType.success);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('سڕینەوە', style: TextStyle(fontFamily: 'Rabar', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
