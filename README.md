# crop_your_image

A flutter plugin which provides a Widget for cropping images.

crop_your_image is controllable via `CropController` from whatever your Widgets designed with your brand.

## Note

Please note that this package is developping (not achieved even alpha). It doesn't have enough functionality, is quite buggy, isn't available confortably.

The basic idea is written above. I will appreciate your idea or suggestions to achieve it.

## Usage

Place `Crop` Widget wherever you want.

```
Widget build(BuildContext context) {
  return Crop(
    imageName: 'assets/images/big_pic.png',
  );
}
```

If you want to controll from your own designed Widgets, create `CropController` and pass it to `controller` property of `Crop`.

```
final _controller = CropController();

Widget build(BuildContext context) {
  return Crop(
    imageName: 'assets/images/big_pic.png',
    controller: _controller,
  );
}
```

You can call `_controller.crop()` to crop a image.

```
child: ElevatedButton(
  child: Text('Crop it!')
  onPressed: _cropController.crop,
),
```