# ``ComponentLibrary/BottomSheetViewController``

The bottom sheet is a modal view presented from the bottom of the screen as a popover.

## Overview

`BottomSheetViewController` is a subclass of `UIViewController`. The bottom sheet content is another view controller embedded within this parent view controller. The bottom sheet itself is displayed as a popover, making it a type of modal. It can be dismissed by tapping the close button, performing a swipe gesture, or clicking outside the sheet. These properties can be configured using its view model ``BottomSheetViewModel``.

## Illustration

> This image are illustrative only. For precise examples of iOS implementation, please run the SampleApplication.

![The BottomSheetViewController on iOS](BottomSheetView)

## Topics

### View Model

- ``BottomSheetViewModel``

### Protocols

- ``BottomSheetChild``
- ``BottomSheetDismissProtocol``
