import 'dart:io';
import 'package:dio/dio.dart';

class ImgBBService {
  final String _apiKey = '02baba925c956ff1bac7fa88063a9a8f';
  final String _uploadUrl = 'https://api.imgbb.com/1/upload';
  final Dio _dio;

  ImgBBService({Dio? dio}) : _dio = dio ?? Dio();

  Future<String?> uploadAvatar(File imageFile) async {
    try {
      String fileName = imageFile.path.split('/').last;

      FormData formData = FormData.fromMap({
        'key': _apiKey,
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      Response response = await _dio.post(_uploadUrl, data: formData);

      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data != null && data['url'] != null) {
          return data['url'] as String;
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to upload image to ImgBB: $e');
    }
  }
}
