import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_session.dart';
import '../models/shoutout_model.dart';
import '../services/firestore_service.dart';
import '../widgets/modern_snackbar.dart';

class AudienceShoutoutsPage extends StatefulWidget {
  const AudienceShoutoutsPage({super.key});

  @override
  State<AudienceShoutoutsPage> createState() => _AudienceShoutoutsPageState();
}

class _AudienceShoutoutsPageState extends State<AudienceShoutoutsPage> {
  final _nameController = TextEditingController();
  final _messageController = TextEditingController();
  double _tipAmount = 1; // £1–£20
  final _firestoreService = FirestoreService();

  @override
  void dispose() {
    _nameController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitShoutout() async {
    final event = AppSession.selectedEvent;
    if (event == null) {
      ModernSnackBar.showWarning(
        context,
        'Please join an event before sending a shoutout.',
      );
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ModernSnackBar.showWarning(
        context,
        'Please log in to send a shoutout.',
      );
      return;
    }

    if (_messageController.text.trim().isEmpty) {
      ModernSnackBar.showWarning(
        context,
        'Shoutout message is required.',
      );
      return;
    }

    final shoutout = Shoutout(
      shoutoutId: '',
      eventId: event.id,
      audienceId: currentUser.uid,
      name: _nameController.text.trim(),
      message: _messageController.text.trim(),
      tipAmount: _tipAmount,
      status: ShoutoutStatus.pending,
      timestamp: DateTime.now(),
    );

    try {
      await _firestoreService.submitShoutout(shoutout);
      if (mounted) {
        ModernSnackBar.showSuccess(
          context,
          'Shoutout sent to ${event.name} with £${_tipAmount.toStringAsFixed(0)} tip',
        );
      }
    } catch (e) {
      if (mounted) {
        ModernSnackBar.showError(
          context,
          'Error sending shoutout: $e',
        );
      }
      return;
    }

    _nameController.clear();
    _messageController.clear();
    setState(() {
      _tipAmount = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF4B0082);
    final event = AppSession.selectedEvent;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Send a Shoutout'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event != null
                          ? 'Event: ${event.name}'
                          : 'No event selected',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (event != null)
                      Text(
                        event.venue,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    if (event != null)
                      Text(
                        event.time,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Name / alias (optional)',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('e.g. Matt, Group 5, VIP Table'),
              ),

              const SizedBox(height: 12),

              const Text(
                'Shoutout message',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: _inputDecoration(
                  'e.g. “Happy birthday to Jake at the front!”',
                ),
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tip amount',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Text(
                    '£${_tipAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _tipAmount,
                min: 1,
                max: 20,
                divisions: 19,
                label: '£${_tipAmount.toStringAsFixed(0)}',
                onChanged: (value) {
                  setState(() {
                    _tipAmount = value;
                  });
                },
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: purple,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => _submitShoutout(),
                  child: const Text(
                    'Send shoutout',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.white38),
    filled: true,
    fillColor: const Color(0xFF1E1E1E),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.white30),
    ),
  );
}
