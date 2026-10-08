import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../core/errors/app_exceptions.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Fetch user profile from Firestore
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection(AppConstants.collectionUsers).doc(uid).get();
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return UserModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      throw AppException.fromFirebase(e);
    }
  }

  /// Real-time stream of current user's profile
  Stream<UserModel?> userProfileStream(String uid) {
    return _firestore
        .collection(AppConstants.collectionUsers)
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromMap(doc.data()!, doc.id);
    });
  }

  /// Sign In with Email & Password
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw AppException('Failed to authenticate. User is null.');
      }

      final profile = await getUserProfile(user.uid);
      if (profile == null) {
        throw AppException('User profile not found in campus database.');
      }

      if (!profile.isActive) {
        await _auth.signOut();
        throw AppException('This account has been deactivated. Please contact campus admin.');
      }

      return profile;
    } on FirebaseAuthException catch (e) {
      throw AppException.fromFirebaseAuth(e.code, e.message);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException.fromFirebase(e);
    }
  }

  /// Register new user (Student / Staff / Worker)
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
    required String department,
    String? studentId,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw AppException('Failed to register user.');
      }

      final now = DateTime.now();
      final userModel = UserModel(
        uid: user.uid,
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        role: role,
        department: department,
        studentId: studentId?.trim(),
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      // Save to Firestore users collection
      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(user.uid)
          .set(userModel.toMap());

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw AppException.fromFirebaseAuth(e.code, e.message);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException.fromFirebase(e);
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AppException.fromFirebaseAuth(e.code, e.message);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException.fromFirebase(e);
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    required String uid,
    String? name,
    String? phone,
    String? department,
    String? profileImage,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };
      if (name != null) updates['name'] = name.trim();
      if (phone != null) updates['phone'] = phone.trim();
      if (department != null) updates['department'] = department;
      if (profileImage != null) updates['profileImage'] = profileImage;

      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(uid)
          .update(updates);
    } catch (e) {
      throw AppException.fromFirebase(e);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
