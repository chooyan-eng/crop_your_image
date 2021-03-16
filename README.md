# crop_your_image

A flutter plugin which provides `Crop` Widget for cropping images.

crop_your_image provides only minimum UI for deciding cropping area inside images. Other UI parts, such as "Crop" button or "Change Aspect Ratio" button, need to be prepared by each app developers.

This policy helps app developers to build "Cropping page" with the design of their own brand.In order to control the actions for cropping images, you can use `CropController` from whatever your Widgets.

![Image Cropping Preview](https://github.com/chooyan-eng/crop_your_image/raw/main/assets/cropyourimage.gif)

## Note

Please note that this package is developping (not achieved even alpha). It doesn't have enough functionality, is quite buggy, isn't available confortably.

The basic idea is written above. I will appreciate your idea or suggestions to achieve it.

## Usage

Place `Crop` Widget wherever you want to place image cropping UI.

```
Widget build(BuildContext context) {
  return Crop(
    image: _imageData,
    aspectRatio: 4 / 3,
    initialSize: 0.5,
    withCircleUi: false,
    onCropped: (image) {
      // do something with image data 
    }
  );
}
```
Usage of each properties are listed below.

- `image` is Image data whose type is `UInt8List`, and the result of cropping can be obtained via `onCropped` callback.
- `aspectRatio` is the aspect ratio of cropping area. Set `null` or just omit if you want to crop images with any aspect ratio.
- `aspectRatio` can be changed dynamically via setter of `CropController.aspectRatio`. (see below)
- `initialSize` is the initial size of cropping area. `1.0` (or `null`, by default) fits the size of image, which means cropping area extends as much as possible. `0.5` would be the half. This value is also referred when `aspectRatio` changes via `CropController.aspectRatio`.
- `withCircleUi` flag is to decide the shape of cropping UI. If `true`, `aspectRatio` is automatically set `1.0` and the shape of cropping UI would be circle. Note that this flag does NOT affect to the result of cropping image. If you want cropped images with circle shape, call `CropController.cropCircle` instead of `CropController.crop`.

If you want to controll from your own designed Widgets, create a `CropController` instance and pass it to `controller` property of `Crop`.
```
final _controller = CropController();

Widget build(BuildContext context) {
  return Crop(
    image: _imageData,
    onCropped: (image) {
      // do something with image data 
    }
    controller: _controller,
  );
}
```

You can call `_controller.crop()` to crop a image.

```
ElevatedButton(
  child: Text('Crop it!')
  onPressed: _cropController.crop,
),
```

Because `_controller.crop()` only kicks the cropping process, this method returns immediately without any cropped image data. You can always obtain the result of cropping images via `onCropped` callback of `Crop` Widget.

# Contact

If you have anything you want to inform me (@chooyan-eng), such as suggestions to enhance this package or functionalities you want etc, feel free to make [issues on GitHub](https://github.com/chooyan-eng/crop_your_image/issues) or send messages on Twitter [@chooyan_i18n](https://twitter.com/chooyan_i18n).