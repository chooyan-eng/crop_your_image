import 'dart:typed_data';

import 'package:crop_your_image/src/logic/format_detector/format.dart';
import 'package:crop_your_image/src/logic/format_detector/format_detector.dart';
import 'package:crop_your_image/src/logic/parser/errors.dart';
import 'package:crop_your_image/src/logic/parser/image_detail.dart';
import 'package:crop_your_image/src/logic/parser/image_parser.dart';

/// Detects common image formats by inspecting the file header.
final FormatDetector imageHeaderFormatDetector = (Uint8List data) {
  if (_isPng(data)) {
    return ImageFormat.png;
  }
  if (_isJpeg(data)) {
    return ImageFormat.jpeg;
  }
  if (_isWebp(data)) {
    return ImageFormat.webp;
  }
  if (_isBmp(data)) {
    return ImageFormat.bmp;
  }
  if (_isIco(data)) {
    return ImageFormat.ico;
  }
  return ImageFormat.png;
};

/// Parses image dimensions without fully decoding image pixels.
///
/// This is especially useful on Flutter web where [compute] executes on the
/// browser UI thread and full Dart image decoding can block rendering.
final ImageParser<Uint8List> imageHeaderParser = (data, {inputFormat}) {
  final format = inputFormat ?? imageHeaderFormatDetector(data);
  late final ImageHeaderSize size;
  try {
    size = readImageHeaderSize(data, format);
  } on FormatException {
    throw InvalidInputFormatException(format);
  }
  return ImageDetail(
    image: data,
    width: size.width.toDouble(),
    height: size.height.toDouble(),
  );
};

ImageHeaderSize readImageHeaderSize(Uint8List data, ImageFormat format) {
  return switch (format) {
    ImageFormat.jpeg => _readJpegSize(data),
    ImageFormat.webp => _readWebpSize(data),
    ImageFormat.bmp => _readBmpSize(data),
    ImageFormat.ico => _readIcoSize(data),
    ImageFormat.png => _readPngSize(data),
  };
}

class ImageHeaderSize {
  const ImageHeaderSize(this.width, this.height);

  final int width;
  final int height;
}

ImageHeaderSize _readPngSize(Uint8List data) {
  if (!_isPng(data) || data.length < 24) {
    throw const FormatException('Invalid PNG image.');
  }
  final bytes = ByteData.sublistView(data);
  return ImageHeaderSize(
    bytes.getUint32(16, Endian.big),
    bytes.getUint32(20, Endian.big),
  );
}

ImageHeaderSize _readJpegSize(Uint8List data) {
  if (!_isJpeg(data)) {
    throw const FormatException('Invalid JPEG image.');
  }

  var orientation = 1;
  var index = 2;
  while (index + 9 < data.length) {
    while (index < data.length && data[index] != 0xFF) {
      index += 1;
    }
    while (index < data.length && data[index] == 0xFF) {
      index += 1;
    }
    if (index >= data.length) {
      break;
    }

    final marker = data[index];
    index += 1;
    if (marker == 0xD8 || marker == 0xD9) {
      continue;
    }
    if (index + 1 >= data.length) {
      break;
    }

    final segmentLength = (data[index] << 8) + data[index + 1];
    if (segmentLength < 2 || index + segmentLength > data.length) {
      break;
    }

    if (marker == 0xE1) {
      orientation = _readExifOrientation(data, index + 2, segmentLength - 2) ??
          orientation;
    }

    if (_isStartOfFrame(marker) && segmentLength >= 7) {
      final height = (data[index + 3] << 8) + data[index + 4];
      final width = (data[index + 5] << 8) + data[index + 6];
      return _applyJpegOrientation(width, height, orientation);
    }

    index += segmentLength;
  }

  throw const FormatException('Could not read JPEG dimensions.');
}

ImageHeaderSize _applyJpegOrientation(
  int width,
  int height,
  int orientation,
) {
  return switch (orientation) {
    5 || 6 || 7 || 8 => ImageHeaderSize(height, width),
    _ => ImageHeaderSize(width, height),
  };
}

