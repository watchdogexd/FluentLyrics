class GeneralTranslationRequestData {
  final String title;
  final String artist;
  final String album;
  final int durationSeconds;
  final String content; // lyric body
  final String? genre;

  GeneralTranslationRequestData({
    required this.title,
    required this.artist,
    required this.album,
    required this.durationSeconds,
    required this.content,
    this.genre,
  });
}
