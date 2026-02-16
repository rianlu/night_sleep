class BilibiliIdUtils {
  static final RegExp _bvRegex = RegExp(r'BV[a-zA-Z0-9]{10}');
  static final RegExp _pageSuffixRegex = RegExp(r':p(\d+)$');

  static String extractBvId(String raw) {
    final match = _bvRegex.firstMatch(raw);
    return match?.group(0) ?? raw;
  }

  static int? extractPageFromItemId(String id) {
    final match = _pageSuffixRegex.firstMatch(id);
    final page = int.tryParse(match?.group(1) ?? '');
    if (page != null && page > 0) return page;
    return null;
  }

  static String buildItemId(String bvId, {int? page}) {
    if (page != null && page > 0) {
      return '$bvId:p$page';
    }
    return bvId;
  }
}
