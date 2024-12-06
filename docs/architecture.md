This document describes how crop_your_image is implemented. This is not only for the maintainers but also Cursor editor, which supports coding and refactoring using AI.

# Architecture of crop_your_image

## Overview

At first, crop_your_image is a Flutter package that provides a widget named `Crop` and its controller `CropController`.

Because this package requires a lot of calculations for detecting the cropping area, we have internally `Calculator` class.  

In addition, `Crop` also provides a mechanism to interchange backend logics for:

- Determining the given image format
- Parsing the image from `Uint8List` to whatever data type 
- Cropping the image with given rect

The default backend uses `image` package for all the image processing, but this mechanism allows you to use other packages, or even delegate the processing to your server side.

## Crop

`Crop` is designed to be a handy widget that can be used at anywhere; this may be used in a `Dialog`, or a `BottomSheet`, etc.

To achieve the design, `Crop` first checks the size of its viewport respecting the given constraints, then it overrides the `MediaQueryData.size` with the size so that its subtree can find the desired size calling `MediaQuery.sizeOf(context)`.

This mechanism introduces one restriction that the user must supply the size of the viewport to `Crop` explicitly, typically using `SizedBox`, `AspectRatio`, or `Expanded`.

`Crop`, or internal `_CropEditor` widget, doesn't use `InteractiveViewer` but does all the calculations for zooming and panning based on the given info by `GestureDetector`. This is because `InteractiveViewer` doesn't provide a handy way to get the current zoom level and pan position, which are required for the cropping area calculation.

## CropController

Users may want to imperatively control `Crop` widget, as in `TextField` has `TextEditingController`. Thus, `Crop` provides `CropController` to allow users to control the widget, such as calling `crop()`.

Once the controller is given to `Crop`, this initializes the controller in `initState()` with attaching `CropControllerDelegate` and its methods declared with `late` keyword.

TODO(chooyan-eng): Revise the implementation of `TextEditingController` or other controller patterns and if `CropController` follows the same pattern.

## Calculator

`Calculator` class is a utility to calculate various data for cropping.

crop_your_image requires various kinds of data, such as:

- Actual image size
- Displaying image size on viewport
- Current zoom level
- Current pan position
- The rect of the cropping area based on given viewport
- The rect of the cropping area based on given image size
- Given aspect ratio for cropping area
- Given initial size for cropping area

meaning the calculation logic is always complex. 

To keep the code clean and testable, `Calculator` provides all the calculation logic in a pure Dart logic.

The calculation logic changes depending on the given image fits vertically or horizontally to the viewport. So `Calculator` has two implementations, `VerticalCalculator` and `HorizontalCalculator`.

TODO(chooyan-eng): Revise the calculation logic must be separated depending on the given image aspect ratio. There can be a nice calculation to be applied regardless of the image orientation.

TODO(chooyan-eng): Currently, `Calculator` exposes the *methods* for calculation and `Crop` calls the methods whenever it needs, however, this can be refactored with the idea mentioned in https://github.com/chooyan-eng/complex_local_state_management/blob/main/docs/local_state.md

