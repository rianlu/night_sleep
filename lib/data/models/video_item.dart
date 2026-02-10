class VideoItem {
  final String id;
  final String title; // 视频标题
  final String artist; // UP主名称
  final String coverUrl; // 封面图URL
  final int duration; // 总时长 (秒)
  final int skipEnd; // 片尾跳过时长 (秒) - 已弃用，保留用于兼容性
  final int startTime; // 自定义开始时间 (秒)
  final int endTime; // 自定义结束时间 (秒)
  final String? filePath; // 本地文件路径 (下载后使用，流媒体模式下为null)
  final String? cid; // Bilibili CID，用于快速音频解析
  final String? category; // 分类 (例如："电台", "白噪音")
  final DateTime addedAt; // 添加时间

  VideoItem({
    required this.id,
    required this.title,
    required this.artist,
    required this.coverUrl,
    required this.duration,
    this.skipEnd = 0, // 已弃用，但保留以保持兼容性或未来复用
    this.startTime = 0,
    required this.endTime,
    this.filePath,
    this.cid,
    this.category,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'coverUrl': coverUrl,
      'duration': duration,
      'skipEnd': skipEnd,
      'startTime': startTime,
      'endTime': endTime,
      'filePath': filePath,
      'cid': cid,
      'category': category,
      'addedAt': addedAt.millisecondsSinceEpoch,
    };
  }

  factory VideoItem.fromMap(Map<String, dynamic> map) {
    return VideoItem(
      id: map['id'],
      title: map['title'],
      artist: map['artist'],
      coverUrl: map['coverUrl'],
      duration: map['duration'],
      skipEnd: map['skipEnd'] ?? 0,
      startTime: map['startTime'] ?? 0,
      endTime: map['endTime'] ?? map['duration'], // 如果未设置，默认为总时长
      filePath: map['filePath'],
      cid: map['cid'],
      category: map['category'],
      addedAt: DateTime.fromMillisecondsSinceEpoch(map['addedAt']),
    );
  }

  VideoItem copyWith({
    String? title,
    String? artist,
    String? coverUrl,
    int? duration,
    int? skipEnd,
    int? startTime,
    int? endTime,
    String? filePath,
    String? cid,
    String? category,
  }) {
    return VideoItem(
      id: id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      coverUrl: coverUrl ?? this.coverUrl,
      duration: duration ?? this.duration,
      skipEnd: skipEnd ?? this.skipEnd,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      filePath: filePath ?? this.filePath,
      cid: cid ?? this.cid,
      category: category ?? this.category,
      addedAt: addedAt,
    );
  }
}
