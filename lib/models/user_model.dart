import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { dj, audience }

class UserModel {
  final String userId;
  final String username;
  final String email;
  final UserRole role;
  final DateTime dateCreated;

  UserModel({
    required this.userId,
    required this.username,
    required this.email,
    required this.role,
    required this.dateCreated,
  });

  // Convert from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      userId: doc.id,
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] == 'dj' ? UserRole.dj : UserRole.audience,
      dateCreated: (data['date_created'] as Timestamp).toDate(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'username': username,
      'email': email,
      'role': role == UserRole.dj ? 'dj' : 'audience',
      'date_created': Timestamp.fromDate(dateCreated),
    };
  }
}

class DjProfile {
  final String djId;
  final String userId;
  final String stageName;
  final String bio;
  final int followerCount;
  final double rating;

  DjProfile({
    required this.djId,
    required this.userId,
    required this.stageName,
    this.bio = '',
    this.followerCount = 0,
    this.rating = 0.0,
  });

  factory DjProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DjProfile(
      djId: doc.id,
      userId: data['user_id'] ?? '',
      stageName: data['stage_name'] ?? '',
      bio: data['bio'] ?? '',
      followerCount: data['follower_count'] ?? 0,
      rating: (data['rating'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'stage_name': stageName,
      'bio': bio,
      'follower_count': followerCount,
      'rating': rating,
    };
  }
}

class AudienceProfile {
  final String audienceId;
  final String userId;
  final String displayName;
  final DateTime joinedDate;

  AudienceProfile({
    required this.audienceId,
    required this.userId,
    required this.displayName,
    required this.joinedDate,
  });

  factory AudienceProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AudienceProfile(
      audienceId: doc.id,
      userId: data['user_id'] ?? '',
      displayName: data['display_name'] ?? '',
      joinedDate: (data['joined_date'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'display_name': displayName,
      'joined_date': Timestamp.fromDate(joinedDate),
    };
  }
}
