import 'package:dio/dio.dart';
import 'package:night_sleep/core/utils/bilibili_id_utils.dart';
import 'package:night_sleep/data/models/video_item.dart';

class BilibiliLinkInfo {
  final String bvId;
  final int? page;

  const BilibiliLinkInfo({
    required this.bvId,
    this.page,
  });
}

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

  int? extractPage(String text) {
    // 优先从 URL query 中解析 p
    final urlRegex = RegExp(r'https?://[^\s]+');
    for (final match in urlRegex.allMatches(text)) {
      final url = match.group(0);
      if (url == null) continue;
      final uri = Uri.tryParse(url);
      final pRaw = uri?.queryParameters['p'];
      final p = int.tryParse(pRaw ?? '');
      if (p != null && p > 0) return p;
    }

    // 兜底：直接从整段文本匹配 ?p=xx 或 &p=xx
    final directMatch = RegExp(r'[?&]p=(\d+)').firstMatch(text);
    final p = int.tryParse(directMatch?.group(1) ?? '');
    if (p != null && p > 0) return p;
    return null;
  }

  BilibiliLinkInfo? parseLinkInfo(String text) {
    final bvId = extractBvId(text);
    if (bvId == null) return null;
    return BilibiliLinkInfo(bvId: bvId, page: extractPage(text));
  }

  // 处理短链接跳转 (b23.tv)
  Future<BilibiliLinkInfo?> resolveLink(String text) async {
    // b23.tv 短链接正则表达式
    final RegExp b23Regex = RegExp(r'https?://b23\.tv/[a-zA-Z0-9]+');
    final match = b23Regex.firstMatch(text);
    if (match != null) {
      final shortUrl = match.group(0)!;
      try {
        final response = await _dio.get(
          shortUrl,
          options: Options(followRedirects: false, validateStatus: (status) => status! < 400),
        );
        // 短链通常通过 30x 跳转，读取 location 头
        if (response.statusCode != null && response.statusCode! >= 300 && response.statusCode! < 400) {
           final location = response.headers.value('location');
           if (location != null) {
             final info = parseLinkInfo(location);
             if (info != null) return info;
           }
        }
      } catch (e) {
        // print('Error resolving short link: $e');
      }
    }
    return parseLinkInfo(text);
  }

  // 兼容旧调用
  Future<String?> resolveShortLink(String text) async {
    final info = await resolveLink(text);
    return info?.bvId;
  }

  Future<VideoItem?> fetchVideoInfo(String bvId, {int? page}) async {
    try {
      final response = await _dio.get(
        'https://api.bilibili.com/x/web-interface/view',
        queryParameters: {'bvid': bvId},
      );

      if (response.statusCode == 200 && response.data['code'] == 0) {
        final data = response.data['data'];
        final List<dynamic> pages = (data['pages'] as List<dynamic>?) ?? [];
        Map<String, dynamic>? selectedPage;
        int? selectedPageNumber;

        if (pages.isNotEmpty) {
          if (page != null && page > 0 && page <= pages.length) {
            selectedPage = (pages[page - 1] as Map).cast<String, dynamic>();
          } else {
            final defaultCid = data['cid']?.toString();
            for (final p in pages) {
              final pMap = (p as Map).cast<String, dynamic>();
              if (pMap['cid']?.toString() == defaultCid) {
                selectedPage = pMap;
                break;
              }
            }
            selectedPage ??= (pages.first as Map).cast<String, dynamic>();
          }
          selectedPageNumber = selectedPage['page'] is int
              ? selectedPage['page'] as int
              : int.tryParse(selectedPage['page']?.toString() ?? '');
        }

        final selectedCid = selectedPage?['cid']?.toString() ?? data['cid']?.toString();
        final selectedDuration = (selectedPage?['duration'] as num?)?.toInt() ?? (data['duration'] as num?)?.toInt() ?? 0;
        final selectedPart = (selectedPage?['part'] ?? '').toString().trim();
        final videoTitle = (data['title'] ?? '').toString();
        final finalTitle = selectedPart.isNotEmpty && selectedPart != videoTitle
            ? '$videoTitle - $selectedPart'
            : videoTitle;

        return VideoItem(
          id: BilibiliIdUtils.buildItemId(bvId, page: selectedPageNumber),
          title: finalTitle,
          artist: data['owner']['name'],
          coverUrl: data['pic'],
          duration: selectedDuration, // 秒
          startTime: 0,
          endTime: selectedDuration,
          addedAt: DateTime.now(),
          skipEnd: 0,
          cid: selectedCid, // 存储对应分P的 CID 以加速播放
          page: selectedPageNumber,
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
