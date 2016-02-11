## Summary

This is the iOS SDK of adjust™. You can read more about adjust™ at
[adjust.com].

## Example app

There is an example app inside the [`example` directory][example]. You can open
the Xcode project to see an example on how the adjust SDK can be integrated.

## Basic integration

We will describe the steps to integrate the adjust SDK into your iOS project.
We are going to assume that you use Xcode for your iOS development.

If you're using [CocoaPods][cocoapods], you can add the following line to your
`Podfile` and continue with [step 3](#step3):

```ruby
pod 'Adjust', :git => 'git://github.com/adjust/ios_sdk.git', :tag => 'v4.3.0'
```

### 1. Get the SDK

Download the latest version from our [releases page][releases]. Extract the
archive into a directory of your choice.

### 2. Add it to your project

In Xcode's Project Navigator locate the `Supporting Files` group (or any other
group of your choice). From Finder, drag the `Adjust` subdirectory into Xcode's
`Supporting Files` group.

![][drag]

In the dialog `Choose options for adding these files` make sure to check the
checkbox to `Copy items if needed` and select the radio button to `Create
groups`.

![][add]

### <a id="step3"></a>3. Add the AdSupport and iAd framework

Select your project in the Project Navigator. In the left hand side of the main
view, select your target. In the tab `Build Phases` expand the group `Link
Binary with Libraries`. On the bottom of that section click on the `+` button.
Select the `AdSupport.framework` and click the `Add` button. Repeat the same
steps to add the `iAd.framework`. Change the `Status` of both frameworks to
`Optional`.

![][framework]

### 4. Integrate Adjust into your app

To start with, we'll set up basic session tracking.

#### Basic Setup

In the Project Navigator, open the source file of your application delegate.
Add the `import` statement at the top of the file, then add the following call
to `Adjust` in the `didFinishLaunching` or `didFinishLaunchingWithOptions`
method of your app delegate:

```objc
#import "Adjust.h"
// ...
NSString *yourAppToken = @"{YourAppToken}";
NSString *environment = ADJEnvironmentSandbox;
ADJConfig *adjustConfig = [ADJConfig configWithAppToken:yourAppToken
                                            environment:environment];
[Adjust appDidLaunch:adjustConfig];
```
![][delegate]

Replace `{YourAppToken}` with your app token. You can find this in your
[dashboard].

Depending on whether you build your app for testing or for production, you must
set `environment` with one of these values:

```objc
NSString *environment = ADJEnvironmentSandbox;
NSString *environment = ADJEnvironmentProduction;
```

**Important:** This value should be set to `ADJEnvironmentSandbox` if and only
if you or someone else is testing your app. Make sure to set the environment to
`ADJEnvironmentProduction` just before you publish the app. Set it back to
`ADJEnvironmentSandbox` when you start developing and testing it again.

We use this environment to distinguish between real traffic and test traffic
from test devices. It is very important that you keep this value meaningful at
all times! This is especially important if you are tracking revenue.

#### Adjust Logging

You can increase or decrease the amount of logs you see in tests by calling
`setLogLevel:` on your `ADJConfig` instance with one of the following
parameters:

```objc
[adjustConfig setLogLevel:ADJLogLevelVerbose]; // enable all logging
[adjustConfig setLogLevel:ADJLogLevelDebug];   // enable more logging
[adjustConfig setLogLevel:ADJLogLevelInfo];    // the default
[adjustConfig setLogLevel:ADJLogLevelWarn];    // disable info logging
[adjustConfig setLogLevel:ADJLogLevelError];   // disable warnings as well
[adjustConfig setLogLevel:ADJLogLevelAssert];  // disable errors as well
```

### 5. Build your app

Build and run your app. If the build succeeds, you should carefully read the
SDK logs in the console. After the app launched for the first time, you should
see the info log `Install tracked`.

![][run]

#### Troubleshooting

If your build failed with the error `Adjust requires ARC`, it looks like your
project is not using [ARC][arc]. In that case we recommend [transitioning your
project to use ARC][transition]. If you don't want to use ARC, you have to
enable ARC for all source files of adjust in the target's Build Phases:

Expand the `Compile Sources` group, select all adjust files (Adjust, ADJ...,
...+ADJAdditions) and change the `Compiler Flags` to `-fobjc-arc` (Select all
and press the `Return` key to change all at once).

## Additional features

Once you integrate the adjust SDK into your project, you can take advantage of
the following features.

### 6. Set up event tracking

You can use adjust to track events. Lets say you want to track every tap on a
particular button. You would create a new event token in your [dashboard],
which has an associated event token - looking something like `abc123`. In your
button's `buttonDown` method you would then add the following lines to track
the tap:

