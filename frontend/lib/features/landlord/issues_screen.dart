import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../models/enums.dart';
import '../../models/issue.dart';
import '../../providers/data.dart';
import '../../router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/semantic_colors.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cards.dart';
import '../../widgets/common.dart';
import '../../widgets/list_states.dart';

/// L2 - issues inbox. Filter by status, priority, property; sort by most nudged.
class IssuesScreen extends ConsumerStatefulWidget {
  const IssuesScreen({super.key});

  @override
  ConsumerState<IssuesScreen> createState() => _IssuesScreenState();
}

class _IssuesScreenState extends ConsumerState<IssuesScreen> {
  bool _searching = false;
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() => _searching = !_searching);
    if (!_searching) {
      _search.clear();
      ref.read(issueFilterProvider.notifier).setQuery('');
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(landlordIssuesProvider);
    final filtered = ref.watch(filteredLandlordIssuesProvider);
    final filter = ref.watch(issueFilterProvider);
    final notifier = ref.read(issueFilterProvider.notifier);

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: 'Issues',
            trailing: IconButton(
              tooltip: _searching ? 'Close search' : 'Search issues',
              icon: Icon(_searching ? Symbols.close_rounded : Symbols.search_rounded),
              onPressed: _toggleSearch,
            ),
          ),
          if (_searching)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: SearchField(controller: _search, hint: 'Search title, student or room', onChanged: notifier.setQuery),
            ),
          if (!all.hasValue && all.isLoading)
            const _ChipPlaceholders()
          else if (all.hasValue) ...[
            _StatusChips(all: all.requireValue, filter: filter, onSelect: notifier.setStatus),
            _FilterRow(filter: filter, onOpenSheet: () => showSortFilterSheet(context, ref)),
          ],
          Expanded(
            child: AsyncBody(
              value: filtered,
              onRetry: () => ref.invalidate(landlordIssuesProvider),
              errorTitle: 'Couldn’t load issues',
              loading: const SkeletonList(),
              data: (issues) {
                if (issues.isEmpty) return _EmptyIssues(filter: filter, all: all.value ?? const []);
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(landlordIssuesProvider.future),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: issues.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) =>
                        IssueCard(issue: issues[i], onTap: () => context.push(Routes.landlordIssue(issues[i].id))),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Pill search field on surfaceContainerHigh (L2, L10).
class SearchField extends StatelessWidget {
  const SearchField({super.key, required this.controller, required this.hint, required this.onChanged, this.autofocus = true});

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(28));
    return TextField(
      controller: controller,
      autofocus: autofocus,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.surfaceHigh,
        prefixIcon: const Icon(Symbols.search_rounded, color: AppColors.onSurface),
        suffixIcon: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => controller.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  tooltip: 'Clear',
                  icon: const Icon(Symbols.close_rounded, size: 20),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
        ),
        border: const OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
        enabledBorder: const OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
        focusedBorder: const OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: AppColors.primary, width: 2)),
      ),
    );
  }
}

class _ChipPlaceholders extends StatelessWidget {
  const _ChipPlaceholders();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Row(children: [
          for (final w in [84.0, 100.0, 120.0]) ...[
            Container(width: w, height: 32, decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(8))),
            const SizedBox(width: 8),
          ],
        ]),
      );
}

class _StatusChips extends StatelessWidget {
  const _StatusChips({required this.all, required this.filter, required this.onSelect});

  final List<Issue> all;
  final IssueFilter filter;
  final ValueChanged<IssueStatus?> onSelect;

  @override
  Widget build(BuildContext context) {
    // Counts respect priority/property filters but not the status chip itself.
    final scoped = all.where((i) => IssueFilter(priorities: filter.priorities, propertyId: filter.propertyId, status: i.status).matches(i));
    int count(IssueStatus s) => scoped.where((i) => i.status == s).length;
    final openCount = scoped.where((i) => i.isOpen).length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: [
          FilterChip(
            label: Text('Open · $openCount'),
            selected: filter.status == null,
            onSelected: (_) => onSelect(null),
          ),
          for (final s in IssueStatus.values) ...[
            const SizedBox(width: 8),
            FilterChip(
              avatar: filter.status == s
                  ? null
                  : Icon(context.statusColors.of(s).icon, size: 16, color: context.statusColors.of(s).onContainer, fill: 1),
              label: Text('${s.label} ${count(s)}'),
              selected: filter.status == s,
              onSelected: (selected) => onSelect(selected ? s : null),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.filter, required this.onOpenSheet});

  final IssueFilter filter;
  final VoidCallback onOpenSheet;

  @override
  Widget build(BuildContext context) {
    final priorityLabel = filter.priorities.isEmpty
        ? 'Priority'
        : (IssuePriority.values.where(filter.priorities.contains).map((p) => p.label).join(', '));
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 16, 12),
      child: Row(
        children: [
          // Chips size to their labels; if they ever run out of room they scroll rather than squash.
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _DropChip(label: priorityLabel, active: filter.priorities.isNotEmpty, onTap: onOpenSheet),
                const SizedBox(width: 8),
                Consumer(builder: (context, ref, _) {
                  final issues = ref.watch(landlordIssuesProvider).value ?? const [];
                  final name = filter.propertyId == null
                      ? 'All properties'
                      : issues.where((i) => i.propertyId == filter.propertyId).firstOrNull?.propertyName ?? 'Property';
                  return _DropChip(label: name, active: filter.propertyId != null, onTap: onOpenSheet);
                }),
              ]),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.tertiaryContainer,
            shape: const StadiumBorder(),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: onOpenSheet,
              child: Container(
                height: 40,
                padding: const EdgeInsets.fromLTRB(10, 0, 12, 0),
                child: Row(children: [
                  const Icon(Symbols.sort_rounded, size: 18, color: AppColors.onTertiaryContainer),
                  const SizedBox(width: 6),
                  Text(filter.sort.label,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.onTertiaryContainer)),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DropChip extends StatelessWidget {
  const _DropChip({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: active ? AppColors.secondaryContainer : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
          side: active ? BorderSide.none : const BorderSide(color: AppColors.outline),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.small),
          child: Container(
            height: 32,
            padding: const EdgeInsets.fromLTRB(12, 0, 6, 0),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.w600 : FontWeight.w500, color: AppColors.onSurface)),
              ),
              const Icon(Symbols.arrow_drop_down_rounded, size: 18),
            ]),
          ),
        ),
      );
}

