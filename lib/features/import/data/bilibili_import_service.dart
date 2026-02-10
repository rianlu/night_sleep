import 'package:dio/dio.dart';
import 'package:night_sleep/data/models/video_item.dart';

class BilibiliImportService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    },
  ));

  // 从文本中提取 BV 号。例如： "【标题】 https://b23.tv/BV1xxxxx"
  String? extractBvId(String text) {
    // BV 号正则表达式
    final RegExp bvRegex = RegExp(r'BV[a-zA-Z0-9]{10}');
    final match = bvRegex.firstMatch(text);
    return match?.group(0);
  }

  // 处理短链接跳转 (b23.tv)
  Future<String?> resolveShortLink(String text) async {
    // b23.tv 短链接正则表达式
    final RegExp b23Regex = RegExp(r'https://b23.tv/[a-zA-Z0-9]+');
    final match = b23Regex.firstMatch(text);
    if (match != null) {
      final shortUrl = match.group(0)!;
      try {
        final response = await _dio.get(
          shortUrl,
          options: Options(followRedirects: false, validateStatus: (status) => status! < 400),
        );
        // 通常是 302 跳转，获取 location 头部
        if (response.statusCode == 302) {
           final location = response.headers.value('location');
           if (location != null) return extractBvId(location);
        }
      } catch (e) {
        // print('Error resolving short link: $e');
      }
    }
    return extractBvId(text);
  }

  Future<VideoItem?> fetchVideoInfo(String bvId) async {
    try {
      final response = await _dio.get(
        'https://api.bilibili.com/x/web-interface/view',
        queryParameters: {'bvid': bvId},
      );

      if (response.statusCode == 200 && response.data['code'] == 0) {
        final data = response.data['data'];
        return VideoItem(
          id: bvId,
          title: data['title'],
          artist: data['owner']['name'],
          coverUrl: data['pic'],
          duration: data['duration'], // 秒
          startTime: 0,
          endTime: data['duration'],
          addedAt: DateTime.now(),
          skipEnd: 0,
          cid: data['cid']?.toString(), // 存储 CID 以加速播放
          filePath: null, 
        );
      }
      return null;
    } catch (e) {
      // print('Error fetching video info: $e');
      return null;
    }
  }
}
