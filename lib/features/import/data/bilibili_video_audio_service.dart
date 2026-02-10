import 'package:dio/dio.dart';

class BilibiliVideoAudioService {
  final Dio _dio = Dio();
  
  // 视频播放地址 API
  static const String _playUrlBase = 'https://api.bilibili.com/x/player/playurl';

  Future<String?> getVideoAudioUrl(String bvid, int cid) async {
    try {
      final response = await _dio.get(
        _playUrlBase,
        queryParameters: {
          'bvid': bvid,
          'cid': cid,
          'fnval': 16, // DASH 格式
          'fnver': 0,
          'fourk': 1,
        },
         options: Options(
          headers: {
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Referer': 'https://www.bilibili.com/video/$bvid',
          },
        ),
      );

      if (response.statusCode == 200 && response.data['code'] == 0) {
        final data = response.data['data'];
        final dash = data['dash'];
        if (dash != null) {
          final audio = dash['audio'] as List<dynamic>;
          if (audio.isNotEmpty) {
            // 获取最佳音质路径
            // 通常是排序过的，这里直接取第一个
            return audio.first['baseUrl'] as String;
          }
        }
      }
      return null;
    } catch (e) {
      // print('Error fetching video audio: $e');
      return null;
    }
  }
}
