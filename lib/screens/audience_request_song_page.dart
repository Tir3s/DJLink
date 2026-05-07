import 'package:flutter/material.dart';
import '../models/app_session.dart';
import '../widgets/modern_snackbar.dart';

class AudienceRequestSongPage extends StatefulWidget {
  const AudienceRequestSongPage({super.key});

  @override
  State<AudienceRequestSongPage> createState() =>
      _AudienceRequestSongPageState();
}

class _AudienceRequestSongPageState extends State<AudienceRequestSongPage> {
  final _songController = TextEditingController();
  final _artistController = TextEditingController();
  final _messageController = TextEditingController();
  double _tipAmount = 1; // £1–£20

  @override
  void dispose() {
    _songController.dispose();
    _artistController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _submitRequest() {
    final event = AppSession.selectedEvent;
    if (event == null) {
      ModernSnackBar.showWarning(
        context,
        'Please join an event before sending a request.',
      );
      return;
    }

    if (_songController.text.trim().isEmpty ||
        _artistController.text.trim().isEmpty) {
      ModernSnackBar.showWarning(context, 'Song and artist are required.');
      return;
    }

    ModernSnackBar.showSuccess(
      context,
      'Song request sent to ${event.name} with £${_tipAmount.toStringAsFixed(0)} tip',
    );

    _songController.clear();
    _artistController.clear();
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
        title: const Text('Request a Song'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Banner
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
                'Song title',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _songController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('e.g. One More Time'),
              ),

              const SizedBox(height: 12),

              const Text(
                'Artist',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _artistController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('e.g. Daft Punk'),
              ),

              const SizedBox(height: 12),

              const Text(
                'Message to DJ (optional)',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: _inputDecoration('Why this song? Dedication?'),
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
                  onPressed: _submitRequest,
                  child: const Text(
                    'Send request',
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
