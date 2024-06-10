# ``ComponentLibrary/CloseButton``

The button which is used for closing a view, such as a bottom sheet, when the user taps on the button.

## Overview

The `CloseButton` is a subclass of the `UIButton`. This means properties of the `UIButton` are accessible, but for easy convenience it's recommended to configure the button title, font and accessibility identifier through it's view model ``CloseButtonViewModel``. The button size shouldn't be adjusted and should be used as is.

## Illustration

> This image is illustrative only. For precise examples of iOS implementation, please run the SampleApplication.

@TabNavigator {
    @Tab("Light") {
        ![The CloseButton on iOS](CloseButton)
    }
    
    @Tab("Dark") {
        ![The CloseButton Dark on iOS](CloseButton-dark)
    }
}

## Topics

### View Model

- ``CloseButtonViewModel``
