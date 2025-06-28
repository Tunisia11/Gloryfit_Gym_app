// lib/services/storage_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;


class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Uploads an XFile to a specified Supabase Storage bucket,
  /// handling web and mobile platforms correctly.
  Future<String> uploadImage({
    required XFile imageFile,
    required String bucket,
  }) async {
    try {
      final fileExt = path.extension(imageFile.name);
      final fileName = '${DateTime.now().toIso8601String()}$fileExt';

      if (kIsWeb) {
        // Web upload uses bytes
        final imageBytes = await imageFile.readAsBytes();
        await _supabase.storage.from(bucket).uploadBinary(
              fileName,
              imageBytes,
              fileOptions: FileOptions(contentType: imageFile.mimeType),
            );
      } else {
        // Mobile upload uses the file path
        final file = File(imageFile.path);
        await _supabase.storage.from(bucket).upload(fileName, file);
      }
      
      return _supabase.storage.from(bucket).getPublicUrl(fileName);
    } catch (e) {
      print('Error uploading image to Supabase: $e');
      rethrow;
    }
  }

  Future<void> deleteMultipleImages(List<String> fileNames, {required String bucket}) async {
    try {
      if (fileNames.isEmpty) return;
      await _supabase.storage.from(bucket).remove(fileNames);
    } catch (e) {
      rethrow;
    }
  }
}