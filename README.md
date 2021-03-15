# crop_your_image

A flutter plugin which provides a Widget for cropping images.

crop_your_image is controllable via `CropController` from whatever your Widgets designed with your brand.

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
    onCropped: (image) {
      // do something with image data 
    }
  );
}
```
`image` is Image data whose type is `UInt8List`, and the result of cropping can be obtained via `onCropped` callback.

`aspectRatio` is the aspect ratio of cropping area. Set `null` or just omit if you want to crop images with any aspect ratio.

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