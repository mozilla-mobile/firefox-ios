# FAQ

#### **How does EarlGrey compare to Xcode’s UI Testing?**

EarlGrey is a [white-box testing](https://en.wikipedia.org/wiki/White_box_testing) solution
whereas Xcode’s UI Testing is [black-box](https://en.wikipedia.org/wiki/Black-box_testing).
EarlGrey runs in the same process as the app under test, so it has access to the same memory as the
app. This allows for better synchronization, such as ability to wait for network requests, and
allows for custom synchronization mechanisms that aren’t possible when using Xcode’s UI Testing feature.

However, EarlGrey is unable to launch or terminate the app under test from within the test case,
something that Xcode UI Testing is capable of. While EarlGrey supports many interactions, it makes
use of private APIs to create and inject touches, whereas Xcode’s UI Testing feature uses public
APIs.

Nonetheless, EarlGrey’s APIs are highly extensible and provide a way to write custom UI actions and
assertions. The ability to search for elements (using search actions) makes test cases resilient to
UI changes. For example, EarlGrey provides APIs that allow searching for elements in scrollable
containers, regardless of the amount of scrolling required.

#### **I see lots of “XXX is implemented in both YYY and ZZZ. One of the two will be used. Which one is undefined.” in the logs**

This usually means that EarlGrey is being linked to more than once. Ensure that only the **Test Target**
depends on *EarlGrey.framework* and EarlGrey.framework is embedded in the app under test (i.e. *$TEST_HOST*) from the
test target's built products via a Copy File(s) Build Phase.

#### **Why do the tests have the application scaled with borders around it? How can I get them to fit in the video frame?**

For your tests to have the application properly scaled, make sure the app under test has correct launch screen images present for all supported devices (see
[iOS Developer Library, Launch Files](https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/MobileHIG/LaunchImages.html)).

#### **Is there a way to return a specific element?**

No, but there is a better alternative. Use [GREYActionBlock](../EarlGrey/Action/GREYActionBlock.h)
to create a custom GREYAction and access any fields or invoke any selector on the element. For example, if you want to invoke a selector on an element, you can use syntax similar to the following:


```objc
// Objective-C
- (void)testInvokeCustomSelectorOnElement {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"id_of_element")]
      performAction:[GREYActionBlock actionWithName:@"Invoke clearStateForTest selector"
       performBlock:^(id element, NSError *__strong *errorOrNil) {
           [element doSomething];
           return YES; // Return YES for success, NO for failure.
       }
  ]];
}
```

The same technique works for extracting element attributes into variables.
Here's an example of storing an element's text attribute.

```swift
// Swift
//
// Must use a wrapper class to force pass by reference in Swift 3 closures.
// inout params cannot be modified within closures. http://stackoverflow.com/a/28252105
open class Element {
  var text = ""
}

/*
 *  Example Usage:
 *
 *  let element = Element()
 *  domainField.performAction(grey_replaceText("hello.there"))
 *             .performAction(grey_getText(element))
 *
 *  GREYAssertTrue(element.text != "", reason: "get text failed")
 */
public func grey_getText(_ elementCopy: Element) -> GREYActionBlock {
  return GREYActionBlock.action(withName: "get text",
  constraints: grey_respondsToSelector(#selector(getter: UILabel.text))) { element,
                                                                           errorOrNil -> Bool in
        let elementObject = element as? NSObject
        let text = elementObject?.perform(#selector(getter: UILabel.text),
                                          with: nil)?.takeRetainedValue() as? String
        elementCopy.text = text ?? ""
        return true
    }
}
```

#### **I get a crash with “Could not swizzle …”**

This means that EarlGrey is trying to swizzle a method that it has swizzled before. It is a result
of EarlGrey being linked to more than once. Ensure that only the **Test Target**
depends on *EarlGrey.framework* and EarlGrey.framework is embedded in the app under test (i.e. *$TEST_HOST*) from the
test target's build phase.

#### **How do I check whether an element exists in the UI hierarchy?**

If you are unsure whether the element exists in the UI hierarchy, pass an `NSError` to the
interaction and check if the error domain and code indicate that the element wasn’t found:

```objc
// Objective-C
NSError *error;
[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"Foo")]
    assertWithMatcher:grey_notNil() error:&error];

if ([error.domain isEqual:kGREYInteractionErrorDomain] &&
    error.code == kGREYInteractionElementNotFoundErrorCode) {
  // Element doesn’t exist.
}
```

#### **My app shows a splash screen. How can I make my test wait for the main screen?**

Use [GREYCondition](../EarlGrey/Synchronization/GREYCondition.h) in your test's setup method to
wait for the main screen’s view controller. Here’s an example:


```objc
// Objective-C
- (void)setUp {
  [super setUp];

  // Wait for the main view controller to become the root view controller.
  BOOL success = [[GREYCondition conditionWithName:@"Wait for main root view controller"
                                             block:^{
    id<UIApplicationDelegate> appDelegate = [UIApplication sharedApplication].delegate;
    UIViewController *rootViewController = appDelegate.window.rootViewController;
    return [rootViewController isKindOfClass:[MainViewController class]];
  }] waitWithTimeout:5];

  GREYAssertTrue(success, @"Main view controller should appear within 5 seconds.");
}
```

#### **Will my test fail if I have other modal dialogs showing on top of my app?**

Yes, if these dialogs belong to the app process running the test and are obscuring UI elements with
which tests are interacting.

#### **Can I use Xcode Test Navigator?**

Yes. EarlGrey supports **Test Navigator** out-of-the-box.

#### **Can I set debug breakpoints in the middle of a test?**

Yes. You can set a breakpoint on any interaction. The breakpoint will be hit before that
interaction is executed, but after all prior interactions have been executed.

#### **Where do I find the XCTest bundle?**

For the Example project, run the `EarlGreyExampleSwiftTests` target once then find the bundle:

> cd ~/Library/Developer/Xcode/DerivedData/EarlGreyExample-*/Build/Products/Debug-iphonesimulator/EarlGreyExampleSwift.app/PlugIns/EarlGreyExampleSwiftTests.xctest/

For physical device builds, replace `Debug-iphonesimulator` with `Debug-iphoneos`.

#### **How do I resolve "dyld: could not load inserted library '@executable_path/EarlGrey.framework/EarlGrey' because image not found" error?**

The error means that the dynamic loader is unable to find *EarlGrey.framework* at the specified path: `@executable_path/EarlGrey.framework/EarlGrey`

Verify that *EarlGrey.framework* is embedded in the app under test bundle. Build the **Test Target** and check for EarlGrey.framework in the app under test bundle. For an app named *MyApp*, EarlGrey.framework should be at `MyApp.app/EarlGrey.framework`. If it isn't there, make sure that the **Test Target** has a `Copy to $(TEST_HOST)` script in **Build Phases**. Follow [these instructions](install-and-run.md) on how to configure it. After configuring it, rebuild and check again. If EarlGrey.framework is still not present in the app under test bundle, please [open an issue](https://github.com/google/EarlGrey/issues/new) describing your project setup and the full error in detail.

#### **How should I handle animations?**

By default, [EarlGrey truncates CALayer based animations](../EarlGrey/Common/GREYConfiguration.h#L108) that exceed a threshold. The max animation duration setting is configurable:

```swift
// Swift
let kMaxAnimationInterval:CFTimeInterval = 5.0
GREYConfiguration.sharedInstance().setValue(kMaxAnimationInterval, forConfigKey: kGREYConfigKeyCALayerMaxAnimationDuration)
```

```objc
// Objective-C
[[GREYConfiguration sharedInstance] setValue:@(kMaxAnimationInterval)
                                forConfigKey:kGREYConfigKeyCALayerMaxAnimationDuration];
```

In addition to truncating, animation speed can be increased. UIKit
completion blocks and async calls execute as they normally would, just faster. This matches the
real conditions the iOS app is run under and will catch more bugs than simply disabling animations.
Note that the speedup doesn't work on `UIScrollView` because it animates via `CADisplayLink` internally.
Refer to the [PSPDFKit blog post for more details.](https://pspdfkit.com/blog/2016/running-ui-tests-with-ludicrous-speed/)

```swift
// Swift
GREYTestHelper.enableFastAnimation()
```

```swift
// Objective-C
[GREYTestHelper enableFastAnimation];
```

If the above doesn't help, you can temporarily disable synchronization to work around an animation
and then turn it back on after the animation is gone.

```swift
// Swift
GREYConfiguration.sharedInstance().setValue(false, forConfigKey: kGREYConfigKeySynchronizationEnabled)
```

```objc
// Objective-C
[[GREYConfiguration sharedInstance] setValue:@NO
                                forConfigKey:kGREYConfigKeySynchronizationEnabled];
```

Alternatively, conditionally disable the animation using `#if EARLGREY_ENV`.

#### **How do I match an element when it's duplicated in the app?**

EarlGrey requires all matchers return exactly one element.
This is difficult to do when an element is duplicated (same label/class/location).

We recommend combining the matchers [as suggested here](api.md#earlgrey-matchers) and then adding
`grey_interactable()` or `grey_sufficientlyVisible()`.

#### **How do I reset application state before each test?**

In the application target's Build Settings, set **Defines Module** to **Yes**. Create a `resetApplicationForTesting()` method on the AppDelegate. The reset method will be invoked on `setUp` instead of `tearDown` because otherwise there's no guarantee the app will be in a clean state when the first test is run.

Swift:
In the EarlGrey test target, import the application using `@testable`. In `setUp()`, acquire a reference to the delegate then invoke `resetApplicationForTesting()`.

```swift
// Swift
@testable import App

class MyTests: XCTestCase {

    override func setUp() {
        super.setUp()

        let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.resetApplicationForTesting()
    }
```


Objective-C:
In the EarlGrey test target, import the application's app delegate header. In `setUp()` acquire a pointer to the delegate then invoke `resetApplicationForTesting()`.

```objc
// Objective-C
#import "MyAppDelegate.h"

@interface MyTests : XCTestCase
@end

@implementation MyTests

- (void)setUp {
    [super setUp];

    MyAppDelegate *delegate = (MyAppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate resetApplicationForTesting];
}
```

#### **How do I create a matcher that matches internal UIKit classes?**

Use `NSClassFromString` to match on internal classes that can't be referenced directly.

```swift
// Swift
grey_kindOfClass(NSClassFromString("_UIAlertControllerView"))
```

#### **Why does the screen appear frozen for 30 seconds?**

If the tests are erroring with a timeout, then a background animation or synchronization bug may be keeping the application busy. EarlGrey will timeout interactions after 30 seconds.

If the tests are passing and just slow, then there's probably a matcher that's checking every element.

Make sure the matchers are ordered from most specific to least. For example:

```swift
// Swift
grey_allOfMatchers([grey_accessibilityID("Foo"), grey_sufficientlyVisible()])
```

```objc
// Objective-C
grey_allOf(grey_accessibilityID(@"Foo"),
           grey_sufficientlyVisible(),
           nil);
```

will find one element with the target id and then check that single element for visibility.
If we had the order wrong:

```swift
// Swift
grey_allOfMatchers([grey_sufficientlyVisible(), grey_accessibilityID("Foo")])
```

```objc
// Objective-C
grey_allOf(grey_sufficientlyVisible(),
           grey_accessibilityID(@"Foo"),
           nil);
```

then all elements in the entire application will be checked for visibility, and finally one
with a matching id will be selected. It's significantly faster to use the most targeted
matchers first (typically `grey_accessibilityID` or `grey_accessibilityLabel`).

#### **How do I inspect the EarlGrey view hierarchy?**

Breakpoint in any test, then paste the following into Xcode's lldb debug window:

```swift
> expression -- print(GREYElementHierarchy.hierarchyStringForAllUIWindows())
```

```objc
> po [GREYElementHierarchy hierarchyStringForAllUIWindows]
```


#### **How can I detect if I'm running in an EarlGrey target?**

Creating a [build configuration](https://developer.apple.com/library/ios/documentation/Swift/Conceptual/BuildingCocoaApps/InteractingWithCAPIs.html#//apple_ref/doc/uid/TP40014216-CH8-ID34) for EarlGrey will allow compilation:

```objc
// Objective-C
#if EARLGREY_ENV
...
#else
...
#endif
```

Alternatively, perform a runtime check for the EarlGrey class:

```swift
// Swift
public static let envEarlGrey:Bool = NSClassFromString("EarlGreyImpl") != nil
```

#### **How do I find off screen elements?**

EarlGrey requires elements to be visible (in the UI hierarchy) to perform automation.
Just as a user would, scroll elements into view before interacting with them.

The matcher must contain either `grey_interactable()` or `grey_sufficientlyVisible()` if
the element will be interacted with (for example via `grey_tap()`). If not, the matcher
may return an element that exists in the UI hierarchy but isn't interactable. The tap
will then fail because the element doesn't meet tap's interactable constraint.

```swift
// Swift
EarlGrey.selectElement(with:matcher)
        .using(searchAction: grey_scrollInDirection(GREYDirection.down, 200),
               onElementWithMatcher: grey_kindOfClass(UITableView.self))
        .assert(grey_notNil())
```

```objc
// Objective-C
[[EarlGrey selectElementWithMatcher:matcher]
                  usingSearchAction:grey_scrollInDirection(kGREYDirectionDown, 200)
               onElementWithMatcher:grey_kindOfClass([UITableView class])
                  assertWithMatcher:grey_notNil()];
```

#### **How do I wait for an element to appear?**

The best way is to [setup synchronization](features.md#synchronization) so that EarlGrey automatically waits
for elements to appear. As a work around for when that's not possible, `GREYCondition` and `waitWithTimeout`
are available. The following is an example of waiting for a collection view to populate. Note that `pollInterval` should be > 0 to avoid excessive hierarchy scans slowing down the main thread.

```swift
// Swift
// Wait until 5 seconds for the view.
let populated = GREYCondition(name: "Wait for UICollectionView to populate", block: { _ in
    var error: NSError?

    // Checking if collection view exists in the UI hierarchy.
    EarlGrey.selectElement(with:collectionViewMatcher)
            .assert(grey_notNil(), error: &error)

    return error == nil
}).wait(withTimeout: 5.0, pollInterval: 0.5)

GREYAssertTrue(populated, reason: "Failed to populate UICollectionView in 5 seconds")
```

```objc
// Objective-C
GREYCondition *waitCondition = [GREYCondition conditionWithName:@"Wait for UICollectionView to populate" block:^BOOL {
  NSError *error;

  // Checking if collection view exists in the UI hierarchy.
  [[EarlGrey selectElementWithMatcher:collectionViewMatcher]
      assertWithMatcher:grey_notNil() error:&error];

  return error == nil;
}];

// Wait until 5 seconds for the view.
BOOL populated = [waitCondition waitWithTimeout:5.0 pollInterval:0.5];
GREYAssertTrue(populated, @"Failed to populate UICollectionView in 5 seconds");
```

#### **How do I match elements that are denoted with "AX=N" in the view hierarchy?**

EarlGrey's view hierarchy identifies non-accessible elements with `AX=N`.
Accessibility IDs can be added to both accessible and non-accessible elements.
When searching for AX=N elements, the following accessibility matchers won't work:

- `grey_accessibilityLabel`
- `grey_accessibilityValue`
- `grey_accessibilityTrait`
- `grey_accessibilityHint`

If the `AX=N` element can't be matched by `grey_accessibilityID`, then you'll have to use non-accessibility
matchers to locate the element.

#### **Why does my Swift project throw compiler errors for all the shorthand matchers?**

A few times, we've noticed Source-Kit issues with Swift projects not finding the EarlGrey C-macros
when the project is built with CocoaPods. This seems to be caused by the naming scheme of the EarlGrey
`Pods/` directory. You might face compilation errors such as :

  <img src="images/image12.png" width="900" height="400">

The immediate solution for this is to update your **Xcode version** to the latest one. We can confirm that
the issue does not exist on Xcode 7.3.1. In case that does not work, you can also get rid of this problem by
manually changing the filename for the CocoaPods EarlGrey folder from `Pods/EarlGrey/EarlGrey-1.0.0` to
`Pods/EarlGrey/EarlGrey`. Once this is done, please re-add the`EarlGrey.framework` file in the `Pods/` folder
in your Project Navigator and also completely remove any Framework Search Paths in your target's Build
Settings pointing to `EarlGrey-1.0.0`. The project should run fine now.

#### **How do I create a custom action in Swift?**

You need to create a new object of type `GREYActionBlock` and call pass it to `performAction`. For example,
take a look at [checkHiddenBlock](../Tests/FunctionalTests/Sources/FTRSwiftTests.swift#L65) in our Functional
Test App's Swift Tests, which creates it as:

```swift
// Swift
let checkHiddenBlock:GREYActionBlock =
    GREYActionBlock.action(withName: "checkHiddenBlock") { (element, errorOrNil) -> Bool in
      // Check if the found element is hidden or not.
      let superView:UIView! = element as! UIView
      return (superView.isHidden == false)
    }

...

EarlGrey().selectElementWithMatcher(grey_accessibilityLabel("label"))
    .performAction(checkHiddenBlock)

```

#### **How do I change the directory location for where the screenshots are stored?**

You can change the kGREYConfigKeyArtifactsDirLocation key in GREYConfiguration to change the location.

```objc
// Objective-C
[[GREYConfiguration sharedInstance] setValue:@"screenshot_dir_path"
                                forConfigKey:kGREYConfigKeyArtifactsDirLocation];
```

#### **How do I run tests against a precompiled app?**

Xcode 8 adds two new commands for building and running tests:

- `build-for-testing` - Generates a xctestrun file for use with `test-without-building`.
- `test-without-building` - Runs the tests from xctestrun against a precompiled app.

For more information see `man xcodebuild.xctestrun`. The following commands work on [the EarlGreyExample project.](../Demo/EarlGreyExample)

```bash
$ cd Demo/EarlGreyExample
$ pod install
```

```bash
xcodebuild \
-workspace EarlGreyExample.xcworkspace \
-scheme EarlGreyExampleSwiftTests \
-destination 'platform=iOS Simulator,name=iPhone 6,OS=latest' \
-derivedDataPath 'xctestrun_dd' \
build-for-testing
```

```bash
xcodebuild \
-workspace EarlGreyExample.xcworkspace \
-scheme EarlGreyExampleSwiftTests \
-destination 'platform=iOS Simulator,name=iPhone 6,OS=latest' \
-derivedDataPath 'xctestrun_dd' \
test-without-building
```

You can also specify the xctestrun file directly:

```bash
xcodebuild \
-xctestrun './xctestrun_dd/Build/Intermediates/CodeCoverage/Products/EarlGreyExample_iphonesimulator10.0-x86_64.xctestrun' \
-destination 'platform=iOS Simulator,name=iPhone 6,OS=latest' \
-derivedDataPath 'xctestrun_dd'
test-without-building
```

#### **I get a compiler error `"Invalid escaped sequence in literal"` when I add the backspace escape character in a Swift string `"grey_typeText("foob\bar")"` to type "fooar". How do I use backspace to delete text in Swift?**

For Swift, the backspace escape character is `\u{8}`. You need to add that in your string to be typed for
Swift. For example, To type "fooar", you should use `grey_typeText("foob\u{8}ar")`

#### **Does EarlGrey support finding react-native elements?**

Yes. By default [all touchable elements](https://facebook.github.io/react-native/docs/accessibility.html)
are accessible. A button with the `accessibilityLabel` prop set can be found by `grey_accessibilityLabel`.
For other elements, `accessible: true` must also be set. Finding by label will not match on `accessible: false` elements.
Components that support the `testID` prop can always be matched with `grey_accessibilityID`, even if the element
is `accessible: false`.

Term               | iOS                | Android
---                | ---                | ---
accessibilityLabel | accessibilityLabel | content description
testID             | accessibilityID    | view tag

```javascript
// Set the test props of a component to enable UI testing
function testLabel(description) {
  return {
                accessible: true,
                    testID: description + "_id",
        accessibilityLabel: description + "_label"
  }
}

<Button
  onPress={()=>{}}
  title="automation"
  {...testLabel('automation_button')} />

<Image
  source={require('./img/image.png')}
  {...testLabel('automation_image')} />
```

```swift
// Swift
EarlGrey.selectElement(with: grey_accessibilityLabel("automation_button_label")).assert(grey_sufficientlyVisible());
EarlGrey.selectElement(with: grey_accessibilityLabel("automation_image_label")).assert(grey_sufficientlyVisible());
EarlGrey.selectElement(with: grey_accessibilityID("automation_image_id")).assert(grey_sufficientlyVisible());
```
