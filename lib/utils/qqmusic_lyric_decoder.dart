import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'app_logger.dart';

class QQMusicLyricDecoder {
  static const int _maxQrcDecodeDepth = 3;
  static const String _qrcKey = r'!@#)(*$%123ZXC!@!@#)(NHL';
  static final Uint8List _qrcKeyBytes = Uint8List.fromList(
    utf8.encode(_qrcKey),
  );
  static const List<List<int>> _sbox = [
    [14, 4, 13, 1, 2, 15, 11, 8, 3, 10, 6, 12, 5, 9, 0, 7, 0, 15, 7, 4, 14, 2, 13, 1, 10, 6, 12, 11, 9, 5, 3, 8, 4, 1, 14, 8, 13, 6, 2, 11, 15, 12, 9, 7, 3, 10, 5, 0, 15, 12, 8, 2, 4, 9, 1, 7, 5, 11, 3, 14, 10, 0, 6, 13],
    [15, 1, 8, 14, 6, 11, 3, 4, 9, 7, 2, 13, 12, 0, 5, 10, 3, 13, 4, 7, 15, 2, 8, 15, 12, 0, 1, 10, 6, 9, 11, 5, 0, 14, 7, 11, 10, 4, 13, 1, 5, 8, 12, 6, 9, 3, 2, 15, 13, 8, 10, 1, 3, 15, 4, 2, 11, 6, 7, 12, 0, 5, 14, 9],
    [10, 0, 9, 14, 6, 3, 15, 5, 1, 13, 12, 7, 11, 4, 2, 8, 13, 7, 0, 9, 3, 4, 6, 10, 2, 8, 5, 14, 12, 11, 15, 1, 13, 6, 4, 9, 8, 15, 3, 0, 11, 1, 2, 12, 5, 10, 14, 7, 1, 10, 13, 0, 6, 9, 8, 7, 4, 15, 14, 3, 11, 5, 2, 12],
    [7, 13, 14, 3, 0, 6, 9, 10, 1, 2, 8, 5, 11, 12, 4, 15, 13, 8, 11, 5, 6, 15, 0, 3, 4, 7, 2, 12, 1, 10, 14, 9, 10, 6, 9, 0, 12, 11, 7, 13, 15, 1, 3, 14, 5, 2, 8, 4, 3, 15, 0, 6, 10, 10, 13, 8, 9, 4, 5, 11, 12, 7, 2, 14],
    [2, 12, 4, 1, 7, 10, 11, 6, 8, 5, 3, 15, 13, 0, 14, 9, 14, 11, 2, 12, 4, 7, 13, 1, 5, 0, 15, 10, 3, 9, 8, 6, 4, 2, 1, 11, 10, 13, 7, 8, 15, 9, 12, 5, 6, 3, 0, 14, 11, 8, 12, 7, 1, 14, 2, 13, 6, 15, 0, 9, 10, 4, 5, 3],
    [12, 1, 10, 15, 9, 2, 6, 8, 0, 13, 3, 4, 14, 7, 5, 11, 10, 15, 4, 2, 7, 12, 9, 5, 6, 1, 13, 14, 0, 11, 3, 8, 9, 14, 15, 5, 2, 8, 12, 3, 7, 0, 4, 10, 1, 13, 11, 6, 4, 3, 2, 12, 9, 5, 15, 10, 11, 14, 1, 7, 6, 0, 8, 13],
    [4, 11, 2, 14, 15, 0, 8, 13, 3, 12, 9, 7, 5, 10, 6, 1, 13, 0, 11, 7, 4, 9, 1, 10, 14, 3, 5, 12, 2, 15, 8, 6, 1, 4, 11, 13, 12, 3, 7, 14, 10, 15, 6, 8, 0, 5, 9, 2, 6, 11, 13, 8, 1, 4, 10, 7, 9, 5, 0, 15, 14, 2, 3, 12],
    [13, 2, 8, 4, 6, 15, 11, 1, 10, 9, 3, 14, 5, 0, 12, 7, 1, 15, 13, 8, 10, 3, 7, 4, 12, 5, 6, 11, 0, 14, 9, 2, 7, 11, 4, 1, 9, 12, 14, 2, 0, 6, 10, 13, 15, 3, 5, 8, 2, 1, 14, 7, 4, 10, 8, 13, 15, 12, 9, 0, 3, 5, 6, 11],
  ];