```objc
ADJEvent *event = [ADJEvent eventWithEventToken:@"abc123"];
[Adjust trackEvent:event];
```

When tapping the button you should now see `Event tracked` in the logs.

The event instance can be used to configure the event even more before tracking
it.

#### Add callback parameters

You can register a callback URL for your events in your [dashboard]. We will
send a GET request to that URL whenever the event gets tracked. You can add
callback parameters to that event by calling `addCallbackParameter` on the
event before tracking it. We will then append these parameters to your callback
URL.

For example, suppose you have registered the URL
`http://www.adjust.com/callback` then track an event like this:

```objc
ADJEvent *event = [ADJEvent eventWithEventToken:@"abc123"];
[event addCallbackParameter:@"key" value:@"value"];
[event addCallbackParameter:@"foo" value:@"bar"];
[Adjust trackEvent:event];
```

In that case we would track the event and send a request to:

    http://www.adjust.com/callback?key=value&foo=bar

It should be mentioned that we support a variety of placeholders like `{idfa}`
that can be used as parameter values. In the resulting callback this
placeholder would be replaced with the ID for Advertisers of the current
device. Also note that we don't store any of your custom parameters, but only
append them to your callbacks. If you haven't registered a callback for an
event, these parameters won't even be read.

You can read more about using URL callbacks, including a full list of available
values, in our [callbacks guide][callbacks-guide].

#### Track revenue

If your users can generate revenue by tapping on advertisements or making
in-app purchases you can track those revenues with events. Lets say a tap is
worth one Euro cent. You could then track the revenue event like this:

```objc
ADJEvent *event = [ADJEvent eventWithEventToken:@"abc123"];
[event setRevenue:0.01 currency:@"EUR"];
[Adjust trackEvent:event];
```

This can be combined with callback parameters of course.

When you set a currency token, adjust will automatically convert the incoming revenues into a reporting revenue of your choice. Read more about [currency conversion here.][currency-conversion]

You can read more about revenue and event tracking in the [event tracking guide.][event-tracking]

#### <a id="deduplication"></a> Revenue deduplication

You can also pass in an optional transaction ID to avoid tracking duplicate
revenues. The last ten transaction IDs are remembered and revenue events with
duplicate transaction IDs are skipped. This is especially useful for in-app
purchase tracking. See an example below.

If you want to track in-app purchases, please make sure to call `trackEvent`
after `finishTransaction` in `paymentQueue:updatedTransaction` only if the
state changed to `SKPaymentTransactionStatePurchased`. That way you can avoid
tracking revenue that is not actually being generated.

```objc
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased:
                [self finishTransaction:transaction];

                ADJEvent *event = [ADJEvent eventWithEventToken:...];
                [event setRevenue:... currency:...];
                [event setTransactionId:transaction.transactionIdentifier]; // avoid duplicates
                [Adjust trackEvent:event];

                break;
            // more cases
        }
    }
}
```

#### Receipt verification

