# ``ComponentLibrary/ContextualHintView``

The contextual hint view is a popover to present more context to the user.

## Overview

The `ContextualHintView` is a subclass of the `UIView`. That view is basically the content that will be enclosed in a popover which includes an arrow. You should configure the contextual hint view arrow direction, title, accessibility identifier, and click actions through it's view model ``ContextualHintViewModel``. The popover size should be set with `preferredContentSize` normally in the `viewDidLayoutSubviews` instance method, as well as setting the `popoverPresentationController` delegate and source view.

## Illustration

> This image is illustrative only. For precise examples of iOS implementation, please run the SampleApplication.

![The ContextualHintView on iOS](ContextualHintView)

## Topics

### View Model

- ``ContextualHintViewModel``
