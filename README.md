# crop_your_image

A flutter plugin that provides `Crop` widget for cropping images.

![Image Cropping Preview](https://github.com/chooyan-eng/crop_your_image/raw/main/assets/cropyourimage.gif)

# Philosophy

crop_your_image provides _flexible_ and _custamizable_ `Crop` widget that can be placed at anywhere in your well designed apps.

As `Crop` is a simple widget displaying minimum cropping UI, `Crop` can be placed anywhere such as, for example, occupying entire screen, at top half of the screen, or even on dialogs or bottomsheets. It's totally up to you!

Users' cropping operation is also customizable. By default, images are fixed on the screen and users can move crop rect to decide where to crop. Once configured _interactive_ mode, images can be zoomed/panned, and crop rect can be configured as fixed.

`CropController` enables you to control _crop rect_ from outside of `Crop`. The controller allows you to run cropping (or related actions) from anywhere on your codebase.

Enjoy building your own cropping UI with __crop_your_image__!

## Features

- __Minimum UI restrictions__
- Flexible `Crop` widget __that can be placed anywhere__ on your widget tree
- `CropController` to control `Crop`
- __Zooming / panning__ images
- Crop with __rect__ or __circle__ whichever you want
- Fix __aspect ratio__
- Configure `Rect` of _crop rect_ programmatically
- Detect events of users' operation
- (advanced) Cropping backend logics are also customizable

Note that this package _DON'T_

- read / download image data from any storages, such as gallery, internet, etc.
- resize, tilt, or other conversions which can be done with [image](https://pub.dev/packages/image) package directly.
- provide UI parts other than cropping editor, such as buttons to control. Building UI is fully UP TO YOU!

## Usage

### Basics
Place `Crop` Widget wherever you want to place image cropping UI.

```dart
final _controller = CropController();

@override
Widget build(BuildContext context) {
  return Crop(
    image: _imageData, 
    controller: _controller,
    onCropped: (image) {
      // do something with cropped image data 
    }
  );
}
```

Then, `Crop` widget will automatically display cropping editor UI on users screen with given image.

By passing `CropController` instance to `controller` argument of `Crop`'s constructor, you can controll the `Crop` widget from anywhere on your source code.

For example, when you want to crop the image with the current crop rect, you can just call `_controller.crop()` whenever you want, such like the code below.

```dart
ElevatedButton(
  child: Text('Crop it!')
  onPressed: () => _cropController.crop(),
),
```

Because `_controller.crop()` only kicks the cropping process, this method returns immediately without any cropped image data. You can obtain the result of cropping images via `onCropped` callback of `Crop` Widget.

### List of configurations 
All the arguments of `Crop` and usages are below.

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
    // initialSize: 0.5,
    // initialArea: Rect.fromLTWH(240, 212, 800, 600),
    initialRectBuilder: (rect) => Rect.fromLTRB(
      rect.left + 24, rect.top + 32, rect.right - 24, rect.bottom - 32
    ), 
    // withCircleUi: true,
    baseColor: Colors.blue.shade900,
    maskColor: Colors.white.withAlpha(100),
    progressIndicator: const CircularProgressIndicator(),
    radius: 20,
    onMoved: (newRect) {
      // do something with current crop rect.
    },
    onStatusChanged: (status) {
      // do something with current CropStatus
    },
    willUpdateScale: (newScale) {
      // if returning false, scaling will be canceled
      return newScale < 5;
    },
    cornerDotBuilder: (size, edgeAlignment) => const DotControl(color: Colors.blue),
    clipBehavior: Clip.none,
    interactive: true,
    // fixCropRect: true,
    // formatDetector: (image) {},
    // imageCropper: myCustomImageCropper,
    // imageParser: (image, {format}) {},
  );
}
```

|argument|type|description|
|-|-|-|
|image|Uint8List|Original image data to be cropped. The result of cropping operation can be obtained via `onCropped` callback.|
|onCropped|void Function(Uint8List)|Callback called when cropping operation is completed.|
|controller|CropController|Controller for managing cropping operation.|
|aspectRatio|double?| Initial aspect ratio of crop rect. Set `null` or just omit if you want to crop images with any aspect ratio. `aspectRatio` can be changed dynamically via setter of `CropController.aspectRatio`. (see below)|
|initialSize|double?| is the initial size of crop rect. `1.0` (or `null`, by default) fits the size of image, which means crop rect extends as much as possible. `0.5` would be the half. This value is also referred when `aspectRatio` changes via `CropController.aspectRatio`.|
|initialArea|Rect?|Initial `Rect` of crop rect based on actual image size.|
|initialRectBuilder|Rect Function(Rect)|Callback to decide initial `Rect` of crop  rect based on viewport of `Crop` itself. `Rect` of `Crop`'s viewport is passed as an argument of the callback.|
|withCircleUi|bool|Flag to decide the shape of cropping UI. If `true`, the shape of cropping UI is circle and `aspectRatio` is automatically set `1.0`. Note that this flag does NOT affect to the result of cropping image. If you want cropped images with circle shape, call `CropController.cropCircle` instead of `CropController.crop`.|
|maskColor|Color?|Color of the mask widget which is placed over the cropping editor.|
|baseColor|Color?|Color of the base color of the cropping editor.|
|radius|double?|Corner radius of crop rect.|
|onMoved|void Function(Rect)?|Callback called when crop rect is moved regardless of its reasons. `newRect` of argument is current `Rect` of crop rect.|
|onStatusChanged|void Function(CropStatus)?|Callback called when status of Crop is changed.|
|willUpdateScale|bool Function(double)?|Callback called before scale changes on _interactive_ mode. By returning `false` to this callback, updating scale will be canceled.|
|cornerDotBuilder|Widget Function(Size, EdgeAlignment)?|Builder function to build Widget placed at four corners used to move crop rect. The builder passes `size` which widget must follow and `edgeAlignment` which indicates the position.|
|progressIndicator|Widget?|Widget for showing preparing image is in progress. Nothing (`SizedBox.shrink()` actually) is shown by default.|
|interactive|bool?|Flag to enable _interactive_ mode that users can move / zoom images. `false` by default|
|fixCropRect|bool?|Flag if crop rect should be fixed on _interactive_ mode. `false` by default|
|clipBehavior|Clip?|Decide clipping strategy for `Crop`. `Clip.hardEdge` by default|

### for Web

|argument|type|description|
|-|-|-|
|scrollZoomSensitivity|double?|Sensitivity for zoom gesture using mouse-wheel. For web applications only.|

### Advanced

`crop_your_image` also allows you to customize backend logic for 

- detecting the format of the image
- detecting detail information (width / height) of the image
- cropping

by passing the arguments below.

|argument|type|description|
|-|-|-|
|formatDetector|ImageFormat Function(Uint8List)?|Function to detect the format of original image. By detecting the format before `imageParser` parses the original image from `Uint8List` to `ImageDetail`, `imageParser` will sufficiently parse the binary, which means the initializing operation speeds up. `defaultFormatDetector` is used by default|
|imageParser|ImageDetail<T> Function(Uint8List, {ImageFormat})?|Function for parsing original image from `Uint8List` to `ImageDetail`, which preserve `height`, `width` and parsed `image` with generic type `<T>`. `image` is passed to `imageCropper` with `Rect` to be cropped. `defaultImageParser` is used by default|
|imageCropper|ImageCropper<T>?|By implementing `ImageCropeper<T>` and passing its instance to this argument, you can exchange cropping logic. `defaultImageCropper` is used by default|

# Gallery App

The repository below is for a sample app of using crop_your_image.
|
[chooyan-eng/crop_your_image_gallery](https://github.com/chooyan-eng/crop_your_image_gallery)

You can find several examples with executable source codes here.

# Contact

If you have anything you want to inform me ([@chooyan-eng](https://github.com/chooyan-eng)), such as suggestions to enhance this package or functionalities you want etc, feel free to make [issues on GitHub](https://github.com/chooyan-eng/crop_your_image/issues) or send messages on X [@tsuyoshi_chujo](https://x.com/tsuyoshi_chujo) (Japanese [@chooyan_i18n](https://x.com/chooyan_i18n)).