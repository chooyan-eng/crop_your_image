part of crop_your_image;

/// Calculation logics for various [Rect] data.
abstract class _Calculator {
  const _Calculator();

  /// calculates [Rect] of image to fit the screenSize.
  Rect imageRect(Size screenSize, double imageRatio);

  /// calculates [Rect] of initial cropping area.
  Rect initialCropRect(
      Size screenSize, Rect imageRect, double aspectRatio, double sizeRatio);

  /// calculates initial scale of image to cover _CropEditor
  double scaleToCover(Size screenSize, Rect imageRect);

  /// calculates ratio of [targetImage] and [screenSize]
  double screenSizeRatio(image.Image targetImage, Size screenSize);

  /// calculates [Rect] of the result of user moving the cropping area.
  Rect moveRect(Rect original, double deltaX, double deltaY, Rect imageRect) {
    if (original.left + deltaX < imageRect.left) {
      deltaX = (original.left - imageRect.left) * -1;
    }
    if (original.right + deltaX > imageRect.right) {
      deltaX = imageRect.right - original.right;
    }
    if (original.top + deltaY < imageRect.top) {
      deltaY = (original.top - imageRect.top) * -1;
    }
    if (original.bottom + deltaY > imageRect.bottom) {
      deltaY = imageRect.bottom - original.bottom;
    }
    return Rect.fromLTWH(
      original.left + deltaX,
      original.top + deltaY,
      original.width,
      original.height,
    );
  }

  /// calculates [Rect] of the result of user moving the top-left dot.
  Rect moveTopLeft(Rect original, double deltaX, double deltaY, Rect imageRect,
      double? aspectRatio) {
    final newLeft =
        max(imageRect.left, min(original.left + deltaX, original.right - 40));
    final newTop =
        min(max(original.top + deltaY, imageRect.top), original.bottom - 40);
    if (aspectRatio == null) {
      return Rect.fromLTRB(
        newLeft,
        newTop,
        original.right,
        original.bottom,
      );
    } else {
      if (deltaX.abs() > deltaY.abs()) {
        var newWidth = original.right - newLeft;
        var newHeight = newWidth / aspectRatio;
        if (original.bottom - newHeight < imageRect.top) {
          newHeight = original.bottom - imageRect.top;
          newWidth = newHeight * aspectRatio;
        }

        return Rect.fromLTRB(
          original.right - newWidth,
          original.bottom - newHeight,
          original.right,
          original.bottom,
        );
      } else {
        var newHeight = original.bottom - newTop;
        var newWidth = newHeight * aspectRatio;
        if (original.right - newWidth < imageRect.left) {
          newWidth = original.right - imageRect.left;
          newHeight = newWidth / aspectRatio;
        }
        return Rect.fromLTRB(
          original.right - newWidth,
          original.bottom - newHeight,
          original.right,
          original.bottom,
        );
      }
    }
  }

  /// calculates [Rect] of the result of user moving the top-right dot.
  Rect moveTopRight(Rect original, double deltaX, double deltaY, Rect imageRect,
      double? aspectRatio) {
    final newTop =
        min(max(original.top + deltaY, imageRect.top), original.bottom - 40);
    final newRight =
        max(min(original.right + deltaX, imageRect.right), original.left + 40);
    if (aspectRatio == null) {
      return Rect.fromLTRB(
        original.left,
        newTop,
        newRight,
        original.bottom,
      );
    } else {
      if (deltaX.abs() > deltaY.abs()) {
        var newWidth = newRight - original.left;
        var newHeight = newWidth / aspectRatio;
        if (original.bottom - newHeight < imageRect.top) {
          newHeight = original.bottom - imageRect.top;
          newWidth = newHeight * aspectRatio;
        }

        return Rect.fromLTWH(
          original.left,
          original.bottom - newHeight,
          newWidth,
          newHeight,
        );
      } else {
        var newHeight = original.bottom - newTop;
        var newWidth = newHeight * aspectRatio;
        if (original.left + newWidth > imageRect.right) {
          newWidth = imageRect.right - original.left;
          newHeight = newWidth / aspectRatio;
        }
        return Rect.fromLTRB(
          original.left,
          original.bottom - newHeight,
          original.left + newWidth,
          original.bottom,
        );
      }
    }
  }

  /// calculates [Rect] of the result of user moving the bottom-left dot.
  Rect moveBottomLeft(Rect original, double deltaX, double deltaY,
      Rect imageRect, double? aspectRatio) {
    final newLeft =
        max(imageRect.left, min(original.left + deltaX, original.right - 40));
    final newBottom =
        max(min(original.bottom + deltaY, imageRect.bottom), original.top + 40);

    if (aspectRatio == null) {
      return Rect.fromLTRB(
        newLeft,
        original.top,
        original.right,
        newBottom,
      );
    } else {
      if (deltaX.abs() > deltaY.abs()) {
        var newWidth = original.right - newLeft;
        var newHeight = newWidth / aspectRatio;
        if (original.top + newHeight > imageRect.bottom) {
          newHeight = imageRect.bottom - original.top;
          newWidth = newHeight * aspectRatio;
        }

        return Rect.fromLTRB(
          original.right - newWidth,
          original.top,
          original.right,
          original.top + newHeight,
        );
      } else {
        var newHeight = newBottom - original.top;
        var newWidth = newHeight * aspectRatio;
        if (original.right - newWidth < imageRect.left) {
          newWidth = original.right - imageRect.left;
          newHeight = newWidth / aspectRatio;
        }
        return Rect.fromLTRB(
          original.right - newWidth,
          original.top,
          original.right,
          original.top + newHeight,
        );
      }
    }
  }