  static QQMusicDecodedLyrics? parseLyricDownloadResponse(String responseBody) {
    final sanitized = responseBody
        .replaceAll('<!--', '')
        .replaceAll('-->', '')
        .replaceAll('miniversion="1"', 'miniversion');

    final lyric = _extractMappedLyricContent(sanitized, 'content');
    final trans = _extractMappedLyricContent(sanitized, 'contentts');
    final roma = _extractMappedLyricContent(sanitized, 'contentroma');

    if (_isBlank(lyric) && _isBlank(trans) && _isBlank(roma)) {
      return null;
    }

    return QQMusicDecodedLyrics(
      lyric: lyric?.trim(),
      trans: trans?.trim(),
      roma: roma?.trim(),
    );
  }

  static String? _extractMappedLyricContent(String xmlLikeText, String tagName) {
    final tagValue = _extractXmlInnerText(xmlLikeText, tagName);
    if (_isBlank(tagValue)) {
      return null;
    }

    final decoded = _decodeNestedLyricPayload(tagValue!.trim());
    if (_isBlank(decoded)) {
      return null;
    }

    final resolvedStructuredLyric = _extractStructuredLyric(decoded!);
    if (!_isBlank(resolvedStructuredLyric)) {
      return resolvedStructuredLyric;
    }

    return decoded;
  }

  static String? _extractStructuredLyric(String decoded) {
    if (!decoded.contains('<')) {
      return null;
    }

    final lyricContent = _decodeNestedLyricPayload(
      _extractXmlAttribute(decoded, 'Lyric_1', 'LyricContent'),
    );
    if (!_isBlank(lyricContent)) {
      return lyricContent;
    }

    for (final nestedTag in const ['content', 'contentts', 'contentroma']) {
      final nestedValue = _decodeNestedLyricPayload(
        _extractXmlInnerText(decoded, nestedTag),
      );
      if (!_isBlank(nestedValue)) {
        return nestedValue;
      }
    }

    return null;
  }

  static String? _decodeQrcPayload(String payload) {
    try {
      if (_isHexString(payload)) {
        final encryptedBytes = _hexToBytes(payload);
        final decryptedBytes = _decryptQrcBytes(encryptedBytes);
        return utf8.decode(ZLibDecoder().convert(decryptedBytes));
      }

      return _repairMojibake(payload);
    } catch (e) {
      AppLogger.debug('[QQMusic] Failed to decode QRC payload: $e');
      final repairedPayload = _repairMojibake(payload);
      return _looksLikeLrc(repairedPayload) ? repairedPayload : null;
    }
  }

  static String? _decodeNestedLyricPayload(String? payload, [int depth = 0]) {
    if (_isBlank(payload) || depth >= _maxQrcDecodeDepth) {
      return payload;
    }

    final normalized = _stripCdata(payload!.trim());
    final decoded = _decodeQrcPayload(normalized) ?? normalized;
    final resolvedStructured = _extractStructuredLyric(decoded);

    if (!_isBlank(resolvedStructured) && resolvedStructured != payload) {
      return _decodeNestedLyricPayload(resolvedStructured, depth + 1);
    }

    if (decoded != normalized) {
      return _decodeNestedLyricPayload(decoded, depth + 1);
    }

    return decoded;
  }

  static String _stripCdata(String value) {
    final match = RegExp(r'^<!\[CDATA\[([\s\S]*?)\]\]>$').firstMatch(value);
    return match?.group(1)?.trim() ?? value;
  }

