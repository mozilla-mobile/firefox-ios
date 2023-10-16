# ``ComponentLibrary/BottomSheetViewController``

The bottom sheet is a modal view presented from the bottom as a pop over.

## Overview

The `BottomSheetViewController` is a subclass of the `UIViewController`. The bottom sheet content is another view controller embedded inside this parent view controller. The bottom sheet itself is shown as a popover, meaning it's type of modal. Bottom sheet can be dismissed from the close button, by doing a swipe gesture or by clicking outside the sheet itself. Those properties can be configured with it's view model ``BottomSheetViewModel``.

## Illustration

> This image are illustrative only. For precise examples of iOS implementation, please run the SampleApplication.

![The BottomSheetViewController on iOS](BottomSheetView)

## Topics

### View Model

- ``BottomSheetViewModel``

### Protocols

- ``BottomSheetChild``
- ``BottomSheetDismissProtocol``
