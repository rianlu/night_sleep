import 'package:dio/dio.dart';

class BilibiliAudioSourceService {
  final Dio _dio = Dio();
  
  // 基础 API 地址
  static const String _baseUrl = 'https://api.bilibili.com/audio/music-service-c/url';
  
  Future<String?> getAudioUrl(String songId) async {
    try {
      final response = await _dio.get(
        _baseUrl,
        queryParameters: {
          'songid': songId,
          'mid': '0', // 当前用户mid (必需，可以为任意值)
          'quality': 2, // 音质选择: 2 (320k)
          'privilege': 2,
          'platform': 'web',
        },
        options: Options(
          headers: {
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Referer': 'https://www.bilibili.com/',
          },
        ),
      );

      if (response.statusCode == 200 && response.data['code'] == 0) {
        final data = response.data['data'];
        final cdns = data['cdns'] as List<dynamic>;
        if (cdns.isNotEmpty) {
          return cdns.first as String;
        }
      }
      return null;
    } catch (e) {
      // print('Error fetching Bilibili audio: $e');
      return null;
    }
  }
}