  /// calculates [Rect] of the result of user moving the bottom-right dot.
  Rect moveBottomRight(Rect original, double deltaX, double deltaY,
      Rect imageRect, double? aspectRatio) {
    final newRight =
        min(imageRect.right, max(original.right + deltaX, original.left + 40));
    final newBottom =
        max(min(original.bottom + deltaY, imageRect.bottom), original.top + 40);
    if (aspectRatio == null) {
      return Rect.fromLTRB(
        original.left,
        original.top,
        newRight,
        newBottom,
      );
    } else {
      if (deltaX.abs() > deltaY.abs()) {
        var newWidth = newRight - original.left;
        var newHeight = newWidth / aspectRatio;
        if (original.top + newHeight > imageRect.bottom) {
          newHeight = imageRect.bottom - original.top;
          newWidth = newHeight * aspectRatio;
        }

        return Rect.fromLTWH(
          original.left,
          original.top,
          newWidth,
          newHeight,
        );
      } else {
        var newHeight = newBottom - original.top;
        var newWidth = newHeight * aspectRatio;
        if (original.left + newWidth > imageRect.right) {
          newWidth = imageRect.right - original.left;
          newHeight = newWidth / aspectRatio;
        }
        return Rect.fromLTWH(
          original.left,
          original.top,
          newWidth,
          newHeight,
        );
      }
    }
  }

  /// correct [Rect] not to exceed [Rect] of image.
  Rect correct(Rect rect, Rect imageRect) {
    return Rect.fromLTRB(
      max(rect.left, imageRect.left),
      max(rect.top, imageRect.top),
      min(rect.right, imageRect.right),
      min(rect.bottom, imageRect.bottom),
    );
  }
}

class _HorizontalCalculator extends _Calculator {
  const _HorizontalCalculator();

  @override
  Rect imageRect(Size screenSize, double imageRatio) {
    final imageScreenHeight = screenSize.width / imageRatio;
    final top = (screenSize.height - imageScreenHeight) / 2;
    final bottom = top + imageScreenHeight;
    return Rect.fromLTWH(0, top, screenSize.width, bottom - top);
  }

  @override
  Rect initialCropRect(
      Size screenSize, Rect imageRect, double aspectRatio, double sizeRatio) {
    final imageRatio = imageRect.width / imageRect.height;
    final imageScreenHeight = screenSize.width / imageRatio;

    final initialSize = imageRatio > aspectRatio
        ? Size((imageScreenHeight * aspectRatio) * sizeRatio,
            imageScreenHeight * sizeRatio)
        : Size(screenSize.width * sizeRatio,
            (screenSize.width / aspectRatio) * sizeRatio);

    return Rect.fromLTWH(
      (screenSize.width - initialSize.width) / 2,
      (screenSize.height - initialSize.height) / 2,
      initialSize.width,
      initialSize.height,
    );
  }

  @override
  double scaleToCover(Size screenSize, Rect imageRect) {
    return screenSize.height / imageRect.height;
  }

  @override
  double screenSizeRatio(image.Image targetImage, Size screenSize) {
    return targetImage.width / screenSize.width;
  }
}

class _VerticalCalculator extends _Calculator {
  const _VerticalCalculator();

  @override
  Rect imageRect(Size screenSize, double imageRatio) {
    final imageScreenWidth = screenSize.height * imageRatio;
    final left = (screenSize.width - imageScreenWidth) / 2;
    final right = left + imageScreenWidth;
    return Rect.fromLTWH(left, 0, right - left, screenSize.height);
  }

  @override
  Rect initialCropRect(
      Size screenSize, Rect imageRect, double aspectRatio, double sizeRatio) {
    final imageRatio = imageRect.width / imageRect.height;
    final imageScreenWidth = screenSize.height * imageRatio;

    final initialSize = imageRatio < aspectRatio
        ? Size(imageScreenWidth * sizeRatio,
            imageScreenWidth / aspectRatio * sizeRatio)
        : Size((screenSize.height * aspectRatio) * sizeRatio,
            screenSize.height * sizeRatio);

    return Rect.fromLTWH(
      (screenSize.width - initialSize.width) / 2,
      (screenSize.height - initialSize.height) / 2,
      initialSize.width,
      initialSize.height,
    );
  }

  @override
  double scaleToCover(Size screenSize, Rect imageRect) {
    return screenSize.width / imageRect.width;
  }

  @override
  double screenSizeRatio(image.Image targetImage, Size screenSize) {
    return targetImage.height / screenSize.height;
  }
}
