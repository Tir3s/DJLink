import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';

class RememberedAccount {
  final String uid;
  final String email;
  final UserRole role;
  final DateTime rememberedUntil;

  const RememberedAccount({
    required this.uid,
    required this.email,
    required this.role,
    required this.rememberedUntil,
  });

  bool get isStillValid => rememberedUntil.isAfter(DateTime.now());

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'role': role == UserRole.dj ? 'dj' : 'audience',
      'remembered_until': rememberedUntil.millisecondsSinceEpoch,
    };
  }

  factory RememberedAccount.fromJson(Map<String, dynamic> json) {
    return RememberedAccount(
      uid: (json['uid'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      role: (json['role'] as String?) == 'dj' ? UserRole.dj : UserRole.audience,
      rememberedUntil: DateTime.fromMillisecondsSinceEpoch(
        (json['remembered_until'] as num?)?.toInt() ?? 0,
      ),
    );
  }
}

class RememberMeService {
  static const _accountsKey = 'remembered_accounts';
  static const _maxRememberedAccounts = 5;

  Future<List<RememberedAccount>> getValidRememberedAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_accountsKey) ?? <String>[];

    final accounts =
        rawList
            .map((raw) {
              try {
                final jsonMap = jsonDecode(raw) as Map<String, dynamic>;
                return RememberedAccount.fromJson(jsonMap);
              } catch (_) {
                return null;
              }
            })
            .whereType<RememberedAccount>()
            .where(
              (account) =>
                  account.uid.isNotEmpty &&
                  account.email.isNotEmpty &&
                  account.isStillValid,
            )
            .toList()
          ..sort((a, b) => b.rememberedUntil.compareTo(a.rememberedUntil));

    await _saveAccounts(accounts);
    return accounts;
  }

  Future<void> rememberForTwoHours({
    required String uid,
    required String email,
    required UserRole role,
  }) async {
    final valid = await getValidRememberedAccounts();
    final newEntry = RememberedAccount(
      uid: uid,
      email: email,
      role: role,
      rememberedUntil: DateTime.now().add(const Duration(hours: 2)),
    );

    final deduped = valid.where((a) => a.uid != uid).toList();
    deduped.insert(0, newEntry);

    if (deduped.length > _maxRememberedAccounts) {
      deduped.removeRange(_maxRememberedAccounts, deduped.length);
    }

    await _saveAccounts(deduped);
  }

  Future<void> forgetCurrentUserIfExpired() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return;
    }

    final accounts = await getValidRememberedAccounts();
    final matching = accounts.where((a) => a.uid == currentUser.uid).toList();
    if (matching.isNotEmpty) {
      return;
    }

    await FirebaseAuth.instance.signOut();
  }

  Future<bool> canQuickLogin(String uid) async {
    final accounts = await getValidRememberedAccounts();
    return accounts.any((account) => account.uid == uid);
  }

  Future<void> _saveAccounts(List<RememberedAccount> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    final serialized = accounts
        .map((account) => jsonEncode(account.toJson()))
        .toList();
    await prefs.setStringList(_accountsKey, serialized);
  }
}
