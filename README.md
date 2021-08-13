# crop_your_image

A flutter plugin which provides `Crop` Widget for cropping images.

crop_your_image provides only minimum UI for deciding cropping area inside images. Other UI parts, such as "Crop" button or "Change Aspect Ratio" button, need to be prepared by each app developers.

This policy helps app developers to build "Cropping page" with the design of their own brand.In order to control the actions for cropping images, you can use `CropController` from whatever your Widgets.

![Image Cropping Preview](https://github.com/chooyan-eng/crop_your_image/raw/main/assets/cropyourimage.gif)

## Features

- __Minimum UI restrictions__.
- Flexible `Crop` widget which __can be placed anywhere__ on your widget tree.
- `CropController` to control crop actions.
- Crop with both __rect__ and __circle__
- Fix __aspect ratio__.
- Set the rect of cropping area programmatically.

Note that this package _DON'T_

- read / download image data from any storages, such as gallery, internet, etc.
- resize, tilt, or other conversions which can be done with [image](https://pub.dev/packages/image) package directly.
- provide UI parts other than cropping editor, such as "Crop" button, "Preview" button or "Change Aspect Ratio" menu. Building UI is completely UP TO YOU!

## Note

Please note that this package is at the very starting point of developping. I'm always waiting for your [feedbacks](https://github.com/chooyan-eng/crop_your_image/issues) and [Pull Requests](https://github.com/chooyan-eng/crop_your_image/pulls) for making crop_your_image more handy and useful with less bugs.

## Usage

### Basics
Place `Crop` Widget wherever you want to place image cropping UI.

```dart
final _controller = CropController();

Widget build(BuildContext context) {
  return Crop(
    image: _imageData,
    controller: _controller,
    onCropped: (image) {
      // do something with image data 
    }
  );
}
```
Then, `Crop` widget will automatically display cropping editor UI on users screen with given image.

By creating a `CropController` instance and pass it to `controller` property of `Crop`, you can controll the `Crop` widget from your own designed Widgets.

For example, when you want to crop the image with current selected cropping area, you can just call `_controller.crop()` wherever you want, such like the code below.

```dart
ElevatedButton(
  child: Text('Crop it!')
  onPressed: _cropController.crop,
),
```

Because `_controller.crop()` only kicks the cropping process, this method returns immediately without any cropped image data. You can always obtain the result of cropping images via `onCropped` callback of `Crop` Widget.

### Advanced
All the properties of `Crop` and their usages are below.

```dart
final _controller = CropController();

Widget build(BuildContext context) {
  return Crop(
    image: _imageData,
    controller: _controller,
    onCropped: (image) {
      // do something with image data 
    },
    aspectRatio: 4 / 3,
    initialSize: 0.5,
    // initialArea: Rect.fromLTWH(240, 212, 800, 600),
    // withCircleUi: true,
    baseColor: Colors.blue.shade900,
    maskColor: Colors.white.withAlpha(100),
    onMoved: (newRect) {
      // do something with current cropping area.
    },
    onStatusChanged: (status) {
      // do something with current CropStatus
    }
    cornerDotBuilder: (size, edgeAlignment) => const DotControl(color: Colors.blue),
  );
}
```

- `image` is Image data whose type is `UInt8List`, and the result of cropping can be obtained via `onCropped` callback.
- `aspectRatio` is the aspect ratio of cropping area. Set `null` or just omit if you want to crop images with any aspect ratio.
- `aspectRatio` can be changed dynamically via setter of `CropController.aspectRatio`. (see below)
- `initialSize` is the initial size of cropping area. `1.0` (or `null`, by default) fits the size of image, which means cropping area extends as much as possible. `0.5` would be the half. This value is also referred when `aspectRatio` changes via `CropController.aspectRatio`.
- `initialArea` is the initial `Rect` of cropping area based on actual image data.
- `withCircleUi` flag is to decide the shape of cropping UI. If `true`, `aspectRatio` is automatically set `1.0` and the shape of cropping UI would be circle. Note that this flag does NOT affect to the result of cropping image. If you want cropped images with circle shape, call `CropController.cropCircle` instead of `CropController.crop`.
- `baseColor` is the color of the mask widget which is placed over the cropping editor.
- `maskColor` is the color of the base color of the cropping editor.
- `onMoved` callback is called when cropping area is moved regardless of its reasons. `newRect` of argument is current `Rect` of cropping area.
- `onStatusChanged` callback is called when status of Crop is changed.
- `cornerDotBuilder` is the builder to build Widget placed at corners. The builder passes `size` which widget must follow and `edgeAlignment` which indicates the position.

In addition, `image`, `aspectRatio`, `withCircleUi`, `rect` and `area` can also be changed via `CropController`, and other properties, such as `baseColor`, `maskColor` and `cornerDotBuilder`, can be changed by `setState`.

# Gallery App

The repository below is for a sample app of using crop_your_image.

[chooyan-eng/crop_your_image_gallery](https://github.com/chooyan-eng/crop_your_image_gallery)

You can find several examples with executable source codes here.

# Contact

If you have anything you want to inform me ([@chooyan-eng](https://github.com/chooyan-eng)), such as suggestions to enhance this package or functionalities you want etc, feel free to make [issues on GitHub](https://github.com/chooyan-eng/crop_your_image/issues) or send messages on Twitter [@chooyan_i18n](https://twitter.com/chooyan_i18n).