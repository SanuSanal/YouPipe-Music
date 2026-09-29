// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SongsTable extends Songs with TableInfo<$SongsTable, Song> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SongsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _videoIdMeta = const VerificationMeta('videoId');
  @override
  late final GeneratedColumn<String> videoId = GeneratedColumn<String>(
    'video_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artistsJsonMeta = const VerificationMeta('artistsJson');
  @override
  late final GeneratedColumn<String> artistsJson = GeneratedColumn<String>(
    'artists_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _albumIdMeta = const VerificationMeta('albumId');
  @override
  late final GeneratedColumn<String> albumId = GeneratedColumn<String>(
    'album_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _albumNameMeta = const VerificationMeta('albumName');
  @override
  late final GeneratedColumn<String> albumName = GeneratedColumn<String>(
    'album_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta('durationMs');
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thumbnailUrlMeta = const VerificationMeta('thumbnailUrl');
  @override
  late final GeneratedColumn<String> thumbnailUrl = GeneratedColumn<String>(
    'thumbnail_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isVideoMeta = const VerificationMeta('isVideo');
  @override
  late final GeneratedColumn<bool> isVideo = GeneratedColumn<bool>(
    'is_video',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("is_video" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    videoId,
    title,
    artistsJson,
    albumId,
    albumName,
    durationMs,
    thumbnailUrl,
    isVideo,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'songs';
  @override
  VerificationContext validateIntegrity(Insertable<Song> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('video_id')) {
      context.handle(_videoIdMeta, videoId.isAcceptableOrUnknown(data['video_id']!, _videoIdMeta));
    } else if (isInserting) {
      context.missing(_videoIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(_titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('artists_json')) {
      context.handle(_artistsJsonMeta, artistsJson.isAcceptableOrUnknown(data['artists_json']!, _artistsJsonMeta));
    }
    if (data.containsKey('album_id')) {
      context.handle(_albumIdMeta, albumId.isAcceptableOrUnknown(data['album_id']!, _albumIdMeta));
    }
    if (data.containsKey('album_name')) {
      context.handle(_albumNameMeta, albumName.isAcceptableOrUnknown(data['album_name']!, _albumNameMeta));
    }
    if (data.containsKey('duration_ms')) {
      context.handle(_durationMsMeta, durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta));
    }
    if (data.containsKey('thumbnail_url')) {
      context.handle(_thumbnailUrlMeta, thumbnailUrl.isAcceptableOrUnknown(data['thumbnail_url']!, _thumbnailUrlMeta));
    }
    if (data.containsKey('is_video')) {
      context.handle(_isVideoMeta, isVideo.isAcceptableOrUnknown(data['is_video']!, _isVideoMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {videoId};
  @override
  Song map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Song(
      videoId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}video_id'])!,
      title: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      artistsJson: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}artists_json'])!,
      albumId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}album_id']),
      albumName: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}album_name']),
      durationMs: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}duration_ms']),
      thumbnailUrl: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}thumbnail_url']),
      isVideo: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}is_video'])!,
    );
  }

  @override
  $SongsTable createAlias(String alias) {
    return $SongsTable(attachedDatabase, alias);
  }
}

class Song extends DataClass implements Insertable<Song> {
  final String videoId;
  final String title;
  final String artistsJson;
  final String? albumId;
  final String? albumName;
  final int? durationMs;
  final String? thumbnailUrl;
  final bool isVideo;
  const Song({
    required this.videoId,
    required this.title,
    required this.artistsJson,
    this.albumId,
    this.albumName,
    this.durationMs,
    this.thumbnailUrl,
    required this.isVideo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['video_id'] = Variable<String>(videoId);
    map['title'] = Variable<String>(title);
    map['artists_json'] = Variable<String>(artistsJson);
    if (!nullToAbsent || albumId != null) {
      map['album_id'] = Variable<String>(albumId);
    }
    if (!nullToAbsent || albumName != null) {
      map['album_name'] = Variable<String>(albumName);
    }
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    if (!nullToAbsent || thumbnailUrl != null) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl);
    }
    map['is_video'] = Variable<bool>(isVideo);
    return map;
  }

  SongsCompanion toCompanion(bool nullToAbsent) {
    return SongsCompanion(
      videoId: Value(videoId),
      title: Value(title),
      artistsJson: Value(artistsJson),
      albumId: albumId == null && nullToAbsent ? const Value.absent() : Value(albumId),
      albumName: albumName == null && nullToAbsent ? const Value.absent() : Value(albumName),
      durationMs: durationMs == null && nullToAbsent ? const Value.absent() : Value(durationMs),
      thumbnailUrl: thumbnailUrl == null && nullToAbsent ? const Value.absent() : Value(thumbnailUrl),
      isVideo: Value(isVideo),
    );
  }

  factory Song.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Song(
      videoId: serializer.fromJson<String>(json['videoId']),
      title: serializer.fromJson<String>(json['title']),
      artistsJson: serializer.fromJson<String>(json['artistsJson']),
      albumId: serializer.fromJson<String?>(json['albumId']),
      albumName: serializer.fromJson<String?>(json['albumName']),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
      thumbnailUrl: serializer.fromJson<String?>(json['thumbnailUrl']),
      isVideo: serializer.fromJson<bool>(json['isVideo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'videoId': serializer.toJson<String>(videoId),
      'title': serializer.toJson<String>(title),
      'artistsJson': serializer.toJson<String>(artistsJson),
      'albumId': serializer.toJson<String?>(albumId),
      'albumName': serializer.toJson<String?>(albumName),
      'durationMs': serializer.toJson<int?>(durationMs),
      'thumbnailUrl': serializer.toJson<String?>(thumbnailUrl),
      'isVideo': serializer.toJson<bool>(isVideo),
    };
  }

  Song copyWith({
    String? videoId,
    String? title,
    String? artistsJson,
    Value<String?> albumId = const Value.absent(),
    Value<String?> albumName = const Value.absent(),
    Value<int?> durationMs = const Value.absent(),
    Value<String?> thumbnailUrl = const Value.absent(),
    bool? isVideo,
  }) => Song(
    videoId: videoId ?? this.videoId,
    title: title ?? this.title,
    artistsJson: artistsJson ?? this.artistsJson,
    albumId: albumId.present ? albumId.value : this.albumId,
    albumName: albumName.present ? albumName.value : this.albumName,
    durationMs: durationMs.present ? durationMs.value : this.durationMs,
    thumbnailUrl: thumbnailUrl.present ? thumbnailUrl.value : this.thumbnailUrl,
    isVideo: isVideo ?? this.isVideo,
  );
  Song copyWithCompanion(SongsCompanion data) {
    return Song(
      videoId: data.videoId.present ? data.videoId.value : this.videoId,
      title: data.title.present ? data.title.value : this.title,
      artistsJson: data.artistsJson.present ? data.artistsJson.value : this.artistsJson,
      albumId: data.albumId.present ? data.albumId.value : this.albumId,
      albumName: data.albumName.present ? data.albumName.value : this.albumName,
      durationMs: data.durationMs.present ? data.durationMs.value : this.durationMs,
      thumbnailUrl: data.thumbnailUrl.present ? data.thumbnailUrl.value : this.thumbnailUrl,
      isVideo: data.isVideo.present ? data.isVideo.value : this.isVideo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Song(')
          ..write('videoId: $videoId, ')
          ..write('title: $title, ')
          ..write('artistsJson: $artistsJson, ')
          ..write('albumId: $albumId, ')
          ..write('albumName: $albumName, ')
          ..write('durationMs: $durationMs, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('isVideo: $isVideo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(videoId, title, artistsJson, albumId, albumName, durationMs, thumbnailUrl, isVideo);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Song &&
          other.videoId == this.videoId &&
          other.title == this.title &&
          other.artistsJson == this.artistsJson &&
          other.albumId == this.albumId &&
          other.albumName == this.albumName &&
          other.durationMs == this.durationMs &&
          other.thumbnailUrl == this.thumbnailUrl &&
          other.isVideo == this.isVideo);
}

class SongsCompanion extends UpdateCompanion<Song> {
  final Value<String> videoId;
  final Value<String> title;
  final Value<String> artistsJson;
  final Value<String?> albumId;
  final Value<String?> albumName;
  final Value<int?> durationMs;
  final Value<String?> thumbnailUrl;
  final Value<bool> isVideo;
  final Value<int> rowid;
  const SongsCompanion({
    this.videoId = const Value.absent(),
    this.title = const Value.absent(),
    this.artistsJson = const Value.absent(),
    this.albumId = const Value.absent(),
    this.albumName = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.isVideo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SongsCompanion.insert({
    required String videoId,
    required String title,
    this.artistsJson = const Value.absent(),
    this.albumId = const Value.absent(),
    this.albumName = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.isVideo = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : videoId = Value(videoId),
       title = Value(title);
  static Insertable<Song> custom({
    Expression<String>? videoId,
    Expression<String>? title,
    Expression<String>? artistsJson,
    Expression<String>? albumId,
    Expression<String>? albumName,
    Expression<int>? durationMs,
    Expression<String>? thumbnailUrl,
    Expression<bool>? isVideo,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (videoId != null) 'video_id': videoId,
      if (title != null) 'title': title,
      if (artistsJson != null) 'artists_json': artistsJson,
      if (albumId != null) 'album_id': albumId,
      if (albumName != null) 'album_name': albumName,
      if (durationMs != null) 'duration_ms': durationMs,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (isVideo != null) 'is_video': isVideo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SongsCompanion copyWith({
    Value<String>? videoId,
    Value<String>? title,
    Value<String>? artistsJson,
    Value<String?>? albumId,
    Value<String?>? albumName,
    Value<int?>? durationMs,
    Value<String?>? thumbnailUrl,
    Value<bool>? isVideo,
    Value<int>? rowid,
  }) {
    return SongsCompanion(
      videoId: videoId ?? this.videoId,
      title: title ?? this.title,
      artistsJson: artistsJson ?? this.artistsJson,
      albumId: albumId ?? this.albumId,
      albumName: albumName ?? this.albumName,
      durationMs: durationMs ?? this.durationMs,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      isVideo: isVideo ?? this.isVideo,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (videoId.present) {
      map['video_id'] = Variable<String>(videoId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (artistsJson.present) {
      map['artists_json'] = Variable<String>(artistsJson.value);
    }
    if (albumId.present) {
      map['album_id'] = Variable<String>(albumId.value);
    }
    if (albumName.present) {
      map['album_name'] = Variable<String>(albumName.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (thumbnailUrl.present) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl.value);
    }
    if (isVideo.present) {
      map['is_video'] = Variable<bool>(isVideo.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SongsCompanion(')
          ..write('videoId: $videoId, ')
          ..write('title: $title, ')
          ..write('artistsJson: $artistsJson, ')
          ..write('albumId: $albumId, ')
          ..write('albumName: $albumName, ')
          ..write('durationMs: $durationMs, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('isVideo: $isVideo, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LikedSongsTable extends LikedSongs with TableInfo<$LikedSongsTable, LikedSong> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LikedSongsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _videoIdMeta = const VerificationMeta('videoId');
  @override
  late final GeneratedColumn<String> videoId = GeneratedColumn<String>(
    'video_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES songs (video_id)'),
  );
  static const VerificationMeta _likedAtMeta = const VerificationMeta('likedAt');
  @override
  late final GeneratedColumn<DateTime> likedAt = GeneratedColumn<DateTime>(
    'liked_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [videoId, likedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'liked_songs';
  @override
  VerificationContext validateIntegrity(Insertable<LikedSong> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('video_id')) {
      context.handle(_videoIdMeta, videoId.isAcceptableOrUnknown(data['video_id']!, _videoIdMeta));
    } else if (isInserting) {
      context.missing(_videoIdMeta);
    }
    if (data.containsKey('liked_at')) {
      context.handle(_likedAtMeta, likedAt.isAcceptableOrUnknown(data['liked_at']!, _likedAtMeta));
    } else if (isInserting) {
      context.missing(_likedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {videoId};
  @override
  LikedSong map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LikedSong(
      videoId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}video_id'])!,
      likedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}liked_at'])!,
    );
  }

  @override
  $LikedSongsTable createAlias(String alias) {
    return $LikedSongsTable(attachedDatabase, alias);
  }
}

class LikedSong extends DataClass implements Insertable<LikedSong> {
  final String videoId;
  final DateTime likedAt;
  const LikedSong({required this.videoId, required this.likedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['video_id'] = Variable<String>(videoId);
    map['liked_at'] = Variable<DateTime>(likedAt);
    return map;
  }

  LikedSongsCompanion toCompanion(bool nullToAbsent) {
    return LikedSongsCompanion(videoId: Value(videoId), likedAt: Value(likedAt));
  }

  factory LikedSong.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LikedSong(
      videoId: serializer.fromJson<String>(json['videoId']),
      likedAt: serializer.fromJson<DateTime>(json['likedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'videoId': serializer.toJson<String>(videoId),
      'likedAt': serializer.toJson<DateTime>(likedAt),
    };
  }

  LikedSong copyWith({String? videoId, DateTime? likedAt}) =>
      LikedSong(videoId: videoId ?? this.videoId, likedAt: likedAt ?? this.likedAt);
  LikedSong copyWithCompanion(LikedSongsCompanion data) {
    return LikedSong(
      videoId: data.videoId.present ? data.videoId.value : this.videoId,
      likedAt: data.likedAt.present ? data.likedAt.value : this.likedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LikedSong(')
          ..write('videoId: $videoId, ')
          ..write('likedAt: $likedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(videoId, likedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is LikedSong && other.videoId == this.videoId && other.likedAt == this.likedAt);
}

class LikedSongsCompanion extends UpdateCompanion<LikedSong> {
  final Value<String> videoId;
  final Value<DateTime> likedAt;
  final Value<int> rowid;
  const LikedSongsCompanion({
    this.videoId = const Value.absent(),
    this.likedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LikedSongsCompanion.insert({required String videoId, required DateTime likedAt, this.rowid = const Value.absent()})
    : videoId = Value(videoId),
      likedAt = Value(likedAt);
  static Insertable<LikedSong> custom({
    Expression<String>? videoId,
    Expression<DateTime>? likedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (videoId != null) 'video_id': videoId,
      if (likedAt != null) 'liked_at': likedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LikedSongsCompanion copyWith({Value<String>? videoId, Value<DateTime>? likedAt, Value<int>? rowid}) {
    return LikedSongsCompanion(
      videoId: videoId ?? this.videoId,
      likedAt: likedAt ?? this.likedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (videoId.present) {
      map['video_id'] = Variable<String>(videoId.value);
    }
    if (likedAt.present) {
      map['liked_at'] = Variable<DateTime>(likedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LikedSongsCompanion(')
          ..write('videoId: $videoId, ')
          ..write('likedAt: $likedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlayHistoryTable extends PlayHistory with TableInfo<$PlayHistoryTable, PlayHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlayHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _videoIdMeta = const VerificationMeta('videoId');
  @override
  late final GeneratedColumn<String> videoId = GeneratedColumn<String>(
    'video_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES songs (video_id)'),
  );
  static const VerificationMeta _playedAtMeta = const VerificationMeta('playedAt');
  @override
  late final GeneratedColumn<DateTime> playedAt = GeneratedColumn<DateTime>(
    'played_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, videoId, playedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'play_history';
  @override
  VerificationContext validateIntegrity(Insertable<PlayHistoryData> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('video_id')) {
      context.handle(_videoIdMeta, videoId.isAcceptableOrUnknown(data['video_id']!, _videoIdMeta));
    } else if (isInserting) {
      context.missing(_videoIdMeta);
    }
    if (data.containsKey('played_at')) {
      context.handle(_playedAtMeta, playedAt.isAcceptableOrUnknown(data['played_at']!, _playedAtMeta));
    } else if (isInserting) {
      context.missing(_playedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlayHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlayHistoryData(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      videoId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}video_id'])!,
      playedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}played_at'])!,
    );
  }

  @override
  $PlayHistoryTable createAlias(String alias) {
    return $PlayHistoryTable(attachedDatabase, alias);
  }
}

class PlayHistoryData extends DataClass implements Insertable<PlayHistoryData> {
  final int id;
  final String videoId;
  final DateTime playedAt;
  const PlayHistoryData({required this.id, required this.videoId, required this.playedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['video_id'] = Variable<String>(videoId);
    map['played_at'] = Variable<DateTime>(playedAt);
    return map;
  }

  PlayHistoryCompanion toCompanion(bool nullToAbsent) {
    return PlayHistoryCompanion(id: Value(id), videoId: Value(videoId), playedAt: Value(playedAt));
  }

  factory PlayHistoryData.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlayHistoryData(
      id: serializer.fromJson<int>(json['id']),
      videoId: serializer.fromJson<String>(json['videoId']),
      playedAt: serializer.fromJson<DateTime>(json['playedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'videoId': serializer.toJson<String>(videoId),
      'playedAt': serializer.toJson<DateTime>(playedAt),
    };
  }

  PlayHistoryData copyWith({int? id, String? videoId, DateTime? playedAt}) =>
      PlayHistoryData(id: id ?? this.id, videoId: videoId ?? this.videoId, playedAt: playedAt ?? this.playedAt);
  PlayHistoryData copyWithCompanion(PlayHistoryCompanion data) {
    return PlayHistoryData(
      id: data.id.present ? data.id.value : this.id,
      videoId: data.videoId.present ? data.videoId.value : this.videoId,
      playedAt: data.playedAt.present ? data.playedAt.value : this.playedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlayHistoryData(')
          ..write('id: $id, ')
          ..write('videoId: $videoId, ')
          ..write('playedAt: $playedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, videoId, playedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayHistoryData &&
          other.id == this.id &&
          other.videoId == this.videoId &&
          other.playedAt == this.playedAt);
}

class PlayHistoryCompanion extends UpdateCompanion<PlayHistoryData> {
  final Value<int> id;
  final Value<String> videoId;
  final Value<DateTime> playedAt;
  const PlayHistoryCompanion({
    this.id = const Value.absent(),
    this.videoId = const Value.absent(),
    this.playedAt = const Value.absent(),
  });
  PlayHistoryCompanion.insert({this.id = const Value.absent(), required String videoId, required DateTime playedAt})
    : videoId = Value(videoId),
      playedAt = Value(playedAt);
  static Insertable<PlayHistoryData> custom({
    Expression<int>? id,
    Expression<String>? videoId,
    Expression<DateTime>? playedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (videoId != null) 'video_id': videoId,
      if (playedAt != null) 'played_at': playedAt,
    });
  }

  PlayHistoryCompanion copyWith({Value<int>? id, Value<String>? videoId, Value<DateTime>? playedAt}) {
    return PlayHistoryCompanion(
      id: id ?? this.id,
      videoId: videoId ?? this.videoId,
      playedAt: playedAt ?? this.playedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (videoId.present) {
      map['video_id'] = Variable<String>(videoId.value);
    }
    if (playedAt.present) {
      map['played_at'] = Variable<DateTime>(playedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlayHistoryCompanion(')
          ..write('id: $id, ')
          ..write('videoId: $videoId, ')
          ..write('playedAt: $playedAt')
          ..write(')'))
        .toString();
  }
}

class $SavedAlbumsTable extends SavedAlbums with TableInfo<$SavedAlbumsTable, SavedAlbum> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedAlbumsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _browseIdMeta = const VerificationMeta('browseId');
  @override
  late final GeneratedColumn<String> browseId = GeneratedColumn<String>(
    'browse_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playlistIdMeta = const VerificationMeta('playlistId');
  @override
  late final GeneratedColumn<String> playlistId = GeneratedColumn<String>(
    'playlist_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artistsJsonMeta = const VerificationMeta('artistsJson');
  @override
  late final GeneratedColumn<String> artistsJson = GeneratedColumn<String>(
    'artists_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<String> year = GeneratedColumn<String>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thumbnailUrlMeta = const VerificationMeta('thumbnailUrl');
  @override
  late final GeneratedColumn<String> thumbnailUrl = GeneratedColumn<String>(
    'thumbnail_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _savedAtMeta = const VerificationMeta('savedAt');
  @override
  late final GeneratedColumn<DateTime> savedAt = GeneratedColumn<DateTime>(
    'saved_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [browseId, playlistId, title, artistsJson, year, thumbnailUrl, savedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_albums';
  @override
  VerificationContext validateIntegrity(Insertable<SavedAlbum> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('browse_id')) {
      context.handle(_browseIdMeta, browseId.isAcceptableOrUnknown(data['browse_id']!, _browseIdMeta));
    } else if (isInserting) {
      context.missing(_browseIdMeta);
    }
    if (data.containsKey('playlist_id')) {
      context.handle(_playlistIdMeta, playlistId.isAcceptableOrUnknown(data['playlist_id']!, _playlistIdMeta));
    }
    if (data.containsKey('title')) {
      context.handle(_titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('artists_json')) {
      context.handle(_artistsJsonMeta, artistsJson.isAcceptableOrUnknown(data['artists_json']!, _artistsJsonMeta));
    }
    if (data.containsKey('year')) {
      context.handle(_yearMeta, year.isAcceptableOrUnknown(data['year']!, _yearMeta));
    }
    if (data.containsKey('thumbnail_url')) {
      context.handle(_thumbnailUrlMeta, thumbnailUrl.isAcceptableOrUnknown(data['thumbnail_url']!, _thumbnailUrlMeta));
    }
    if (data.containsKey('saved_at')) {
      context.handle(_savedAtMeta, savedAt.isAcceptableOrUnknown(data['saved_at']!, _savedAtMeta));
    } else if (isInserting) {
      context.missing(_savedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {browseId};
  @override
  SavedAlbum map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedAlbum(
      browseId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}browse_id'])!,
      playlistId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}playlist_id']),
      title: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      artistsJson: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}artists_json'])!,
      year: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}year']),
      thumbnailUrl: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}thumbnail_url']),
      savedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}saved_at'])!,
    );
  }

  @override
  $SavedAlbumsTable createAlias(String alias) {
    return $SavedAlbumsTable(attachedDatabase, alias);
  }
}

class SavedAlbum extends DataClass implements Insertable<SavedAlbum> {
  final String browseId;
  final String? playlistId;
  final String title;
  final String artistsJson;
  final String? year;
  final String? thumbnailUrl;
  final DateTime savedAt;
  const SavedAlbum({
    required this.browseId,
    this.playlistId,
    required this.title,
    required this.artistsJson,
    this.year,
    this.thumbnailUrl,
    required this.savedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['browse_id'] = Variable<String>(browseId);
    if (!nullToAbsent || playlistId != null) {
      map['playlist_id'] = Variable<String>(playlistId);
    }
    map['title'] = Variable<String>(title);
    map['artists_json'] = Variable<String>(artistsJson);
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<String>(year);
    }
    if (!nullToAbsent || thumbnailUrl != null) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl);
    }
    map['saved_at'] = Variable<DateTime>(savedAt);
    return map;
  }

  SavedAlbumsCompanion toCompanion(bool nullToAbsent) {
    return SavedAlbumsCompanion(
      browseId: Value(browseId),
      playlistId: playlistId == null && nullToAbsent ? const Value.absent() : Value(playlistId),
      title: Value(title),
      artistsJson: Value(artistsJson),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      thumbnailUrl: thumbnailUrl == null && nullToAbsent ? const Value.absent() : Value(thumbnailUrl),
      savedAt: Value(savedAt),
    );
  }

  factory SavedAlbum.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedAlbum(
      browseId: serializer.fromJson<String>(json['browseId']),
      playlistId: serializer.fromJson<String?>(json['playlistId']),
      title: serializer.fromJson<String>(json['title']),
      artistsJson: serializer.fromJson<String>(json['artistsJson']),
      year: serializer.fromJson<String?>(json['year']),
      thumbnailUrl: serializer.fromJson<String?>(json['thumbnailUrl']),
      savedAt: serializer.fromJson<DateTime>(json['savedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'browseId': serializer.toJson<String>(browseId),
      'playlistId': serializer.toJson<String?>(playlistId),
      'title': serializer.toJson<String>(title),
      'artistsJson': serializer.toJson<String>(artistsJson),
      'year': serializer.toJson<String?>(year),
      'thumbnailUrl': serializer.toJson<String?>(thumbnailUrl),
      'savedAt': serializer.toJson<DateTime>(savedAt),
    };
  }

  SavedAlbum copyWith({
    String? browseId,
    Value<String?> playlistId = const Value.absent(),
    String? title,
    String? artistsJson,
    Value<String?> year = const Value.absent(),
    Value<String?> thumbnailUrl = const Value.absent(),
    DateTime? savedAt,
  }) => SavedAlbum(
    browseId: browseId ?? this.browseId,
    playlistId: playlistId.present ? playlistId.value : this.playlistId,
    title: title ?? this.title,
    artistsJson: artistsJson ?? this.artistsJson,
    year: year.present ? year.value : this.year,
    thumbnailUrl: thumbnailUrl.present ? thumbnailUrl.value : this.thumbnailUrl,
    savedAt: savedAt ?? this.savedAt,
  );
  SavedAlbum copyWithCompanion(SavedAlbumsCompanion data) {
    return SavedAlbum(
      browseId: data.browseId.present ? data.browseId.value : this.browseId,
      playlistId: data.playlistId.present ? data.playlistId.value : this.playlistId,
      title: data.title.present ? data.title.value : this.title,
      artistsJson: data.artistsJson.present ? data.artistsJson.value : this.artistsJson,
      year: data.year.present ? data.year.value : this.year,
      thumbnailUrl: data.thumbnailUrl.present ? data.thumbnailUrl.value : this.thumbnailUrl,
      savedAt: data.savedAt.present ? data.savedAt.value : this.savedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedAlbum(')
          ..write('browseId: $browseId, ')
          ..write('playlistId: $playlistId, ')
          ..write('title: $title, ')
          ..write('artistsJson: $artistsJson, ')
          ..write('year: $year, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('savedAt: $savedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(browseId, playlistId, title, artistsJson, year, thumbnailUrl, savedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedAlbum &&
          other.browseId == this.browseId &&
          other.playlistId == this.playlistId &&
          other.title == this.title &&
          other.artistsJson == this.artistsJson &&
          other.year == this.year &&
          other.thumbnailUrl == this.thumbnailUrl &&
          other.savedAt == this.savedAt);
}

class SavedAlbumsCompanion extends UpdateCompanion<SavedAlbum> {
  final Value<String> browseId;
  final Value<String?> playlistId;
  final Value<String> title;
  final Value<String> artistsJson;
  final Value<String?> year;
  final Value<String?> thumbnailUrl;
  final Value<DateTime> savedAt;
  final Value<int> rowid;
  const SavedAlbumsCompanion({
    this.browseId = const Value.absent(),
    this.playlistId = const Value.absent(),
    this.title = const Value.absent(),
    this.artistsJson = const Value.absent(),
    this.year = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.savedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavedAlbumsCompanion.insert({
    required String browseId,
    this.playlistId = const Value.absent(),
    required String title,
    this.artistsJson = const Value.absent(),
    this.year = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    required DateTime savedAt,
    this.rowid = const Value.absent(),
  }) : browseId = Value(browseId),
       title = Value(title),
       savedAt = Value(savedAt);
  static Insertable<SavedAlbum> custom({
    Expression<String>? browseId,
    Expression<String>? playlistId,
    Expression<String>? title,
    Expression<String>? artistsJson,
    Expression<String>? year,
    Expression<String>? thumbnailUrl,
    Expression<DateTime>? savedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (browseId != null) 'browse_id': browseId,
      if (playlistId != null) 'playlist_id': playlistId,
      if (title != null) 'title': title,
      if (artistsJson != null) 'artists_json': artistsJson,
      if (year != null) 'year': year,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (savedAt != null) 'saved_at': savedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavedAlbumsCompanion copyWith({
    Value<String>? browseId,
    Value<String?>? playlistId,
    Value<String>? title,
    Value<String>? artistsJson,
    Value<String?>? year,
    Value<String?>? thumbnailUrl,
    Value<DateTime>? savedAt,
    Value<int>? rowid,
  }) {
    return SavedAlbumsCompanion(
      browseId: browseId ?? this.browseId,
      playlistId: playlistId ?? this.playlistId,
      title: title ?? this.title,
      artistsJson: artistsJson ?? this.artistsJson,
      year: year ?? this.year,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      savedAt: savedAt ?? this.savedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (browseId.present) {
      map['browse_id'] = Variable<String>(browseId.value);
    }
    if (playlistId.present) {
      map['playlist_id'] = Variable<String>(playlistId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (artistsJson.present) {
      map['artists_json'] = Variable<String>(artistsJson.value);
    }
    if (year.present) {
      map['year'] = Variable<String>(year.value);
    }
    if (thumbnailUrl.present) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl.value);
    }
    if (savedAt.present) {
      map['saved_at'] = Variable<DateTime>(savedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedAlbumsCompanion(')
          ..write('browseId: $browseId, ')
          ..write('playlistId: $playlistId, ')
          ..write('title: $title, ')
          ..write('artistsJson: $artistsJson, ')
          ..write('year: $year, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('savedAt: $savedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SavedArtistsTable extends SavedArtists with TableInfo<$SavedArtistsTable, SavedArtist> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedArtistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _browseIdMeta = const VerificationMeta('browseId');
  @override
  late final GeneratedColumn<String> browseId = GeneratedColumn<String>(
    'browse_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _thumbnailUrlMeta = const VerificationMeta('thumbnailUrl');
  @override
  late final GeneratedColumn<String> thumbnailUrl = GeneratedColumn<String>(
    'thumbnail_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _savedAtMeta = const VerificationMeta('savedAt');
  @override
  late final GeneratedColumn<DateTime> savedAt = GeneratedColumn<DateTime>(
    'saved_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [browseId, title, thumbnailUrl, savedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_artists';
  @override
  VerificationContext validateIntegrity(Insertable<SavedArtist> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('browse_id')) {
      context.handle(_browseIdMeta, browseId.isAcceptableOrUnknown(data['browse_id']!, _browseIdMeta));
    } else if (isInserting) {
      context.missing(_browseIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(_titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('thumbnail_url')) {
      context.handle(_thumbnailUrlMeta, thumbnailUrl.isAcceptableOrUnknown(data['thumbnail_url']!, _thumbnailUrlMeta));
    }
    if (data.containsKey('saved_at')) {
      context.handle(_savedAtMeta, savedAt.isAcceptableOrUnknown(data['saved_at']!, _savedAtMeta));
    } else if (isInserting) {
      context.missing(_savedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {browseId};
  @override
  SavedArtist map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedArtist(
      browseId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}browse_id'])!,
      title: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      thumbnailUrl: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}thumbnail_url']),
      savedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}saved_at'])!,
    );
  }

  @override
  $SavedArtistsTable createAlias(String alias) {
    return $SavedArtistsTable(attachedDatabase, alias);
  }
}

class SavedArtist extends DataClass implements Insertable<SavedArtist> {
  final String browseId;
  final String title;
  final String? thumbnailUrl;
  final DateTime savedAt;
  const SavedArtist({required this.browseId, required this.title, this.thumbnailUrl, required this.savedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['browse_id'] = Variable<String>(browseId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || thumbnailUrl != null) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl);
    }
    map['saved_at'] = Variable<DateTime>(savedAt);
    return map;
  }

  SavedArtistsCompanion toCompanion(bool nullToAbsent) {
    return SavedArtistsCompanion(
      browseId: Value(browseId),
      title: Value(title),
      thumbnailUrl: thumbnailUrl == null && nullToAbsent ? const Value.absent() : Value(thumbnailUrl),
      savedAt: Value(savedAt),
    );
  }

  factory SavedArtist.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedArtist(
      browseId: serializer.fromJson<String>(json['browseId']),
      title: serializer.fromJson<String>(json['title']),
      thumbnailUrl: serializer.fromJson<String?>(json['thumbnailUrl']),
      savedAt: serializer.fromJson<DateTime>(json['savedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'browseId': serializer.toJson<String>(browseId),
      'title': serializer.toJson<String>(title),
      'thumbnailUrl': serializer.toJson<String?>(thumbnailUrl),
      'savedAt': serializer.toJson<DateTime>(savedAt),
    };
  }

  SavedArtist copyWith({
    String? browseId,
    String? title,
    Value<String?> thumbnailUrl = const Value.absent(),
    DateTime? savedAt,
  }) => SavedArtist(
    browseId: browseId ?? this.browseId,
    title: title ?? this.title,
    thumbnailUrl: thumbnailUrl.present ? thumbnailUrl.value : this.thumbnailUrl,
    savedAt: savedAt ?? this.savedAt,
  );
  SavedArtist copyWithCompanion(SavedArtistsCompanion data) {
    return SavedArtist(
      browseId: data.browseId.present ? data.browseId.value : this.browseId,
      title: data.title.present ? data.title.value : this.title,
      thumbnailUrl: data.thumbnailUrl.present ? data.thumbnailUrl.value : this.thumbnailUrl,
      savedAt: data.savedAt.present ? data.savedAt.value : this.savedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedArtist(')
          ..write('browseId: $browseId, ')
          ..write('title: $title, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('savedAt: $savedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(browseId, title, thumbnailUrl, savedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedArtist &&
          other.browseId == this.browseId &&
          other.title == this.title &&
          other.thumbnailUrl == this.thumbnailUrl &&
          other.savedAt == this.savedAt);
}

class SavedArtistsCompanion extends UpdateCompanion<SavedArtist> {
  final Value<String> browseId;
  final Value<String> title;
  final Value<String?> thumbnailUrl;
  final Value<DateTime> savedAt;
  final Value<int> rowid;
  const SavedArtistsCompanion({
    this.browseId = const Value.absent(),
    this.title = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.savedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavedArtistsCompanion.insert({
    required String browseId,
    required String title,
    this.thumbnailUrl = const Value.absent(),
    required DateTime savedAt,
    this.rowid = const Value.absent(),
  }) : browseId = Value(browseId),
       title = Value(title),
       savedAt = Value(savedAt);
  static Insertable<SavedArtist> custom({
    Expression<String>? browseId,
    Expression<String>? title,
    Expression<String>? thumbnailUrl,
    Expression<DateTime>? savedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (browseId != null) 'browse_id': browseId,
      if (title != null) 'title': title,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (savedAt != null) 'saved_at': savedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavedArtistsCompanion copyWith({
    Value<String>? browseId,
    Value<String>? title,
    Value<String?>? thumbnailUrl,
    Value<DateTime>? savedAt,
    Value<int>? rowid,
  }) {
    return SavedArtistsCompanion(
      browseId: browseId ?? this.browseId,
      title: title ?? this.title,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      savedAt: savedAt ?? this.savedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (browseId.present) {
      map['browse_id'] = Variable<String>(browseId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (thumbnailUrl.present) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl.value);
    }
    if (savedAt.present) {
      map['saved_at'] = Variable<DateTime>(savedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedArtistsCompanion(')
          ..write('browseId: $browseId, ')
          ..write('title: $title, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('savedAt: $savedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SavedPlaylistsTable extends SavedPlaylists with TableInfo<$SavedPlaylistsTable, SavedPlaylist> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedPlaylistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _playlistIdMeta = const VerificationMeta('playlistId');
  @override
  late final GeneratedColumn<String> playlistId = GeneratedColumn<String>(
    'playlist_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thumbnailUrlMeta = const VerificationMeta('thumbnailUrl');
  @override
  late final GeneratedColumn<String> thumbnailUrl = GeneratedColumn<String>(
    'thumbnail_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _savedAtMeta = const VerificationMeta('savedAt');
  @override
  late final GeneratedColumn<DateTime> savedAt = GeneratedColumn<DateTime>(
    'saved_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [playlistId, title, author, thumbnailUrl, savedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_playlists';
  @override
  VerificationContext validateIntegrity(Insertable<SavedPlaylist> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('playlist_id')) {
      context.handle(_playlistIdMeta, playlistId.isAcceptableOrUnknown(data['playlist_id']!, _playlistIdMeta));
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(_titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('author')) {
      context.handle(_authorMeta, author.isAcceptableOrUnknown(data['author']!, _authorMeta));
    }
    if (data.containsKey('thumbnail_url')) {
      context.handle(_thumbnailUrlMeta, thumbnailUrl.isAcceptableOrUnknown(data['thumbnail_url']!, _thumbnailUrlMeta));
    }
    if (data.containsKey('saved_at')) {
      context.handle(_savedAtMeta, savedAt.isAcceptableOrUnknown(data['saved_at']!, _savedAtMeta));
    } else if (isInserting) {
      context.missing(_savedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {playlistId};
  @override
  SavedPlaylist map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedPlaylist(
      playlistId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}playlist_id'])!,
      title: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      author: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}author']),
      thumbnailUrl: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}thumbnail_url']),
      savedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}saved_at'])!,
    );
  }

  @override
  $SavedPlaylistsTable createAlias(String alias) {
    return $SavedPlaylistsTable(attachedDatabase, alias);
  }
}

class SavedPlaylist extends DataClass implements Insertable<SavedPlaylist> {
  final String playlistId;
  final String title;
  final String? author;
  final String? thumbnailUrl;
  final DateTime savedAt;
  const SavedPlaylist({
    required this.playlistId,
    required this.title,
    this.author,
    this.thumbnailUrl,
    required this.savedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['playlist_id'] = Variable<String>(playlistId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || author != null) {
      map['author'] = Variable<String>(author);
    }
    if (!nullToAbsent || thumbnailUrl != null) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl);
    }
    map['saved_at'] = Variable<DateTime>(savedAt);
    return map;
  }

  SavedPlaylistsCompanion toCompanion(bool nullToAbsent) {
    return SavedPlaylistsCompanion(
      playlistId: Value(playlistId),
      title: Value(title),
      author: author == null && nullToAbsent ? const Value.absent() : Value(author),
      thumbnailUrl: thumbnailUrl == null && nullToAbsent ? const Value.absent() : Value(thumbnailUrl),
      savedAt: Value(savedAt),
    );
  }

  factory SavedPlaylist.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedPlaylist(
      playlistId: serializer.fromJson<String>(json['playlistId']),
      title: serializer.fromJson<String>(json['title']),
      author: serializer.fromJson<String?>(json['author']),
      thumbnailUrl: serializer.fromJson<String?>(json['thumbnailUrl']),
      savedAt: serializer.fromJson<DateTime>(json['savedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'playlistId': serializer.toJson<String>(playlistId),
      'title': serializer.toJson<String>(title),
      'author': serializer.toJson<String?>(author),
      'thumbnailUrl': serializer.toJson<String?>(thumbnailUrl),
      'savedAt': serializer.toJson<DateTime>(savedAt),
    };
  }

  SavedPlaylist copyWith({
    String? playlistId,
    String? title,
    Value<String?> author = const Value.absent(),
    Value<String?> thumbnailUrl = const Value.absent(),
    DateTime? savedAt,
  }) => SavedPlaylist(
    playlistId: playlistId ?? this.playlistId,
    title: title ?? this.title,
    author: author.present ? author.value : this.author,
    thumbnailUrl: thumbnailUrl.present ? thumbnailUrl.value : this.thumbnailUrl,
    savedAt: savedAt ?? this.savedAt,
  );
  SavedPlaylist copyWithCompanion(SavedPlaylistsCompanion data) {
    return SavedPlaylist(
      playlistId: data.playlistId.present ? data.playlistId.value : this.playlistId,
      title: data.title.present ? data.title.value : this.title,
      author: data.author.present ? data.author.value : this.author,
      thumbnailUrl: data.thumbnailUrl.present ? data.thumbnailUrl.value : this.thumbnailUrl,
      savedAt: data.savedAt.present ? data.savedAt.value : this.savedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedPlaylist(')
          ..write('playlistId: $playlistId, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('savedAt: $savedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(playlistId, title, author, thumbnailUrl, savedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedPlaylist &&
          other.playlistId == this.playlistId &&
          other.title == this.title &&
          other.author == this.author &&
          other.thumbnailUrl == this.thumbnailUrl &&
          other.savedAt == this.savedAt);
}

class SavedPlaylistsCompanion extends UpdateCompanion<SavedPlaylist> {
  final Value<String> playlistId;
  final Value<String> title;
  final Value<String?> author;
  final Value<String?> thumbnailUrl;
  final Value<DateTime> savedAt;
  final Value<int> rowid;
  const SavedPlaylistsCompanion({
    this.playlistId = const Value.absent(),
    this.title = const Value.absent(),
    this.author = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.savedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavedPlaylistsCompanion.insert({
    required String playlistId,
    required String title,
    this.author = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    required DateTime savedAt,
    this.rowid = const Value.absent(),
  }) : playlistId = Value(playlistId),
       title = Value(title),
       savedAt = Value(savedAt);
  static Insertable<SavedPlaylist> custom({
    Expression<String>? playlistId,
    Expression<String>? title,
    Expression<String>? author,
    Expression<String>? thumbnailUrl,
    Expression<DateTime>? savedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (playlistId != null) 'playlist_id': playlistId,
      if (title != null) 'title': title,
      if (author != null) 'author': author,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (savedAt != null) 'saved_at': savedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavedPlaylistsCompanion copyWith({
    Value<String>? playlistId,
    Value<String>? title,
    Value<String?>? author,
    Value<String?>? thumbnailUrl,
    Value<DateTime>? savedAt,
    Value<int>? rowid,
  }) {
    return SavedPlaylistsCompanion(
      playlistId: playlistId ?? this.playlistId,
      title: title ?? this.title,
      author: author ?? this.author,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      savedAt: savedAt ?? this.savedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (playlistId.present) {
      map['playlist_id'] = Variable<String>(playlistId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (thumbnailUrl.present) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl.value);
    }
    if (savedAt.present) {
      map['saved_at'] = Variable<DateTime>(savedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedPlaylistsCompanion(')
          ..write('playlistId: $playlistId, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('savedAt: $savedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalPlaylistsTable extends LocalPlaylists with TableInfo<$LocalPlaylistsTable, LocalPlaylist> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalPlaylistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_playlists';
  @override
  VerificationContext validateIntegrity(Insertable<LocalPlaylist> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalPlaylist map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalPlaylist(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $LocalPlaylistsTable createAlias(String alias) {
    return $LocalPlaylistsTable(attachedDatabase, alias);
  }
}

class LocalPlaylist extends DataClass implements Insertable<LocalPlaylist> {
  final int id;
  final String name;
  final DateTime createdAt;
  const LocalPlaylist({required this.id, required this.name, required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LocalPlaylistsCompanion toCompanion(bool nullToAbsent) {
    return LocalPlaylistsCompanion(id: Value(id), name: Value(name), createdAt: Value(createdAt));
  }

  factory LocalPlaylist.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalPlaylist(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocalPlaylist copyWith({int? id, String? name, DateTime? createdAt}) =>
      LocalPlaylist(id: id ?? this.id, name: name ?? this.name, createdAt: createdAt ?? this.createdAt);
  LocalPlaylist copyWithCompanion(LocalPlaylistsCompanion data) {
    return LocalPlaylist(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalPlaylist(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalPlaylist && other.id == this.id && other.name == this.name && other.createdAt == this.createdAt);
}

class LocalPlaylistsCompanion extends UpdateCompanion<LocalPlaylist> {
  final Value<int> id;
  final Value<String> name;
  final Value<DateTime> createdAt;
  const LocalPlaylistsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  LocalPlaylistsCompanion.insert({this.id = const Value.absent(), required String name, required DateTime createdAt})
    : name = Value(name),
      createdAt = Value(createdAt);
  static Insertable<LocalPlaylist> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  LocalPlaylistsCompanion copyWith({Value<int>? id, Value<String>? name, Value<DateTime>? createdAt}) {
    return LocalPlaylistsCompanion(id: id ?? this.id, name: name ?? this.name, createdAt: createdAt ?? this.createdAt);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalPlaylistsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $LocalPlaylistItemsTable extends LocalPlaylistItems with TableInfo<$LocalPlaylistItemsTable, LocalPlaylistItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalPlaylistItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _playlistIdMeta = const VerificationMeta('playlistId');
  @override
  late final GeneratedColumn<int> playlistId = GeneratedColumn<int>(
    'playlist_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES local_playlists (id) ON DELETE CASCADE'),
  );
  static const VerificationMeta _videoIdMeta = const VerificationMeta('videoId');
  @override
  late final GeneratedColumn<String> videoId = GeneratedColumn<String>(
    'video_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES songs (video_id)'),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta('position');
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, playlistId, videoId, position];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_playlist_items';
  @override
  VerificationContext validateIntegrity(Insertable<LocalPlaylistItem> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('playlist_id')) {
      context.handle(_playlistIdMeta, playlistId.isAcceptableOrUnknown(data['playlist_id']!, _playlistIdMeta));
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('video_id')) {
      context.handle(_videoIdMeta, videoId.isAcceptableOrUnknown(data['video_id']!, _videoIdMeta));
    } else if (isInserting) {
      context.missing(_videoIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta, position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalPlaylistItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalPlaylistItem(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      playlistId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}playlist_id'])!,
      videoId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}video_id'])!,
      position: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}position'])!,
    );
  }

  @override
  $LocalPlaylistItemsTable createAlias(String alias) {
    return $LocalPlaylistItemsTable(attachedDatabase, alias);
  }
}

class LocalPlaylistItem extends DataClass implements Insertable<LocalPlaylistItem> {
  final int id;
  final int playlistId;
  final String videoId;
  final int position;
  const LocalPlaylistItem({required this.id, required this.playlistId, required this.videoId, required this.position});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['playlist_id'] = Variable<int>(playlistId);
    map['video_id'] = Variable<String>(videoId);
    map['position'] = Variable<int>(position);
    return map;
  }

  LocalPlaylistItemsCompanion toCompanion(bool nullToAbsent) {
    return LocalPlaylistItemsCompanion(
      id: Value(id),
      playlistId: Value(playlistId),
      videoId: Value(videoId),
      position: Value(position),
    );
  }

  factory LocalPlaylistItem.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalPlaylistItem(
      id: serializer.fromJson<int>(json['id']),
      playlistId: serializer.fromJson<int>(json['playlistId']),
      videoId: serializer.fromJson<String>(json['videoId']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'playlistId': serializer.toJson<int>(playlistId),
      'videoId': serializer.toJson<String>(videoId),
      'position': serializer.toJson<int>(position),
    };
  }

  LocalPlaylistItem copyWith({int? id, int? playlistId, String? videoId, int? position}) => LocalPlaylistItem(
    id: id ?? this.id,
    playlistId: playlistId ?? this.playlistId,
    videoId: videoId ?? this.videoId,
    position: position ?? this.position,
  );
  LocalPlaylistItem copyWithCompanion(LocalPlaylistItemsCompanion data) {
    return LocalPlaylistItem(
      id: data.id.present ? data.id.value : this.id,
      playlistId: data.playlistId.present ? data.playlistId.value : this.playlistId,
      videoId: data.videoId.present ? data.videoId.value : this.videoId,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalPlaylistItem(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('videoId: $videoId, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, playlistId, videoId, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalPlaylistItem &&
          other.id == this.id &&
          other.playlistId == this.playlistId &&
          other.videoId == this.videoId &&
          other.position == this.position);
}

class LocalPlaylistItemsCompanion extends UpdateCompanion<LocalPlaylistItem> {
  final Value<int> id;
  final Value<int> playlistId;
  final Value<String> videoId;
  final Value<int> position;
  const LocalPlaylistItemsCompanion({
    this.id = const Value.absent(),
    this.playlistId = const Value.absent(),
    this.videoId = const Value.absent(),
    this.position = const Value.absent(),
  });
  LocalPlaylistItemsCompanion.insert({
    this.id = const Value.absent(),
    required int playlistId,
    required String videoId,
    required int position,
  }) : playlistId = Value(playlistId),
       videoId = Value(videoId),
       position = Value(position);
  static Insertable<LocalPlaylistItem> custom({
    Expression<int>? id,
    Expression<int>? playlistId,
    Expression<String>? videoId,
    Expression<int>? position,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (playlistId != null) 'playlist_id': playlistId,
      if (videoId != null) 'video_id': videoId,
      if (position != null) 'position': position,
    });
  }

  LocalPlaylistItemsCompanion copyWith({
    Value<int>? id,
    Value<int>? playlistId,
    Value<String>? videoId,
    Value<int>? position,
  }) {
    return LocalPlaylistItemsCompanion(
      id: id ?? this.id,
      playlistId: playlistId ?? this.playlistId,
      videoId: videoId ?? this.videoId,
      position: position ?? this.position,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (playlistId.present) {
      map['playlist_id'] = Variable<int>(playlistId.value);
    }
    if (videoId.present) {
      map['video_id'] = Variable<String>(videoId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalPlaylistItemsCompanion(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('videoId: $videoId, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }
}

class $SearchHistoryTable extends SearchHistory with TableInfo<$SearchHistoryTable, SearchHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SearchHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _queryMeta = const VerificationMeta('query');
  @override
  late final GeneratedColumn<String> query = GeneratedColumn<String>(
    'query',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _searchedAtMeta = const VerificationMeta('searchedAt');
  @override
  late final GeneratedColumn<DateTime> searchedAt = GeneratedColumn<DateTime>(
    'searched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [query, searchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'search_history';
  @override
  VerificationContext validateIntegrity(Insertable<SearchHistoryData> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('query')) {
      context.handle(_queryMeta, query.isAcceptableOrUnknown(data['query']!, _queryMeta));
    } else if (isInserting) {
      context.missing(_queryMeta);
    }
    if (data.containsKey('searched_at')) {
      context.handle(_searchedAtMeta, searchedAt.isAcceptableOrUnknown(data['searched_at']!, _searchedAtMeta));
    } else if (isInserting) {
      context.missing(_searchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {query};
  @override
  SearchHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SearchHistoryData(
      query: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}query'])!,
      searchedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}searched_at'])!,
    );
  }

  @override
  $SearchHistoryTable createAlias(String alias) {
    return $SearchHistoryTable(attachedDatabase, alias);
  }
}

class SearchHistoryData extends DataClass implements Insertable<SearchHistoryData> {
  final String query;
  final DateTime searchedAt;
  const SearchHistoryData({required this.query, required this.searchedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['query'] = Variable<String>(query);
    map['searched_at'] = Variable<DateTime>(searchedAt);
    return map;
  }

  SearchHistoryCompanion toCompanion(bool nullToAbsent) {
    return SearchHistoryCompanion(query: Value(query), searchedAt: Value(searchedAt));
  }

  factory SearchHistoryData.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SearchHistoryData(
      query: serializer.fromJson<String>(json['query']),
      searchedAt: serializer.fromJson<DateTime>(json['searchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'query': serializer.toJson<String>(query),
      'searchedAt': serializer.toJson<DateTime>(searchedAt),
    };
  }

  SearchHistoryData copyWith({String? query, DateTime? searchedAt}) =>
      SearchHistoryData(query: query ?? this.query, searchedAt: searchedAt ?? this.searchedAt);
  SearchHistoryData copyWithCompanion(SearchHistoryCompanion data) {
    return SearchHistoryData(
      query: data.query.present ? data.query.value : this.query,
      searchedAt: data.searchedAt.present ? data.searchedAt.value : this.searchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SearchHistoryData(')
          ..write('query: $query, ')
          ..write('searchedAt: $searchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(query, searchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SearchHistoryData && other.query == this.query && other.searchedAt == this.searchedAt);
}

class SearchHistoryCompanion extends UpdateCompanion<SearchHistoryData> {
  final Value<String> query;
  final Value<DateTime> searchedAt;
  final Value<int> rowid;
  const SearchHistoryCompanion({
    this.query = const Value.absent(),
    this.searchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SearchHistoryCompanion.insert({
    required String query,
    required DateTime searchedAt,
    this.rowid = const Value.absent(),
  }) : query = Value(query),
       searchedAt = Value(searchedAt);
  static Insertable<SearchHistoryData> custom({
    Expression<String>? query,
    Expression<DateTime>? searchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (query != null) 'query': query,
      if (searchedAt != null) 'searched_at': searchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SearchHistoryCompanion copyWith({Value<String>? query, Value<DateTime>? searchedAt, Value<int>? rowid}) {
    return SearchHistoryCompanion(
      query: query ?? this.query,
      searchedAt: searchedAt ?? this.searchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (query.present) {
      map['query'] = Variable<String>(query.value);
    }
    if (searchedAt.present) {
      map['searched_at'] = Variable<DateTime>(searchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SearchHistoryCompanion(')
          ..write('query: $query, ')
          ..write('searchedAt: $searchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DownloadsTable extends Downloads with TableInfo<$DownloadsTable, Download> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _videoIdMeta = const VerificationMeta('videoId');
  @override
  late final GeneratedColumn<String> videoId = GeneratedColumn<String>(
    'video_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES songs (video_id)'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DownloadStatus, int> status = GeneratedColumn<int>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<DownloadStatus>($DownloadsTable.$converterstatus);
  static const VerificationMeta _filePathMeta = const VerificationMeta('filePath');
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _artPathMeta = const VerificationMeta('artPath');
  @override
  late final GeneratedColumn<String> artPath = GeneratedColumn<String>(
    'art_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta('sizeBytes');
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _downloadedBytesMeta = const VerificationMeta('downloadedBytes');
  @override
  late final GeneratedColumn<int> downloadedBytes = GeneratedColumn<int>(
    'downloaded_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta('addedAt');
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [videoId, status, filePath, artPath, sizeBytes, downloadedBytes, addedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'downloads';
  @override
  VerificationContext validateIntegrity(Insertable<Download> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('video_id')) {
      context.handle(_videoIdMeta, videoId.isAcceptableOrUnknown(data['video_id']!, _videoIdMeta));
    } else if (isInserting) {
      context.missing(_videoIdMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(_filePathMeta, filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta));
    }
    if (data.containsKey('art_path')) {
      context.handle(_artPathMeta, artPath.isAcceptableOrUnknown(data['art_path']!, _artPathMeta));
    }
    if (data.containsKey('size_bytes')) {
      context.handle(_sizeBytesMeta, sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta));
    }
    if (data.containsKey('downloaded_bytes')) {
      context.handle(
        _downloadedBytesMeta,
        downloadedBytes.isAcceptableOrUnknown(data['downloaded_bytes']!, _downloadedBytesMeta),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(_addedAtMeta, addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta));
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {videoId};
  @override
  Download map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Download(
      videoId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}video_id'])!,
      status: $DownloadsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}status'])!,
      ),
      filePath: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}file_path']),
      artPath: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}art_path']),
      sizeBytes: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}size_bytes'])!,
      downloadedBytes: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}downloaded_bytes'])!,
      addedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}added_at'])!,
    );
  }

  @override
  $DownloadsTable createAlias(String alias) {
    return $DownloadsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<DownloadStatus, int, int> $converterstatus = const EnumIndexConverter<DownloadStatus>(
    DownloadStatus.values,
  );
}

class Download extends DataClass implements Insertable<Download> {
  final String videoId;
  final DownloadStatus status;
  final String? filePath;
  final String? artPath;
  final int sizeBytes;
  final int downloadedBytes;
  final DateTime addedAt;
  const Download({
    required this.videoId,
    required this.status,
    this.filePath,
    this.artPath,
    required this.sizeBytes,
    required this.downloadedBytes,
    required this.addedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['video_id'] = Variable<String>(videoId);
    {
      map['status'] = Variable<int>($DownloadsTable.$converterstatus.toSql(status));
    }
    if (!nullToAbsent || filePath != null) {
      map['file_path'] = Variable<String>(filePath);
    }
    if (!nullToAbsent || artPath != null) {
      map['art_path'] = Variable<String>(artPath);
    }
    map['size_bytes'] = Variable<int>(sizeBytes);
    map['downloaded_bytes'] = Variable<int>(downloadedBytes);
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  DownloadsCompanion toCompanion(bool nullToAbsent) {
    return DownloadsCompanion(
      videoId: Value(videoId),
      status: Value(status),
      filePath: filePath == null && nullToAbsent ? const Value.absent() : Value(filePath),
      artPath: artPath == null && nullToAbsent ? const Value.absent() : Value(artPath),
      sizeBytes: Value(sizeBytes),
      downloadedBytes: Value(downloadedBytes),
      addedAt: Value(addedAt),
    );
  }

  factory Download.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Download(
      videoId: serializer.fromJson<String>(json['videoId']),
      status: $DownloadsTable.$converterstatus.fromJson(serializer.fromJson<int>(json['status'])),
      filePath: serializer.fromJson<String?>(json['filePath']),
      artPath: serializer.fromJson<String?>(json['artPath']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      downloadedBytes: serializer.fromJson<int>(json['downloadedBytes']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'videoId': serializer.toJson<String>(videoId),
      'status': serializer.toJson<int>($DownloadsTable.$converterstatus.toJson(status)),
      'filePath': serializer.toJson<String?>(filePath),
      'artPath': serializer.toJson<String?>(artPath),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'downloadedBytes': serializer.toJson<int>(downloadedBytes),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  Download copyWith({
    String? videoId,
    DownloadStatus? status,
    Value<String?> filePath = const Value.absent(),
    Value<String?> artPath = const Value.absent(),
    int? sizeBytes,
    int? downloadedBytes,
    DateTime? addedAt,
  }) => Download(
    videoId: videoId ?? this.videoId,
    status: status ?? this.status,
    filePath: filePath.present ? filePath.value : this.filePath,
    artPath: artPath.present ? artPath.value : this.artPath,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    downloadedBytes: downloadedBytes ?? this.downloadedBytes,
    addedAt: addedAt ?? this.addedAt,
  );
  Download copyWithCompanion(DownloadsCompanion data) {
    return Download(
      videoId: data.videoId.present ? data.videoId.value : this.videoId,
      status: data.status.present ? data.status.value : this.status,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      artPath: data.artPath.present ? data.artPath.value : this.artPath,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      downloadedBytes: data.downloadedBytes.present ? data.downloadedBytes.value : this.downloadedBytes,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Download(')
          ..write('videoId: $videoId, ')
          ..write('status: $status, ')
          ..write('filePath: $filePath, ')
          ..write('artPath: $artPath, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('downloadedBytes: $downloadedBytes, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(videoId, status, filePath, artPath, sizeBytes, downloadedBytes, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Download &&
          other.videoId == this.videoId &&
          other.status == this.status &&
          other.filePath == this.filePath &&
          other.artPath == this.artPath &&
          other.sizeBytes == this.sizeBytes &&
          other.downloadedBytes == this.downloadedBytes &&
          other.addedAt == this.addedAt);
}

class DownloadsCompanion extends UpdateCompanion<Download> {
  final Value<String> videoId;
  final Value<DownloadStatus> status;
  final Value<String?> filePath;
  final Value<String?> artPath;
  final Value<int> sizeBytes;
  final Value<int> downloadedBytes;
  final Value<DateTime> addedAt;
  final Value<int> rowid;
  const DownloadsCompanion({
    this.videoId = const Value.absent(),
    this.status = const Value.absent(),
    this.filePath = const Value.absent(),
    this.artPath = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.downloadedBytes = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DownloadsCompanion.insert({
    required String videoId,
    required DownloadStatus status,
    this.filePath = const Value.absent(),
    this.artPath = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.downloadedBytes = const Value.absent(),
    required DateTime addedAt,
    this.rowid = const Value.absent(),
  }) : videoId = Value(videoId),
       status = Value(status),
       addedAt = Value(addedAt);
  static Insertable<Download> custom({
    Expression<String>? videoId,
    Expression<int>? status,
    Expression<String>? filePath,
    Expression<String>? artPath,
    Expression<int>? sizeBytes,
    Expression<int>? downloadedBytes,
    Expression<DateTime>? addedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (videoId != null) 'video_id': videoId,
      if (status != null) 'status': status,
      if (filePath != null) 'file_path': filePath,
      if (artPath != null) 'art_path': artPath,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (downloadedBytes != null) 'downloaded_bytes': downloadedBytes,
      if (addedAt != null) 'added_at': addedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DownloadsCompanion copyWith({
    Value<String>? videoId,
    Value<DownloadStatus>? status,
    Value<String?>? filePath,
    Value<String?>? artPath,
    Value<int>? sizeBytes,
    Value<int>? downloadedBytes,
    Value<DateTime>? addedAt,
    Value<int>? rowid,
  }) {
    return DownloadsCompanion(
      videoId: videoId ?? this.videoId,
      status: status ?? this.status,
      filePath: filePath ?? this.filePath,
      artPath: artPath ?? this.artPath,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      addedAt: addedAt ?? this.addedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (videoId.present) {
      map['video_id'] = Variable<String>(videoId.value);
    }
    if (status.present) {
      map['status'] = Variable<int>($DownloadsTable.$converterstatus.toSql(status.value));
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (artPath.present) {
      map['art_path'] = Variable<String>(artPath.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (downloadedBytes.present) {
      map['downloaded_bytes'] = Variable<int>(downloadedBytes.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadsCompanion(')
          ..write('videoId: $videoId, ')
          ..write('status: $status, ')
          ..write('filePath: $filePath, ')
          ..write('artPath: $artPath, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('downloadedBytes: $downloadedBytes, ')
          ..write('addedAt: $addedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SongsTable songs = $SongsTable(this);
  late final $LikedSongsTable likedSongs = $LikedSongsTable(this);
  late final $PlayHistoryTable playHistory = $PlayHistoryTable(this);
  late final $SavedAlbumsTable savedAlbums = $SavedAlbumsTable(this);
  late final $SavedArtistsTable savedArtists = $SavedArtistsTable(this);
  late final $SavedPlaylistsTable savedPlaylists = $SavedPlaylistsTable(this);
  late final $LocalPlaylistsTable localPlaylists = $LocalPlaylistsTable(this);
  late final $LocalPlaylistItemsTable localPlaylistItems = $LocalPlaylistItemsTable(this);
  late final $SearchHistoryTable searchHistory = $SearchHistoryTable(this);
  late final $DownloadsTable downloads = $DownloadsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    songs,
    likedSongs,
    playHistory,
    savedAlbums,
    savedArtists,
    savedPlaylists,
    localPlaylists,
    localPlaylistItems,
    searchHistory,
    downloads,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName('local_playlists', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('local_playlist_items', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$SongsTableCreateCompanionBuilder = SongsCompanion Function({
  required String videoId,
  required String title,
  Value<String> artistsJson,
  Value<String?> albumId,
  Value<String?> albumName,
  Value<int?> durationMs,
  Value<String?> thumbnailUrl,
  Value<bool> isVideo,
  Value<int> rowid,
});
typedef $$SongsTableUpdateCompanionBuilder = SongsCompanion Function({
  Value<String> videoId,
  Value<String> title,
  Value<String> artistsJson,
  Value<String?> albumId,
  Value<String?> albumName,
  Value<int?> durationMs,
  Value<String?> thumbnailUrl,
  Value<bool> isVideo,
  Value<int> rowid,
});

final class $$SongsTableReferences extends BaseReferences<_$AppDatabase, $SongsTable, Song> {
  $$SongsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$LikedSongsTable, List<LikedSong>> _likedSongsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.likedSongs, aliasName: 'songs__video_id__liked_songs__video_id');

  $$LikedSongsTableProcessedTableManager get likedSongsRefs {
    final manager = $$LikedSongsTableTableManager(
      $_db,
      $_db.likedSongs,
    ).filter((f) => f.videoId.videoId.sqlEquals($_itemColumn<String>('video_id')!));

    final cache = $_typedResult.readTableOrNull(_likedSongsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$PlayHistoryTable, List<PlayHistoryData>> _playHistoryRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.playHistory, aliasName: 'songs__video_id__play_history__video_id');

  $$PlayHistoryTableProcessedTableManager get playHistoryRefs {
    final manager = $$PlayHistoryTableTableManager(
      $_db,
      $_db.playHistory,
    ).filter((f) => f.videoId.videoId.sqlEquals($_itemColumn<String>('video_id')!));

    final cache = $_typedResult.readTableOrNull(_playHistoryRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$LocalPlaylistItemsTable, List<LocalPlaylistItem>> _localPlaylistItemsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.localPlaylistItems,
    aliasName: 'songs__video_id__local_playlist_items__video_id',
  );

  $$LocalPlaylistItemsTableProcessedTableManager get localPlaylistItemsRefs {
    final manager = $$LocalPlaylistItemsTableTableManager(
      $_db,
      $_db.localPlaylistItems,
    ).filter((f) => f.videoId.videoId.sqlEquals($_itemColumn<String>('video_id')!));

    final cache = $_typedResult.readTableOrNull(_localPlaylistItemsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$DownloadsTable, List<Download>> _downloadsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.downloads, aliasName: 'songs__video_id__downloads__video_id');

  $$DownloadsTableProcessedTableManager get downloadsRefs {
    final manager = $$DownloadsTableTableManager(
      $_db,
      $_db.downloads,
    ).filter((f) => f.videoId.videoId.sqlEquals($_itemColumn<String>('video_id')!));

    final cache = $_typedResult.readTableOrNull(_downloadsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$SongsTableFilterComposer extends Composer<_$AppDatabase, $SongsTable> {
  $$SongsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get videoId =>
      $composableBuilder(column: $table.videoId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get artistsJson =>
      $composableBuilder(column: $table.artistsJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get albumId =>
      $composableBuilder(column: $table.albumId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get albumName =>
      $composableBuilder(column: $table.albumName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationMs =>
      $composableBuilder(column: $table.durationMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get thumbnailUrl =>
      $composableBuilder(column: $table.thumbnailUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isVideo =>
      $composableBuilder(column: $table.isVideo, builder: (column) => ColumnFilters(column));

  Expression<bool> likedSongsRefs(Expression<bool> Function($$LikedSongsTableFilterComposer f) f) {
    final $$LikedSongsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.videoId,
      referencedTable: $db.likedSongs,
      getReferencedColumn: (t) => t.videoId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LikedSongsTableFilterComposer(
            $db: $db,
            $table: $db.likedSongs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> playHistoryRefs(Expression<bool> Function($$PlayHistoryTableFilterComposer f) f) {
    final $$PlayHistoryTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.videoId,
      referencedTable: $db.playHistory,
      getReferencedColumn: (t) => t.videoId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$PlayHistoryTableFilterComposer(
            $db: $db,
            $table: $db.playHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> localPlaylistItemsRefs(Expression<bool> Function($$LocalPlaylistItemsTableFilterComposer f) f) {
    final $$LocalPlaylistItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.videoId,
      referencedTable: $db.localPlaylistItems,
      getReferencedColumn: (t) => t.videoId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LocalPlaylistItemsTableFilterComposer(
            $db: $db,
            $table: $db.localPlaylistItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> downloadsRefs(Expression<bool> Function($$DownloadsTableFilterComposer f) f) {
    final $$DownloadsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.videoId,
      referencedTable: $db.downloads,
      getReferencedColumn: (t) => t.videoId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$DownloadsTableFilterComposer(
            $db: $db,
            $table: $db.downloads,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SongsTableOrderingComposer extends Composer<_$AppDatabase, $SongsTable> {
  $$SongsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get videoId =>
      $composableBuilder(column: $table.videoId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get artistsJson =>
      $composableBuilder(column: $table.artistsJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get albumId =>
      $composableBuilder(column: $table.albumId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get albumName =>
      $composableBuilder(column: $table.albumName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationMs =>
      $composableBuilder(column: $table.durationMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get thumbnailUrl =>
      $composableBuilder(column: $table.thumbnailUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isVideo =>
      $composableBuilder(column: $table.isVideo, builder: (column) => ColumnOrderings(column));
}

class $$SongsTableAnnotationComposer extends Composer<_$AppDatabase, $SongsTable> {
  $$SongsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get videoId => $composableBuilder(column: $table.videoId, builder: (column) => column);

  GeneratedColumn<String> get title => $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get artistsJson =>
      $composableBuilder(column: $table.artistsJson, builder: (column) => column);

  GeneratedColumn<String> get albumId => $composableBuilder(column: $table.albumId, builder: (column) => column);

  GeneratedColumn<String> get albumName => $composableBuilder(column: $table.albumName, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(column: $table.durationMs, builder: (column) => column);

  GeneratedColumn<String> get thumbnailUrl =>
      $composableBuilder(column: $table.thumbnailUrl, builder: (column) => column);

  GeneratedColumn<bool> get isVideo => $composableBuilder(column: $table.isVideo, builder: (column) => column);

  Expression<T> likedSongsRefs<T extends Object>(Expression<T> Function($$LikedSongsTableAnnotationComposer a) f) {
    final $$LikedSongsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.videoId,
      referencedTable: $db.likedSongs,
      getReferencedColumn: (t) => t.videoId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LikedSongsTableAnnotationComposer(
            $db: $db,
            $table: $db.likedSongs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> playHistoryRefs<T extends Object>(Expression<T> Function($$PlayHistoryTableAnnotationComposer a) f) {
    final $$PlayHistoryTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.videoId,
      referencedTable: $db.playHistory,
      getReferencedColumn: (t) => t.videoId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$PlayHistoryTableAnnotationComposer(
            $db: $db,
            $table: $db.playHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> localPlaylistItemsRefs<T extends Object>(
    Expression<T> Function($$LocalPlaylistItemsTableAnnotationComposer a) f,
  ) {
    final $$LocalPlaylistItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.videoId,
      referencedTable: $db.localPlaylistItems,
      getReferencedColumn: (t) => t.videoId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LocalPlaylistItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.localPlaylistItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> downloadsRefs<T extends Object>(Expression<T> Function($$DownloadsTableAnnotationComposer a) f) {
    final $$DownloadsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.videoId,
      referencedTable: $db.downloads,
      getReferencedColumn: (t) => t.videoId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$DownloadsTableAnnotationComposer(
            $db: $db,
            $table: $db.downloads,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SongsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SongsTable,
          Song,
          $$SongsTableFilterComposer,
          $$SongsTableOrderingComposer,
          $$SongsTableAnnotationComposer,
          $$SongsTableCreateCompanionBuilder,
          $$SongsTableUpdateCompanionBuilder,
          (Song, $$SongsTableReferences),
          Song,
          PrefetchHooks Function({
            bool likedSongsRefs,
            bool playHistoryRefs,
            bool localPlaylistItemsRefs,
            bool downloadsRefs,
          })
        > {
  $$SongsTableTableManager(_$AppDatabase db, $SongsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$SongsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$SongsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$SongsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> videoId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> artistsJson = const Value.absent(),
                Value<String?> albumId = const Value.absent(),
                Value<String?> albumName = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<String?> thumbnailUrl = const Value.absent(),
                Value<bool> isVideo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SongsCompanion(
                videoId: videoId,
                title: title,
                artistsJson: artistsJson,
                albumId: albumId,
                albumName: albumName,
                durationMs: durationMs,
                thumbnailUrl: thumbnailUrl,
                isVideo: isVideo,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String videoId,
                required String title,
                Value<String> artistsJson = const Value.absent(),
                Value<String?> albumId = const Value.absent(),
                Value<String?> albumName = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<String?> thumbnailUrl = const Value.absent(),
                Value<bool> isVideo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SongsCompanion.insert(
                videoId: videoId,
                title: title,
                artistsJson: artistsJson,
                albumId: albumId,
                albumName: albumName,
                durationMs: durationMs,
                thumbnailUrl: thumbnailUrl,
                isVideo: isVideo,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable<$SongsTable, Song>(table), $$SongsTableReferences(db, table, e))).toList(),
          prefetchHooksCallback:
              ({
                likedSongsRefs = false,
                playHistoryRefs = false,
                localPlaylistItemsRefs = false,
                downloadsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (likedSongsRefs) db.likedSongs,
                    if (playHistoryRefs) db.playHistory,
                    if (localPlaylistItemsRefs) db.localPlaylistItems,
                    if (downloadsRefs) db.downloads,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (likedSongsRefs)
                        await $_getPrefetchedData<Song, $SongsTable, LikedSong>(
                          currentTable: table,
                          referencedTable: $$SongsTableReferences._likedSongsRefsTable(db),
                          managerFromTypedResult: (p0) => $$SongsTableReferences(db, table, p0).likedSongsRefs,
                          referencedItemsForCurrentItem: (item, referencedItems) =>
                              referencedItems.where((e) => e.videoId == item.videoId),
                          typedResults: items,
                        ),
                      if (playHistoryRefs)
                        await $_getPrefetchedData<Song, $SongsTable, PlayHistoryData>(
                          currentTable: table,
                          referencedTable: $$SongsTableReferences._playHistoryRefsTable(db),
                          managerFromTypedResult: (p0) => $$SongsTableReferences(db, table, p0).playHistoryRefs,
                          referencedItemsForCurrentItem: (item, referencedItems) =>
                              referencedItems.where((e) => e.videoId == item.videoId),
                          typedResults: items,
                        ),
                      if (localPlaylistItemsRefs)
                        await $_getPrefetchedData<Song, $SongsTable, LocalPlaylistItem>(
                          currentTable: table,
                          referencedTable: $$SongsTableReferences._localPlaylistItemsRefsTable(db),
                          managerFromTypedResult: (p0) => $$SongsTableReferences(db, table, p0).localPlaylistItemsRefs,
                          referencedItemsForCurrentItem: (item, referencedItems) =>
                              referencedItems.where((e) => e.videoId == item.videoId),
                          typedResults: items,
                        ),
                      if (downloadsRefs)
                        await $_getPrefetchedData<Song, $SongsTable, Download>(
                          currentTable: table,
                          referencedTable: $$SongsTableReferences._downloadsRefsTable(db),
                          managerFromTypedResult: (p0) => $$SongsTableReferences(db, table, p0).downloadsRefs,
                          referencedItemsForCurrentItem: (item, referencedItems) =>
                              referencedItems.where((e) => e.videoId == item.videoId),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SongsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SongsTable,
      Song,
      $$SongsTableFilterComposer,
      $$SongsTableOrderingComposer,
      $$SongsTableAnnotationComposer,
      $$SongsTableCreateCompanionBuilder,
      $$SongsTableUpdateCompanionBuilder,
      (Song, $$SongsTableReferences),
      Song,
      PrefetchHooks Function({
        bool likedSongsRefs,
        bool playHistoryRefs,
        bool localPlaylistItemsRefs,
        bool downloadsRefs,
      })
    >;
typedef $$LikedSongsTableCreateCompanionBuilder = LikedSongsCompanion Function({
  required String videoId,
  required DateTime likedAt,
  Value<int> rowid,
});
typedef $$LikedSongsTableUpdateCompanionBuilder = LikedSongsCompanion Function({
  Value<String> videoId,
  Value<DateTime> likedAt,
  Value<int> rowid,
});

final class $$LikedSongsTableReferences extends BaseReferences<_$AppDatabase, $LikedSongsTable, LikedSong> {
  $$LikedSongsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SongsTable _videoIdTable(_$AppDatabase db) => db.songs.createAlias('liked_songs__video_id__songs__video_id');

  $$SongsTableProcessedTableManager get videoId {
    final $_column = $_itemColumn<String>('video_id')!;

    final manager = $$SongsTableTableManager($_db, $_db.songs).filter((f) => f.videoId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_videoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$LikedSongsTableFilterComposer extends Composer<_$AppDatabase, $LikedSongsTable> {
  $$LikedSongsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get likedAt =>
      $composableBuilder(column: $table.likedAt, builder: (column) => ColumnFilters(column));

  $$SongsTableFilterComposer get videoId {
    final $$SongsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.videoId,
      referencedTable: $db.songs,
      getReferencedColumn: (t) => t.videoId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$SongsTableFilterComposer(
            $db: $db,
            $table: $db.songs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LikedSongsTableOrderingComposer extends Composer<_$AppDatabase, $LikedSongsTable> {
  $$LikedSongsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get likedAt =>
      $composableBuilder(column: $table.likedAt, builder: (column) => ColumnOrderings(column));

  $$SongsTableOrderingComposer get videoId {
    final $$SongsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.videoId,
      referencedTable: $db.songs,
      getReferencedColumn: (t) => t.videoId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$SongsTableOrderingComposer(
            $db: $db,
            $table: $db.songs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LikedSongsTableAnnotationComposer extends Composer<_$AppDatabase, $LikedSongsTable> {
  $$LikedSongsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get likedAt => $composableBuilder(column: $table.likedAt, builder: (column) => column);

  $$SongsTableAnnotationComposer get videoId {
    final $$SongsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.videoId,
      referencedTable: $db.songs,
      getReferencedColumn: (t) => t.videoId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$SongsTableAnnotationComposer(
            $db: $db,
            $table: $db.songs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LikedSongsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LikedSongsTable,
          LikedSong,
          $$LikedSongsTableFilterComposer,
          $$LikedSongsTableOrderingComposer,
          $$LikedSongsTableAnnotationComposer,
          $$LikedSongsTableCreateCompanionBuilder,
          $$LikedSongsTableUpdateCompanionBuilder,
          (LikedSong, $$LikedSongsTableReferences),
          LikedSong,
          PrefetchHooks Function({bool videoId})
        > {
  $$LikedSongsTableTableManager(_$AppDatabase db, $LikedSongsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$LikedSongsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$LikedSongsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$LikedSongsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> videoId = const Value.absent(),
            Value<DateTime> likedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => LikedSongsCompanion(videoId: videoId, likedAt: likedAt, rowid: rowid),
          createCompanionCallback: ({
            required String videoId,
            required DateTime likedAt,
            Value<int> rowid = const Value.absent(),
          }) => LikedSongsCompanion.insert(videoId: videoId, likedAt: likedAt, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable<$LikedSongsTable, LikedSong>(table), $$LikedSongsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({videoId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (videoId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.videoId,
                        referencedTable: $$LikedSongsTableReferences._videoIdTable(db),
                        referencedColumn: $$LikedSongsTableReferences._videoIdTable(db).videoId,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LikedSongsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LikedSongsTable,
      LikedSong,
      $$LikedSongsTableFilterComposer,
      $$LikedSongsTableOrderingComposer,
      $$LikedSongsTableAnnotationComposer,
      $$LikedSongsTableCreateCompanionBuilder,
      $$LikedSongsTableUpdateCompanionBuilder,
      (LikedSong, $$LikedSongsTableReferences),
      LikedSong,
      PrefetchHooks Function({bool videoId})
    >;
typedef $$PlayHistoryTableCreateCompanionBuilder = PlayHistoryCompanion Function({
  Value<int> id,
  required String videoId,
  required DateTime playedAt,
});
typedef $$PlayHistoryTableUpdateCompanionBuilder = PlayHistoryCompanion Function({
  Value<int> id,
  Value<String> videoId,
  Value<DateTime> playedAt,
});

final class $$PlayHistoryTableReferences extends BaseReferences<_$AppDatabase, $PlayHistoryTable, PlayHistoryData> {
  $$PlayHistoryTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SongsTable _videoIdTable(_$AppDatabase db) => db.songs.createAlias('play_history__video_id__songs__video_id');

  $$SongsTableProcessedTableManager get videoId {
    final $_column = $_itemColumn<String>('video_id')!;

    final manager = $$SongsTableTableManager($_db, $_db.songs).filter((f) => f.videoId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_videoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$PlayHistoryTableFilterComposer extends Composer<_$AppDatabase, $PlayHistoryTable> {
  $$PlayHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get playedAt =>
      $composableBuilder(column: $table.playedAt, builder: (column) => ColumnFilters(column));

  $$SongsTableFilterComposer get videoId {
    final $$SongsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.videoId,
      referencedTable: $db.songs,
      getReferencedColumn: (t) => t.videoId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$SongsTableFilterComposer(
            $db: $db,
            $table: $db.songs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlayHistoryTableOrderingComposer extends Composer<_$AppDatabase, $PlayHistoryTable> {
  $$PlayHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get playedAt =>
      $composableBuilder(column: $table.playedAt, builder: (column) => ColumnOrderings(column));

  $$SongsTableOrderingComposer get videoId {
    final $$SongsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.videoId,
      referencedTable: $db.songs,
      getReferencedColumn: (t) => t.videoId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$SongsTableOrderingComposer(
            $db: $db,
            $table: $db.songs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlayHistoryTableAnnotationComposer extends Composer<_$AppDatabase, $PlayHistoryTable> {
  $$PlayHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get playedAt => $composableBuilder(column: $table.playedAt, builder: (column) => column);

  $$SongsTableAnnotationComposer get videoId {
    final $$SongsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.videoId,
      referencedTable: $db.songs,
      getReferencedColumn: (t) => t.videoId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$SongsTableAnnotationComposer(
            $db: $db,
            $table: $db.songs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlayHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlayHistoryTable,
          PlayHistoryData,
          $$PlayHistoryTableFilterComposer,
          $$PlayHistoryTableOrderingComposer,
          $$PlayHistoryTableAnnotationComposer,
          $$PlayHistoryTableCreateCompanionBuilder,
          $$PlayHistoryTableUpdateCompanionBuilder,
          (PlayHistoryData, $$PlayHistoryTableReferences),
          PlayHistoryData,
          PrefetchHooks Function({bool videoId})
        > {
  $$PlayHistoryTableTableManager(_$AppDatabase db, $PlayHistoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$PlayHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$PlayHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$PlayHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> videoId = const Value.absent(),
            Value<DateTime> playedAt = const Value.absent(),
          }) => PlayHistoryCompanion(id: id, videoId: videoId, playedAt: playedAt),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String videoId,
            required DateTime playedAt,
          }) => PlayHistoryCompanion.insert(id: id, videoId: videoId, playedAt: playedAt),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlayHistoryTable, PlayHistoryData>(table),
                  $$PlayHistoryTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({videoId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (videoId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.videoId,
                        referencedTable: $$PlayHistoryTableReferences._videoIdTable(db),
                        referencedColumn: $$PlayHistoryTableReferences._videoIdTable(db).videoId,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PlayHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlayHistoryTable,
      PlayHistoryData,
      $$PlayHistoryTableFilterComposer,
      $$PlayHistoryTableOrderingComposer,
      $$PlayHistoryTableAnnotationComposer,
      $$PlayHistoryTableCreateCompanionBuilder,
      $$PlayHistoryTableUpdateCompanionBuilder,
      (PlayHistoryData, $$PlayHistoryTableReferences),
      PlayHistoryData,
      PrefetchHooks Function({bool videoId})
    >;
typedef $$SavedAlbumsTableCreateCompanionBuilder = SavedAlbumsCompanion Function({
  required String browseId,
  Value<String?> playlistId,
  required String title,
  Value<String> artistsJson,
  Value<String?> year,
  Value<String?> thumbnailUrl,
  required DateTime savedAt,
  Value<int> rowid,
});
typedef $$SavedAlbumsTableUpdateCompanionBuilder = SavedAlbumsCompanion Function({
  Value<String> browseId,
  Value<String?> playlistId,
  Value<String> title,
  Value<String> artistsJson,
  Value<String?> year,
  Value<String?> thumbnailUrl,
  Value<DateTime> savedAt,
  Value<int> rowid,
});

class $$SavedAlbumsTableFilterComposer extends Composer<_$AppDatabase, $SavedAlbumsTable> {
  $$SavedAlbumsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get browseId =>
      $composableBuilder(column: $table.browseId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get playlistId =>
      $composableBuilder(column: $table.playlistId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get artistsJson =>
      $composableBuilder(column: $table.artistsJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get year => $composableBuilder(column: $table.year, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get thumbnailUrl =>
      $composableBuilder(column: $table.thumbnailUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => ColumnFilters(column));
}

class $$SavedAlbumsTableOrderingComposer extends Composer<_$AppDatabase, $SavedAlbumsTable> {
  $$SavedAlbumsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get browseId =>
      $composableBuilder(column: $table.browseId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get playlistId =>
      $composableBuilder(column: $table.playlistId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get artistsJson =>
      $composableBuilder(column: $table.artistsJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get year =>
      $composableBuilder(column: $table.year, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get thumbnailUrl =>
      $composableBuilder(column: $table.thumbnailUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => ColumnOrderings(column));
}

class $$SavedAlbumsTableAnnotationComposer extends Composer<_$AppDatabase, $SavedAlbumsTable> {
  $$SavedAlbumsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get browseId => $composableBuilder(column: $table.browseId, builder: (column) => column);

  GeneratedColumn<String> get playlistId => $composableBuilder(column: $table.playlistId, builder: (column) => column);

  GeneratedColumn<String> get title => $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get artistsJson =>
      $composableBuilder(column: $table.artistsJson, builder: (column) => column);

  GeneratedColumn<String> get year => $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get thumbnailUrl =>
      $composableBuilder(column: $table.thumbnailUrl, builder: (column) => column);

  GeneratedColumn<DateTime> get savedAt => $composableBuilder(column: $table.savedAt, builder: (column) => column);
}

class $$SavedAlbumsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SavedAlbumsTable,
          SavedAlbum,
          $$SavedAlbumsTableFilterComposer,
          $$SavedAlbumsTableOrderingComposer,
          $$SavedAlbumsTableAnnotationComposer,
          $$SavedAlbumsTableCreateCompanionBuilder,
          $$SavedAlbumsTableUpdateCompanionBuilder,
          (SavedAlbum, BaseReferences<_$AppDatabase, $SavedAlbumsTable, SavedAlbum>),
          SavedAlbum,
          PrefetchHooks Function()
        > {
  $$SavedAlbumsTableTableManager(_$AppDatabase db, $SavedAlbumsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$SavedAlbumsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$SavedAlbumsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$SavedAlbumsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> browseId = const Value.absent(),
                Value<String?> playlistId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> artistsJson = const Value.absent(),
                Value<String?> year = const Value.absent(),
                Value<String?> thumbnailUrl = const Value.absent(),
                Value<DateTime> savedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavedAlbumsCompanion(
                browseId: browseId,
                playlistId: playlistId,
                title: title,
                artistsJson: artistsJson,
                year: year,
                thumbnailUrl: thumbnailUrl,
                savedAt: savedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String browseId,
                Value<String?> playlistId = const Value.absent(),
                required String title,
                Value<String> artistsJson = const Value.absent(),
                Value<String?> year = const Value.absent(),
                Value<String?> thumbnailUrl = const Value.absent(),
                required DateTime savedAt,
                Value<int> rowid = const Value.absent(),
              }) => SavedAlbumsCompanion.insert(
                browseId: browseId,
                playlistId: playlistId,
                title: title,
                artistsJson: artistsJson,
                year: year,
                thumbnailUrl: thumbnailUrl,
                savedAt: savedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SavedAlbumsTable, SavedAlbum>(table),
                  BaseReferences<_$AppDatabase, $SavedAlbumsTable, SavedAlbum>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SavedAlbumsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SavedAlbumsTable,
      SavedAlbum,
      $$SavedAlbumsTableFilterComposer,
      $$SavedAlbumsTableOrderingComposer,
      $$SavedAlbumsTableAnnotationComposer,
      $$SavedAlbumsTableCreateCompanionBuilder,
      $$SavedAlbumsTableUpdateCompanionBuilder,
      (SavedAlbum, BaseReferences<_$AppDatabase, $SavedAlbumsTable, SavedAlbum>),
      SavedAlbum,
      PrefetchHooks Function()
    >;
typedef $$SavedArtistsTableCreateCompanionBuilder = SavedArtistsCompanion Function({
  required String browseId,
  required String title,
  Value<String?> thumbnailUrl,
  required DateTime savedAt,
  Value<int> rowid,
});
typedef $$SavedArtistsTableUpdateCompanionBuilder = SavedArtistsCompanion Function({
  Value<String> browseId,
  Value<String> title,
  Value<String?> thumbnailUrl,
  Value<DateTime> savedAt,
  Value<int> rowid,
});

class $$SavedArtistsTableFilterComposer extends Composer<_$AppDatabase, $SavedArtistsTable> {
  $$SavedArtistsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get browseId =>
      $composableBuilder(column: $table.browseId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get thumbnailUrl =>
      $composableBuilder(column: $table.thumbnailUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => ColumnFilters(column));
}

class $$SavedArtistsTableOrderingComposer extends Composer<_$AppDatabase, $SavedArtistsTable> {
  $$SavedArtistsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get browseId =>
      $composableBuilder(column: $table.browseId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get thumbnailUrl =>
      $composableBuilder(column: $table.thumbnailUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => ColumnOrderings(column));
}

class $$SavedArtistsTableAnnotationComposer extends Composer<_$AppDatabase, $SavedArtistsTable> {
  $$SavedArtistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get browseId => $composableBuilder(column: $table.browseId, builder: (column) => column);

  GeneratedColumn<String> get title => $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get thumbnailUrl =>
      $composableBuilder(column: $table.thumbnailUrl, builder: (column) => column);

  GeneratedColumn<DateTime> get savedAt => $composableBuilder(column: $table.savedAt, builder: (column) => column);
}

class $$SavedArtistsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SavedArtistsTable,
          SavedArtist,
          $$SavedArtistsTableFilterComposer,
          $$SavedArtistsTableOrderingComposer,
          $$SavedArtistsTableAnnotationComposer,
          $$SavedArtistsTableCreateCompanionBuilder,
          $$SavedArtistsTableUpdateCompanionBuilder,
          (SavedArtist, BaseReferences<_$AppDatabase, $SavedArtistsTable, SavedArtist>),
          SavedArtist,
          PrefetchHooks Function()
        > {
  $$SavedArtistsTableTableManager(_$AppDatabase db, $SavedArtistsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$SavedArtistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$SavedArtistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$SavedArtistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> browseId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> thumbnailUrl = const Value.absent(),
                Value<DateTime> savedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavedArtistsCompanion(
                browseId: browseId,
                title: title,
                thumbnailUrl: thumbnailUrl,
                savedAt: savedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String browseId,
                required String title,
                Value<String?> thumbnailUrl = const Value.absent(),
                required DateTime savedAt,
                Value<int> rowid = const Value.absent(),
              }) => SavedArtistsCompanion.insert(
                browseId: browseId,
                title: title,
                thumbnailUrl: thumbnailUrl,
                savedAt: savedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SavedArtistsTable, SavedArtist>(table),
                  BaseReferences<_$AppDatabase, $SavedArtistsTable, SavedArtist>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SavedArtistsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SavedArtistsTable,
      SavedArtist,
      $$SavedArtistsTableFilterComposer,
      $$SavedArtistsTableOrderingComposer,
      $$SavedArtistsTableAnnotationComposer,
      $$SavedArtistsTableCreateCompanionBuilder,
      $$SavedArtistsTableUpdateCompanionBuilder,
      (SavedArtist, BaseReferences<_$AppDatabase, $SavedArtistsTable, SavedArtist>),
      SavedArtist,
      PrefetchHooks Function()
    >;
typedef $$SavedPlaylistsTableCreateCompanionBuilder = SavedPlaylistsCompanion Function({
  required String playlistId,
  required String title,
  Value<String?> author,
  Value<String?> thumbnailUrl,
  required DateTime savedAt,
  Value<int> rowid,
});
typedef $$SavedPlaylistsTableUpdateCompanionBuilder = SavedPlaylistsCompanion Function({
  Value<String> playlistId,
  Value<String> title,
  Value<String?> author,
  Value<String?> thumbnailUrl,
  Value<DateTime> savedAt,
  Value<int> rowid,
});

class $$SavedPlaylistsTableFilterComposer extends Composer<_$AppDatabase, $SavedPlaylistsTable> {
  $$SavedPlaylistsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get playlistId =>
      $composableBuilder(column: $table.playlistId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get thumbnailUrl =>
      $composableBuilder(column: $table.thumbnailUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => ColumnFilters(column));
}

class $$SavedPlaylistsTableOrderingComposer extends Composer<_$AppDatabase, $SavedPlaylistsTable> {
  $$SavedPlaylistsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get playlistId =>
      $composableBuilder(column: $table.playlistId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get thumbnailUrl =>
      $composableBuilder(column: $table.thumbnailUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => ColumnOrderings(column));
}

class $$SavedPlaylistsTableAnnotationComposer extends Composer<_$AppDatabase, $SavedPlaylistsTable> {
  $$SavedPlaylistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get playlistId => $composableBuilder(column: $table.playlistId, builder: (column) => column);

  GeneratedColumn<String> get title => $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get author => $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get thumbnailUrl =>
      $composableBuilder(column: $table.thumbnailUrl, builder: (column) => column);

  GeneratedColumn<DateTime> get savedAt => $composableBuilder(column: $table.savedAt, builder: (column) => column);
}

class $$SavedPlaylistsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SavedPlaylistsTable,
          SavedPlaylist,
          $$SavedPlaylistsTableFilterComposer,
          $$SavedPlaylistsTableOrderingComposer,
          $$SavedPlaylistsTableAnnotationComposer,
          $$SavedPlaylistsTableCreateCompanionBuilder,
          $$SavedPlaylistsTableUpdateCompanionBuilder,
          (SavedPlaylist, BaseReferences<_$AppDatabase, $SavedPlaylistsTable, SavedPlaylist>),
          SavedPlaylist,
          PrefetchHooks Function()
        > {
  $$SavedPlaylistsTableTableManager(_$AppDatabase db, $SavedPlaylistsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$SavedPlaylistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$SavedPlaylistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$SavedPlaylistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> playlistId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> author = const Value.absent(),
                Value<String?> thumbnailUrl = const Value.absent(),
                Value<DateTime> savedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavedPlaylistsCompanion(
                playlistId: playlistId,
                title: title,
                author: author,
                thumbnailUrl: thumbnailUrl,
                savedAt: savedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String playlistId,
                required String title,
                Value<String?> author = const Value.absent(),
                Value<String?> thumbnailUrl = const Value.absent(),
                required DateTime savedAt,
                Value<int> rowid = const Value.absent(),
              }) => SavedPlaylistsCompanion.insert(
                playlistId: playlistId,
                title: title,
                author: author,
                thumbnailUrl: thumbnailUrl,
                savedAt: savedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SavedPlaylistsTable, SavedPlaylist>(table),
                  BaseReferences<_$AppDatabase, $SavedPlaylistsTable, SavedPlaylist>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SavedPlaylistsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SavedPlaylistsTable,
      SavedPlaylist,
      $$SavedPlaylistsTableFilterComposer,
      $$SavedPlaylistsTableOrderingComposer,
      $$SavedPlaylistsTableAnnotationComposer,
      $$SavedPlaylistsTableCreateCompanionBuilder,
      $$SavedPlaylistsTableUpdateCompanionBuilder,
      (SavedPlaylist, BaseReferences<_$AppDatabase, $SavedPlaylistsTable, SavedPlaylist>),
      SavedPlaylist,
      PrefetchHooks Function()
    >;
typedef $$LocalPlaylistsTableCreateCompanionBuilder = LocalPlaylistsCompanion Function({
  Value<int> id,
  required String name,
  required DateTime createdAt,
});
typedef $$LocalPlaylistsTableUpdateCompanionBuilder = LocalPlaylistsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<DateTime> createdAt,
});

final class $$LocalPlaylistsTableReferences extends BaseReferences<_$AppDatabase, $LocalPlaylistsTable, LocalPlaylist> {
  $$LocalPlaylistsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$LocalPlaylistItemsTable, List<LocalPlaylistItem>> _localPlaylistItemsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.localPlaylistItems,
    aliasName: 'local_playlists__id__local_playlist_items__playlist_id',
  );

  $$LocalPlaylistItemsTableProcessedTableManager get localPlaylistItemsRefs {
    final manager = $$LocalPlaylistItemsTableTableManager(
      $_db,
      $_db.localPlaylistItems,
    ).filter((f) => f.playlistId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_localPlaylistItemsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$LocalPlaylistsTableFilterComposer extends Composer<_$AppDatabase, $LocalPlaylistsTable> {
  $$LocalPlaylistsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> localPlaylistItemsRefs(Expression<bool> Function($$LocalPlaylistItemsTableFilterComposer f) f) {
    final $$LocalPlaylistItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.localPlaylistItems,
      getReferencedColumn: (t) => t.playlistId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LocalPlaylistItemsTableFilterComposer(
            $db: $db,
            $table: $db.localPlaylistItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LocalPlaylistsTableOrderingComposer extends Composer<_$AppDatabase, $LocalPlaylistsTable> {
  $$LocalPlaylistsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$LocalPlaylistsTableAnnotationComposer extends Composer<_$AppDatabase, $LocalPlaylistsTable> {
  $$LocalPlaylistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> localPlaylistItemsRefs<T extends Object>(
    Expression<T> Function($$LocalPlaylistItemsTableAnnotationComposer a) f,
  ) {
    final $$LocalPlaylistItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.localPlaylistItems,
      getReferencedColumn: (t) => t.playlistId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LocalPlaylistItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.localPlaylistItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LocalPlaylistsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalPlaylistsTable,
          LocalPlaylist,
          $$LocalPlaylistsTableFilterComposer,
          $$LocalPlaylistsTableOrderingComposer,
          $$LocalPlaylistsTableAnnotationComposer,
          $$LocalPlaylistsTableCreateCompanionBuilder,
          $$LocalPlaylistsTableUpdateCompanionBuilder,
          (LocalPlaylist, $$LocalPlaylistsTableReferences),
          LocalPlaylist,
          PrefetchHooks Function({bool localPlaylistItemsRefs})
        > {
  $$LocalPlaylistsTableTableManager(_$AppDatabase db, $LocalPlaylistsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$LocalPlaylistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$LocalPlaylistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$LocalPlaylistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) => LocalPlaylistsCompanion(id: id, name: name, createdAt: createdAt),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required DateTime createdAt,
          }) => LocalPlaylistsCompanion.insert(id: id, name: name, createdAt: createdAt),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalPlaylistsTable, LocalPlaylist>(table),
                  $$LocalPlaylistsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({localPlaylistItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (localPlaylistItemsRefs) db.localPlaylistItems],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (localPlaylistItemsRefs)
                    await $_getPrefetchedData<LocalPlaylist, $LocalPlaylistsTable, LocalPlaylistItem>(
                      currentTable: table,
                      referencedTable: $$LocalPlaylistsTableReferences._localPlaylistItemsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$LocalPlaylistsTableReferences(db, table, p0).localPlaylistItemsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.playlistId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$LocalPlaylistsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalPlaylistsTable,
      LocalPlaylist,
      $$LocalPlaylistsTableFilterComposer,
      $$LocalPlaylistsTableOrderingComposer,
      $$LocalPlaylistsTableAnnotationComposer,
      $$LocalPlaylistsTableCreateCompanionBuilder,
      $$LocalPlaylistsTableUpdateCompanionBuilder,
      (LocalPlaylist, $$LocalPlaylistsTableReferences),
      LocalPlaylist,
      PrefetchHooks Function({bool localPlaylistItemsRefs})
    >;
typedef $$LocalPlaylistItemsTableCreateCompanionBuilder = LocalPlaylistItemsCompanion Function({
  Value<int> id,
  required int playlistId,
  required String videoId,
  required int position,
});
typedef $$LocalPlaylistItemsTableUpdateCompanionBuilder = LocalPlaylistItemsCompanion Function({
  Value<int> id,
  Value<int> playlistId,
  Value<String> videoId,
  Value<int> position,
});

final class $$LocalPlaylistItemsTableReferences
    extends BaseReferences<_$AppDatabase, $LocalPlaylistItemsTable, LocalPlaylistItem> {
  $$LocalPlaylistItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LocalPlaylistsTable _playlistIdTable(_$AppDatabase db) =>
      db.localPlaylists.createAlias('local_playlist_items__playlist_id__local_playlists__id');

  $$LocalPlaylistsTableProcessedTableManager get playlistId {
    final $_column = $_itemColumn<int>('playlist_id')!;

    final manager = $$LocalPlaylistsTableTableManager(
      $_db,
      $_db.localPlaylists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playlistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static $SongsTable _videoIdTable(_$AppDatabase db) =>
      db.songs.createAlias('local_playlist_items__video_id__songs__video_id');

  $$SongsTableProcessedTableManager get videoId {
    final $_column = $_itemColumn<String>('video_id')!;

    final manager = $$SongsTableTableManager($_db, $_db.songs).filter((f) => f.videoId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_videoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$LocalPlaylistItemsTableFilterComposer extends Composer<_$AppDatabase, $LocalPlaylistItemsTable> {
  $$LocalPlaylistItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => ColumnFilters(column));

  $$LocalPlaylistsTableFilterComposer get playlistId {
    final $$LocalPlaylistsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.localPlaylists,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LocalPlaylistsTableFilterComposer(
            $db: $db,
            $table: $db.localPlaylists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SongsTableFilterComposer get videoId {
    final $$SongsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.videoId,
      referencedTable: $db.songs,
      getReferencedColumn: (t) => t.videoId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$SongsTableFilterComposer(
            $db: $db,
            $table: $db.songs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalPlaylistItemsTableOrderingComposer extends Composer<_$AppDatabase, $LocalPlaylistItemsTable> {
  $$LocalPlaylistItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => ColumnOrderings(column));

  $$LocalPlaylistsTableOrderingComposer get playlistId {
    final $$LocalPlaylistsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.localPlaylists,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LocalPlaylistsTableOrderingComposer(
            $db: $db,
            $table: $db.localPlaylists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SongsTableOrderingComposer get videoId {
    final $$SongsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.videoId,
      referencedTable: $db.songs,
      getReferencedColumn: (t) => t.videoId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$SongsTableOrderingComposer(
            $db: $db,
            $table: $db.songs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalPlaylistItemsTableAnnotationComposer extends Composer<_$AppDatabase, $LocalPlaylistItemsTable> {
  $$LocalPlaylistItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get position => $composableBuilder(column: $table.position, builder: (column) => column);

  $$LocalPlaylistsTableAnnotationComposer get playlistId {
    final $$LocalPlaylistsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.localPlaylists,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LocalPlaylistsTableAnnotationComposer(
            $db: $db,
            $table: $db.localPlaylists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SongsTableAnnotationComposer get videoId {
    final $$SongsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.videoId,
      referencedTable: $db.songs,
      getReferencedColumn: (t) => t.videoId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$SongsTableAnnotationComposer(
            $db: $db,
            $table: $db.songs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalPlaylistItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalPlaylistItemsTable,
          LocalPlaylistItem,
          $$LocalPlaylistItemsTableFilterComposer,
          $$LocalPlaylistItemsTableOrderingComposer,
          $$LocalPlaylistItemsTableAnnotationComposer,
          $$LocalPlaylistItemsTableCreateCompanionBuilder,
          $$LocalPlaylistItemsTableUpdateCompanionBuilder,
          (LocalPlaylistItem, $$LocalPlaylistItemsTableReferences),
          LocalPlaylistItem,
          PrefetchHooks Function({bool playlistId, bool videoId})
        > {
  $$LocalPlaylistItemsTableTableManager(_$AppDatabase db, $LocalPlaylistItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$LocalPlaylistItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$LocalPlaylistItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$LocalPlaylistItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> playlistId = const Value.absent(),
            Value<String> videoId = const Value.absent(),
            Value<int> position = const Value.absent(),
          }) => LocalPlaylistItemsCompanion(id: id, playlistId: playlistId, videoId: videoId, position: position),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int playlistId,
                required String videoId,
                required int position,
              }) => LocalPlaylistItemsCompanion.insert(
                id: id,
                playlistId: playlistId,
                videoId: videoId,
                position: position,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalPlaylistItemsTable, LocalPlaylistItem>(table),
                  $$LocalPlaylistItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playlistId = false, videoId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (playlistId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.playlistId,
                        referencedTable: $$LocalPlaylistItemsTableReferences._playlistIdTable(db),
                        referencedColumn: $$LocalPlaylistItemsTableReferences._playlistIdTable(db).id,
                      ) as T;
                    }
                    if (videoId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.videoId,
                        referencedTable: $$LocalPlaylistItemsTableReferences._videoIdTable(db),
                        referencedColumn: $$LocalPlaylistItemsTableReferences._videoIdTable(db).videoId,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LocalPlaylistItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalPlaylistItemsTable,
      LocalPlaylistItem,
      $$LocalPlaylistItemsTableFilterComposer,
      $$LocalPlaylistItemsTableOrderingComposer,
      $$LocalPlaylistItemsTableAnnotationComposer,
      $$LocalPlaylistItemsTableCreateCompanionBuilder,
      $$LocalPlaylistItemsTableUpdateCompanionBuilder,
      (LocalPlaylistItem, $$LocalPlaylistItemsTableReferences),
      LocalPlaylistItem,
      PrefetchHooks Function({bool playlistId, bool videoId})
    >;
typedef $$SearchHistoryTableCreateCompanionBuilder = SearchHistoryCompanion Function({
  required String query,
  required DateTime searchedAt,
  Value<int> rowid,
});
typedef $$SearchHistoryTableUpdateCompanionBuilder = SearchHistoryCompanion Function({
  Value<String> query,
  Value<DateTime> searchedAt,
  Value<int> rowid,
});

class $$SearchHistoryTableFilterComposer extends Composer<_$AppDatabase, $SearchHistoryTable> {
  $$SearchHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get query =>
      $composableBuilder(column: $table.query, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get searchedAt =>
      $composableBuilder(column: $table.searchedAt, builder: (column) => ColumnFilters(column));
}

class $$SearchHistoryTableOrderingComposer extends Composer<_$AppDatabase, $SearchHistoryTable> {
  $$SearchHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get query =>
      $composableBuilder(column: $table.query, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get searchedAt =>
      $composableBuilder(column: $table.searchedAt, builder: (column) => ColumnOrderings(column));
}

class $$SearchHistoryTableAnnotationComposer extends Composer<_$AppDatabase, $SearchHistoryTable> {
  $$SearchHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get query => $composableBuilder(column: $table.query, builder: (column) => column);

  GeneratedColumn<DateTime> get searchedAt =>
      $composableBuilder(column: $table.searchedAt, builder: (column) => column);
}

class $$SearchHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SearchHistoryTable,
          SearchHistoryData,
          $$SearchHistoryTableFilterComposer,
          $$SearchHistoryTableOrderingComposer,
          $$SearchHistoryTableAnnotationComposer,
          $$SearchHistoryTableCreateCompanionBuilder,
          $$SearchHistoryTableUpdateCompanionBuilder,
          (SearchHistoryData, BaseReferences<_$AppDatabase, $SearchHistoryTable, SearchHistoryData>),
          SearchHistoryData,
          PrefetchHooks Function()
        > {
  $$SearchHistoryTableTableManager(_$AppDatabase db, $SearchHistoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$SearchHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$SearchHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$SearchHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> query = const Value.absent(),
            Value<DateTime> searchedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SearchHistoryCompanion(query: query, searchedAt: searchedAt, rowid: rowid),
          createCompanionCallback: ({
            required String query,
            required DateTime searchedAt,
            Value<int> rowid = const Value.absent(),
          }) => SearchHistoryCompanion.insert(query: query, searchedAt: searchedAt, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SearchHistoryTable, SearchHistoryData>(table),
                  BaseReferences<_$AppDatabase, $SearchHistoryTable, SearchHistoryData>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SearchHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SearchHistoryTable,
      SearchHistoryData,
      $$SearchHistoryTableFilterComposer,
      $$SearchHistoryTableOrderingComposer,
      $$SearchHistoryTableAnnotationComposer,
      $$SearchHistoryTableCreateCompanionBuilder,
      $$SearchHistoryTableUpdateCompanionBuilder,
      (SearchHistoryData, BaseReferences<_$AppDatabase, $SearchHistoryTable, SearchHistoryData>),
      SearchHistoryData,
      PrefetchHooks Function()
    >;
typedef $$DownloadsTableCreateCompanionBuilder = DownloadsCompanion Function({
  required String videoId,
  required DownloadStatus status,
  Value<String?> filePath,
  Value<String?> artPath,
  Value<int> sizeBytes,
  Value<int> downloadedBytes,
  required DateTime addedAt,
  Value<int> rowid,
});
typedef $$DownloadsTableUpdateCompanionBuilder = DownloadsCompanion Function({
  Value<String> videoId,
  Value<DownloadStatus> status,
  Value<String?> filePath,
  Value<String?> artPath,
  Value<int> sizeBytes,
  Value<int> downloadedBytes,
  Value<DateTime> addedAt,
  Value<int> rowid,
});

final class $$DownloadsTableReferences extends BaseReferences<_$AppDatabase, $DownloadsTable, Download> {
  $$DownloadsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SongsTable _videoIdTable(_$AppDatabase db) => db.songs.createAlias('downloads__video_id__songs__video_id');

  $$SongsTableProcessedTableManager get videoId {
    final $_column = $_itemColumn<String>('video_id')!;

    final manager = $$SongsTableTableManager($_db, $_db.songs).filter((f) => f.videoId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_videoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$DownloadsTableFilterComposer extends Composer<_$AppDatabase, $DownloadsTable> {
  $$DownloadsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<DownloadStatus, DownloadStatus, int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get artPath =>
      $composableBuilder(column: $table.artPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get downloadedBytes =>
      $composableBuilder(column: $table.downloadedBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => ColumnFilters(column));

  $$SongsTableFilterComposer get videoId {
    final $$SongsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.videoId,
      referencedTable: $db.songs,
      getReferencedColumn: (t) => t.videoId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$SongsTableFilterComposer(
            $db: $db,
            $table: $db.songs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DownloadsTableOrderingComposer extends Composer<_$AppDatabase, $DownloadsTable> {
  $$DownloadsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get artPath =>
      $composableBuilder(column: $table.artPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get downloadedBytes =>
      $composableBuilder(column: $table.downloadedBytes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => ColumnOrderings(column));

  $$SongsTableOrderingComposer get videoId {
    final $$SongsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.videoId,
      referencedTable: $db.songs,
      getReferencedColumn: (t) => t.videoId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$SongsTableOrderingComposer(
            $db: $db,
            $table: $db.songs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DownloadsTableAnnotationComposer extends Composer<_$AppDatabase, $DownloadsTable> {
  $$DownloadsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<DownloadStatus, int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get filePath => $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get artPath => $composableBuilder(column: $table.artPath, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes => $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<int> get downloadedBytes =>
      $composableBuilder(column: $table.downloadedBytes, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt => $composableBuilder(column: $table.addedAt, builder: (column) => column);

  $$SongsTableAnnotationComposer get videoId {
    final $$SongsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.videoId,
      referencedTable: $db.songs,
      getReferencedColumn: (t) => t.videoId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$SongsTableAnnotationComposer(
            $db: $db,
            $table: $db.songs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DownloadsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DownloadsTable,
          Download,
          $$DownloadsTableFilterComposer,
          $$DownloadsTableOrderingComposer,
          $$DownloadsTableAnnotationComposer,
          $$DownloadsTableCreateCompanionBuilder,
          $$DownloadsTableUpdateCompanionBuilder,
          (Download, $$DownloadsTableReferences),
          Download,
          PrefetchHooks Function({bool videoId})
        > {
  $$DownloadsTableTableManager(_$AppDatabase db, $DownloadsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$DownloadsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$DownloadsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$DownloadsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> videoId = const Value.absent(),
                Value<DownloadStatus> status = const Value.absent(),
                Value<String?> filePath = const Value.absent(),
                Value<String?> artPath = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<int> downloadedBytes = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DownloadsCompanion(
                videoId: videoId,
                status: status,
                filePath: filePath,
                artPath: artPath,
                sizeBytes: sizeBytes,
                downloadedBytes: downloadedBytes,
                addedAt: addedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String videoId,
                required DownloadStatus status,
                Value<String?> filePath = const Value.absent(),
                Value<String?> artPath = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<int> downloadedBytes = const Value.absent(),
                required DateTime addedAt,
                Value<int> rowid = const Value.absent(),
              }) => DownloadsCompanion.insert(
                videoId: videoId,
                status: status,
                filePath: filePath,
                artPath: artPath,
                sizeBytes: sizeBytes,
                downloadedBytes: downloadedBytes,
                addedAt: addedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable<$DownloadsTable, Download>(table), $$DownloadsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({videoId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (videoId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.videoId,
                        referencedTable: $$DownloadsTableReferences._videoIdTable(db),
                        referencedColumn: $$DownloadsTableReferences._videoIdTable(db).videoId,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DownloadsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DownloadsTable,
      Download,
      $$DownloadsTableFilterComposer,
      $$DownloadsTableOrderingComposer,
      $$DownloadsTableAnnotationComposer,
      $$DownloadsTableCreateCompanionBuilder,
      $$DownloadsTableUpdateCompanionBuilder,
      (Download, $$DownloadsTableReferences),
      Download,
      PrefetchHooks Function({bool videoId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SongsTableTableManager get songs => $$SongsTableTableManager(_db, _db.songs);
  $$LikedSongsTableTableManager get likedSongs => $$LikedSongsTableTableManager(_db, _db.likedSongs);
  $$PlayHistoryTableTableManager get playHistory => $$PlayHistoryTableTableManager(_db, _db.playHistory);
  $$SavedAlbumsTableTableManager get savedAlbums => $$SavedAlbumsTableTableManager(_db, _db.savedAlbums);
  $$SavedArtistsTableTableManager get savedArtists => $$SavedArtistsTableTableManager(_db, _db.savedArtists);
  $$SavedPlaylistsTableTableManager get savedPlaylists => $$SavedPlaylistsTableTableManager(_db, _db.savedPlaylists);
  $$LocalPlaylistsTableTableManager get localPlaylists => $$LocalPlaylistsTableTableManager(_db, _db.localPlaylists);
  $$LocalPlaylistItemsTableTableManager get localPlaylistItems =>
      $$LocalPlaylistItemsTableTableManager(_db, _db.localPlaylistItems);
  $$SearchHistoryTableTableManager get searchHistory => $$SearchHistoryTableTableManager(_db, _db.searchHistory);
  $$DownloadsTableTableManager get downloads => $$DownloadsTableTableManager(_db, _db.downloads);
}
