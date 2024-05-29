## [1.1.0] - 2024.5.29
* apply changes of latest version of `image` package

## [1.0.2] - 2024.2.26
* fix bug of causing `InvalidRectError` unexpectedly

## [1.0.1] - 2024.2.11
* fix bug of `withCircleUi` not working

## [1.0.0] - 2024.2.11
* `crop_your_image` is now stable!
* well architectured and tested
* works also on Web / Desktop 
* backend logic is also interchangeable
* some breaking changes. see [migration guide](https://github.com/chooyan-eng/crop_your_image/issues/133).

## [1.0.0-dev.4] - 2024.2.10
* `interactive` is now available for macOS! 
* fix a tiny bug

## [1.0.0-dev.3] - 2024.2.10
* Rename some arguments of `Crop` and setter of `CropController`. See [migration guide](https://github.com/chooyan-eng/crop_your_image/issues/133).
* `interactive` is now available for Web!

## [1.0.0-dev.2] - 2024.2.9
* Add test codes and fix some bugs.
* Update README.md
* Add `clipBehavior`.
* Rename `allowScale` to `willUpdateScale`.

## [1.0.0-dev.1] - 2024.2.8
* Refactor and update the architecture of the entire codebase.
* Add injecting backend logic features.
* Add `allowScale` flag.

## [0.7.5] - 2023.6.5
* Update Fluter version to 3.10.3

## [0.7.4] - 2023.1.10
* Update versions of depencencies.

## [0.7.3] - 2022.11.15
* Add `progressIndicator` parameter to pass a Widget indicating progress.
* Updated versions of dependencies.

## [0.7.2] - 2022.03.16
* Enhanced zooming / panning behavior

## [0.7.1] - 2022.03.13
* Add `initialAreaBuilder` parameter to configure inital cropping area based on viewport of `Crop`.
* Add `radius` parameter to configure corner radius of cropping area.
* Control image scale not to be smaller than cropping area.
* Calculate initial scale to cover cropping area.
* Fix bug image could't be bigger than certain scale.

## [0.7.0] - 2022.03.08
* Add _experimental_ feature of moving and zooming images.
  * setting `interactive: true` enables the feature.
* Add `fixArea` flag to fix cropping area. 

## [0.6.0+1] - 2021.08.14
* Fix static analysis issues.

## [0.6.0] - 2021.08.14
* _Braking Change:_ The second argument of `cornerDotBuilder` is now enum of `EdgeAlignment`, not meaningful index.
* Add callback for `CropStatus`.
* Enhancement of not to block UI when loading image data.

## [0.5.3] - 2021.03.28
* Fix a bug that calcuration of cropping area is wrong when Exif has orientation data.

## [0.5.2+2] - 2021.03.28
* Update Readme

## [0.5.2+1] - 2021.03.28
* Fix problems of static analysis.
* Update Readme

## [0.5.2] - 2021.03.28
* Update Readme
* Remove unused code

## [0.5.1+1] - 2021.03.25
* Enable to set initial cropping area with `initialArea` property.

## [0.5.0] - 2021.03.18
* Enable to configure corner Dots with whatever Widget.
* Enable to configure cropping mask colors and base colors.

## [0.4.0] - 2021.03.18
* Enable to change original image via `CropController`
* Add callback when cropping area moves.
* Enable to control cropping area programmatically via `CropController`
* Fix bug that wrong cropping area is calculated when image is smaller than display.

## [0.3.0] - 2021.03.17
* Add example project in `example` directory.

## [0.2.3] - 2021.03.17
* Fix a bug of wrong cropping rect when vertically longer image is set.
* Make the size of dots smaller.

## [0.2.2] - 2021.03.16
* Rename `isCircle` flag into `withCircleUi`. This flag no more affects the result of the shape of cropped images.
* Add `CropController.cropCircle` method so that images are cropped with circle shape.

## [0.2.1] - 2021.03.16
* Enable to pass `isCircle` property to crop with circle shape. This flag can also be changed via `CropController`.

## [0.2.0] - 2021.03.16
* Enable to change `aspectRatio` dynamically via `CropController`.
* Enable to set `initialSize` via `Crop` constructor.

## [0.1.4] - 2021.03.16
* Bug fixed. and improve performance.

## [0.1.3] - 2021.03.16
* Fix not to block UI update when cropping image.

## [0.1.2] - 2021.03.15
* Enable to fix aspect ratio if `aspectRatio` property is given.

## [0.1.1] - 2021.03.14
* Fix README.md

## [0.1.0] - 2021.03.14

* prevent Dot controls from exceeding thier horizontal / vertical limits.

## [0.0.6] - 2021.03.12

* change the type of `image` parameters to `UInt8List`.
* return cropped data via `onCropped` callback.
* now Crop Widget is available at any place and any size.

## [0.0.5] - 2021.03.12

* Enable controling crop actions via CropController.

## [0.0.4] - 2021.03.12

* Rename classes.

## [0.0.3] - 2021.03.12

* Add first implementation of crop_your_image.

## [0.0.2] - 2021.03.12

* Update information about this package.