  static String _repairMojibake(String value) {
    if (!_looksLikeMojibake(value)) {
      return value;
    }

    try {
      return utf8.decode(latin1.encode(value));
    } catch (_) {
      return value;
    }
  }

  static Uint8List _decryptQrcBytes(Uint8List encryptedBytes) {
    final schedule = _tripleDesKeySetup(_qrcKeyBytes, _decryptMode);
    final decrypted = BytesBuilder(copy: false);

    for (int i = 0; i < encryptedBytes.length; i += 8) {
      final block = Uint8List(8);
      final remaining = encryptedBytes.length - i;
      final copyLength = remaining >= 8 ? 8 : remaining;
      block.setRange(0, copyLength, encryptedBytes.sublist(i, i + copyLength));
      decrypted.add(_tripleDesCrypt(block, schedule));
    }

    return decrypted.toBytes();
  }

  static String? _extractXmlInnerText(String text, String tagName) {
    final match = RegExp(
      '<$tagName(?:\\s[^>]*)?>([\\s\\S]*?)</$tagName>',
      caseSensitive: false,
    ).firstMatch(text);
    if (match == null) {
      return null;
    }

    return _decodeXmlEntities(match.group(1)?.trim());
  }

  static String? _extractXmlAttribute(
    String text,
    String tagName,
    String attributeName,
  ) {
    if (tagName == 'Lyric_1' && attributeName == 'LyricContent') {
      final lyricContent = _extractLyricContentAttribute(text);
      if (!_isBlank(lyricContent)) {
        return _decodeXmlEntities(lyricContent?.trim());
      }
    }

    final match = RegExp(
      '<$tagName\\b[^>]*\\b$attributeName="([\\s\\S]*?)"[^>]*/?>',
      caseSensitive: false,
    ).firstMatch(text);
    if (match == null) {
      return null;
    }

    return _decodeXmlEntities(match.group(1)?.trim());
  }

  static String? _extractLyricContentAttribute(String text) {
    final startTag = text.indexOf('<Lyric_1');
    if (startTag == -1) {
      return null;
    }

    const attrToken = 'LyricContent="';
    final attrStart = text.indexOf(attrToken, startTag);
    if (attrStart == -1) {
      return null;
    }

    final valueStart = attrStart + attrToken.length;
    const endCandidates = ['" />', '"/>', '"></Lyric_1>', '" ></Lyric_1>'];

    int? bestEnd;
    for (final candidate in endCandidates) {
      final candidateIndex = text.indexOf(candidate, valueStart);
      if (candidateIndex == -1) {
        continue;
      }
      if (bestEnd == null || candidateIndex < bestEnd) {
        bestEnd = candidateIndex;
      }
    }

    if (bestEnd == null || bestEnd <= valueStart) {
      return null;
    }

    return text.substring(valueStart, bestEnd);
  }

  static String? _decodeXmlEntities(String? value) {
    if (value == null) {
      return null;
    }

    return value
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&amp;', '&');
  }

  static bool _isBlank(String? value) => value == null || value.trim().isEmpty;

  static bool _isHexString(String value) {
    final normalized = value.trim();
    return normalized.isNotEmpty &&
        normalized.length.isEven &&
        RegExp(r'^[0-9a-fA-F]+$').hasMatch(normalized);
  }

  static bool _looksLikeLrc(String value) {
    return value.contains('[') && value.contains(']');
  }

  static bool _looksLikeMojibake(String value) {
    return value.contains('Ã') ||
        value.contains('Â') ||
        value.contains('æ') ||
        value.contains('ä') ||
        value.contains('å') ||
        value.contains('ã') ||
        value.contains('ï');
  }

  static Uint8List _hexToBytes(String value) {
    final normalized = value.trim();
    final bytes = Uint8List(normalized.length ~/ 2);
    for (int i = 0; i < normalized.length; i += 2) {
      bytes[i ~/ 2] = int.parse(normalized.substring(i, i + 2), radix: 16);
    }
    return bytes;
  }

