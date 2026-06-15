import 'dart:io';
import 'package:dio/dio.dart';

class MultiImgBBService {
  final String _apiKey = '02baba925c956ff1bac7fa88063a9a8f';
  final String _uploadUrl = 'https://api.imgbb.com/1/upload';
  final Dio _dio;

  MultiImgBBService({Dio? dio}) : _dio = dio ?? Dio();

  Future<List<String>> uploadImages(List<File> imageFiles) async {
    List<String> uploadedUrls = [];

    for (var file in imageFiles) {
      try {
        String fileName = file.path.split('/').last;

        FormData formData = FormData.fromMap({
          'key': _apiKey,
          'image': await MultipartFile.fromFile(
            file.path,
            filename: fileName,
          ),
        });

        Response response = await _dio.post(_uploadUrl, data: formData);

        if (response.statusCode == 200) {
          final data = response.data['data'];
          if (data != null && data['url'] != null) {
            uploadedUrls.add(data['url'] as String);
          }
        }
      } catch (e) {
        // We log or throw depending on how strict we want the upload to be
        throw Exception('Failed to upload one of the images: $e');
      }
    }

    return uploadedUrls;
  }
}
