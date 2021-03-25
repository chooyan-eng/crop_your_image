# crop_your_image

A flutter plugin which provides `Crop` Widget for cropping images.

crop_your_image provides only minimum UI for deciding cropping area inside images. Other UI parts, such as "Crop" button or "Change Aspect Ratio" button, need to be prepared by each app developers.

This policy helps app developers to build "Cropping page" with the design of their own brand.In order to control the actions for cropping images, you can use `CropController` from whatever your Widgets.

![Image Cropping Preview](https://github.com/chooyan-eng/crop_your_image_gallery/raw/main/screenshots/cyig_3.gif)

## Note

Please note that this package is at the very starting point of developping. Some functionality may lack, APIs have to be more enhanced, and several bugs have to be fixed.

I will appreciate your idea or suggestions to achieve the basic idea written above.

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
    withCircleUi: false,
    baseColor: Colors.blue.shade900,
    maskColor: Colors.white.withAlpha(100),
    onMoved: (newRect) {
      // do something with current cropping area.
    }
    cornerDotBuilder: (size, cornerIndex) => const DotControl(color: Colors.blue),
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
- `cornerDotBuilder` is the builder to build Widget placed at corners. The builder passes `size` which widget must follow and `cornerIndex` which indicates the position: 0: left-top, 1: right-top, 2: left-bottom, 3: right-bottom.

In addition, `image`, `aspectRatio`, `withCircleUi`, `rect` and `area` can also be changed via `CropController`, and other properties, such as `baseColor`, `maskColor` and `cornerDotBuilder`, can be changed by `setState`.

# Contact

If you have anything you want to inform me ([@chooyan-eng](https://github.com/chooyan-eng)), such as suggestions to enhance this package or functionalities you want etc, feel free to make [issues on GitHub](https://github.com/chooyan-eng/crop_your_image/issues) or send messages on Twitter [@chooyan_i18n](https://twitter.com/chooyan_i18n).