int? _readExifOrientation(Uint8List data, int start, int length) {
  final end = start + length;
  if (length < 14 || start < 0 || end > data.length) {
    return null;
  }
  if (!_hasExifHeader(data, start)) {
    return null;
  }

  final tiffStart = start + 6;
  final endian = switch ((data[tiffStart], data[tiffStart + 1])) {
    (0x49, 0x49) => Endian.little,
    (0x4D, 0x4D) => Endian.big,
    _ => null,
  };
  if (endian == null) {
    return null;
  }

  final bytes = ByteData.sublistView(data);
  if (bytes.getUint16(tiffStart + 2, endian) != 42) {
    return null;
  }

  final ifdStart = tiffStart + bytes.getUint32(tiffStart + 4, endian);
  if (ifdStart < tiffStart || ifdStart + 2 > end) {
    return null;
  }

  final entryCount = bytes.getUint16(ifdStart, endian);
  var entryStart = ifdStart + 2;
  for (var index = 0; index < entryCount; index += 1) {
    if (entryStart + 12 > end) {
      return null;
    }

    final tag = bytes.getUint16(entryStart, endian);
    final type = bytes.getUint16(entryStart + 2, endian);
    final count = bytes.getUint32(entryStart + 4, endian);
    if (tag == 0x0112 && type == 3 && count == 1) {
      return bytes.getUint16(entryStart + 8, endian);
    }
    entryStart += 12;
  }

  return null;
}

ImageHeaderSize _readWebpSize(Uint8List data) {
  if (!_isWebp(data) || data.length < 30) {
    throw const FormatException('Invalid WEBP image.');
  }

  final chunk = _ascii(data, 12, 16);
  if (chunk == 'VP8X') {
    return ImageHeaderSize(
        _readUint24(data, 24) + 1, _readUint24(data, 27) + 1);
  }
  if (chunk == 'VP8L' && data.length >= 25 && data[20] == 0x2F) {
    final bits =
        data[21] | (data[22] << 8) | (data[23] << 16) | (data[24] << 24);
    return ImageHeaderSize((bits & 0x3FFF) + 1, ((bits >> 14) & 0x3FFF) + 1);
  }
  if (chunk == 'VP8 ' && data.length >= 30) {
    final width = (data[26] | (data[27] << 8)) & 0x3FFF;
    final height = (data[28] | (data[29] << 8)) & 0x3FFF;
    return ImageHeaderSize(width, height);
  }

  throw const FormatException('Could not read WEBP dimensions.');
}

ImageHeaderSize _readBmpSize(Uint8List data) {
  if (!_isBmp(data) || data.length < 26) {
    throw const FormatException('Invalid BMP image.');
  }
  final bytes = ByteData.sublistView(data);
  final width = bytes.getInt32(18, Endian.little);
  final height = bytes.getInt32(22, Endian.little).abs();
  return ImageHeaderSize(width, height);
}

ImageHeaderSize _readIcoSize(Uint8List data) {
  if (!_isIco(data) || data.length < 8) {
    throw const FormatException('Invalid ICO image.');
  }
  return ImageHeaderSize(
    data[6] == 0 ? 256 : data[6],
    data[7] == 0 ? 256 : data[7],
  );
}

bool _isPng(Uint8List data) {
  return data.length >= 24 &&
      data[0] == 0x89 &&
      data[1] == 0x50 &&
      data[2] == 0x4E &&
      data[3] == 0x47 &&
      data[4] == 0x0D &&
      data[5] == 0x0A &&
      data[6] == 0x1A &&
      data[7] == 0x0A;
}

bool _isJpeg(Uint8List data) {
  return data.length >= 4 && data[0] == 0xFF && data[1] == 0xD8;
}

bool _isWebp(Uint8List data) {
  return data.length >= 16 &&
      _ascii(data, 0, 4) == 'RIFF' &&
      _ascii(data, 8, 12) == 'WEBP';
}

bool _isBmp(Uint8List data) {
  return data.length >= 26 && data[0] == 0x42 && data[1] == 0x4D;
}

bool _isIco(Uint8List data) {
  return data.length >= 8 &&
      data[0] == 0x00 &&
      data[1] == 0x00 &&
      (data[2] == 0x01 || data[2] == 0x02) &&
      data[3] == 0x00 &&
      (data[4] | (data[5] << 8)) > 0;
}

bool _isStartOfFrame(int marker) {
  return marker == 0xC0 ||
      marker == 0xC1 ||
      marker == 0xC2 ||
      marker == 0xC3 ||
      marker == 0xC5 ||
      marker == 0xC6 ||
      marker == 0xC7 ||
      marker == 0xC9 ||
      marker == 0xCA ||
      marker == 0xCB ||
      marker == 0xCD ||
      marker == 0xCE ||
      marker == 0xCF;
}

bool _hasExifHeader(Uint8List data, int start) {
  return data[start] == 0x45 &&
      data[start + 1] == 0x78 &&
      data[start + 2] == 0x69 &&
      data[start + 3] == 0x66 &&
      data[start + 4] == 0x00 &&
      data[start + 5] == 0x00;
}

int _readUint24(Uint8List data, int offset) {
  return data[offset] | (data[offset + 1] << 8) | (data[offset + 2] << 16);
}

String _ascii(Uint8List data, int start, int end) {
  if (data.length < end) {
    return '';
  }
  return String.fromCharCodes(data.sublist(start, end));
}
