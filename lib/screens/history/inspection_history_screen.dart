import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/inspection_model.dart';
import '../../repositories/inspection_repository.dart';
import '../../routes/app_router.dart';

/// Inspection History Screen
///
/// Displays all inspection jobs assigned to the driver (pending + completed).
/// Filters: Date Range, Vehicle Number, Inspection Type, Status.
/// Each card shows: Inspection ID, Vehicle Number, Type, Date, Status.
class InspectionHistoryScreen extends StatefulWidget {
  const InspectionHistoryScreen({super.key});

  @override
  State<InspectionHistoryScreen> createState() => _InspectionHistoryScreenState();
}

class _InspectionHistoryScreenState extends State<InspectionHistoryScreen> {
  final _repo   = InspectionRepository();
  final _search = TextEditingController();

  // ── Filter state ──────────────────────────────────────
  String? _dateRange;   // null | 'today' | 'yesterday' | 'last_7_days' | 'custom'
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String? _type;        // null | 'pre_trip' | 'post_trip'
  String? _status;      // null | 'completed' | 'pending' | 'under_review'

  // ── Data state ────────────────────────────────────────
  List<InspectionResult> _items     = [];
  bool                   _loading   = true;
  bool                   _loadingMore = false;
  String?                _error;
  int                    _page      = 1;
  bool                   _hasMore   = true;

  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _load(reset: true);
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200 &&
        !_loadingMore && _hasMore) {
      _load(reset: false);
    }
  }

  Future<void> _load({bool reset = true}) async {
    if (reset) {
      setState(() { _loading = true; _error = null; _page = 1; _hasMore = true; });
    } else {
      setState(() => _loadingMore = true);
    }

    final res = await _repo.getInspections(
      dateRange:     _dateRange,
      dateFrom:      _dateFrom != null ? DateFormat('yyyy-MM-dd').format(_dateFrom!) : null,
      dateTo:        _dateTo   != null ? DateFormat('yyyy-MM-dd').format(_dateTo!)   : null,
      vehicleNumber: _search.text.trim().isEmpty ? null : _search.text.trim(),
      type:          _type,
      status:        _status,
      page:          _page,
      limit:         20,
    );

    if (!mounted) return;
    setState(() {
      _loading     = false;
      _loadingMore = false;
      if (res.success) {
        final newItems = res.data ?? [];
        if (reset) {
          _items = newItems;
        } else {
          _items.addAll(newItems);
        }
        _hasMore = newItems.length == 20;
        if (newItems.isNotEmpty) _page++;
      } else {
        _error = res.error;
      }
    });
  }

  Future<void> _pickCustomDate() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            secondary: AppColors.secondary,
          ),
        ),
        child: child!,
      ),
    );
    if (range != null) {
      setState(() {
        _dateRange = 'custom';
        _dateFrom  = range.start;
        _dateTo    = range.end;
      });
      _load(reset: true);
    }
  }

  void _clearFilters() {
    setState(() {
      _dateRange = null;
      _dateFrom  = null;
      _dateTo    = null;
      _type      = null;
      _status    = null;
      _search.clear();
    });
    _load(reset: true);
  }

  bool get _hasActiveFilters =>
      _dateRange != null || _type != null || _status != null ||
      _search.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appbg,
      body: Column(children: [
        _buildHeader(),
        _buildFilters(),
        Expanded(child: _buildBody()),
      ]),
    );
  }

  // ── Dark navy header ───────────────────────────────────────────────────────
  Widget _buildHeader() {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      padding: EdgeInsets.fromLTRB(20, top + 12, 20, 20),
      child: Row(children: [
        GestureDetector(
          onTap: () => context.go(AppRoutes.dashboard),
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Text('Inspection History',
              style: TextStyle(color: Colors.white, fontSize: 22,
                  fontWeight: FontWeight.w800)),
        ),
        GestureDetector(
          onTap: _hasActiveFilters ? _clearFilters : null,
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: _hasActiveFilters
                  ? AppColors.amber
                  : Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _hasActiveFilters ? Icons.filter_alt_off_rounded : Icons.filter_list_rounded,
              color: Colors.white, size: 20,
            ),
          ),
        ),
      ]),
    );
  }

  // ── 4 filter boxes ─────────────────────────────────────────────────────────
  Widget _buildFilters() {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(children: [
        // Row 1: Date Range | Truck Number
        Row(children: [
          Expanded(child: _FilterDropdown(
            hint: 'Date Range',
            value: _dateRangeLabel,
            onTap: _showDateRangePicker,
          )),
          const SizedBox(width: 10),
          Expanded(child: _FilterDropdown(
            hint: 'Truck Number',
            value: _search.text.trim().isEmpty ? null : _search.text.trim(),
            onTap: _showVehicleSearch,
          )),
        ]),
        const SizedBox(height: 10),
        // Row 2: Inspection Type | Status
        Row(children: [
          Expanded(child: _FilterDropdown(
            hint: 'Inspection Type',
            value: _typeLabel,
            onTap: _showTypePicker,
          )),
          const SizedBox(width: 10),
          Expanded(child: _FilterDropdown(
            hint: 'Status',
            value: _statusLabel,
            onTap: _showStatusPicker,
          )),
        ]),
      ]),
    );
  }

  String? get _dateRangeLabel {
    switch (_dateRange) {
      case 'today':      return 'Today';
      case 'yesterday':  return 'Yesterday';
      case 'last_7_days':return 'Last 7 Days';
      case 'custom':
        if (_dateFrom != null && _dateTo != null) {
          return '${DateFormat('d MMM').format(_dateFrom!)} – ${DateFormat('d MMM').format(_dateTo!)}';
        }
        return 'Custom';
      default: return null;
    }
  }

  String? get _typeLabel {
    switch (_type) {
      case 'pre_trip':  return 'Pre-Trip';
      case 'post_trip': return 'Post-Trip';
      default: return null;
    }
  }

  String? get _statusLabel {
    switch (_status) {
      case 'completed':   return 'Completed';
      case 'pending':     return 'Pending';
      case 'under_review':return 'Under Review';
      case 'failed':      return 'Rejected';
      default: return null;
    }
  }

  void _showDateRangePicker() {
    _showBottomSheet('Date Range', [
      _SheetOption('All Dates',  null,          _dateRange == null),
      _SheetOption('Today',      'today',       _dateRange == 'today'),
      _SheetOption('Yesterday',  'yesterday',   _dateRange == 'yesterday'),
      _SheetOption('Last 7 Days','last_7_days', _dateRange == 'last_7_days'),
      _SheetOption('Custom Date…','custom',     _dateRange == 'custom'),
    ], (val) {
      if (val == 'custom') {
        _pickCustomDate();
      } else {
        setState(() { _dateRange = val; _dateFrom = null; _dateTo = null; });
        _load(reset: true);
      }
    });
  }

  void _showTypePicker() {
    _showBottomSheet('Inspection Type', [
      _SheetOption('All Types',          null,         _type == null),
      _SheetOption('Pre-Trip Inspection','pre_trip',   _type == 'pre_trip'),
      _SheetOption('Post-Trip Inspection','post_trip', _type == 'post_trip'),
    ], (val) {
      setState(() => _type = val);
      _load(reset: true);
    });
  }

  void _showStatusPicker() {
    _showBottomSheet('Status', [
      _SheetOption('All Statuses',  null,          _status == null),
      _SheetOption('Pending',       'pending',     _status == 'pending'),
      _SheetOption('Completed',     'completed',   _status == 'completed'),
      _SheetOption('Under Review',  'under_review',_status == 'under_review'),
      _SheetOption('Rejected',      'failed',      _status == 'failed'),
    ], (val) {
      setState(() => _status = val);
      _load(reset: true);
    });
  }

  void _showVehicleSearch() {
    final ctrl = TextEditingController(text: _search.text);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              alignment: Alignment.center,
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(99)),
              ),
            ),
            const Text('Truck Number',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Enter truck number',
                prefixIcon: const Icon(Icons.directions_car_rounded, size: 20),
                filled: true,
                fillColor: AppColors.background,
              ),
              onSubmitted: (_) {
                Navigator.pop(ctx);
                setState(() => _search.text = ctrl.text);
                _load(reset: true);
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() => _search.text = ctrl.text);
                  _load(reset: true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBottomSheet(String title, List<_SheetOption> options, void Function(String?) onSelect) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
          ),
          const Divider(height: 1),
          ...options.map((opt) => ListTile(
            leading: Icon(
              opt.selected ? Icons.radio_button_checked_rounded
                           : Icons.radio_button_unchecked_rounded,
              color: opt.selected ? AppColors.secondary : AppColors.textSecondary,
              size: 20,
            ),
            title: Text(opt.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: opt.selected ? FontWeight.w700 : FontWeight.w500,
                  color: opt.selected ? AppColors.secondary : AppColors.textPrimary,
                )),
            onTap: () { Navigator.pop(context); onSelect(opt.value); },
          )),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }

  // ── Body: loading / error / list ───────────────────────────────────────────
  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.secondary));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.wifi_off_rounded, size: 56, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _load(reset: true),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ]),
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.assignment_outlined, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          const Text('No inspections found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text(
            _hasActiveFilters
                ? 'No inspections match your current filters.'
                : 'No inspection jobs have been assigned to you yet.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          if (_hasActiveFilters) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: _clearFilters,
              child: const Text('Clear Filters',
                  style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w700)),
            ),
          ],
        ]),
      );
    }

    return RefreshIndicator(
      color: AppColors.secondary,
      onRefresh: () => _load(reset: true),
      child: ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _items.length + (_loadingMore ? 1 : 0),
        itemBuilder: (ctx, i) {
          if (i == _items.length) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator(color: AppColors.secondary)),
            );
          }
          return _InspectionCard(
            item: _items[i],
            onTap: () => context.push(
              '/history/${_items[i].id}',
            ),
          );
        },
      ),
    );
  }
}

