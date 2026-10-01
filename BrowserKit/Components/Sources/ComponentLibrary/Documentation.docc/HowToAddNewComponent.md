# How to add a new component

This article is aimed at developers wanting to add new components inside the library.

## Overview
Let's go over the different considerations before adding a component inside the library, then we can discuss the guidelines on how to add one.

### Is it Component Library worthy?
If your UI component is used for one feature only, then let's keep this component with the feature code. If the UI component you are building has UI elements that can be reused (Example: with a specific type of container, or a specific type of button) then it can be worth moving it to the component library. If there's ambiguity, then you should bring this up with teammates for discussion in #firefox-ios-dev Slack channel or during our weekly engineering meeting.

## How to add a new component
> Once you have made sure you indeed have a component that should be added to that library, please see previous section first.

When adding a new component, there are two steps you need to be aware of. The first one is adding the component to the actual component library package located in `BrowserKit`, and the second one is adding the component to the sample application.

### Component Library
You should add the code under the `ComponentLibrary` folder in `BrowserKit`, following the guidelines:

#### Guidelines for components
1. Image identifiers should come from the `StandardImageIndentifiers`. If the image isn't standard, then it's probably a feature component that shouldn't live in Component Library.
1. Accessibility identifiers should be customizable and injected from the Client application. Each identifier needs to be unique whenever the component is reused. Injection should happen through the view model.
1. Localized strings and accessibility labels should be injected from the Client application, since translations live there. Injection should happen through the view model.
1. Prefer having a `configure` method on the component rather than making properties public. This will ensure we have a standard way of using components. This will make code easier to maintain and understand over time.
1. Ensure your component behaves properly with `Dynamic Type`. This means the component should be able to resize itself dynamically depending on its content size, and cannot have fixed height under any circumstances. Constraints should be done for that in all directions (top, bottom, trailing, leading). If you find yourself using a center constraint, you should make sure this is indeed needed and works properly (hint, extra work needs to be done if you center things only, the component won't behave properly otherwise).
1. Ensure your component behaves properly with RTL languages. This means using trailing and leading constraints, and ensure images are flipped where ever needed. See [`imageFlippedForRightToLeftLayoutDirection`](https://developer.apple.com/documentation/uikit/uiimage/1624140-imageflippedforrighttoleftlayout) for more information.
1. Ensure your component behaves properly with Voice Over. This means we should inject needed identifiers for images to be read out loud to users to have the proper context. As developers, we should ensure the constraints are made properly, so the field highlighted with Voice Over is actually the one being read out loud.
1. Ensure your component reacts properly to theme manager changes by being `ThemeApplicable`.
1. Make sure that your component is added to the component library documentation. It needs to be listed on the landing page, as well as having its own documentation page.

### Sample application
> You will need to close the Client application to be able to navigate `BrowserKit` in the Sample application when you open [`Sample app xcodeproj`](https://github.com/mozilla-mobile/firefox-ios/tree/main/SampleComponentLibraryApp)

Once your component is added under the library, you are now ready to add an example of usage of that component in the sample application. This step is mandatory, to ensure that we have an easy way to keep track of components, know how to use them, and keep them relevant. Sample application could also be used to have screenshot tests at one point to ensure the components looks as they should on different device, with different text size, theme and so on.

#### How to add a Sample app example
1. Add a new `UIViewController` that will show the component you created. Make sure it constrained properly so Dynamic Type will work with it. Make sure it's the view controller is `Themeable` and `listenForThemeChange`, making sure the component you added is themed. If there are multiple states to the component, ensure this view controller shows all the components states (so you can add more than one component to the view controller).
1. Add a new component view model following the `ComponentViewModel` protocol.
1. Make sure the `ComponentData` data array includes your new view model.
1. Bravo! You are now ready to test accessibility and theme change on your component following the components guidelines.