If you track in-app purchases, you can also attach the receipt to the tracked
event. In that case our servers will verify that receipt with Apple and discard
the event if the verification failed. To make this work, you also need to send
us the transaction ID of the purchase. The transaction ID will also be used for
SDK side deduplication as explained [above](#deduplication):

```objc
NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
NSData *receipt = [NSData dataWithContentsOfURL:receiptURL];

ADJEvent *event = [ADJEvent eventWithEventToken:...];
[event setRevenue:... currency:...];
[event setReceipt:receipt transactionId:transaction.transactionIdentifier];

[Adjust trackEvent:event];
```

### 7. Set up deep link reattributions

You can set up the adjust SDK to handle deep links that are used to open your
app via a custom URL scheme. We will only read certain adjust specific
parameters. This is essential if you are planning to run retargeting or
re-engagement campaigns with deep links.

In the Project Navigator open the source file your Application Delegate. Find
or add the method `openURL` and add the following call to adjust:

```objc
- (BOOL)  application:(UIApplication *)application openURL:(NSURL *)url
    sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    [Adjust appWillOpenUrl:url];
    
    // Your code goes here
    Bool canHandle = [self someLogic:url];
    return canHandle;
}
```

### 8. Enable event buffering

If your app makes heavy use of event tracking, you might want to delay some
HTTP requests in order to send them in one batch every minute. You can enable
event buffering with your `ADJConfig` instance:

```objc
[adjustConfig setEventBufferingEnabled:YES];
```

### 9. Implement the attribution callback

You can register a delegate callback to be notified of tracker attribution
changes. Due to the different sources considered for attribution, this
information can not by provided synchronously. Follow these steps to implement
the optional delegate protocol in your app delegate:

Please make sure to consider our [applicable attribution data
policies.][attribution-data]

1. Open `AppDelegate.h` and add the import and the `AdjustDelegate`
   declaration.

    ```objc
    #import "Adjust.h"

    @interface AppDelegate : UIResponder <UIApplicationDelegate, AdjustDelegate>
    ```

2. Open `AppDelegate.m` and add the following delegate callback function to
   your app delegate implementation.

    ```objc
    - (void)adjustAttributionChanged:(ADJAttribution *)attribution {
    }
    ```

3. Set the delegate with your `ADJConfig` instance:

    ```objc
    [adjustConfig setDelegate:self];
    ```
    
As the delegate callback is configured using the `ADJConfig` instance, you
should call `setDelegate` before calling `[Adjust appDidLaunch:adjustConfig]`.

The delegate function will get when the SDK receives final attribution data.
Within the delegate function you have access to the `attribution` parameter.
Here is a quick summary of its properties:

- `NSString trackerToken` the tracker token of the current install.
- `NSString trackerName` the tracker name of the current install.
- `NSString network` the network grouping level of the current install.
- `NSString campaign` the campaign grouping level of the current install.
- `NSString adgroup` the ad group grouping level of the current install.
- `NSString creative` the creative grouping level of the current install.
- `NSString clickLabel` the click label of the current install.

### 10. Disable tracking

You can disable the adjust SDK from tracking any activities of the current
device by calling `setEnabled` with parameter `NO`. This setting is remembered
between sessions, but it can only be activated after the first session.

```objc
[Adjust setEnabled:NO];
```

You can check if the adjust SDK is currently enabled by calling the function
`isEnabled`. It is always possible to activate the adjust SDK by invoking
`setEnabled` with the enabled parameter as `YES`.

### 11. Offline mode

You can put the adjust SDK in offline mode to suspend transmission to our servers, 
while retaining tracked data to be sent later. While in offline mode, all information is saved
in a file, so be careful not to trigger too many events while in offline mode.

You can activate offline mode by calling `setOfflineMode` with the parameter `YES`.

```objc
[Adjust setOfflineMode:YES];
```

Conversely, you can deactivate offline mode by calling `setOfflineMode` with `NO`.
When the adjust SDK is put back in online mode, all saved information is send to our servers 
with the correct time information.

Unlike disabling tracking, this setting is *not remembered*
bettween sessions. This means that the SDK is in online mode whenever it is started,
even if the app was terminated in offline mode.

### 12. Partner parameters

You can also add parameters to be transmitted to network partners, for the
integrations that have been activated in your adjust dashboard.

This works similarly to the callback parameters mentioned above, but can
be added by calling the `addPartnerParameter` method on your `ADJEvent`
instance.

```objc
ADJEvent *event = [ADJEvent eventWithEventToken:@"abc123"];
[event addPartnerParameter:@"key" value:@"value"];
[Adjust trackEvent:event];
```

You can read more about special partners and these integrations in our
[guide to special partners.][special-partners]

[adjust.com]: http://adjust.com
[cocoapods]: http://cocoapods.org
[dashboard]: http://adjust.com
[example]: http://github.com/adjust/ios_sdk/tree/master/example
[releases]: https://github.com/adjust/ios_sdk/releases
[arc]: http://en.wikipedia.org/wiki/Automatic_Reference_Counting
[transition]: http://developer.apple.com/library/mac/#releasenotes/ObjectiveC/RN-TransitioningToARC/Introduction/Introduction.html
[drag]: https://raw.github.com/adjust/sdks/master/Resources/ios/drag4.png
[add]: https://raw.github.com/adjust/sdks/master/Resources/ios/add3.png
[framework]: https://raw.github.com/adjust/sdks/master/Resources/ios/framework4.png
[delegate]: https://raw.github.com/adjust/sdks/master/Resources/ios/delegate4.png
[run]: https://raw.github.com/adjust/sdks/master/Resources/ios/run4.png
[AEPriceMatrix]: https://github.com/adjust/AEPriceMatrix
[attribution-data]: https://github.com/adjust/sdks/blob/master/doc/attribution-data.md
[callbacks-guide]: https://docs.adjust.com/en/callbacks
[event-tracking]: https://docs.adjust.com/en/event-tracking
[special-partners]: https://docs.adjust.com/en/special-partners
[currency-conversion]: https://docs.adjust.com/en/event-tracking/#tracking-purchases-in-different-currencies

## License

The adjust-SDK is licensed under the MIT License.

Copyright (c) 2012-2014 adjust GmbH,
http://www.adjust.com

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
