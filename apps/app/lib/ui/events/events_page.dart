import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.g.dart';
import '../widgets/common.dart';

class EventsPage extends ConsumerWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final p = context.palette;
    final data = ref.watch(ledgerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.moreEvents)),
      floatingActionButton: FloatingActionButton(
        tooltip: l.eventNew,
        onPressed: () => context.go('/more/events/new'),
        child: const Icon(Icons.add),
      ),
      body: PageBody(
        child: data.events.isEmpty
            ? EmptyState(icon: Icons.luggage_outlined, title: l.emptyEventsTitle, body: l.emptyEventsBody)
            : ListView(
                padding: const EdgeInsets.fromLTRB(QtSpace.s4, 0, QtSpace.s4, 96),
                children: [
                  Card(
                    child: Column(
                      children: [
                        for (final e in data.events)
                          ListTile(
                            leading: Icon(Icons.luggage_outlined, color: e.archived ? p.textMuted : null),
                            title: Text(e.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(
                              e.end == null ? formatDate(e.start) : '${formatDate(e.start)} - ${formatDate(e.end!)}',
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [for (final m in data.eventSpending(e.id).values) MoneyText(m)],
                            ),
                            onTap: () => context.go('/more/events/${e.id}'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
