import 'package:flutter/material.dart';
import '../session.dart';
import '../services/auth_service.dart';
import '../services/remember_me_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _rememberMeService = RememberMeService();
  bool _isLoading = false;
  String? _errorMessage;
  List<RememberedAccount> _rememberedAccounts = const [];
  RememberedAccount? _selectedRememberedAccount;

  @override
  void initState() {
    super.initState();
    _loadRememberedAccounts();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userCredential = await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCredential != null && mounted) {
        final role = await _authService.getUserRole(userCredential.user!.uid);

        if (role != null) {
          final remember = await _askRememberForTwoHours();
          if (remember) {
            await _rememberMeService.rememberForTwoHours(
              uid: userCredential.user!.uid,
              email: userCredential.user?.email ?? _emailController.text.trim(),
              role: role,
            );
          }

          // Convert Firebase role to Session role
          Session.role = role == UserRole.dj ? UserRole.dj : UserRole.audience;

          if (role == UserRole.dj) {
            Navigator.pushReplacementNamed(context, '/dj_dashboard');
          } else {
            Navigator.pushReplacementNamed(context, '/audience_dashboard');
          }
        }
      }
    } catch (e) {
      setState(() {
        String errorMsg = e.toString();

        print('Login error: $errorMsg'); // Debug log

        if (errorMsg.contains('user-not-found')) {
          _errorMessage =
              'No account found with this email. Please register first.';
        } else if (errorMsg.contains('wrong-password')) {
          _errorMessage = 'Incorrect password. Please try again.';
        } else if (errorMsg.contains('invalid-email')) {
          _errorMessage = 'Invalid email address.';
        } else if (errorMsg.contains('operation-not-allowed')) {
          _errorMessage =
              'Email/Password sign-in is not enabled. Please contact support.';
        } else if (errorMsg.contains('CONFIGURATION_NOT_FOUND')) {
          _errorMessage = 'App configuration error. Please restart the app.';
        } else {
          _errorMessage =
              'Login failed. Please check your credentials and try again.';
        }

        _isLoading = false;
      });
    }
  }

  Future<void> _loadRememberedAccounts() async {
    final accounts = await _rememberMeService.getValidRememberedAccounts();
    if (!mounted) return;

    setState(() {
      _rememberedAccounts = accounts;
      _selectedRememberedAccount = null;
    });
  }

  Future<bool> _askRememberForTwoHours() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remember This Login?'),
          content: const Text(
            'Remember this account for 2 hours so you can log back in quickly without entering your password.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Remember 2h'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _quickLoginFromSuggestion() async {
    final selected = _selectedRememberedAccount;
    if (selected == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final canQuickLogin = await _rememberMeService.canQuickLogin(
        selected.uid,
      );
      if (!canQuickLogin) {
        if (!mounted) return;
        setState(() {
          _errorMessage =
              'Quick login expired for this account. Please enter your password.';
          _isLoading = false;
        });
        await _loadRememberedAccounts();
        return;
      }

      final currentUser = _authService.currentUser;
      if (currentUser == null || currentUser.uid != selected.uid) {
        if (!mounted) return;
        setState(() {
          _errorMessage =
              'Quick login is only available for your recent signed-in account on this device. Please enter password.';
          _isLoading = false;
        });
        return;
      }

      Session.role = selected.role;
      if (!mounted) return;

      if (selected.role == UserRole.dj) {
        Navigator.pushReplacementNamed(context, '/dj_dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/audience_dashboard');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Quick login failed. Please log in with password.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleLabel = Session.getRoleLabel();
    final titleText = roleLabel.isNotEmpty ? 'Log in as $roleLabel' : 'Log in';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(titleText),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_rememberedAccounts.isNotEmpty) ...[
                        DropdownButtonFormField<RememberedAccount>(
                          initialValue: _selectedRememberedAccount,
                          decoration: const InputDecoration(
                            labelText: 'Quick login suggestion',
                          ),
                          items: _rememberedAccounts
                              .map(
                                (
                                  account,
                                ) => DropdownMenuItem<RememberedAccount>(
                                  value: account,
                                  child: Text(
                                    '${account.email} (${account.role == UserRole.dj ? 'DJ' : 'Audience'})',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: _isLoading
                              ? null
                              : (value) {
                                  setState(() {
                                    _selectedRememberedAccount = value;
                                  });
                                },
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed:
                                (_isLoading ||
                                    _selectedRememberedAccount == null)
                                ? null
                                : _quickLoginFromSuggestion,
                            child: const Text('Quick login (2h)'),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Log in'),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/register');
                        },
                        child: const Text('Don\'t have an account? Register'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
