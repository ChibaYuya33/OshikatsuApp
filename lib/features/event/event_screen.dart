import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/db/models.dart';
import '../../core/state/app_providers.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/common.dart';
import 'event_detail_screen.dart';
import 'event_edit_screen.dart';

/// イベントのカレンダー表示＋一覧。
class EventScreen extends ConsumerStatefulWidget {
  const EventScreen({super.key});

  @override
  ConsumerState<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends ConsumerState<EventScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _format = CalendarFormat.month;

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appProvider);
    final oshiMap = ref.watch(oshiMapProvider);
    final events = data.events;

    List<EventItem> eventsOn(DateTime day) =>
        events.where((e) => _sameDay(e.dateTime, day)).toList();

    final dayEvents = eventsOn(_selectedDay)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return Scaffold(
      appBar: AppBar(title: const Text('イベント')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => EventEditScreen(initialDate: _selectedDay),
        )),
        icon: const Icon(Icons.add),
        label: const Text('イベントを追加'),
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(8),
            child: TableCalendar<EventItem>(
              locale: 'ja_JP',
              firstDay: DateTime(2000),
              lastDay: DateTime(2100),
              focusedDay: _focusedDay,
              calendarFormat: _format,
              availableCalendarFormats: const {
                CalendarFormat.month: '月',
                CalendarFormat.twoWeeks: '2週',
                CalendarFormat.week: '週',
              },
              selectedDayPredicate: (d) => _sameDay(d, _selectedDay),
              eventLoader: eventsOn,
              onDaySelected: (sel, foc) => setState(() {
                _selectedDay = sel;
                _focusedDay = foc;
              }),
              onFormatChanged: (f) => setState(() => _format = f),
              onPageChanged: (foc) => _focusedDay = foc,
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Expanded(
            child: dayEvents.isEmpty
                ? EmptyState(
                    icon: Icons.event_available_outlined,
                    message: '${formatDate(_selectedDay)} の予定はありません',
                    hint: '右下のボタンからイベントを追加できます',
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 88),
                    children: dayEvents.map((e) {
                      final oshi = oshiMap[e.oshiId];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: (oshi != null
                                    ? Color(oshi.themeColor)
                                    : Colors.grey)
                                .withValues(alpha: 0.2),
                            child: Icon(_iconFor(e.type),
                                color: oshi != null
                                    ? Color(oshi.themeColor)
                                    : Colors.grey),
                          ),
                          title: Text(e.title),
                          subtitle: Text(
                              '${formatTime(e.dateTime)} ・ ${e.type.label}${e.location != null ? ' ・ ${e.location}' : ''}'),
                          trailing: e.isAttended
                              ? const Icon(Icons.check_circle,
                                  color: Color(0xFF7FA07F))
                              : null,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  EventDetailScreen(eventId: e.id),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(EventType type) => switch (type) {
        EventType.live => Icons.music_note,
        EventType.ticketSale => Icons.confirmation_number_outlined,
        EventType.release => Icons.album_outlined,
        EventType.birthday => Icons.cake_outlined,
        EventType.broadcast => Icons.live_tv_outlined,
        EventType.other => Icons.event_outlined,
      };
}