  static const int _encryptMode = 1;
  static const int _decryptMode = 0;

  static int _bitnum(Uint8List value, int bit, int shift) {
    final pos = (bit ~/ 32) * 4 + 3 - ((bit % 32) ~/ 8);
    return (((value[pos] >> (7 - bit % 8)) & 1) << shift) & 0xffffffff;
  }

  static int _bitnumIntr(int value, int bit, int shift) {
    return (((value >> (31 - bit)) & 1) << shift) & 0xffffffff;
  }

  static int _bitnumIntl(int value, int bit, int shift) {
    return (((value << bit) & 0x80000000) >> shift) & 0xffffffff;
  }

  static int _sboxBit(int value) {
    return (value & 32) | ((value & 31) >> 1) | ((value & 1) << 4);
  }

  static List<int> _initialPermutation(Uint8List inputData) {
    var s0 = 0;
    var s1 = 0;

    const s0Bits = [57, 49, 41, 33, 25, 17, 9, 1, 59, 51, 43, 35, 27, 19, 11, 3, 61, 53, 45, 37, 29, 21, 13, 5, 63, 55, 47, 39, 31, 23, 15, 7];
    const s1Bits = [56, 48, 40, 32, 24, 16, 8, 0, 58, 50, 42, 34, 26, 18, 10, 2, 60, 52, 44, 36, 28, 20, 12, 4, 62, 54, 46, 38, 30, 22, 14, 6];

    for (int i = 0; i < 32; i++) {
      s0 |= _bitnum(inputData, s0Bits[i], 31 - i);
      s1 |= _bitnum(inputData, s1Bits[i], 31 - i);
    }

    return [s0 & 0xffffffff, s1 & 0xffffffff];
  }

