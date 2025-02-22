# ``ComponentLibrary/CloseButton``

The button which is used for closing a view, such as a bottom sheet, when the user taps on the button.

## Overview

`CloseButton` is a subclass of `UIButton`. This means that the properties of `UIButton` are accessible, however it's recommended to configure the button title, font, and accessibility identifier through its view model ``CloseButtonViewModel``. The button size shouldn't be adjusted and should be used as is.

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
