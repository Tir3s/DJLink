import 'package:flutter/material.dart';
import '../session.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _selectRoleAndGoToLogin(BuildContext context, UserRole role) {
    Session.role = role;
    Navigator.pushNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Color(0xFF4B0082), // purple at bottom
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 360,
                    height: 360,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'DJ LINK',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Crowd–interactive music requests for live events',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Pick role first
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                      onPressed: () =>
                          _selectRoleAndGoToLogin(context, UserRole.dj),
                      child: const Text(
                        'I am a DJ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                      onPressed: () =>
                          _selectRoleAndGoToLogin(context, UserRole.audience),
                      child: const Text(
                        'I am in the Audience',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
