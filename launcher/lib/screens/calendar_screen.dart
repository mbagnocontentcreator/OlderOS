import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/olderos_theme.dart';
import '../widgets/top_bar.dart';
import '../widgets/big_button.dart';

enum EventType {
  compleanno,
  appuntamento,
  promemoria,
}

class CalendarEvent {
  final String id;
  final String title;
  final String? description;
  final DateTime date;
  final TimeOfDay? time;  // Orario per appuntamenti
  final EventType type;
  final bool isRecurringYearly;

  CalendarEvent({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    this.time,
    required this.type,
    this.isRecurringYearly = false,
  });

  String? get formattedTime {
    if (time == null) return null;
    final hour = time!.hour.toString().padLeft(2, '0');
    final minute = time!.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Color get color {
    switch (type) {
      case EventType.compleanno:
        return const Color(0xFFE11D48);
      case EventType.appuntamento:
        return const Color(0xFF2563EB);
      case EventType.promemoria:
        return const Color(0xFFF59E0B);
    }
  }

  IconData get icon {
    switch (type) {
      case EventType.compleanno:
        return Icons.cake;
      case EventType.appuntamento:
        return Icons.event;
      case EventType.promemoria:
        return Icons.notifications;
    }
  }

  String get typeLabel {
    switch (type) {
      case EventType.compleanno:
        return 'Compleanno';
      case EventType.appuntamento:
        return 'Appuntamento';
      case EventType.promemoria:
        return 'Promemoria';
    }
  }
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _currentMonth;
  late DateTime _selectedDate;
  final List<CalendarEvent> _events = [];

  final List<String> _weekDays = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];
  final List<String> _months = [
    'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
    'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day);

    // Eventi di esempio
    _events.addAll([
      CalendarEvent(
        id: '1',
        title: 'Compleanno Maria',
        description: 'La mia figlia compie 45 anni',
        date: DateTime(now.year, now.month, 15),
        type: EventType.compleanno,
        isRecurringYearly: true,
      ),
      CalendarEvent(
        id: '2',
        title: 'Visita dal dottore',
        description: 'Controllo annuale - Dott. Rossi',
        date: DateTime(now.year, now.month, now.day + 3),
        time: const TimeOfDay(hour: 10, minute: 30),
        type: EventType.appuntamento,
      ),
      CalendarEvent(
        id: '3',
        title: 'Pagare bolletta luce',
        date: DateTime(now.year, now.month, 20),
        type: EventType.promemoria,
      ),
    ]);
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _currentMonth = DateTime(now.year, now.month, 1);
      _selectedDate = DateTime(now.year, now.month, now.day);
    });
  }

  List<CalendarEvent> _getEventsForDate(DateTime date) {
    return _events.where((event) {
      if (event.isRecurringYearly) {
        return event.date.month == date.month && event.date.day == date.day;
      }
      return event.date.year == date.year &&
          event.date.month == date.month &&
          event.date.day == date.day;
    }).toList();
  }

  bool _hasEventsOnDate(DateTime date) {
    return _getEventsForDate(date).isNotEmpty;
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  void _showAddEventDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    EventType selectedType = EventType.appuntamento;
    bool isRecurring = false;
    TimeOfDay? selectedTime;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(OlderOSTheme.borderRadiusCard),
          ),
          title: Text(
            'Nuovo Evento',
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data: ${DateFormat('d MMMM yyyy', 'it_IT').format(_selectedDate)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: OlderOSTheme.calendarColor,
                  ),
                ),
                const SizedBox(height: 24),

                // Titolo
                Text('Titolo:', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                TextField(
                  controller: titleController,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Es: Visita dal dottore',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 16),

                // Descrizione
                Text('Descrizione (opzionale):', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  style: Theme.of(context).textTheme.bodyLarge,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Aggiungi dettagli...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 24),

                // Tipo evento
                Text('Tipo:', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: EventType.values.map((type) {
                    final isSelected = selectedType == type;
                    final color = CalendarEvent(
                      id: '',
                      title: '',
                      date: DateTime.now(),
                      type: type,
                    ).color;
                    final icon = CalendarEvent(
                      id: '',
                      title: '',
                      date: DateTime.now(),
                      type: type,
                    ).icon;
                    final label = CalendarEvent(
                      id: '',
                      title: '',
                      date: DateTime.now(),
                      type: type,
                    ).typeLabel;

                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedType = type),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? color : color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: color, width: 2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, color: isSelected ? Colors.white : color, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              label,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: isSelected ? Colors.white : color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                // Orario per appuntamenti
                if (selectedType == EventType.appuntamento) ...[
                  const SizedBox(height: 24),
                  Text('Orario:', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              timePickerTheme: TimePickerThemeData(
                                backgroundColor: OlderOSTheme.cardBackground,
                                hourMinuteTextStyle: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                                dayPeriodTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (time != null) {
                        setDialogState(() => selectedTime = time);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: selectedTime != null
                            ? OlderOSTheme.primary.withAlpha(25)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selectedTime != null ? OlderOSTheme.primary : Colors.grey.shade400,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 28,
                            color: selectedTime != null ? OlderOSTheme.primary : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            selectedTime != null
                                ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                                : 'Seleziona orario',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: selectedTime != null ? OlderOSTheme.primary : Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                if (selectedType == EventType.compleanno) ...[
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => setDialogState(() => isRecurring = !isRecurring),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isRecurring ? OlderOSTheme.calendarColor : Colors.transparent,
                            border: Border.all(color: OlderOSTheme.calendarColor, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: isRecurring
                              ? const Icon(Icons.check, color: Colors.white, size: 24)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Ripeti ogni anno',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  BigButton(
                    label: 'Annulla',
                    backgroundColor: OlderOSTheme.textSecondary,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  BigButton(
                    label: 'Salva',
                    icon: Icons.save,
                    backgroundColor: OlderOSTheme.success,
                    onTap: () {
                      if (titleController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Inserisci un titolo',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            backgroundColor: OlderOSTheme.danger,
                          ),
                        );
                        return;
                      }

                      setState(() {
                        _events.add(CalendarEvent(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          title: titleController.text.trim(),
                          description: descriptionController.text.trim().isEmpty
                              ? null
                              : descriptionController.text.trim(),
                          date: _selectedDate,
                          time: selectedType == EventType.appuntamento ? selectedTime : null,
                          type: selectedType,
                          isRecurringYearly: selectedType == EventType.compleanno && isRecurring,
                        ));
                      });
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEventDetails(CalendarEvent event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OlderOSTheme.borderRadiusCard),
        ),
        title: Row(
          children: [
            Icon(event.icon, color: event.color, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                event.title,
                style: Theme.of(context).textTheme.displayMedium,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: event.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                event.typeLabel,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: event.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 24, color: OlderOSTheme.textSecondary),
                const SizedBox(width: 8),
                Text(
                  DateFormat('EEEE d MMMM yyyy', 'it_IT').format(event.date),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
            if (event.formattedTime != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 24, color: OlderOSTheme.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    'Ore ${event.formattedTime}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: OlderOSTheme.primary,
                    ),
                  ),
                ],
              ),
            ],
            if (event.description != null) ...[
              const SizedBox(height: 16),
              Text(
                event.description!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: OlderOSTheme.textSecondary,
                ),
              ),
            ],
            if (event.isRecurringYearly) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.repeat, size: 24, color: OlderOSTheme.calendarColor),
                  const SizedBox(width: 8),
                  Text(
                    'Si ripete ogni anno',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: OlderOSTheme.calendarColor,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                BigButton(
                  label: 'Elimina',
                  icon: Icons.delete,
                  backgroundColor: OlderOSTheme.danger,
                  onTap: () {
                    setState(() {
                      _events.removeWhere((e) => e.id == event.id);
                    });
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(width: 16),
                BigButton(
                  label: 'Chiudi',
                  backgroundColor: OlderOSTheme.primary,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<DateTime> _getDaysInMonth() {
    final firstDayOfMonth = _currentMonth;

    // Trova il primo lunedi da mostrare
    int startWeekday = firstDayOfMonth.weekday;
    final firstDisplayDate = firstDayOfMonth.subtract(Duration(days: startWeekday - 1));

    // Genera 42 giorni (6 settimane) per riempire la griglia
    final days = <DateTime>[];
    for (int i = 0; i < 42; i++) {
      days.add(firstDisplayDate.add(Duration(days: i)));
    }

    return days;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  bool _isSelected(DateTime date) {
    return date.year == _selectedDate.year &&
        date.month == _selectedDate.month &&
        date.day == _selectedDate.day;
  }

  bool _isCurrentMonth(DateTime date) {
    return date.month == _currentMonth.month;
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = _getDaysInMonth();
    final eventsForSelectedDate = _getEventsForDate(_selectedDate);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            TopBar(
              title: 'CALENDARIO',
              onGoHome: () => Navigator.of(context).pop(),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(OlderOSTheme.marginScreen),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Calendario
                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          color: OlderOSTheme.cardBackground,
                          borderRadius: BorderRadius.circular(OlderOSTheme.borderRadiusCard),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Header navigazione mese
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _NavButton(
                                    icon: Icons.chevron_left,
                                    onTap: _previousMonth,
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        _months[_currentMonth.month - 1],
                                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                          color: OlderOSTheme.calendarColor,
                                        ),
                                      ),
                                      Text(
                                        '${_currentMonth.year}',
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          color: OlderOSTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  _NavButton(
                                    icon: Icons.chevron_right,
                                    onTap: _nextMonth,
                                  ),
                                ],
                              ),
                            ),

                            // Pulsante "Oggi"
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: GestureDetector(
                                onTap: _goToToday,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: OlderOSTheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'OGGI',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: OlderOSTheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Giorni della settimana
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                children: _weekDays.map((day) => Expanded(
                                  child: Center(
                                    child: Text(
                                      day,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: OlderOSTheme.textSecondary,
                                      ),
                                    ),
                                  ),
                                )).toList(),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Griglia giorni
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: GridView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 7,
                                    childAspectRatio: 1,
                                    mainAxisSpacing: 4,
                                    crossAxisSpacing: 4,
                                  ),
                                  itemCount: 42,
                                  itemBuilder: (context, index) {
                                    final date = daysInMonth[index];
                                    final isToday = _isToday(date);
                                    final isSelected = _isSelected(date);
                                    final isCurrentMonth = _isCurrentMonth(date);
                                    final hasEvents = _hasEventsOnDate(date);

                                    return GestureDetector(
                                      onTap: () => _selectDate(date),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? OlderOSTheme.calendarColor
                                              : isToday
                                                  ? OlderOSTheme.calendarColor.withOpacity(0.2)
                                                  : Colors.transparent,
                                          borderRadius: BorderRadius.circular(12),
                                          border: isToday && !isSelected
                                              ? Border.all(color: OlderOSTheme.calendarColor, width: 2)
                                              : null,
                                        ),
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Text(
                                              '${date.day}',
                                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                color: isSelected
                                                    ? Colors.white
                                                    : isCurrentMonth
                                                        ? OlderOSTheme.textPrimary
                                                        : OlderOSTheme.textSecondary.withOpacity(0.5),
                                                fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                                              ),
                                            ),
                                            if (hasEvents && !isSelected)
                                              Positioned(
                                                bottom: 4,
                                                child: Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    color: OlderOSTheme.calendarColor,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 24),

                    // Panel eventi
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          color: OlderOSTheme.cardBackground,
                          borderRadius: BorderRadius.circular(OlderOSTheme.borderRadiusCard),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Header data selezionata
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: OlderOSTheme.calendarColor,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(OlderOSTheme.borderRadiusCard),
                                  topRight: Radius.circular(OlderOSTheme.borderRadiusCard),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '${_selectedDate.day}',
                                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                      color: Colors.white,
                                      fontSize: 48,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('EEEE', 'it_IT').format(_selectedDate),
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Lista eventi
                            Expanded(
                              child: eventsForSelectedDate.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.event_available,
                                            size: 64,
                                            color: OlderOSTheme.textSecondary.withOpacity(0.5),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Nessun evento',
                                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                              color: OlderOSTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.all(16),
                                      itemCount: eventsForSelectedDate.length,
                                      itemBuilder: (context, index) {
                                        final event = eventsForSelectedDate[index];
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 12),
                                          child: GestureDetector(
                                            onTap: () => _showEventDetails(event),
                                            child: Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: event.color.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: event.color, width: 2),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(event.icon, color: event.color, size: 32),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          event.title,
                                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                        Row(
                                                          children: [
                                                            Text(
                                                              event.typeLabel,
                                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                                color: event.color,
                                                              ),
                                                            ),
                                                            if (event.formattedTime != null) ...[
                                                              Text(
                                                                '  •  ',
                                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                                  color: OlderOSTheme.textSecondary,
                                                                ),
                                                              ),
                                                              Icon(
                                                                Icons.access_time,
                                                                size: 16,
                                                                color: OlderOSTheme.primary,
                                                              ),
                                                              const SizedBox(width: 4),
                                                              Text(
                                                                event.formattedTime!,
                                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                                  color: OlderOSTheme.primary,
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                              ),
                                                            ],
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Icon(
                                                    Icons.chevron_right,
                                                    color: OlderOSTheme.textSecondary,
                                                    size: 28,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),

                            // Pulsante aggiungi
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: SizedBox(
                                width: double.infinity,
                                child: BigButton(
                                  label: 'NUOVO EVENTO',
                                  icon: Icons.add,
                                  backgroundColor: OlderOSTheme.calendarColor,
                                  onTap: _showAddEventDialog,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavButton({required this.icon, required this.onTap});

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _isHovered ? OlderOSTheme.calendarColor : OlderOSTheme.calendarColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            widget.icon,
            size: 36,
            color: _isHovered ? Colors.white : OlderOSTheme.calendarColor,
          ),
        ),
      ),
    );
  }
}