// ── Filter Widgets ────────────────────────────────────────────────────────────

class _FilterDropdown extends StatelessWidget {
  final String hint;
  final String? value;
  final VoidCallback onTap;

  const _FilterDropdown({
    required this.hint,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = value != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: active
              ? AppColors.secondary.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? AppColors.accent.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.18),
          ),
        ),
        child: Row(children: [
          Expanded(
            child: Text(
              value ?? hint,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : Colors.white.withValues(alpha: 0.75),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(Icons.arrow_drop_down_rounded, size: 20,
              color: Colors.white.withValues(alpha: 0.7)),
        ]),
      ),
    );
  }
}

// ── Inspection Card ───────────────────────────────────────────────────────────
class _InspectionCard extends StatelessWidget {
  final InspectionResult item;
  final VoidCallback onTap;

  const _InspectionCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(item.status);
    final statusLabel = _statusLabel(item.status);
    final typeLabel   = item.inspectionType == 'pre_trip' ? 'Pre-Trip' : 'Post-Trip';
    final dateStr     = DateFormat('MMM d, yyyy').format(item.displayDate);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.local_shipping_rounded, color: statusColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.inspectionId,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                          color: AppColors.primary)),
                  const SizedBox(height: 4),
                  Text(
                      '${item.vehicleNumber.isEmpty ? '—' : item.vehicleNumber} · $typeLabel',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(dateStr,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: statusColor, width: 1.3),
              ),
              child: Text(statusLabel,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
                      color: statusColor)),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'completed':   return AppColors.success;
      case 'under_review':return AppColors.amber;
      case 'failed':      return AppColors.danger;
      default:            return AppColors.statusPending;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'completed':   return 'Completed';
      case 'under_review':return 'Under Review';
      case 'failed':      return 'Rejected';
      default:            return 'Pending';
    }
  }
}

// ── Helper models ─────────────────────────────────────────────────────────────
class _SheetOption {
  final String  label;
  final String? value;
  final bool    selected;
  const _SheetOption(this.label, this.value, this.selected);
}
