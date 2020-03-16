# API
EarlGrey includes three main groups of APIs:

  * [Interaction APIs](#interaction-apis)
  * [Synchronization APIs](#synchronization-apis)
  * [Other Top Level APIs](#other-top-level-apis)


## Interaction APIs

EarlGrey test cases are made up of interactions with UI elements. Each interaction consists of:

  * Selecting an element to interact with,
  * Performing an action on it, and/or
  * Making an assertion to verify state and behavior.

To reflect this, the Interaction APIs are organized into the following:

  * [Selection API](#selection-api)
  * [Action API](#action-api)
  * [Assertion API](#assertion-api)

Each of these APIs is designed with extensibility in mind, giving the user flexibility for customization,
while preserving the prose-like structure of tests. Consider the following snippet:


```objc
[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"ClickMe")];
```

It shows how to start an interaction by selecting an element with `ClickMe` as the Accessibility
Identifier. After you select an element, you can continue the interaction with an action or an
assertion. EarlGrey works with any element that conforms to the [UIAccessibility protocol](https://developer.apple.com/library/ios/documentation/uikit/reference/UIAccessibility_Protocol/Introduction/Introduction.html),
not just `UIViews`; this allows tests to perform a richer set of interactions.

You can chain a selection and an action in one statement. For example, you can tap on the element
that has `ClickMe` as its Accessibility Identifier as follows:


```objc
[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"ClickMe")]
    performAction:grey_tap()];
```

Note: `selectElementWithMatcher:` doesn't return an element; it just marks the beginning of an
interaction.

You can also chain a selection and an assertion. The following snippet shows how to select an
element that has `ClickMe` as its accessibility identifier and asserts that it is displayed:


```objc
[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"ClickMe")]
    assertWithMatcher:grey_sufficientlyVisible()];
```

Finally, you can perform actions and assertions in sequence. The following statement finds an element with
the accessibility identifier `ClickMe`, taps on it, and asserts that it is not displayed.


```objc
[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"ClickMe")]
    performAction:grey_tap()]
    assertWithMatcher:grey_notVisible()];
```


The following is an example of a simple interaction:


```objc
[[[EarlGrey selectElementWithMatcher:<element_matcher>]
    performAction:<action>]
    assertWithMatcher:<assertion_matcher>];
```

Where `<element_matcher>` and `<assertion_matcher>` are matchers contained in `GREYMatchers.h` and
`<action>` is one of the actions in `GREYActions.h`. Because each of these has a shorthand
C-function, instead of using `[GREYMatchers matcherForSufficientlyVisible]` you can use
`grey_sufficientlyVisible()`. Shorthand notation is enabled by default. To disable it, add
`#define GREY_DISABLE_SHORTHAND 1` to the project's prefix header.

### Selection API

Use the Selection API to locate a UI element on the screen. This API accepts a matcher and tests it against all
the elements in the UI hierarchy to locate an element to interact with. In
EarlGrey, matchers support an API that is similar to that of [OCHamcrest](https://github.com/hamcrest/OCHamcrest)
matchers. You can combine matchers using AND-OR-NOT logic, allowing you to create matching rules
that can pinpoint any element in the UI hierarchy.

#### EarlGrey Matchers

All EarlGrey matchers are available in the [GREYMatchers](../EarlGrey/Matcher/GREYMatchers.m)
factory class. The best way to find a UI element is to use its accessibility properties. We
strongly recommend using an [accessibility identifier](https://developer.apple.com/library/ios/documentation/uikit/reference/UIAccessibilityIdentification_Protocol/Introduction/Introduction.html)
as it uniquely identifies an element. Use `grey_accessibilityID()` as your matcher to select a UI
element by its accessibility identifier. You can also use other accessibility properties, such as using
`grey_accessibilityTrait()` as the matcher for UI elements with specific accessibility traits, or by using
`grey_accessibilityLabel()` as the matcher for accessibility labels.

A matcher can be ambiguous and match multiple elements: for example, `grey_sufficientlyVisible()`
will match all sufficiently visible UI elements. In such cases, you must narrow down the
selection until it can uniquely identify a single UI element. You can make the matchers more specific
by combining matchers with `grey_allOf()`, `grey_anyOf()`, `grey_not()`  or by supplying a root
matcher with the `inRoot` method to narrow the selection.

Consider these examples for both cases.

First, with collection matchers, the following snippet finds a UI element that has an accessibility
label `Send` **and** is displayed on the screen.


```objc
id<GREYMatcher> visibleSendButtonMatcher =
    grey_allOf(grey_accessibilityLabel(@"Send"), grey_sufficientlyVisible(), nil);

[[EarlGrey selectElementWithMatcher:visibleSendButtonMatcher]
    performAction:grey_tap()];
```

Note that with `grey_allOf` the order matters. If `grey_sufficientlyVisible` is used first, then every element
in the entire application will be checked for visibility. It's important to order matchers from
most selective (such as accessibility label and accessibility id) to least.

Next, with `inRoot`, the following statement finds an element that has the accessibility label set
to `Send` and is contained in a UI element that is an instance of the `SendMessageView` class.

```objc
[[[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Send")]
    inRoot:grey_kindOfClass([SendMessageView class])]
    performAction:grey_tap()];
```

Note: For compatibility with Swift, we use `grey_allOfMatchers()` and `grey_anyOfMatchers()` instead of `grey_allOf()` and `grey_anyOf()` respectively.

#### Custom Matchers

To create custom matchers, use the block-based [GREYElementMatcherBlock](../EarlGrey/Matcher/GREYElementMatcherBlock.h)
class. For example, the following code matches views that don't have any subviews:


```objc
+ (id<GREYMatcher>)matcherForViewsWithoutSubviews {
  MatchesBlock matches = ^BOOL(UIView *view) {
    return view.subviews.count == 0;
  };
  DescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:@"Views without subviews"];
  };

  return [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches
                                              descriptionBlock:describe];
}
```

`MatchesBlock` can also accept type `id` instead of `UIView *`. You should use `id` when the
matcher must also work with accessibility elements. The following matcher example works
universally for all UI element types:


```objc
+ (id<GREYMatcher>)matcherForElementWithoutChildren {
  MatchesBlock matches = ^BOOL(id element) {
    if ([element isKindOfClass:[UIView class]]) {
      return ((UIView *)element).subviews.count == 0;
    }
    // Handle accessibility elements here.
    return ...;
  };
  DescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:@"UI element without children"];
  };
  return [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches
                                              descriptionBlock:describe];
}
```

This matcher can be used in a test to select a UI element that doesn’t have any children (or
subviews) and double-tap on it (assuming that the method was declared in a class `CustomMatchers`):


```objc
[[EarlGrey selectElementWithMatcher:[CustomMatchers matcherForElementWithoutChildren]]
    performAction:grey_doubleTap()];
```

#### Selecting Off-Screen UI Elements

In certain situations the UI element may be hidden off-screen, and may require certain interactions
to bring it onto the screen. Common examples include scrolling to an element that is not visible in
the scrollview, zooming-in on a map to show UI elements that are shown only in street-view,
navigating through a [UICollectionView](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UICollectionView_class/)
that has a custom layout, etc. You can use the `[usingSearchAction:onElementWithMatcher:]` method
to provide a search action for such elements. The API allows you to specify a search action and a
matcher for the element on which the search action will be applied. EarlGrey applies the search
action repeatedly until the element you are looking for is found (or a timeout occurs).

For example, the following statement attempts to find an element matching `aButtonMatcher` by
repeatedly scrolling down (by 50 points at a time) on the element matching `aScrollViewMatcher` and
taps the button when it finally finds it.


```objc
[[[EarlGrey selectElementWithMatcher:aButtonMatcher]
    usingSearchAction:grey_scrollInDirection(kGREYDirectionDown, 50)
 onElementWithMatcher:aScrollViewMatcher]
    performAction:grey_tap()];
```

And in this example, this statement attempts to find a table view cell matching `aCellMatcher` by
repeatedly scrolling up (by 50 points at a time) on a table matching `aTableViewMatcher`.

```objc
[[[EarlGrey selectElementWithMatcher:aCellMatcher]
    usingSearchAction:grey_scrollInDirection(kGREYDirectionUp, 50)
 onElementWithMatcher:aTableViewMatcher]
    performAction:grey_tap()];
```

### Action API

Use the Action API to specify the test actions to perform on a selected UI element.

#### EarlGrey Actions

All EarlGrey actions are available in the [GREYActions](../EarlGrey/Action/GREYActions.h) factory
class. The most common action is tapping (or clicking) on a given element using the `grey_tap()`
method:

```objc
[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TapMe")]
    performAction:grey_tap()];
```

If an action triggers changes in the UI hierarchy, EarlGrey synchronizes each action (including
chained actions) with the UI, ensuring that it is in a stable state before the next action is
performed.

Not all actions can be performed on all elements; for example, the tap action cannot be performed
on elements that are not visible. To enforce this, EarlGrey uses **constraints** which are
preconditions in the form of [GREYMatcher](../EarlGrey/Matcher/GREYMatcher.h) that
must be met before an action is actually performed. Failure to meet these constraints results in an
exception being thrown and the test marked as failed. To avoid test failure, you can invoke
`performAction:error:` to get an [NSError](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSError_Class/)
object containing failure details.


```objc
NSError *error;
[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"Non-Existent-Ax-Id")]
    performAction:grey_tap()
            error:&error];
```

In the above case, an exception **will not** be thrown for the EarlGrey interaction being performed
on a non-existent element. Instead, the error object passed will save the failure details and not
fail the test immediately. The error details can then be perused for finding the failure details.

#### Custom Actions

Custom actions can be created by conforming to the [GREYAction](../EarlGrey/Action/GREYAction.h)
protocol. For convenience, you can use [GREYActionBlock](../EarlGrey/Action/GREYActionBlock.h),
which already conforms to the GREYAction protocol and allows you to express an action in the form
of a block. The following code creates an action using a block that invokes a custom selector
(`animateWindow`) to animate the selected element’s window:


```objc
- (id<GREYAction>)animateWindowAction {
  return [GREYActionBlock actionWithName:@"Animate Window"
                             constraints:nil
                            performBlock:^(id element, NSError *__strong *errorOrNil) {
    // First, make sure the element is attached to a window.
    if ([element window] == nil) {
      // Populate error.
      *errorOrNil = ...
      // Indicates that the action failed.
      return NO;
    }
    // Invoke a custom selector that animates the window of the element.
    [element animateWindow];
    // Indicates that the action was executed successfully.
    return YES;
  }];
}
```

### Assertion API

Use the Assertion API to verify the state and behavior of a UI element.

#### Assertions Using Matchers

Use `assertWithMatcher:` to perform an assertion with [GREYMatcher](../EarlGrey/Matcher/GREYMatcher.h)
matchers. The selected element is run through the matcher for verification. For example,
the following snippet asserts that the element with the accessibility ID `ClickMe` is visible,
and the test fails if the element is not visible on the screen.

```objc
[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"ClickMe")]
    assertWithMatcher:grey_sufficientlyVisible()];
```

To prevent test failure, you can provide an `NSError` object to the `assertWithMatcher:error:`
method, as in the statement shown below. Instead of failing, the EarlGrey assertion will provide
you with an `NSError` object that contains details about the failure.

```objc
NSError *error;
[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"ClickMe")]
    assertWithMatcher:grey_sufficientlyVisible()
                error:&error];
```

You can also perform an assertion by using the `assert` method and passing an instance of
[`GREYAssertion`](../EarlGrey/Assertion/GREYAssertion.h). We recommend that you create
assertions from matchers using `assertWithMatcher:`
whenever possible. Matchers are lightweight and ideal for simple assertions. However, a custom
`GREYAssertion` could be a better choice in the case of an assertion that needs to perform complex
logic, like manipulating the UI, to proceed with the assertion.

#### Custom Assertions

You can create custom assertions using the [`GREYAssertion`](../EarlGrey/Assertion/GREYAssertion.h)
protocol or by using [`GREYAssertionBlock`](../EarlGrey/Assertion/GREYAssertionBlock.h) that
accepts the assertion logic in a block. The following example uses `GREYAssertionBlock` to write an
assertion that checks that the view's alpha is equal to the provided value:


```objc
+ (id<GREYAssertion>)hasAlpha:(CGFloat)alpha {
  return [GREYAssertionBlock assertionWithName:@"Has Alpha"
                                assertionBlock:^(UIView *view, NSError *__strong *errorOrNil) {
    if (view.alpha != alpha) {
      NSString *reason =
        [NSString stringWithFormat:@"Alpha value doesn't match for %@", view];
      // Check if errorOrNil was provided, if so populate it with relevant details.
      if (errorOrNil) {
        *errorOrNil = ...
      }
      // Indicates assertion failed.
      return NO;
    }
    // Indicates assertion passed.
    return YES;
  }];
}
```

Note: Do not assume that assertions are run against valid UI elements. You will need to perform
your own check to make sure the UI element is in a valid state before validating the assertion. For
instance, the following snippet checks that the element exists (that it isn’t `nil`) before
asserting the rest of the state:

```objc
+ (id<GREYAssertion>)hasAlpha:(CGFloat)alpha {
  return [GREYAssertionBlock assertionWithName:@"Has Alpha"
                                assertionBlock:^(UIView *view, NSError *__strong *errorOrNil) {
    // Assertions can be performed on nil elements. Make sure view isn’t nil.
    if (view == nil) {
      // Check if errorOrNil was provided, if so populate it with relevant details.
      if (errorOrNil) {
        *errorOrNil = [NSError errorWithDomain:kGREYInteractionErrorDomain
                                        code:kGREYInteractionElementNotFoundErrorCode
                                    userInfo:nil];
      }
      return NO;
    }
    // Perform rest of the assertion logic.
    ...
    // Indicates assertion passed.
    return YES;
  }];
}
```

Alternatively, you can create a class that conforms to
[GREYAssertion](../EarlGrey/Assertion/GREYAssertion.h).

#### Failure Handlers

By default, EarlGrey uses a failure handler that is invoked when any exception is raised by the
framework. The default handler logs the exception, takes a screenshot, and then prints its path
along with any other useful information. You can choose to provide your own custom failure handler
and install it using the `EarlGrey setFailureHandler:` API which replaces the global default
framework handler. To create a custom failure handler, write a class that conforms to the
[GREYFailureHandler](../EarlGrey/Exception/GREYFailureHandler.h) protocol:


```objc
@interface MyFailureHandler : NSObject <GREYFailureHandler>
@end

@implementation MyFailureHandler

- (void)handleException:(GREYFrameworkException *)exception details:(NSString *)details {
  // Log the failure and state of the app if required.
  // Call thru to XCTFail() with an appropriate error message.
}

- (void)setInvocationFile:(NSString *)fileName
        andInvocationLine:(NSUInteger)lineNumber {
  // Record the file name and line number of the statement which was executing before the
  // failure occurred.
}
@end
```

#### Assertions Macros

EarlGrey provides its own macros that can be used within a testcase for
assertion and verification. These macros are similar to the macros provided by
XCTest and invoke the global failure handler upon assertion failure.

  * `GREYAssert(expression, reason, ...)` — Fails if the expression evaluates to false
  * `GREYAssertTrue(expression, reason, ...)` — Fails if the expression evaluates to
false. Use for BOOL expressions
  * `GREYAssertFalse(expression, reason, ...)` — Fails if the expression evaluates to
true. Use for BOOL expressions
  * `GREYAssertNotNil(expression, reason, ...)` — Fails if the expression evaluates to
nil
  * `GREYAssertNil(expression, reason, ...)` — Fails if the expression evaluates to a
non-nil value
  * `GREYAssertEqual(left, right, reason, ...)` — Fails if left != right for scalar
types
  * `GREYAssertNotEqual(left, right, reason, ...)` — Fails if left == right for scalar
types
  * `GREYAssertEqualObjects(left, right, reason, ...)` — Fails if [left isEqual:right] returns
false
  * `GREYAssertNotEqualObjects(left, right, reason, ...)` — Fails if [left isEqual:right] returns
true
  * `GREYFail(reason, ...)` — Fails immediately with the provided reason
  * `GREYFailWithDetails(reason, details, ...)` — Fails immediately with the provided reason and
  details

#### Layout Testing

EarlGrey provides APIs to verify the layout of UI elements; for example, to verify that element X
is to the left of element Y. Layout assertions are modeled after [NSLayoutConstraint](https://developer.apple.com/library/ios/DOCUMENTATION/AppKit/Reference/NSLayoutConstraint_Class/index.html).
To verify the layout, you need to first create a constraint that specifies the layout,
select an element constrained by it, and then assert that it matches the constraint using
`grey_layout(...)`. Note that `grey_layout(...)` takes an array of constraints, all of which must
be satisfied. This allows for easy specification of complex layout assertions.

For example, the following constraint specifies that the selected element is to the right of any
other arbitrary element used as a reference.


```objc
GREYLayoutConstraint *rightConstraint =
    [GREYLayoutConstraint layoutConstraintWithAttribute:kGREYLayoutAttributeLeft
                                              relatedBy:kGREYLayoutRelationGreaterThanOrEqual
                                   toReferenceAttribute:kGREYLayoutAttributeRight
                                             multiplier:1.0
                                               constant:0.0];
```

You can now select the element with the `RelativeRight` accessibility ID and use
`grey_layout(@[rightConstraint])` to assert if it's on the right of the reference element, which in
our example is the element with `TheReference` accessibility ID.

```objc
[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@”RelativeRight”)]
    assertWithMatcher:grey_layout(@[rightConstraint], grey_accessibilityID(@”TheReference”))];
```

You can also create simple directional constraints using `layoutConstraintForDirection:`. The
following code is equivalent to the previous example:

```
GREYLayoutConstraint *rightConstraint =
    [GREYLayoutConstraint layoutConstraintForDirection:kGREYLayoutDirectionRight
                                  andMinimumSeparation:0.0];
```

## Synchronization APIs

These APIs let you control how EarlGrey synchronizes with the app under test.

### GREYCondition

If your test case requires special handling, you can use `GREYCondition` to wait or synchronize
with certain conditions. `GREYCondition` takes a block that returns a `BOOL` to indicate whether
the condition has been met. The framework polls this block until the condition is met before
proceeding with rest of the test case. The following snippet illustrates how to create and use a
`GREYCondition`:

```objc
GREYCondition *myCondition = [GREYCondition conditionWithName:@"my condition"
                                                        block:^BOOL {
  ... do your condition check here ...
  return yesIfMyConditionWasSatisfied;
}];
// Wait for my condition to be satisfied or timeout after 5 seconds.
BOOL success = [myCondition waitWithTimeout:5];
if (!success) {
  // Handle condition timeout.
}
```

### Synchronization

EarlGrey automatically waits for the app to idle by tracking the main dispatch queue, main
operation queue, network, animations and several other signals and performs interactions only when
the app is Idle. However there may be situations where the interactions must be performed in spite
of app being busy. For example in a messaging app, a photo might be uploading and corresponding animation
running but the test might still want to type and send a text message. To address such situations, you can
disable EarlGrey's synchronization using `kGREYConfigKeySynchronizationEnabled`, as shown in the following snippet:

```objc
[[GREYConfiguration sharedInstance] setValue:@(NO)
                                forConfigKey:kGREYConfigKeySynchronizationEnabled];
```

Once disabled all interactions will proceed without waiting for the app to idle until synchronization is
reenabled again. Note that to maximize test effectiveness, synchronization must be reenabled as soon
as possible. Also instead of disabling synchronization completely you can configure the synchronization parameters
to suit the needs of your app. For example:

- `kGREYConfigKeyNSTimerMaxTrackableInterval` can be used to specify the maximum interval of non-repeating
NSTimers that EarlGrey should synchronize with.
- `kGREYConfigKeyDispatchAfterMaxTrackableDelay` can be used to specify the maximum delay
for future executions using `dispatch_after` calls that EarlGrey must synchronize with.
- `kGREYConfigKeyURLBlacklistRegex` can be used to specify a list of URLs for which EarlGrey should
**not** wait.

And several such configurations are available in [GREYConfiguration](../EarlGrey/Common/GREYConfiguration.h).
See below for some specific use cases in detail.

### Network

By default, EarlGrey synchronizes with all network calls, but you can customize this behavior by
providing regular expressions to skip over certain URLs. To blacklist a URL, create a regular
expression that matches the URL, add it to an `NSArray` and pass it to `GREYConfiguration`.
For multiple URLs, repeat the same process by creating one regular expression for each URL.
For example, to tell the framework not to wait for www.google.com and www.youtube.com,
do something like:

```objc
NSArray *blacklist = @[ @".*www\\.google\\.com", @".*www\\.youtube\\.com" ];
[[GREYConfiguration sharedInstance] setValue:blacklist
                                forConfigKey:kGREYConfigKeyURLBlacklistRegex];
```

### Interaction Timeout

By default, a thirty second timeout is used for any interaction. In that time, if the app under
test fails to idle, a timeout exception is thrown and the test is marked as failed. You can use
[GREYConfiguration](../EarlGrey/Common/GREYConfiguration.h) to change this timeout value. For
example, to increase the timeout to 60 seconds (one minute):

```objc
[[GREYConfiguration sharedInstance] setValue:@(60.0)
                                forConfigKey:kGREYConfigKeyInteractionTimeoutDuration];
```

### Animation Timeout

Animations that repeat indefinitely — or that run for a long time — affect synchronization.
Animations that run longer than the test timeout value result in a timeout exception. To avoid such
cases, EarlGrey limits the animation duration to five seconds and disables repeating animations
(continuous animations run once). To instruct EarlGrey to allow animations to run longer, change
the maximum allowable animation duration value. Make sure this doesn’t affect your test timeouts.
The following snippet increases the maximum animation duration to 30 seconds.

```objc
[[GREYConfiguration sharedInstance] setValue:@(30.0)
                                forConfigKey:kGREYConfigKeyCALayerMaxAnimationDuration];
```

### Invocation From Non-Main Thread

Due to limitation of dispatch queues and the way EarlGrey synchronizes with them, calling into EarlGrey
statements from a `dispatch_queue` leads to a livelock. To mitigate this, we've introduced new block-based
APIs that wrap EarlGrey statements, and that can be safely called from non-main threads:

  * `grey_execute_sync(void (^block)())` — Synchronous. Blocks until execution is
complete.
  * `grey_execute_async(void (^block)())` — Asynchronous.

## Other Top Level APIs

Outside of UI interaction, you can use EarlGrey to control the device and system in various ways.

### Global Configuration

The `GREYConfiguration` class lets you configure the behavior of the framework. It provides a
means to configure synchronization, interaction timeouts, action constraints checks, logging, etc.
As soon as a configuration is changed, it is applied globally. For instance, the following code
changes the delay limit for dispatch after calls that EarlGrey tracks:


```objc
[[GREYConfiguration sharedInstance] setValue:@(5)
                                forConfigKey:kGREYConfigKeyDispatchAfterMaxTrackableDelay];
```

### Controlling Device Orientation

To rotate a device, use `[EarlGrey rotateDeviceToOrientation:errorOrNil:]` to simulate a device in
a specific orientation. For instance, the following causes the system (and your app) to act as if
the device is in **Landscape** mode with the device held upright and the **Home** button on the
right side:


```objc
[EarlGrey rotateDeviceToOrientation:UIDeviceOrientationLandscapeLeft errorOrNil:nil];
```

You can choose from the following orientation modes (for more information, see [UIDeviceOrientation](https://developer.apple.com/library/ios/documentation/uikit/reference/UIDevice_Class/Reference/UIDevice.html#//apple_ref/doc/c_ref/UIDeviceOrientation)):

  * `UIDeviceOrientationUnknown`
  * `UIDeviceOrientationPortrait`
  * `UIDeviceOrientationPortraitUpsideDown`
  * `UIDeviceOrientationLandscapeLeft`
  * `UIDeviceOrientationLandscapeRight`
  * `UIDeviceOrientationFaceUp`
  * `UIDeviceOrientationFaceDown`

### Shake Gesture

You can use `[EarlGrey shakeDeviceWithError:]` to simulate a shake gesture in a simulator.
