# ``ComponentLibrary``

The UI Component library aims at unifying how we build UI elements in Firefox for iOS.

## Overview
This library was needed since over time UX tech debt was accrued due to various look and feel of UI elements in the application. Fixing each view takes developer time since it needs to be done individually. Having standardized components will help us solve this problem. Developers can access those pre-built components, reducing the time and effort required to create new UI elements from scratch. Those components will be aligned with the [Figma components](https://www.figma.com/file/YIbYarab5aYte7KbK0bcVw/iOS-Components?node-id=1202%3A53176&mode=dev) and [Acorn](https://acorn.firefox.com/latest/components/button/i-os.html), improving collaboration between developers and designers since we’ll have a common language.

## What is a component

UI Components are parts of the UI that can be reused in multiple places in the application. They are normally defined by designers. We should use the names from [Figma components](https://www.figma.com/file/YIbYarab5aYte7KbK0bcVw/iOS-Components?node-id=1202%3A53176&mode=dev) or [Acorn](https://acorn.firefox.com/latest/components/button/i-os.html). You can also take a look into the different [Android components](https://searchfox.org/mozilla-mobile/source/firefox-android/fenix/app/src/main/java/org/mozilla/fenix/compose) to ensure we are aligned on all platforms. If we are not, then conversation between related parties should happen, so we become aligned. 

As devs, we can have three general categories for components: general components, features components and building blocks.

### General components
As developers, we sometimes need building blocks which aren't technically UX components. For example, a general component could be the base class to enable a certain type of `UITableView` cell which is then reused for features. Or it could a `CardView` that is reused in multiple feature components. More to come on that once we have more examples added to the library.

### Feature components
Feature components are entirely defined by designers. They can depend on some of the General components (our building blocks). The feature component, when used only for a specific feature should live with the feature code. Example: if we have a Jump back in cell, although it can be based on some general components UI code, it should live with the Jump back in code in the Homepage since it's only used there. If that cell is reused at one point for other features, then we should move it to live under the Component Library.

### Building blocks
Buildings blocks are classes uses by devs to enabled General or Feature components. They aren't necessarely UI related, but they are sometimes needed to be able to structure our code more elegantly.

## Topics

### Getting started

- <doc:GettingStarted>
- <doc:HowToAddNewComponent>

### General

- ``BottomSheetViewController``
- ``CardView``
- ``CloseButton``
- ``CollapsibleCardView``
- ``ContextualHintView``
- ``LinkButton``
- ``PaddedSwitch``
- ``PrimaryRoundedButton``
- ``SecondaryRoundedButton``
- ``ShadowCardView``

### Building Blocks

- ``ActionButton``
- ``FadeScrollView``
- ``ResizableButton``