  static Uint8List _inversePermutation(int s0, int s1) {
    final data = Uint8List(8);
    const mappings = <({int byteIndex, int bitIndex, int shift, bool useS0})>[
      (byteIndex: 3, bitIndex: 7, shift: 7, useS0: false), (byteIndex: 3, bitIndex: 7, shift: 6, useS0: true), (byteIndex: 3, bitIndex: 15, shift: 5, useS0: false), (byteIndex: 3, bitIndex: 15, shift: 4, useS0: true), (byteIndex: 3, bitIndex: 23, shift: 3, useS0: false), (byteIndex: 3, bitIndex: 23, shift: 2, useS0: true), (byteIndex: 3, bitIndex: 31, shift: 1, useS0: false), (byteIndex: 3, bitIndex: 31, shift: 0, useS0: true),
      (byteIndex: 2, bitIndex: 6, shift: 7, useS0: false), (byteIndex: 2, bitIndex: 6, shift: 6, useS0: true), (byteIndex: 2, bitIndex: 14, shift: 5, useS0: false), (byteIndex: 2, bitIndex: 14, shift: 4, useS0: true), (byteIndex: 2, bitIndex: 22, shift: 3, useS0: false), (byteIndex: 2, bitIndex: 22, shift: 2, useS0: true), (byteIndex: 2, bitIndex: 30, shift: 1, useS0: false), (byteIndex: 2, bitIndex: 30, shift: 0, useS0: true),
      (byteIndex: 1, bitIndex: 5, shift: 7, useS0: false), (byteIndex: 1, bitIndex: 5, shift: 6, useS0: true), (byteIndex: 1, bitIndex: 13, shift: 5, useS0: false), (byteIndex: 1, bitIndex: 13, shift: 4, useS0: true), (byteIndex: 1, bitIndex: 21, shift: 3, useS0: false), (byteIndex: 1, bitIndex: 21, shift: 2, useS0: true), (byteIndex: 1, bitIndex: 29, shift: 1, useS0: false), (byteIndex: 1, bitIndex: 29, shift: 0, useS0: true),
      (byteIndex: 0, bitIndex: 4, shift: 7, useS0: false), (byteIndex: 0, bitIndex: 4, shift: 6, useS0: true), (byteIndex: 0, bitIndex: 12, shift: 5, useS0: false), (byteIndex: 0, bitIndex: 12, shift: 4, useS0: true), (byteIndex: 0, bitIndex: 20, shift: 3, useS0: false), (byteIndex: 0, bitIndex: 20, shift: 2, useS0: true), (byteIndex: 0, bitIndex: 28, shift: 1, useS0: false), (byteIndex: 0, bitIndex: 28, shift: 0, useS0: true),
      (byteIndex: 7, bitIndex: 3, shift: 7, useS0: false), (byteIndex: 7, bitIndex: 3, shift: 6, useS0: true), (byteIndex: 7, bitIndex: 11, shift: 5, useS0: false), (byteIndex: 7, bitIndex: 11, shift: 4, useS0: true), (byteIndex: 7, bitIndex: 19, shift: 3, useS0: false), (byteIndex: 7, bitIndex: 19, shift: 2, useS0: true), (byteIndex: 7, bitIndex: 27, shift: 1, useS0: false), (byteIndex: 7, bitIndex: 27, shift: 0, useS0: true),
      (byteIndex: 6, bitIndex: 2, shift: 7, useS0: false), (byteIndex: 6, bitIndex: 2, shift: 6, useS0: true), (byteIndex: 6, bitIndex: 10, shift: 5, useS0: false), (byteIndex: 6, bitIndex: 10, shift: 4, useS0: true), (byteIndex: 6, bitIndex: 18, shift: 3, useS0: false), (byteIndex: 6, bitIndex: 18, shift: 2, useS0: true), (byteIndex: 6, bitIndex: 26, shift: 1, useS0: false), (byteIndex: 6, bitIndex: 26, shift: 0, useS0: true),
      (byteIndex: 5, bitIndex: 1, shift: 7, useS0: false), (byteIndex: 5, bitIndex: 1, shift: 6, useS0: true), (byteIndex: 5, bitIndex: 9, shift: 5, useS0: false), (byteIndex: 5, bitIndex: 9, shift: 4, useS0: true), (byteIndex: 5, bitIndex: 17, shift: 3, useS0: false), (byteIndex: 5, bitIndex: 17, shift: 2, useS0: true), (byteIndex: 5, bitIndex: 25, shift: 1, useS0: false), (byteIndex: 5, bitIndex: 25, shift: 0, useS0: true),
      (byteIndex: 4, bitIndex: 0, shift: 7, useS0: false), (byteIndex: 4, bitIndex: 0, shift: 6, useS0: true), (byteIndex: 4, bitIndex: 8, shift: 5, useS0: false), (byteIndex: 4, bitIndex: 8, shift: 4, useS0: true), (byteIndex: 4, bitIndex: 16, shift: 3, useS0: false), (byteIndex: 4, bitIndex: 16, shift: 2, useS0: true), (byteIndex: 4, bitIndex: 24, shift: 1, useS0: false), (byteIndex: 4, bitIndex: 24, shift: 0, useS0: true),
    ];

    for (int i = 0; i < mappings.length; i += 8) {
      int value = 0;
      for (int j = 0; j < 8; j++) {
        final map = mappings[i + j];
        value |= _bitnumIntr(map.useS0 ? s0 : s1, map.bitIndex, map.shift);
      }
      data[mappings[i].byteIndex] = value;
    }

    return data;
  }

