import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_session.dart';
import '../models/song_request_model.dart';
import '../services/firestore_service.dart';

class AudienceRequestSongPageRealtime extends StatefulWidget {
  const AudienceRequestSongPageRealtime({super.key});

  @override
  State<AudienceRequestSongPageRealtime> createState() =>
      _AudienceRequestSongPageRealtimeState();
}

class _AudienceRequestSongPageRealtimeState
    extends State<AudienceRequestSongPageRealtime> {
  final _formKey = GlobalKey<FormState>();
  final _songController = TextEditingController();
  final _artistController = TextEditingController();
  final _messageController = TextEditingController();
  final _firestoreService = FirestoreService();

  double _tipAmount = 1;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _songController.dispose();
    _artistController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    final event = AppSession.selectedEvent;
    if (event == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please join an event before sending a request.'),
        ),
      );
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to submit a request.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final request = SongRequest(
        requestId: '',
        eventId: event.id,
        audienceId: currentUser.uid,
        songName: _songController.text.trim(),
        artistName: _artistController.text.trim(),
        tipAmount: _tipAmount,
        comment: _messageController.text.trim(),
        status: RequestStatus.pending,
        timestamp: DateTime.now(),
      );

      await _firestoreService.submitSongRequest(request);
      try {
        await _firestoreService.updateEventAnalytics(event.id);
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Song request sent to ${event.name}' +
                  (_tipAmount > 0
                      ? ' with £${_tipAmount.toStringAsFixed(2)} tip'
                      : ''),
            ),
            backgroundColor: Colors.green,
          ),
        );

        _songController.clear();
        _artistController.clear();
        _messageController.clear();
        setState(() {
          _tipAmount = 1;
          _isSubmitting = false;
        });

        Navigator.pop(context);
      }
    } on RequestBlockedException catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (event != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: purple),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event, color: purple),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                event.venue,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                const Text(
                  'Song Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _songController,
                  decoration: const InputDecoration(
                    labelText: 'Song Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a song name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _artistController,
                  decoration: const InputDecoration(
                    labelText: 'Artist Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an artist name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    labelText: 'Message (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Add a Tip',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Higher tips get priority in the queue',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _tipAmount,
                        min: 1,
                        max: 20,
                        divisions: 19,
                        activeColor: purple,
                        label: '£${_tipAmount.toStringAsFixed(0)}',
                        onChanged: (value) {
                          setState(() {
                            _tipAmount = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: purple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: purple),
                      ),
                      child: Text(
                        '£${_tipAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitRequest,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: purple,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Submit Request',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'The DJ will see your request in real-time',
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
