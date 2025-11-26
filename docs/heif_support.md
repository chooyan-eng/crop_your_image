# HEIF/HEIC Image Support

## Overview

Starting from version 2.1.0, `crop_your_image` supports HEIF (High Efficiency Image Format) and HEIC formats, which are commonly used by iOS devices for photos. The package automatically detects and converts these formats for cropping operations.

## What is HEIF/HEIC?

HEIF (High Efficiency Image Format) and HEIC (the specific variant used by Apple) are modern image formats that provide better compression than JPEG while maintaining similar or better image quality. iOS devices have been using HEIC as the default photo format since iOS 11.

## How It Works

The package automatically:
1. **Detects** HEIF/HEIC format by examining the file signature
2. **Converts** the image to JPEG format using platform-specific helpers
3. **Processes** the converted image for cropping

This happens seamlessly in the background - you don't need to change your code!

## Usage

Simply pass HEIF/HEIC image data to the `Crop` widget as you would with any other format:

```dart
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

class MyCropScreen extends StatelessWidget {
  final Uint8List imageData; // Can be HEIF, HEIC, JPEG, PNG, etc.
  final _controller = CropController();

  @override
  Widget build(BuildContext context) {
    return Crop(
      image: imageData, // HEIF/HEIC will be automatically detected and converted
      controller: _controller,
      onCropped: (result) {
        switch(result) {
          case CropSuccess(:final croppedImage):
            // Handle cropped image (always in JPEG format)
            print('Cropped successfully!');
          case CropFailure(:final cause, :final stackTrace):
            // Handle error
            print('Crop failed: $cause');
        }
      },
    );
  }
}
```

## Error Handling

If HEIF conversion fails (e.g., on unsupported platforms or due to corrupted data), the package will throw an `UnsupportedImageFormatException` with a descriptive message:

```dart
Crop(
  image: imageData,
  controller: _controller,
  onCropped: (result) {
    switch(result) {
      case CropSuccess(:final croppedImage):
        // Success
      case CropFailure(:final cause):
        if (cause is UnsupportedImageFormatException) {
          // Handle unsupported format error
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Unsupported Format'),
              content: Text(cause.toString()),
            ),
          );
        }
    }
  },
);
```

## Platform Support

HEIF/HEIC conversion is supported on:
- **iOS / Android**: [`heic_to_png_jpg`](https://pub.dev/packages/heic_to_png_jpg) leverages the native `heif_converter` plugin under the hood (Android 8.0+ / API 26+ required)
- **Web**: [`heic_to_png_jpg`](https://pub.dev/packages/heic_to_png_jpg) ships a Web implementation backed by `libheif-js`
- **macOS**: [`flutter_image_compress`](https://pub.dev/packages/flutter_image_compress) converts HEIC payloads to JPEG on-device (macOS 10.15+)
- **Windows / Linux / Fuchsia**: HEIF conversion is currently not available

## Performance Considerations

- HEIF/HEIC conversion happens on the main isolate (UI thread) because it requires platform channel communication
- For other formats (JPEG, PNG, etc.), the package uses Flutter's `compute()` function to perform decoding on a background isolate
- The conversion is typically fast, but for very large images, you may notice a brief delay

## Example: Loading from iOS Photo Library

When using packages like `image_picker` or `photo_manager` to select images from the iOS photo library, you'll often get HEIF/HEIC images. Here's how to handle them:

```dart
import 'package:image_picker/image_picker.dart';
import 'package:crop_your_image/crop_your_image.dart';

Future<void> pickAndCropImage() async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
  
  if (pickedFile != null) {
    final imageBytes = await pickedFile.readAsBytes();
    
    // Navigate to crop screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CropScreen(imageData: imageBytes),
      ),
    );
  }
}

class CropScreen extends StatelessWidget {
  final Uint8List imageData;
  final _controller = CropController();
  
  CropScreen({required this.imageData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crop Image'),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: () => _controller.crop(),
          ),
        ],
      ),
      body: Crop(
        image: imageData, // Automatically handles HEIF/HEIC
        controller: _controller,
        onCropped: (result) {
          switch(result) {
            case CropSuccess(:final croppedImage):
              // Handle cropped image
              Navigator.pop(context, croppedImage);
            case CropFailure(:final cause):
              // Handle error
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Crop failed: $cause')),
              );
          }
        },
      ),
    );
  }
}
```

## Troubleshooting

### "Failed to convert HEIF/HEIC image" Error

This error occurs when the platform cannot convert the HEIF/HEIC image. Possible causes:

1. **Unsupported Platform**: Web and some desktop platforms may not support HEIF conversion
2. **Old Android Version**: Android versions below 8.0 (API 26) don't have native HEIF support
3. **Corrupted Image Data**: The image file may be corrupted or not actually in HEIF format

**Solution**: Consider converting images to JPEG on the device before passing to the crop widget, or provide a fallback mechanism.

### Slow Performance on Large Images

If you're experiencing slow performance with large HEIF images:

1. **Resize before cropping**: Use the `image_picker` package's `maxWidth` and `maxHeight` parameters
2. **Use thumbnails**: For preview purposes, load a smaller version first
3. **Show loading indicator**: Inform users that the image is being processed

```dart
bool _isLoading = true;

@override
Widget build(BuildContext context) {
  return Stack(
    children: [
      Crop(
        image: imageData,
        controller: _controller,
        onStatusChanged: (status) {
          if (status == CropStatus.ready) {
            setState(() => _isLoading = false);
          }
        },
        onCropped: (result) { /* ... */ },
      ),
      if (_isLoading)
        Center(child: CircularProgressIndicator()),
    ],
  );
}
```

## Dependencies

HEIF support is provided by the [`heic_to_png_jpg`](https://pub.dev/packages/heic_to_png_jpg) (Android/iOS/Web) and [`flutter_image_compress`](https://pub.dev/packages/flutter_image_compress) (macOS) packages, which are automatically included as dependencies.

## Migration from Earlier Versions

If you were previously handling the assertion error "Failed assertion: line 20 pos 10: 'tempImage != null'" when loading HEIF images, you can now safely remove any workarounds. The package will:

1. Automatically detect HEIF/HEIC format
2. Convert it to a supported format
3. Provide proper error messages if conversion fails

No code changes are required - just update to the latest version!