  static int _f(int state, List<int> key) {
    final uState = state & 0xffffffff;

    final t1 = (_bitnumIntl(uState, 31, 0) |
            ((uState & 0xF0000000) >> 1) |
            _bitnumIntl(uState, 4, 5) |
            _bitnumIntl(uState, 3, 6) |
            ((uState & 0x0F000000) >> 3) |
            _bitnumIntl(uState, 8, 11) |
            _bitnumIntl(uState, 7, 12) |
            ((uState & 0x00F00000) >> 5) |
            _bitnumIntl(uState, 12, 17) |
            _bitnumIntl(uState, 11, 18) |
            ((uState & 0x000F0000) >> 7) |
            _bitnumIntl(uState, 16, 23)) &
        0xffffffff;

    final t2 = (_bitnumIntl(uState, 15, 0) |
            ((uState & 0x0000F000) << 15) |
            _bitnumIntl(uState, 20, 5) |
            _bitnumIntl(uState, 19, 6) |
            ((uState & 0x00000F00) << 13) |
            _bitnumIntl(uState, 24, 11) |
            _bitnumIntl(uState, 23, 12) |
            ((uState & 0x000000F0) << 11) |
            _bitnumIntl(uState, 28, 17) |
            _bitnumIntl(uState, 27, 18) |
            ((uState & 0x0000000F) << 9) |
            _bitnumIntl(uState, 0, 23)) &
        0xffffffff;

    final lrgstateSource = [
      (t1 >> 24) & 0xff,
      (t1 >> 16) & 0xff,
      (t1 >> 8) & 0xff,
      (t2 >> 24) & 0xff,
      (t2 >> 16) & 0xff,
      (t2 >> 8) & 0xff,
    ];

    final lrgstate = List<int>.generate(
      6,
      (index) => lrgstateSource[index] ^ key[index],
    );

    final newState = ((_sbox[0][_sboxBit(lrgstate[0] >> 2)] << 28) |
            (_sbox[1][_sboxBit(((lrgstate[0] & 0x03) << 4) | (lrgstate[1] >> 4))] << 24) |
            (_sbox[2][_sboxBit(((lrgstate[1] & 0x0F) << 2) | (lrgstate[2] >> 6))] << 20) |
            (_sbox[3][_sboxBit(lrgstate[2] & 0x3F)] << 16) |
            (_sbox[4][_sboxBit(lrgstate[3] >> 2)] << 12) |
            (_sbox[5][_sboxBit(((lrgstate[3] & 0x03) << 4) | (lrgstate[4] >> 4))] << 8) |
            (_sbox[6][_sboxBit(((lrgstate[4] & 0x0F) << 2) | (lrgstate[5] >> 6))] << 4) |
            _sbox[7][_sboxBit(lrgstate[5] & 0x3F)]) &
        0xffffffff;

    final result = (_bitnumIntl(newState, 15, 0) |
            _bitnumIntl(newState, 6, 1) |
            _bitnumIntl(newState, 19, 2) |
            _bitnumIntl(newState, 20, 3) |
            _bitnumIntl(newState, 28, 4) |
            _bitnumIntl(newState, 11, 5) |
            _bitnumIntl(newState, 27, 6) |
            _bitnumIntl(newState, 16, 7) |
            _bitnumIntl(newState, 0, 8) |
            _bitnumIntl(newState, 14, 9) |
            _bitnumIntl(newState, 22, 10) |
            _bitnumIntl(newState, 25, 11) |
            _bitnumIntl(newState, 4, 12) |
            _bitnumIntl(newState, 17, 13) |
            _bitnumIntl(newState, 30, 14) |
            _bitnumIntl(newState, 9, 15) |
            _bitnumIntl(newState, 1, 16) |
            _bitnumIntl(newState, 7, 17) |
            _bitnumIntl(newState, 23, 18) |
            _bitnumIntl(newState, 13, 19) |
            _bitnumIntl(newState, 31, 20) |
            _bitnumIntl(newState, 26, 21) |
            _bitnumIntl(newState, 2, 22) |
            _bitnumIntl(newState, 8, 23) |
            _bitnumIntl(newState, 18, 24) |
            _bitnumIntl(newState, 12, 25) |
            _bitnumIntl(newState, 29, 26) |
            _bitnumIntl(newState, 5, 27) |
            _bitnumIntl(newState, 21, 28) |
            _bitnumIntl(newState, 10, 29) |
            _bitnumIntl(newState, 3, 30) |
            _bitnumIntl(newState, 24, 31)) &
        0xffffffff;

    return result;
  }

