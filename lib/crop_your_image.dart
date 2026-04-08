import 'package:crop_your_image/src/logic/cropper/image_cropper.dart';
import 'package:crop_your_image/src/logic/cropper/legacy_image_image_cropper.dart';
import 'package:crop_your_image/src/logic/defaults/defaults.dart' as defaults;
import 'package:crop_your_image/src/logic/format_detector/format_detector.dart';
import 'package:crop_your_image/src/logic/parser/image_parser.dart';

export 'src/widget/widget.dart';
export 'src/logic/logic.dart';

final ImageParser defaultImageParser = defaults.defaultImageParser;
final FormatDetector defaultFormatDetector = defaults.defaultFormatDetector;
const ImageCropper defaultImageCropper = defaults.defaultImageCropper;
const legacyImageCropper = LegacyImageImageCropper();
