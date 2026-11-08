// ignore_for_file: always_put_control_body_on_new_line
import 'dart:convert';
import 'dart:io';

import 'package:yaka2/core/network/logged_http.dart' as http;

import '../../../../core/result/result.dart';
import '../../../home/domain/entities/product_entity.dart';

class SearchByImageRemoteDataSource {
  const SearchByImageRemoteDataSource({
    required this.baseUrl,
    required this.tokenProvider,
  });

  final String baseUrl;
  final Future<String?> Function() tokenProvider;

  Future<Result<List<ProductEntity>>> searchByImage(File image) async {
    try {
      final token = await tokenProvider();
      final uri = Uri.parse('$baseUrl/api/v1/collars/search-by-image');
      final request = http.MultipartRequest('POST', uri);
      if (token != null && token.isNotEmpty) {
        request.headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
      }
      request.files.add(await http.MultipartFile.fromPath('image', image.path));
      request.fields['limit'] = '10';

      final streamed = await http.send(request);
      final raw = await streamed.stream.bytesToString();
      final body = jsonDecode(raw) as Map<String, dynamic>;

      if (body['success'] == true) {
        final data = body['data'];
        if (data is! List) return const Success(<ProductEntity>[]);
        final results = data.whereType<Map>().map((item) {
          final rawImages = item['images'];
          var firstImage = '';
          if (rawImages is List && rawImages.isNotEmpty) {
            final first = rawImages.first;
            if (first is Map) {
              final url = first['url']?.toString() ?? '';
              firstImage = url.startsWith('http') ? url : '$baseUrl$url';
            } else {
              final url = first?.toString() ?? '';
              firstImage = url.startsWith('http') ? url : '$baseUrl$url';
            }
          }
          return ProductEntity(
            id: item['id'] is int ? item['id'] as int : 0,
            name: item['name']?.toString() ?? '',
            price: item['price']?.toString() ?? '0',
            image: firstImage,
            categoryName: item['machine_name']?.toString() ?? 'Ýaka',
            downloadable: true,
            createdAt: item['created_at']?.toString() ?? '',
          );
        }).toList();
        return Success(results);
      }

      final message = body['message']?.toString() ?? 'search_failed';
      return Failure(ServerFailure(message));
    } catch (_) {
      return const Failure(NetworkFailure());
    }
  }
}
