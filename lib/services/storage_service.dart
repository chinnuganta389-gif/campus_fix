import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage;

  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  /// Upload an image from an XFile with strict timeouts and resilient fallback
  Future<String> uploadImage({
    required XFile file,
    required String path,
    void Function(double progress)? onProgress,
  }) async {
    debugPrint('[CampusFix] Image upload started');
    Uint8List? bytes;

    try {
      bytes = await file.readAsBytes().timeout(
        const Duration(seconds: 10),
      );

      final ref = _storage.ref().child(path);

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'uploadedAt': DateTime.now().toIso8601String()},
      );

      final uploadTask = ref.putData(bytes, metadata);

      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((event) {
          if (event.totalBytes > 0) {
            final progress = event.bytesTransferred / event.totalBytes;
            onProgress(progress);
          }
        });
      }

      // Strict 15-second timeout on upload task
      final snapshot = await uploadTask.timeout(
        const Duration(seconds: 15),
      );
      debugPrint('[CampusFix] Image upload completed');

      // Strict 10-second timeout on download URL retrieval
      final downloadUrl = await snapshot.ref.getDownloadURL().timeout(
        const Duration(seconds: 10),
      );
      debugPrint('[CampusFix] Download URL obtained');
      return downloadUrl;
    } catch (e) {
      debugPrint('[CampusFix] Storage upload warning: $e');
      // If Storage bucket is unprovisioned, times out, or blocked by CORS on Web,
      // fallback to inline Base64 Data URL so user submission is NEVER blocked.
      if (bytes != null && bytes.isNotEmpty) {
        debugPrint('[CampusFix] Fallback: encoding image as inline Base64 data URL');
        final base64String = base64Encode(bytes);
        return 'data:image/jpeg;base64,$base64String';
      }
      rethrow;
    }
  }

  /// Upload complaint image
  Future<String> uploadComplaintImage({
    required XFile file,
    required String complaintId,
    void Function(double progress)? onProgress,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return uploadImage(
      file: file,
      path: 'complaints/$complaintId/evidence_$timestamp.jpg',
      onProgress: onProgress,
    );
  }

  /// Upload resolution image
  Future<String> uploadResolutionImage({
    required XFile file,
    required String complaintId,
    void Function(double progress)? onProgress,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return uploadImage(
      file: file,
      path: 'complaints/$complaintId/resolution_$timestamp.jpg',
      onProgress: onProgress,
    );
  }

  /// Upload profile image
  Future<String> uploadProfileImage({
    required XFile file,
    required String userId,
    void Function(double progress)? onProgress,
  }) {
    return uploadImage(
      file: file,
      path: 'profiles/$userId.jpg',
      onProgress: onProgress,
    );
  }
}