  static Uint8List _crypt(Uint8List inputData, List<List<int>> key) {
    final perm = _initialPermutation(inputData);
    var s0 = perm[0];
    var s1 = perm[1];

    for (int idx = 0; idx < 15; idx++) {
      final previousS1 = s1;
      s1 = (_f(s1, key[idx]) ^ s0) & 0xffffffff;
      s0 = previousS1;
    }
    s0 = (_f(s1, key[15]) ^ s0) & 0xffffffff;

    return _inversePermutation(s0, s1);
  }

  static List<List<int>> _keySchedule(Uint8List key, int mode) {
    final schedule = List.generate(16, (_) => List.filled(6, 0));
    const keyRndShift = [1, 1, 2, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 2, 1];
    const keyPermC = [56, 48, 40, 32, 24, 16, 8, 0, 57, 49, 41, 33, 25, 17, 9, 1, 58, 50, 42, 34, 26, 18, 10, 2, 59, 51, 43, 35];
    const keyPermD = [62, 54, 46, 38, 30, 22, 14, 6, 61, 53, 45, 37, 29, 21, 13, 5, 60, 52, 44, 36, 28, 20, 12, 4, 27, 19, 11, 3];
    const keyCompression = [13, 16, 10, 23, 0, 4, 2, 27, 14, 5, 20, 9, 22, 18, 11, 3, 25, 7, 15, 6, 26, 19, 12, 1, 40, 51, 30, 36, 46, 54, 29, 39, 50, 44, 32, 47, 43, 48, 38, 55, 33, 52, 45, 41, 49, 35, 28, 31];

    var c = 0;
    var d = 0;

    for (int i = 0; i < 28; i++) {
      c += _bitnum(key, keyPermC[i], 31 - i);
      d += _bitnum(key, keyPermD[i], 31 - i);
    }

    for (int i = 0; i < 16; i++) {
      c = (((c << keyRndShift[i]) | (c >> (28 - keyRndShift[i]))) & 0xFFFFFFF0);
      d = (((d << keyRndShift[i]) | (d >> (28 - keyRndShift[i]))) & 0xFFFFFFF0);

      final togen = mode == _decryptMode ? 15 - i : i;
      for (int j = 0; j < 6; j++) {
        schedule[togen][j] = 0;
      }

      for (int j = 0; j < 24; j++) {
        schedule[togen][j ~/ 8] |= _bitnumIntr(c, keyCompression[j], 7 - (j % 8));
      }
      for (int j = 24; j < 48; j++) {
        schedule[togen][j ~/ 8] |= _bitnumIntr(d, keyCompression[j] - 27, 7 - (j % 8));
      }
    }

    return schedule;
  }

  static List<List<List<int>>> _tripleDesKeySetup(Uint8List key, int mode) {
    if (mode == _encryptMode) {
      return [
        _keySchedule(key.sublist(0, 8), _encryptMode),
        _keySchedule(key.sublist(8, 16), _decryptMode),
        _keySchedule(key.sublist(16, 24), _encryptMode),
      ];
    }

    return [
      _keySchedule(key.sublist(16, 24), _decryptMode),
      _keySchedule(key.sublist(8, 16), _encryptMode),
      _keySchedule(key.sublist(0, 8), _decryptMode),
    ];
  }

  static Uint8List _tripleDesCrypt(Uint8List data, List<List<List<int>>> key) {
    var output = data;
    for (int i = 0; i < 3; i++) {
      output = _crypt(output, key[i]);
    }
    return output;
  }
}

class QQMusicDecodedLyrics {
  const QQMusicDecodedLyrics({
    required this.lyric,
    required this.trans,
    required this.roma,
  });

  final String? lyric;
  final String? trans;
  final String? roma;
}
