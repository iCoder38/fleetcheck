import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/inspection_model.dart';
import '../../repositories/inspection_repository.dart';
import '../../routes/app_router.dart';

class InspectionHistoryScreen extends StatefulWidget {
  const InspectionHistoryScreen({super.key});

  @override
  State<InspectionHistoryScreen> createState() => _InspectionHistoryScreenState();
}

class _InspectionHistoryScreenState extends State<InspectionHistoryScreen> {
  final _repo = InspectionRepository();

  // Filter state
  String _dateRange    = 'all';
  String? _typeFilter;
  String? _statusFilter;
  final _vehicleCtrl   = TextEditingController();

  bool _isLoading      = true;
  String? _error;
  List<InspectionResult> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _vehicleCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    final result = await _repo.getInspections(
      dateRange:     _dateRange == 'all' ? null : _dateRange,
      vehicleNumber: _vehicleCtrl.text.trim().isEmpty ? null : _vehicleCtrl.text.trim(),
      type:          _typeFilter,
      status:        _statusFilter,
    );
    if (!mounted) return;
    if (result.success) {
      setState(() { _items = result.data ?? []; _isLoading = false; });
    } else {
      setState(() { _error = result.error; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text(AppStrings.inspectionHistory)),
      body: Column(
        children: [
          // ─── Filters ────────────────────────────────────
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date range chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final d in [
                        ('all',    'All'),
                        ('today',  'Today'),
                        ('yesterday', 'Yesterday'),
                        ('week',   'Last 7 Days'),
                        ('custom', 'Custom'),
                      ])
                        _DateChip(
                          label:    d.$2,
                          selected: _dateRange == d.$1,
                          onTap:    () {
                            if (d.$1 == 'custom') {
                              _pickDateRange();
                            } else {
                              setState(() => _dateRange = d.$1);
                              _load();
                            }
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Second row: type + status
                Row(
                  children: [
                    Expanded(
                      child: _DropdownFilter<String>(
                        hint:  'All Types',
                        value: _typeFilter,
                        items: const {'pre_trip': 'Pre-Trip', 'post_trip': 'Post-Trip'},
                        onChanged: (v) { setState(() => _typeFilter = v); _load(); },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DropdownFilter<String>(
                        hint:  'All Status',
                        value: _statusFilter,
                        items: const {'completed': 'Completed', 'pending': 'Pending', 'rejected': 'Rejected', 'under_review': 'Under Review'},
                        onChanged: (v) { setState(() => _statusFilter = v); _load(); },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                // Vehicle number search
                TextField(
                  controller:   _vehicleCtrl,
                  decoration:   InputDecoration(
                    hintText:    'Search by Vehicle Number',
                    prefixIcon:  const Icon(Icons.search_rounded, size: 20),
                    suffixIcon:  _vehicleCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () { _vehicleCtrl.clear(); _load(); })
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _load(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ─── Results ────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
                : _error != null
                    ? _ErrorState(message: _error!, onRetry: _load)
                    : _items.isEmpty
                        ? _EmptyState()
                        : RefreshIndicator(
                            onRefresh: _load,
                            color: AppColors.secondary,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _items.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (_, i) => _HistoryCard(
                                item:  _items[i],
                                onTap: () => context.push('/history/${_items[i].id}'),
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context:      context,
      firstDate:    DateTime(2023),
      lastDate:     DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (range != null) {
      setState(() => _dateRange = 'custom');
      _load();
    }
  }
}

class _HistoryCard extends StatelessWidget {
  final InspectionResult item;
  final VoidCallback onTap;

  const _HistoryCard({required this.item, required this.onTap});

  Color get _statusColor => switch (item.status) {
    'completed'    => AppColors.secondary,
    'pending'      => AppColors.amber,
    'rejected'     => AppColors.danger,
    'under_review' => AppColors.primary,
    _              => AppColors.textSecondary,
  };

  String get _statusLabel => switch (item.status) {
    'completed'    => 'Completed',
    'pending'      => 'Pending',
    'rejected'     => 'Rejected',
    'under_review' => 'Under Review',
    _              => item.status,
  };

  @override
  Widget build(BuildContext context) {
    final isPreTrip = item.inspectionType == 'pre_trip';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:        AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: AppColors.border),
          boxShadow:    [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            // Type icon
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color:         (isPreTrip ? AppColors.secondary : AppColors.primary).withOpacity(0.08),
                borderRadius:  BorderRadius.circular(10),
              ),
              child: Icon(
                isPreTrip ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded,
                color: isPreTrip ? AppColors.secondary : AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.inspectionId,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.primary,
                          fontFamily: 'monospace')),
                  const SizedBox(height: 2),
                  Text(item.vehicleNumber,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Row(children: [
                    Text(isPreTrip ? 'Pre-Trip' : 'Post-Trip',
                        style: TextStyle(fontSize: 11, color: isPreTrip ? AppColors.secondary : AppColors.primary, fontWeight: FontWeight.w600)),
                    const Text('  ·  ', style: TextStyle(color: AppColors.textLight)),
                    Text(DateFormat('MM/dd/yyyy').format(item.submittedAt),
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ]),
                ],
              ),
            ),

            // Status + arrow
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color:        _statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(_statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _statusColor)),
                ),
                const SizedBox(height: 8),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helper widgets ───────────────────────────────────────

class _DateChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _DateChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color:        selected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border:       Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary)),
      ),
    );
  }
}

class _DropdownFilter<T> extends StatelessWidget {
  final String hint;
  final T? value;
  final Map<T, String> items;
  final ValueChanged<T?> onChanged;
  const _DropdownFilter({required this.hint, required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color:        AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border:       Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value:       value,
          hint:        Text(hint, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          isExpanded:  true,
          icon:        const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textSecondary),
          isDense:     true,
          style:       const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontFamily: 'Poppins'),
          items:       [
            DropdownMenuItem<T>(value: null, child: Text(hint, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
            ...items.entries.map((e) => DropdownMenuItem<T>(value: e.key, child: Text(e.value))),
          ],
          onChanged:   onChanged,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.textSecondary),
      const SizedBox(height: 12),
      Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
      const SizedBox(height: 16),
      ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded, size: 18), label: const Text('Retry')),
    ])),
  );
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.assignment_outlined, size: 56, color: AppColors.textSecondary.withOpacity(0.4)),
      const SizedBox(height: 12),
      const Text('No inspections found.', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      const Text('Try adjusting your filters.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
    ])),
  );
}
