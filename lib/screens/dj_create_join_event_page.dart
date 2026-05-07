import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/app_session.dart';
import '../models/event_model.dart';
import '../services/firestore_service.dart';
import '../widgets/modern_snackbar.dart';

class DjCreateJoinEventPage extends StatefulWidget {
  const DjCreateJoinEventPage({super.key});

  @override
  State<DjCreateJoinEventPage> createState() => _DjCreateJoinEventPageState();
}

class _DjCreateJoinEventPageState extends State<DjCreateJoinEventPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();
  final _eventNameController = TextEditingController();
  final _venueController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _durationController = TextEditingController(text: '180');
  final _genreController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _joinCodeController = TextEditingController();
  LatLng _mapCenter = const LatLng(50.8198, -1.0880);
  LatLng? _selectedLatLng;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _venueController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _durationController.dispose();
    _genreController.dispose();
    _descriptionController.dispose();
    _joinCodeController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    if (message.contains('Error') || message.contains('require') || message.contains('invalid')) {
      ModernSnackBar.showError(context, message);
    } else if (message.contains('must be') || message.contains('Code')) {
      ModernSnackBar.showWarning(context, message);
    } else {
      ModernSnackBar.showInfo(context, message);
    }
  }

  Future<void> _initLocation() async {
    setState(() {
      _isLocating = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLocating = false;
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _isLocating = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _mapCenter = LatLng(position.latitude, position.longitude);
        _isLocating = false;
      });
    } catch (_) {
      setState(() {
        _isLocating = false;
      });
    }
  }

  DateTime? _parseDate(String input) {
    final cleaned = input.trim().replaceAll(',', '');
    final parts = cleaned.split(RegExp(r'\s+'));
    if (parts.length < 2) return null;

    final day = int.tryParse(parts[0]);
    if (day == null || day < 1 || day > 31) return null;

    final monthStr = parts[1].toLowerCase();
    const months = {
      'jan': 1,
      'january': 1,
      'feb': 2,
      'february': 2,
      'mar': 3,
      'march': 3,
      'apr': 4,
      'april': 4,
      'may': 5,
      'jun': 6,
      'june': 6,
      'jul': 7,
      'july': 7,
      'aug': 8,
      'august': 8,
      'sep': 9,
      'sept': 9,
      'september': 9,
      'oct': 10,
      'october': 10,
      'nov': 11,
      'november': 11,
      'dec': 12,
      'december': 12,
    };
    final month = months[monthStr];
    if (month == null) return null;

    final now = DateTime.now();
    return DateTime(now.year, month, day);
  }

  TimeOfDay? _parseTime(String input) {
    final cleaned = input.trim();
    final parts = cleaned.split(':');
    if (parts.length != 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      _showSnack('Please log in again.');
      return;
    }

    final parsedDate = _parseDate(_dateController.text);
    final parsedTime = _parseTime(_timeController.text);
    final durationMinutes = int.tryParse(_durationController.text.trim());
    if (parsedDate == null || parsedTime == null) {
      _showSnack('Use date like 12 Oct and time like 22:30');
      return;
    }
    if (durationMinutes == null || durationMinutes <= 0) {
      _showSnack('Enter a valid duration in minutes.');
      return;
    }

    if (_selectedLatLng == null) {
      _showSnack('Tap the map to drop a venue pin.');
      return;
    }

    final startTime = DateTime(
      parsedDate.year,
      parsedDate.month,
      parsedDate.day,
      parsedTime.hour,
      parsedTime.minute,
    );
    if (startTime.isBefore(DateTime.now())) {
      _showSnack(
        'You cannot create an event in the past. Please choose a future date and time.',
      );
      return;
    }

    final event = Event(
      eventId: '',
      djId: userId,
      eventName: _eventNameController.text.trim(),
      location: _venueController.text.trim(),
      latitude: _selectedLatLng!.latitude,
      longitude: _selectedLatLng!.longitude,
      date: parsedDate,
      theme: _genreController.text.trim(),
      status: EventStatus.scheduled,
      startTime: startTime,
      durationMinutes: durationMinutes,
    );

    try {
      final eventId = await _firestoreService.createEvent(event);
      _showSnack(
        'Event created. Join code: $eventId. Use Join to activate it.',
      );
      _formKey.currentState!.reset();
      _eventNameController.clear();
      _venueController.clear();
      _dateController.clear();
      _timeController.clear();
      _durationController.text = '180';
      _genreController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedLatLng = null;
      });
    } catch (e) {
      _showSnack('Failed to create event.');
    }
  }

  Future<void> _joinEvent() async {
    if (_joinCodeController.text.trim().isEmpty) {
      _showSnack('Enter a join code');
      return;
    }
    final code = _joinCodeController.text.trim().toUpperCase();
    try {
      final event = await _firestoreService.getEvent(code);
      if (event == null) {
        _showSnack('No event found for that code');
        return;
      }
      final now = DateTime.now();
      if (!event.isJoinableAt(now)) {
        if (now.isBefore(event.joinOpensAt)) {
          _showSnack('You can join 2 hours before the event starts.');
        } else {
          _showSnack('This event has ended and can no longer be joined.');
        }
        return;
      }
      AppSession.selectedEvent = EventSummary(
        id: event.eventId,
        name: event.eventName,
        venue: event.location,
        time: 'Live now',
        isLive: event.status == EventStatus.active,
      );
      _showSnack('Joined ${event.eventName}');
      _joinCodeController.clear();
    } catch (e) {
      _showSnack('Could not join event');
    }
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF4B0082);
    const darkBg = Colors.black;

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Create / Join Event'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create a new event',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _Input(
                        label: 'Event name',
                        controller: _eventNameController,
                      ),
                      const SizedBox(height: 12),
                      _Input(label: 'Venue', controller: _venueController),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Venue pin',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: _mapCenter,
                            initialZoom: 15,
                            onTap: (_, latLng) {
                              setState(() {
                                _selectedLatLng = latLng;
                              });
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'dj_link',
                            ),
                            MarkerLayer(
                              markers: _selectedLatLng == null
                                  ? []
                                  : [
                                      Marker(
                                        point: _selectedLatLng!,
                                        width: 40,
                                        height: 40,
                                        child: Icon(
                                          Icons.location_on,
                                          color: purple,
                                          size: 36,
                                        ),
                                      ),
                                    ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedLatLng == null
                                  ? 'Tap the map to drop a pin.'
                                  : 'Pin: ${_selectedLatLng!.latitude.toStringAsFixed(5)}, ${_selectedLatLng!.longitude.toStringAsFixed(5)}',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          if (_isLocating)
                            const Text(
                              'Locating...',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _Input(
                              label: 'Date',
                              controller: _dateController,
                              hint: 'e.g. 12 Oct',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _Input(
                              label: 'Time',
                              controller: _timeController,
                              hint: 'e.g. 22:30',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _Input(
                        label: 'Duration (minutes)',
                        controller: _durationController,
                        hint: 'e.g. 180',
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final value = int.tryParse((v ?? '').trim());
                          if (value == null || value <= 0) {
                            return 'Enter a valid duration';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _Input(
                        label: 'Genre',
                        controller: _genreController,
                        hint: 'House, Techno, Open format…',
                      ),
                      const SizedBox(height: 12),
                      _Input(
                        label: 'Description',
                        controller: _descriptionController,
                        maxLines: 3,
                        hint: 'Short vibe/notes for the crowd',
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: purple,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _createEvent,
                          child: const Text(
                            'Create event',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Text(
                'Join existing event',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    _Input(
                      label: 'Enter join code',
                      controller: _joinCodeController,
                      hint: 'e.g. ABC123',
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Join code required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: purple),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _joinEvent,
                        child: const Text('Join event'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // No bottom navigation to keep focus on create/join flow
    );
  }
}

class _Input extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _Input({
    required this.label,
    required this.controller,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator:
              validator ??
              (v) {
                if (v == null || v.trim().isEmpty) {
                  return '$label is required';
                }
                return null;
              },
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF121212),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
