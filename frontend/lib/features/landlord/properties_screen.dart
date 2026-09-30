import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../models/property.dart';
import '../../providers/data.dart';
import '../../router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/format.dart';
import '../../widgets/buttons.dart';
import '../../widgets/common.dart';
import '../../widgets/issue_badges.dart';
import '../../widgets/list_states.dart';

/// L5 / L5e - the landlord's properties, beds filled, open issues, nudges.
class PropertiesScreen extends ConsumerWidget {
  const PropertiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(propertiesProvider);
    final list = value.value;
    final hasProperties = list != null && list.isNotEmpty;
    final filled = list?.fold<int>(0, (n, p) => n + p.bedsFilled) ?? 0;
    final total = list?.fold<int>(0, (n, p) => n + p.bedsTotal) ?? 0;

    return Scaffold(
      floatingActionButton: hasProperties
          ? FloatingActionButton.extended(
              onPressed: () => context.push(Routes.newProperty),
              icon: const Icon(Symbols.add_rounded),
              label: const Text('Add property'),
            )
          : null,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: 'Properties',
              subtitle: hasProperties ? '${Fmt.plural(list.length, 'property', 'properties')} · $filled of $total beds filled' : null,
            ),
            Expanded(
              child: AsyncBody(
                value: value,
                onRetry: () => ref.invalidate(propertiesProvider),
                errorTitle: 'Couldn’t load properties',
                data: (properties) => properties.isEmpty
                    ? StateMessage(
                        icon: Symbols.add_home_work_rounded,
                        size: 96,
                        iconBackground: AppColors.primaryContainer,
                        iconForeground: AppColors.primary,
                        title: 'Add your first property',
                        message: 'Add a property, set up its rooms, then assign students so they can report issues.',
                        action: BigButton(
                          label: 'Add property',
                          icon: Symbols.add_rounded,
                          expand: false,
                          fontSize: 15,
                          onPressed: () => context.push(Routes.newProperty),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => ref.refresh(propertiesProvider.future),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
                          itemCount: properties.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, i) => PropertyCard(
                            property: properties[i],
                            onTap: () => context.push(Routes.property(properties[i].id)),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PropertyCard extends StatelessWidget {
  const PropertyCard({super.key, required this.property, this.onTap});

  final Property property;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = property;
    final fraction = p.bedsTotal == 0 ? 0.0 : p.bedsFilled / p.bedsTotal;
    return OutlinedCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IconTile(Symbols.apartment_rounded, size: 48, background: AppColors.primary, foreground: Colors.white, iconSize: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.name, style: t.titleMedium!.copyWith(fontSize: 17)),
                  const SizedBox(height: 2),
                  Text(p.shortAddress, style: t.bodySmall!.copyWith(fontSize: 13, color: AppColors.onSurfaceVariant)),
                ]),
              ),
              const Icon(Symbols.chevron_right_rounded, color: AppColors.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: Text(Fmt.plural(p.roomCount, 'room'), style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant))),
            Text.rich(TextSpan(style: const TextStyle(fontSize: 13), children: [
              TextSpan(text: '${p.bedsFilled} / ${p.bedsTotal}', style: const TextStyle(fontWeight: FontWeight.w700)),
              const TextSpan(text: ' beds'),
            ])),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: AppColors.surfaceHighest,
              color: AppColors.primary,
              semanticsLabel: 'Beds filled',
              semanticsValue: '${p.bedsFilled} of ${p.bedsTotal}',
            ),
          ),
          if (p.openIssueCount > 0 || p.openIssueNudges > 0) ...[
            const SizedBox(height: 14),
            Row(children: [
              if (p.openIssueCount > 0) CountChip(icon: Symbols.build_rounded, label: '${p.openIssueCount} open'),
              if (p.openIssueNudges > 0) ...[const SizedBox(width: 8), NudgePill(p.openIssueNudges)],
            ]),
          ],
        ],
      ),
    );
  }
}

/// Small white stat tile (L6 "11/12 Beds filled").
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.value, required this.label, this.highlight = false});

  final String value;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final fg = highlight ? AppColors.onTertiaryContainer : AppColors.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: highlight ? AppColors.tertiaryContainer : Colors.white,
        border: highlight ? null : Border.all(color: AppColors.surfaceHighest),
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: fg)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: highlight ? fg : AppColors.onSurfaceVariant)),
      ]),
    );
  }
}
