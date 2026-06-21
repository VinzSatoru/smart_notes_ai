import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../bloc/notes_bloc.dart';
import '../bloc/notes_state.dart';
import '../../domain/entities/note.dart';
import 'note_editor_screen.dart';
import '../widgets/note_card.dart';

class CalendarScreen extends StatefulWidget {
  final String userId;
  const CalendarScreen({super.key, required this.userId});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  
  final Color primaryColor = const Color(0xFF4F64F2);
  final Color navyColor = const Color(0xFF1E293B);

  List<Note> _getNotesForDay(List<Note> allNotes, DateTime day) {
    return allNotes.where((note) {
      if (note.created.isEmpty) return false;
      try {
        final noteDate = DateTime.parse(note.created).toLocal();
        return isSameDay(noteDate, day);
      } catch (_) {
        return false;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: navyColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Kalender Pintar',
          style: TextStyle(color: navyColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: BlocBuilder<NotesBloc, NotesState>(
        builder: (context, state) {
          final dayNotes = _getNotesForDay(state.notes, _selectedDay);

          return Column(
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color ?? Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: navyColor.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  eventLoader: (day) => _getNotesForDay(state.notes, day),
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: BoxDecoration(
                      color: const Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                    ),
                    weekendTextStyle: const TextStyle(color: Colors.redAccent),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'Catatan pada ${DateFormat('dd MMM yyyy').format(_selectedDay)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: navyColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${dayNotes.length}',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: dayNotes.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: dayNotes.length,
                        itemBuilder: (context, index) {
                          final note = dayNotes[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: NoteCard(
                              note: note,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => NoteEditorScreen(
                                      note: note,
                                      userId: widget.userId,
                                      categories: state.categories,
                                    ),
                                  ),
                                );
                              },
                              onLongPress: () {
                                // Opsional: Berikan aksi long press di dalam kalender
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy_rounded,
            size: 64,
            color: navyColor.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada catatan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: navyColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Anda tidak membuat catatan pada tanggal ini.',
            style: TextStyle(
              fontSize: 14,
              color: navyColor.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}
