import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart';

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // CHANGE: Renamed to uploadFile for clarity
  Future<String> uploadFile({
    required File file,
    required String bucket,
  }) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}-${basename(file.path)}';
      await _supabase.storage.from(bucket).upload(fileName, file);
      // Return the public URL for the uploaded file
      return _supabase.storage.from(bucket).getPublicUrl(fileName);
    } catch (e) {
      print('Error uploading to Supabase: $e');
      rethrow;
    }
  }

  Future<void> deleteMultipleFiles(List<String> fileUrls, {required String bucket}) async {
    try {
        if (fileUrls.isEmpty) return;
        // Extract file names from URLs
        final fileNames = fileUrls.map((url) => url.split('/').last).toList();
        await _supabase.storage.from(bucket).remove(fileNames);
    } catch (e) {
      print('Error deleting from Supabase: $e');
      rethrow;
    }
  }
}
