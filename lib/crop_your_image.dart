import 'package:crop_your_image/src/logic/cropper/image_image_cropper.dart';
import 'package:crop_your_image/src/logic/format_detector/format_detector.dart';
import 'package:crop_your_image/src/logic/parser/image_image_parser.dart';

export 'src/widget/widget.dart';
export 'src/logic/logic.dart';

final defaultImageParser = imageImageParser;

// TODO(chooyan-eng): implement format detector if possible
const FormatDetector? defaultFormatDetector = null;

const defaultImageCropper = ImageImageCropper();