class _EmptyIssues extends ConsumerWidget {
  const _EmptyIssues({required this.filter, required this.all});

  final IssueFilter filter;
  final List<Issue> all;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (all.isEmpty) {
      return StateMessage(
        icon: Symbols.task_alt_rounded,
        iconBackground: context.statusColors.resolved.container,
        iconForeground: context.statusColors.resolved.onContainer,
        title: 'No issues yet',
        message: 'When students report something, it shows up here.',
      );
    }
    if (!filter.hasNarrowing && filter.query.isEmpty) {
      return StateMessage(
        icon: Symbols.task_alt_rounded,
        iconBackground: context.statusColors.resolved.container,
        iconForeground: context.statusColors.resolved.onContainer,
        title: filter.status == null ? 'No open issues' : 'Nothing ${filter.status!.label.toLowerCase()}',
        message: filter.status == null ? 'Everything reported is resolved.' : 'No issues are at this stage right now.',
      );
    }
    final property = filter.propertyId == null ? null : all.where((i) => i.propertyId == filter.propertyId).firstOrNull?.propertyName;
    final priorities = IssuePriority.values.where(filter.priorities.contains).map((p) => p.label.toLowerCase()).join(' or ');
    final what = [
      filter.status == null ? 'open' : filter.status!.label.toLowerCase(),
      if (priorities.isNotEmpty) '$priorities-priority',
      'issues',
    ].join(' ');
    return StateMessage(
      icon: Symbols.filter_alt_off_rounded,
      title: 'No issues match',
      message: filter.query.isNotEmpty
          ? 'Nothing matches “${filter.query}”.'
          : 'There are no $what${property == null ? '' : ' at $property'}.',
      action: BigButton(
        label: 'Clear filters',
        variant: BigButtonVariant.outlined,
        height: 48,
        fontSize: 14,
        expand: false,
        onPressed: () => ref.read(issueFilterProvider.notifier).set(IssueFilter(sort: filter.sort)),
      ),
    );
  }
}

/// L2s - sort & filter bottom sheet. Edits a draft; "Show N issues" applies it.
Future<void> showSortFilterSheet(BuildContext context, WidgetRef ref) {
  final all = ref.read(landlordIssuesProvider).value ?? const <Issue>[];
  var draft = ref.read(issueFilterProvider);
  final properties = <int, String>{for (final i in all) i.propertyId: i.propertyName};

  return showModalBottomSheet<void>(
    context: context,
    // Cover the bottom navigation too, like the design.
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => StatefulBuilder(builder: (context, setState) {
      final t = Theme.of(context).textTheme;
      final count = draft.apply(all).length;
      Widget label(String text) => Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 10),
            child: Text(text, style: t.labelLarge!.copyWith(fontSize: 13, color: AppColors.onSurfaceVariant)),
          );

      return SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 8, 8),
              child: Row(children: [
                Expanded(child: Text('Sort & filter', style: t.titleLarge)),
                TextButton(
                  onPressed: () => setState(() => draft = IssueFilter(status: draft.status)),
                  child: const Text('Reset'),
                ),
              ]),
            ),
            label('Sort by'),
            RadioGroup<IssueSort>(
              groupValue: draft.sort,
              onChanged: (v) => setState(() => draft = draft.copyWith(sort: v)),
              child: Column(children: [
                for (final s in IssueSort.values)
                  RadioListTile<IssueSort>(
                    value: s,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    title: Text(s.label, style: TextStyle(fontWeight: draft.sort == s ? FontWeight.w600 : FontWeight.w400)),
                    subtitle: s.description == null ? null : Text(s.description!),
                    secondary: s == IssueSort.mostNudged
                        ? const Icon(Symbols.notifications_active_rounded, color: AppColors.tertiary, fill: 1)
                        : null,
                  ),
              ]),
            ),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12), child: Divider()),
            label('Priority'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Wrap(spacing: 8, runSpacing: 8, children: [
                for (final p in IssuePriority.values.reversed)
                  FilterChip(
                    label: Text(p.label),
                    selected: draft.priorities.contains(p),
                    onSelected: (on) => setState(() {
                      final next = {...draft.priorities};
                      on ? next.add(p) : next.remove(p);
                      draft = draft.copyWith(priorities: next);
                    }),
                  ),
              ]),
            ),
            const SizedBox(height: 10),
            label('Property'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Wrap(spacing: 8, runSpacing: 8, children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: draft.propertyId == null,
                  onSelected: (_) => setState(() => draft = draft.copyWith(propertyId: () => null)),
                ),
                for (final e in properties.entries)
                  ChoiceChip(
                    label: Text(e.value),
                    selected: draft.propertyId == e.key,
                    onSelected: (_) => setState(() => draft = draft.copyWith(propertyId: () => e.key)),
                  ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: BigButton(
                label: count == 0 ? 'No matching issues' : 'Show ${count == 1 ? '1 issue' : '$count issues'}',
                onPressed: () {
                  ref.read(issueFilterProvider.notifier).set(draft);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      );
    }),
  );
}
