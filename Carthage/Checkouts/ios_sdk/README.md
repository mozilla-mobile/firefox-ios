## Summary

This is the iOS SDK of Adjust™. You can read more about Adjust™ at [adjust.com].

If your app is an app which uses web views you would like to use adjust tracking from Javascript code, please consult our [iOS web views SDK guide][ios-web-views-guide].

Read this in other languages: [English][en-readme], [中文][zh-readme], [日本語][ja-readme], [한국어][ko-readme].

## Table of contents

* [Example apps](#example-apps)
* [Basic integration](#basic-integration)
   * [Add the SDK to your project](#sdk-add)
   * [Add iOS frameworks](#sdk-frameworks)
   * [Integrate the SDK into your app](#sdk-integrate)
   * [Basic setup](#basic-setup)
      * [iMessage specific setup](#basic-setup-imessage)
   * [Adjust logging](#adjust-logging)
   * [Build your app](#build-the-app)
* [Additional features](#additional-features)
   * [Event tracking](#event-tracking)
      * [Revenue tracking](#revenue-tracking)
      * [Revenue deduplication](#revenue-deduplication)
      * [In-App Purchase verification](#iap-verification)
      * [Callback parameters](#callback-parameters)
      * [Partner parameters](#partner-parameters)
      * [Callback identifier](#callback-id)
   * [Session parameters](#session-parameters)
      * [Session callback parameters](#session-callback-parameters)
      * [Session partner parameters](#session-partner-parameters)
      * [Delay start](#delay-start)
   * [Attribution callback](#attribution-callback)
   * [Ad revenue tracking](#ad-revenue)
   * [Event and session callbacks](#event-session-callbacks)
   * [Disable tracking](#disable-tracking)
   * [Offline mode](#offline-mode)
   * [Event buffering](#event-buffering)
   * [GDPR right to be forgotten](#gdpr-forget-me)
   * [SDK signature](#sdk-signature)
   * [Background tracking](#background-tracking)
   * [Device IDs](#device-ids)
      * [iOS Advertising Identifier](#di-idfa)
      * [Adjust device identifier](#di-adid)
   * [User attribution](#user-attribution)
   * [Push token](#push-token)
   * [Pre-installed trackers](#pre-installed-trackers)
   * [Deep linking](#deeplinking)
      * [Standard deep linking scenario](#deeplinking-standard)
      * [Deep linking on iOS 8 and earlier](#deeplinking-setup-old)
      * [Deep linking on iOS 9 and later](#deeplinking-setup-new)
      * [Deferred deep linking scenario](#deeplinking-deferred)
      * [Reattribution via deep links](#deeplinking-reattribution)
* [Troubleshooting](#troubleshooting)
   * [Issues with delayed SDK initialisation](#ts-delayed-init)
   * [I'm seeing "Adjust requires ARC" error](#ts-arc)
   * [I'm seeing "\[UIDevice adjTrackingEnabled\]: unrecognized selector sent to instance" error](#ts-categories)
   * [I'm seeing the "Session failed (Ignoring too frequent session.)" error](#ts-session-failed)
   * [I'm not seeing "Install tracked" in the logs](#ts-install-tracked)
   * [I'm seeing "Unattributable SDK click ignored" message](#ts-iad-sdk-click)
   * [I'm seeing wrong revenue data in the adjust dashboard](#ts-wrong-revenue-amount)
* [License](#license)

## <a id="example-apps"></a>Example apps

There are example apps inside the [`examples` directory][examples] for [`iOS (Objective-C)`][example-ios-objc], [`iOS (Swift)`][example-ios-swift], [`tvOS`][example-tvos], [`iMessage`][example-imessage] and [`Apple Watch`][example-iwatch]. You can open any of these Xcode projects to see an example of how the Adjust SDK can be integrated.

## <a id="basic-integration">Basic integration

We will describe the steps to integrate the Adjust SDK into your iOS project. We are going to assume that you are using Xcode for your iOS development.

### <a id="sdk-add"></a>Add the SDK to your project

If you're using [CocoaPods][cocoapods], you can add the following line to your `Podfile` and continue from [this step](#sdk-integrate):

```ruby
pod 'Adjust', '~> 4.18.3'
```

or:

```ruby
pod 'Adjust', :git => 'https://github.com/adjust/ios_sdk.git', :tag => 'v4.18.3'
```

---

If you're using [Carthage][carthage], you can add following line to your `Cartfile` and continue from [this step](#sdk-frameworks):

```ruby
github "adjust/ios_sdk"
```

---

You can also choose to integrate the Adjust SDK by adding it to your project as a framework. On the [releases page][releases] you can find the following archives:

* `AdjustSdkStatic.framework.zip`
* `AdjustSdkDynamic.framework.zip`
* `AdjustSdkTv.framework.zip`
* `AdjustSdkIm.framework.zip`

Since the release of iOS 8, Apple has introduced dynamic frameworks (also known as embedded frameworks). If your app is targeting iOS 8 or higher, you can use the Adjust SDK dynamic framework. Choose which framework you want to use – static or dynamic – and add it to your project.

If you are having `tvOS` app, you can use the Adjust SDK with it as well with usage of our tvOS framework which you can extract from `AdjustSdkTv.framework.zip` archive.

If you are having `iMessage` app, you can use the Adjust SDK with it as well with usage of our IM framework which you can extract from `AdjustSdkIm.framework.zip` archive.

### <a id="sdk-frameworks"></a>Add iOS frameworks

1. Select your project in the Project Navigator
2. In the left-hand side of the main view, select your target
3. In the `Build Phases` tab, expand the `Link Binary with Libraries` group
4. At the bottom of that section, select the `+` button
5. Select the `AdSupport.framework`, then the `Add` button 
6. Unless you are using tvOS, repeat the same steps to add the `iAd.framework` and `CoreTelephony.framework`
7. Change the `Status` of the frameworks to `Optional`.

### <a id="sdk-integrate"></a>Integrate the SDK into your app

If you added the Adjust SDK via a Pod repository, you should use one of the following import statements:

```objc
#import "Adjust.h"
```

or

```objc
#import <Adjust/Adjust.h>
```

---

If you added the Adjust SDK as a static/dynamic framework or via Carthage, you should use the following import statement:

```objc
#import <AdjustSdk/Adjust.h>
```

---

If you are are using the Adjust SDK with your tvOS app, you should use the following import statement:

```objc
#import <AdjustSdkTv/Adjust.h>
```

---

If you are are using the Adjust SDK with your iMessage app, you should use the following import statement:

```objc
#import <AdjustSdkIm/Adjust.h>
```

Next, we'll set up basic session tracking.

### <a id="basic-setup"></a>Basic setup

In the Project Navigator, open the source file of your application delegate. Add the `import` statement at the top of the file, then add the following call to `Adjust` in the `didFinishLaunching` or `didFinishLaunchingWithOptions` method of your app delegate:

```objc
#import "Adjust.h"
// or #import <Adjust/Adjust.h>
// or #import <AdjustSdk/Adjust.h>
// or #import <AdjustSdkTv/Adjust.h>
// or #import <AdjustSdkIm/Adjust.h>

// ...

NSString *yourAppToken = @"{YourAppToken}";
NSString *environment = ADJEnvironmentSandbox;
ADJConfig *adjustConfig = [ADJConfig configWithAppToken:yourAppToken
                                            environment:environment];

[Adjust appDidLaunch:adjustConfig];
```

![][delegate]

**Note**: Initialising the Adjust SDK like this is `very important`. Otherwise, you may encounter different kinds of issues as described in our [troubleshooting section](#ts-delayed-init).

Replace `{YourAppToken}` with your app token. You can find this in your [dashboard].

Depending on whether you build your app for testing or for production, you must set `environment` with one of these values:

```objc
NSString *environment = ADJEnvironmentSandbox;
NSString *environment = ADJEnvironmentProduction;
```

**Important:** This value should be set to `ADJEnvironmentSandbox` if and only if you or someone else is testing your app. Make sure to set the environment to `ADJEnvironmentProduction` just before you publish the app. Set it back to `ADJEnvironmentSandbox` when you start developing and testing it again.

We use this environment to distinguish between real traffic and test traffic from test devices. It is very important that you keep this value meaningful at all times! This is especially important if you are tracking revenue.

### <a id="basic-setup-imessage"></a>iMessage specific setup

**Adding SDK from source:** In case that you have chosen to add Adjust SDK to your iMessage app **from source**, please make sure that you have pre-processor macro **ADJUST_IM=1** set in your iMessage project settings.

**Adding SDK as framework:** After you have added `AdjustSdkIm.framework` to your iMessage app, please make sure to add `New Copy Files Phase` in your `Build Phases` project settings and select that `AdjustSdkIm.framework` should be copied to `Frameworks` folder.

**Session tracking:** If you would like to have session tracking properly working in your iMessage app, you will need to do one additional integration step. In standard iOS apps Adjust SDK is automatically subscribed to iOS system notifications which enable us to know when app entered or left foreground. In case of iMessage app, this is not the case, so we need you to add explicit calls to `trackSubsessionStart` and `trackSubsessionEnd` methods inside of your iMessage app view controller to make our SDK aware of the moments when your app is being in foreground or not.

Add call to `trackSubsessionStart` inside of `didBecomeActiveWithConversation:` method:

```objc
-(void)didBecomeActiveWithConversation:(MSConversation *)conversation {
    // Called when the extension is about to move from the inactive to active state.
    // This will happen when the extension is about to present UI.
    // Use this method to configure the extension and restore previously stored state.

    [Adjust trackSubsessionStart];
}
```

Add call to `trackSubsessionEnd` inside of `willResignActiveWithConversation:` method:

```objc
-(void)willResignActiveWithConversation:(MSConversation *)conversation {
    // Called when the extension is about to move from the active to inactive state.
    // This will happen when the user dissmises the extension, changes to a different
    // conversation or quits Messages.
    
    // Use this method to release shared resources, save user data, invalidate timers,
    // and store enough state information to restore your extension to its current state
    // in case it is terminated later.

    [Adjust trackSubsessionEnd];
}
```

With this set, Adjust SDK will be able to successfully perform session tracking inside of your iMessage app.

**Note:** You should be aware that your iOS app and iMessage extension you wrote for it are running in different memory spaces and they as well have different bundle identifiers. Initialising Adjust SDK with same app token in both places will result in two independent instances tracking things unaware of each other which might cause data mixture you don't want to see in your dashboard data. General advice would be to create separate app in Adjust dashboard for your iMessage app and initialise SDK inside of it with separate app token.

### <a id="adjust-logging"></a>Adjust logging

You can increase or decrease the amount of logs that you see during testing by calling `setLogLevel:` on your `ADJConfig` instance with one of the following parameters:

```objc
[adjustConfig setLogLevel:ADJLogLevelVerbose];  // enable all logging
[adjustConfig setLogLevel:ADJLogLevelDebug];    // enable more logging
[adjustConfig setLogLevel:ADJLogLevelInfo];     // the default
[adjustConfig setLogLevel:ADJLogLevelWarn];     // disable info logging
[adjustConfig setLogLevel:ADJLogLevelError];    // disable warnings as well
[adjustConfig setLogLevel:ADJLogLevelAssert];   // disable errors as well
[adjustConfig setLogLevel:ADJLogLevelSuppress]; // disable all logging
```

If you don't want your app in production to display any logs coming from the Adjust SDK, then you should select `ADJLogLevelSuppress` and in addition to that, initialise `ADJConfig` object with another constructor where you should enable suppress log level mode:

```objc
#import "Adjust.h"
// or #import <Adjust/Adjust.h>
// or #import <AdjustSdk/Adjust.h>
// or #import <AdjustSdkTv/Adjust.h>
// or #import <AdjustSdkIm/Adjust.h>

// ...

NSString *yourAppToken = @"{YourAppToken}";
NSString *environment = ADJEnvironmentSandbox;
ADJConfig *adjustConfig = [ADJConfig configWithAppToken:yourAppToken
                                            environment:environment
                                   allowSuppressLogLevel:YES];

[Adjust appDidLaunch:adjustConfig];
```

### <a id="build-the-app"></a>Build your app

Build and run your app. If the build succeeds, you should carefully read the SDK logs in the console. After the app launches for the first time, you should see the info log `Install tracked`.

![][run]

## <a id="additional-feature">Additional features

Once you integrate the Adjust SDK into your project, you can take advantage of the following features.

### <a id="event-tracking"></a>Event tracking

You can use adjust to track events. Lets say you want to track every tap on a particular button. You would create a new event token in your [dashboard], which has an associated event token - looking something like `abc123`. In your button's `buttonDown` method you would then add the following lines to track the tap:

```objc
ADJEvent *event = [ADJEvent eventWithEventToken:@"abc123"];
[Adjust trackEvent:event];
```

When tapping the button you should now see `Event tracked` in the logs.

The event instance can be used to configure the event further before tracking it:

### <a id="revenue-tracking"></a>Revenue tracking

If your users can generate revenue by tapping on advertisements or making in-app purchases you can track those revenues with events. Lets say a tap is worth one Euro cent. You could then track the revenue event like this:

```objc
ADJEvent *event = [ADJEvent eventWithEventToken:@"abc123"];

[event setRevenue:0.01 currency:@"EUR"];

[Adjust trackEvent:event];
```

This can be combined with callback parameters of course.

When you set a currency token, adjust will automatically convert the incoming revenues into a reporting revenue of your choice. Read more about [currency conversion here.][currency-conversion]

You can read more about revenue and event tracking in the [event tracking guide](https://docs.adjust.com/en/event-tracking/#tracking-purchases-and-revenues).

### <a id="revenue-deduplication"></a>Revenue deduplication

You can also pass in an optional transaction ID to avoid tracking duplicate revenues. The last ten transaction IDs are remembered and revenue events with duplicate transaction IDs are skipped. This is especially useful for in-app purchase tracking. See an example below.

If you want to track in-app purchases, please make sure to call `trackEvent` after `finishTransaction` in `paymentQueue:updatedTransaction` only if the state changed to `SKPaymentTransactionStatePurchased`. That way you can avoid tracking revenue that is not actually being generated.

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

### <a id="iap-verification"></a>In-App Purchase verification

If you want to check the validity of In-App Purchases made in your app using Purchase Verification, adjust's server side receipt verification tool, then check out our iOS purchase SDK and read more about it [here][ios-purchase-verification].

### <a id="callback-parameters"></a>Callback parameters

You can register a callback URL for your events in your [dashboard]. We will send a GET request to that URL whenever the event is tracked. You can add callback parameters to that event by calling `addCallbackParameter` to the event before tracking it. We will then append these parameters to your callback URL.

For example, suppose you have registered the URL `http://www.mydomain.com/callback` then track an event like this:

```objc
ADJEvent *event = [ADJEvent eventWithEventToken:@"abc123"];

[event addCallbackParameter:@"key" value:@"value"];
[event addCallbackParameter:@"foo" value:@"bar"];

[Adjust trackEvent:event];
```

In that case we would track the event and send a request to:

    http://www.mydomain.com/callback?key=value&foo=bar

It should be mentioned that we support a variety of placeholders like `{idfa}` that can be used as parameter values. In the resulting callback this placeholder would be replaced with the ID for Advertisers of the current device. Also note that we don't store any of your custom parameters, but only append them to your callbacks, thus without a callback they will not be saved nor sent to you.

You can read more about using URL callbacks, including a full list of available values, in our [callbacks guide][callbacks-guide].

### <a id="partner-parameters"></a>Partner parameters

You can also add parameters to be transmitted to network partners, which have been activated in your Adjust dashboard.

This works similarly to the callback parameters mentioned above, but can be added by calling the `addPartnerParameter` method on your `ADJEvent` instance.

```objc
ADJEvent *event = [ADJEvent eventWithEventToken:@"abc123"];

[event addPartnerParameter:@"key" value:@"value"];
[event addPartnerParameter:@"foo" value:@"bar"];

[Adjust trackEvent:event];
```

You can read more about special partners and these integrations in our [guide to special partners][special-partners].

### <a id="callback-id"></a>Callback identifier

You can also add custom string identifier to each event you want to track. This identifier will later be reported in event success and/or event failure callbacks to enable you to keep track on which event was successfully tracked or not. You can set this identifier by calling the `setCallbackId` method on your `ADJEvent` instance:


```objc
ADJEvent *event = [ADJEvent eventWithEventToken:@"abc123"];

[event setCallbackId:@"Your-Custom-Id"];

[Adjust trackEvent:event];
```

### <a id="session-parameters"></a>Session parameters

Some parameters are saved to be sent in every event and session of the Adjust SDK. Once you have added any of these parameters, you don't need to add them every time, since they will be saved locally. If you add the same parameter twice, there will be no effect.

If you want to send session parameters with the initial install event, they must be called before the Adjust SDK launches via `[Adjust appDidLaunch:]`. If you need to send them with an install, but can only obtain the needed values after launch, it's possible to [delay](#delay-start) the first launch of the Adjust SDK to allow this behavior.

### <a id="session-callback-parameters"></a>Session callback parameters

The same callback parameters that are registered for [events](#callback-parameters) can be also saved to be sent in every event or session of the Adjust SDK.

The session callback parameters have a similar interface of the event callback parameters. Instead of adding the key and it's value to an event, it's added through a call to `Adjust` method `addSessionCallbackParameter:value:`:

```objc
[Adjust addSessionCallbackParameter:@"foo" value:@"bar"];
```

The session callback parameters will be merged with the callback parameters added to an event. The callback parameters added to an event have precedence over the session callback parameters. Meaning that, when adding a callback parameter to an event with the same key to one added from the session, the value that prevails is the callback parameter added to the event.

It's possible to remove a specific session callback parameter by passing the desiring key to the method `removeSessionCallbackParameter`.

```objc
[Adjust removeSessionCallbackParameter:@"foo"];
```

If you wish to remove all key and values from the session callback parameters, you can reset it with the method `resetSessionCallbackParameters`.

```objc
[Adjust resetSessionCallbackParameters];
```

### <a id="session-partner-parameters"></a>Session partner parameters

In the same way that there is [session callback parameters](#session-callback-parameters) that are sent every in event or session of the Adjust SDK, there is also session partner parameters.

These will be transmitted to network partners, for the integrations that have been activated in your adjust [dashboard].

The session partner parameters have a similar interface to the event partner parameters. Instead of adding the key and it's value to an event, it's added through a call to `Adjust` method `addSessionPartnerParameter:value:`:

```objc
[Adjust addSessionPartnerParameter:@"foo" value:@"bar"];
```

The session partner parameters will be merged with the partner parameters added to an event. The partner parameters added to an event have precedence over the session partner parameters. Meaning that, when adding a partner parameter to an event with the same key to one added from the session, the value that prevails is the partner parameter added to the event.

It's possible to remove a specific session partner parameter by passing the desiring key to the method `removeSessionPartnerParameter`.

```objc
[Adjust removeSessionPartnerParameter:@"foo"];
```

If you wish to remove all key and values from the session partner parameters, you can reset it with the method `resetSessionPartnerParameters`.

```objc
[Adjust resetSessionPartnerParameters];
```

### <a id="delay-start"></a>Delay start

Delaying the start of the Adjust SDK allows your app some time to obtain session parameters, such as unique identifiers, to be send on install.

Set the initial delay time in seconds with the method `setDelayStart` in the `ADJConfig` instance:

```objc
[adjustConfig setDelayStart:5.5];
```

In this case this will make the Adjust SDK not send the initial install session and any event created for 5.5 seconds. After this time is expired or if you call `[Adjust sendFirstPackages]` in the meanwhile, every session parameter will be added to the delayed install session and events and the Adjust SDK will resume as usual.

**The maximum delay start time of the Adjust SDK is 10 seconds**.

### <a id="attribution-callback"></a>Attribution callback

You can register a delegate callback to be notified of tracker attribution changes. Due to the different sources considered for attribution, this information can not be provided synchronously. Follow these steps to implement the optional delegate protocol in your app delegate:

Please make sure to consider our [applicable attribution data policies.][attribution-data]

1. Open `AppDelegate.h` and add the import and the `AdjustDelegate` declaration.

    ```objc
    @interface AppDelegate : UIResponder <UIApplicationDelegate, AdjustDelegate>
    ```

2. Open `AppDelegate.m` and add the following delegate callback function to your app delegate implementation.

    ```objc
    - (void)adjustAttributionChanged:(ADJAttribution *)attribution {
    }
    ```

3. Set the delegate with your `ADJConfig` instance:

    ```objc
    [adjustConfig setDelegate:self];
    ```

As the delegate callback is configured using the `ADJConfig` instance, you should call `setDelegate` before calling `[Adjust appDidLaunch:adjustConfig]`.

The delegate function will be called after the SDK receives the final attribution data. Within the delegate function you have access to the `attribution` parameter. Here is a quick summary of its properties:

- `NSString trackerToken` the tracker token of the current attribution.
- `NSString trackerName` the tracker name of the current attribution.
- `NSString network` the network grouping level of the current attribution.
- `NSString campaign` the campaign grouping level of the current attribution.
- `NSString adgroup` the ad group grouping level of the current attribution.
- `NSString creative` the creative grouping level of the current attribution.
- `NSString clickLabel` the click label of the current attribution.
- `NSString adid` the unique device identifier provided by attribution.

If any value is unavailable, it will default to `nil`.

### <a id="ad-revenue"></a>Ad revenue tracking

You can track ad revenue information with Adjust SDK by invoking following method:

```objc
[Adjust trackAdRevenue:source payload:payload];
```

Parameters of the method which you need to pass are:

- `source` - `NSString` object which indicates the source of ad revenue info.
- `payload` - `NSData` object which contains ad revenue JSON.

Currently we support the below `source` parameter values:

- `ADJAdRevenueSourceMopub` - representing MoPub mediation platform (for more information, check [integration guide][sdk2sdk-mopub])

### <a id="event-session-callbacks"></a>Event and session callbacks

You can register a delegate callback to be notified of successful and failed tracked events and/or sessions. The same optional protocol `AdjustDelegate` used for the [attribution callback](#attribution-callback) is used.

Follow the same steps and implement the following delegate callback function for successful tracked events:

```objc
- (void)adjustEventTrackingSucceeded:(ADJEventSuccess *)eventSuccessResponseData {
}
```

The following delegate callback function for failed tracked events:

```objc
- (void)adjustEventTrackingFailed:(ADJEventFailure *)eventFailureResponseData {
}
```

For successful tracked sessions:

```objc
- (void)adjustSessionTrackingSucceeded:(ADJSessionSuccess *)sessionSuccessResponseData {
}
```

And for failed tracked sessions:

```objc
- (void)adjustSessionTrackingFailed:(ADJSessionFailure *)sessionFailureResponseData {
}
```

The delegate functions will be called after the SDK tries to send a package to the server. Within the delegate callback you have access to a response data object specifically for the delegate callback. Here is a quick summary of the session response data properties:

- `NSString message` the message from the server or the error logged by the SDK.
- `NSString timeStamp` timestamp from the server.
- `NSString adid` a unique device identifier provided by adjust.
- `NSDictionary jsonResponse` the JSON object with the response from the server.

Both event response data objects contain:

- `NSString eventToken` the event token, if the package tracked was an event.
- `NSString callbackId` the custom defined callback ID set on event object.

If any value is unavailable, it will default to `nil`.

And both event and session failed objects also contain:

- `BOOL willRetry` indicates that there will be an attempt to resend the package at a later time.

### <a id="disable-tracking"></a>Disable tracking

You can disable the Adjust SDK from tracking any activities of the current device by calling `setEnabled` with parameter `NO`. **This setting is remembered between sessions**.

```objc
[Adjust setEnabled:NO];
```

<a id="is-enabled">You can check if the Adjust SDK is currently enabled by calling the function `isEnabled`. It is always possible to activate the Adjust SDK by invoking `setEnabled` with the enabled parameter as `YES`.

### <a id="offline-mode"></a>Offline mode

You can put the Adjust SDK in offline mode to suspend transmission to our servers while retaining tracked data to be sent later. While in offline mode, all information is saved in a file, so be careful not to trigger too many events while in offline mode.

You can activate offline mode by calling `setOfflineMode` with the parameter `YES`.

```objc
[Adjust setOfflineMode:YES];
```

Conversely, you can deactivate offline mode by calling `setOfflineMode` with `NO`. When the Adjust SDK is put back in online mode, all saved information is sent to our servers with the correct time information.

Unlike disabling tracking, this setting is **not remembered** bettween sessions. This means that the SDK is in online mode whenever it is started, even if the app was terminated in offline mode.

### <a id="event-buffering"></a>Event buffering

If your app makes heavy use of event tracking, you might want to delay some HTTP requests in order to send them in one batch every minute. You can enable event buffering with your `ADJConfig` instance:

```objc
[adjustConfig setEventBufferingEnabled:YES];
```

If nothing is set, event buffering is **disabled by default**.

### <a id="gdpr-forget-me"></a>GDPR right to be forgotten

In accordance with article 17 of the EU's General Data Protection Regulation (GDPR), you can notify Adjust when a user has exercised their right to be forgotten. Calling the following method will instruct the Adjust SDK to communicate the user's choice to be forgotten to the Adjust backend:

```objc
[Adjust gdprForgetMe];
```

Upon receiving this information, Adjust will erase the user's data and the Adjust SDK will stop tracking the user. No requests from this device will be sent to Adjust in the future.

### <a id="sdk-signature"></a> SDK signature

The Adjust SDK signature is enabled on a client-by-client basis. If you are interested in using this feature, please contact your account manager.

If the SDK signature has already been enabled on your account and you have access to App Secrets in your Adjust Dashboard, please use the method below to integrate the SDK signature into your app.

An App Secret is set by calling `setAppSecret` on your `AdjustConfig` instance:

```objc
[adjustConfig setAppSecret:secretId info1:info1 info2:info2 info3:info3 info4:info4];
```

### <a id="background-tracking"></a>Background tracking

The default behaviour of the Adjust SDK is to pause sending HTTP requests while the app is in the background. You can change this in your `AdjustConfig` instance:

```objc
[adjustConfig setSendInBackground:YES];
```

If nothing is set, sending in background is **disabled by default**.

### <a id="device-ids"></a>Device IDs

The Adjust SDK offers you possibility to obtain some of the device identifiers.

### <a id="di-idfa"></a>iOS Advertising Identifier

Certain services (such as Google Analytics) require you to coordinate device and client IDs in order to prevent duplicate reporting.

To obtain the device identifier IDFA, call the function `idfa`:

```objc
NSString *idfa = [Adjust idfa];
```

### <a id="di-adid"></a>Adjust device identifier

For each device with your app installed, adjust backend generates unique **adjust device identifier** (**adid**). In order to obtain this identifier, you can make a call to the following method on the `Adjust` instance:

```objc
NSString *adid = [Adjust adid];
```

**Note**: Information about the **adid** is available after the app's installation has been tracked by the adjust backend. From that moment on, the Adjust SDK has information about the device **adid** and you can access it with this method. So, **it is not possible** to access the **adid** before the SDK has been initialised and the installation of your app has been tracked successfully.

### <a id="user-attribution"></a>User attribution

The attribution callback will be triggered as described in the [attribution callback section](#attribution-callback), providing you with the information about any new attribution when ever it changes. In any other case, where you want to access information about your user's current attribution, you can make a call to the following method of the `Adjust` instance:

```objc
ADJAttribution *attribution = [Adjust attribution];
```

**Note**: Information about current attribution is available after app installation has been tracked by the adjust backend and attribution callback has been initially triggered. From that moment on, Adjust SDK has information about your user's attribution and you can access it with this method. So, **it is not possible** to access user's attribution value before the SDK has been initialised and attribution callback has been initially triggered.

### <a id="push-token"></a>Push token

Push tokens are used for Audience Builder and client callbacks, and they are required for uninstall and reinstall tracking.

To send us the push notification token, add the following call to `Adjust` in the `didRegisterForRemoteNotificationsWithDeviceToken` of your app delegate:

```objc
- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [Adjust setDeviceToken:deviceToken];
}
```

### <a id="pre-installed-trackers"></a>Pre-installed trackers

If you want to use the Adjust SDK to recognize users that found your app pre-installed on their device, follow these steps.

1. Create a new tracker in your [dashboard].
2. Open your app delegate and add set the default tracker of your `ADJConfig`:

  ```objc
  ADJConfig *adjustConfig = [ADJConfig configWithAppToken:yourAppToken environment:environment];
  [adjustConfig setDefaultTracker:@"{TrackerToken}"];
  [Adjust appDidLaunch:adjustConfig];
  ```

  Replace `{TrackerToken}` with the tracker token you created in step 2. Please note that the dashboard displays a tracker
  URL (including `http://app.adjust.com/`). In your source code, you should specify only the six-character token and not
  the entire URL.

3. Build and run your app. You should see a line like the following in XCode:

    ```
    Default tracker: 'abc123'
    ```

### <a id="deeplinking"></a>Deep linking

If you are using the adjust tracker URL with an option to deep link into your app from the URL, there is the possibility to get info about the deep link URL and its content. Hitting the URL can happen when the user has your app already installed (standard deep linking scenario) or if they don't have the app on their device (deferred deep linking scenario). Both of these scenarios are supported by the Adjust SDK and in both cases the deep link URL will be provided to you after you app has been started after hitting the tracker URL. In order to use this feature in your app, you need to set it up properly.

### <a id="deeplinking-standard"></a>Standard deep linking scenario

If your user already has the app installed and hits the tracker URL with deep link information in it, your application will be opened and the content of the deep link will be sent to your app so that you can parse it and decide what to do next. With introduction of iOS 9, Apple has changed the way how deep linking should be handled in the app. Depending on which scenario you want to use for your app (or if you want to use them both to support wide range of devices), you need to set up your app to handle one or both of the following scenarios.

### <a id="deeplinking-setup-old"></a>Deep linking on iOS 8 and earlier

Deep linking on iOS 8 and earlier devices is being done with usage of a custom URL scheme setting. You need to pick a custom URL scheme name which your app will be in charge for opening. This scheme name will also be used in the adjust tracker URL as part of the `deep_link` parameter. In order to set this in your app, open your `Info.plist` file and add new `URL types` row to it. In there, as `URL identifier` write you app's bundle ID and under `URL schemes` add scheme name(s) which you want your app to handle. In the example below, we have chosen that our app should handle the `adjustExample` scheme name.

![][custom-url-scheme]

After this has been set up, your app will be opened after you click the adjust tracker URL with `deep_link` parameter which contains the scheme name which you have chosen. After app is opened, `openURL` method of your `AppDelegate` class will be triggered and the place where the content of the `deep_link` parameter from the tracker URL will be delivered. If you want to access the content of the deep link, override this method.

```objc
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    // url object contains your deep link content

    // Apply your logic to determine the return value of this method
    return YES;
    // or
    // return NO;
}
```

With this setup, you have successfully set up deep linking handling for iOS devices with iOS 8 and earlier versions.

### <a id="deeplinking-setup-new"></a>Deep linking on iOS 9 and later

In order to set deep linking support for iOS 9 and later devices, you need to enable your app to handle Apple universal links. To find out more about universal links and how their setup looks like, you can check [here][universal-links].

Adjust is taking care of lots of things to do with universal links behind the scenes. But, in order to support universal links with the adjust, you need to perform small setup for universal links in the adjust dashboard. For more information on that should be done, please consult our official [docs][universal-links-guide].

Once you have successfully enabled the universal links feature in the dashboard, you need to do this in your app as well:

After enabling `Associated Domains` for your app in Apple Developer Portal, you need to do the same thing in your app's Xcode project. After enabling `Assciated Domains`, add the universal link which was generated for you in the adjust dashboard in the `Domains` section by prefixing it with `applinks:` and make sure that you also remove the `http(s)` part of the universal link.

![][associated-domains-applinks]

After this has been set up, your app will be opened after you click the adjust tracker universal link. After app is opened, `continueUserActivity` method of your `AppDelegate` class will be triggered and the place where the content of the universal link URL will be delivered. If you want to access the content of the deep link, override this method.

``` objc
- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity
 restorationHandler:(void (^)(NSArray *restorableObjects))restorationHandler {
    if ([[userActivity activityType] isEqualToString:NSUserActivityTypeBrowsingWeb]) {
        NSURL *url = [userActivity webpageURL];

        // url object contains your universal link content
    }

    // Apply your logic to determine the return value of this method
    return YES;
    // or
    // return NO;
}
```

With this setup, you have successfully set up deep linking handling for iOS devices with iOS 9 and later versions.

We provide a helper function that allows you to convert a universal link to an old style deep link URL, in case you had some custom logic in your code which was always expecting deep link info to arrive in old style custom URL scheme format. You can call this method with universal link and the custom URL scheme name which you would like to see your deep link prefixed with and we will generate the custom URL scheme deep link for you:

``` objc
- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity
 restorationHandler:(void (^)(NSArray *restorableObjects))restorationHandler {
    if ([[userActivity activityType] isEqualToString:NSUserActivityTypeBrowsingWeb]) {
        NSURL *url = [userActivity webpageURL];

        NSURL *oldStyleDeeplink = [Adjust convertUniversalLink:url scheme:@"adjustExample"];
    }

    // Apply your logic to determine the return value of this method
    return YES;
    // or
    // return NO;
}
```

### <a id="deeplinking-deferred"></a>Deferred deep linking scenario

You can register a delegate callback to be notified before a deferred deep link is opened and decide if the Adjust SDK will try to open it. The same optional protocol `AdjustDelegate` used for the [attribution callback](#attribution-callback) and for [event and session callbacks](#event-session-callbacks) is used.

Follow the same steps and implement the following delegate callback function for deferred deep links:

```objc
- (BOOL)adjustDeeplinkResponse:(NSURL *)deeplink {
    // deeplink object contains information about deferred deep link content

    // Apply your logic to determine whether the Adjust SDK should try to open the deep link
    return YES;
    // or
    // return NO;
}
```

The callback function will be called after the SDK receives a deffered deep link from our server and before opening it. Within the callback function you have access to the deep link. The returned boolean value determines if the SDK will launch the deep link. You could, for example, not allow the SDK to open the deep link at the current moment, save it, and open it yourself later.

If this callback is not implemented, **the Adjust SDK will always try to open the deep link by default**.

### <a id="deeplinking-reattribution"></a>Reattribution via deep links

Adjust enables you to run re-engagement campaigns with usage of deep links. For more information on how to do that, please check our [official docs][reattribution-with-deeplinks].

If you are using this feature, in order for your user to be properly reattributed, you need to make one additional call to the Adjust SDK in your app.

Once you have received deep link content information in your app, add a call to the `appWillOpenUrl` method. By making this call, the Adjust SDK will try to find if there is any new attribution info inside of the deep link and if any, it will be sent to the adjust backend. If your user should be reattributed due to a click on the adjust tracker URL with deep link content in it, you will see the [attribution callback](#attribution-callback) in your app being triggered with new attribution info for this user.

The call to `appWillOpenUrl` should be done like this to support deep linking reattributions in all iOS versions:

```objc
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    // url object contains your deep link content
    
    [Adjust appWillOpenUrl:url];

    // Apply your logic to determine the return value of this method
    return YES;
    // or
    // return NO;
}
```

``` objc
- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity
 restorationHandler:(void (^)(NSArray *restorableObjects))restorationHandler {
    if ([[userActivity activityType] isEqualToString:NSUserActivityTypeBrowsingWeb]) {
        NSURL url = [userActivity webpageURL];

        [Adjust appWillOpenUrl:url];
    }

    // Apply your logic to determine the return value of this method
    return YES;
    // or
    // return NO;
}
```

## <a id="troubleshooting"></a>Troubleshooting

### <a id="ts-delayed-init"></a>Issues with delayed SDK initialisation

As described in the [basic setup step](#basic-setup), we strongly advise you to initialise the Adjust SDK in the `didFinishLaunching` or `didFinishLaunchingWithOptions` method of your app delegate. It is imperative to initialise the Adjust SDK in as soon as possible so that you can use all the features of the SDK.

Deciding not to initialise the Adjust SDK immediately can have all kinds of impacts on the tracking in your app: **In order to perform any kind of tracking in your app, the Adjust SDK *must* be initialised.**

If you decide to perform any of these actions:

* [Event tracking](#event-tracking)
* [Reattribution via deep links](#deeplinking-reattribution)
* [Disable tracking](#disable-tracking)
* [Offline mode](#offline-mode)

before initialising the SDK, `they won't be performed`.

If you want any of these actions to be tracked with the Adjust SDK before its actual initialisation, you must build a `custom actions queueing mechanism` inside your app. You need to queue all the actions you want our SDK to perform and perform them once the SDK is initialised.

Offline mode state won't be changed, tracking enabled/disabled state won't be changed, deep link reattributions will not be possible to happen, any of tracked events will be `dropped`.

Another thing which might be affected by delayed SDK initialisation is session tracking. The Adjust SDK can't start to collect any session length info before it is actually initialised. This can affect your DAU numbers in the dashboard which might not be tracked properly.

As an example, let's assume this scenario: You are initialising the Adjust SDK when some specific view or view controller is loaded and let's say that this is not the splash nor the first screen in your app, but user has to navigate to it from the home screen. If user downloads your app and opens it, the home screen will be displayed. At this moment, this user has made an install which should be tracked. However, the Adjust SDK doesn't know anything about this, because the user needs to navigate to the screen mentioned previously where you decided to initialise the Adjust SDK. Further, if the user decides that he/she doesn't like the app and uninstalls it right after seeing home screen, all the information mentioned above will never be tracked by our SDK, nor displayed in the dashboard.

#### Event tracking

For the events you want to track, queue them with some internal queueing mechanism and track them after SDK is initialised. Tracking events before initialising SDK will cause the events to be `dropped` and `permanently lost`, so make sure you are tracking them once SDK is `initialised` and [`enabled`](#is-enabled).

#### Offline mode and enable/disable tracking

Offline mode is not the feature which is persisted between SDK initialisations, so it is set to `false` by default. If you try to enable offline mode before initialising SDK, it will still be set to `false` when you eventually initialise the SDK.

Enabling/disabling tracking is the setting which is persisted between the SDK initialisations. If you try to toggle this value before initialising the SDK, toggle attempt will be ignored. Once initialised, SDK will be in the state (enabled or disabled) like before this toggle attempt.

#### Reattribution via deep links

As described [above](#deeplinking-reattribution), when handling deep link reattributions, depending on deep linking mechanism you are using (old style vs. universal links), you will obtain `NSURL` object after which you need to make following call:

```objc
[Adjust appWillOpenUrl:url]
```

If you make this call before the SDK has been initialised, information about the attribution information from the deep link URL will be permanetly lost. If you want the Adjust SDK to successfully reattribute your user, you would need to queue this `NSURL` object information and trigger `appWillOpenUrl` method once the SDK has been initialised.

#### Session tracking

Session tracking is something what the Adjust SDK performs automatically and is beyond reach of an app developer. For proper session tracking it is crucial to have the Adjust SDK initialised as advised in this README. Not doing so can have unpredicted influences on proper session tracking and DAU numbers in the dashboard.

For example:
* A user opens but then deletes your app before the SDK was even inialised, causing the install and session to have never been tracked, thus never reported in the dashboard.
* If a user downloads and opens your app before midnight, and the Adjust SDK gets initialised after midnight, all queued install and session data will be reported on wrong day.
* If a user didn't use your app on some day but opens it shortly after midnight and the SDK gets initialised after midnight, causing DAU to be reported on another day from the day of the app opening.

For all these reasons, please follow the instructions in this document and initialise the Adjust SDK in the `didFinishLaunching` or `didFinishLaunchingWithOptions` method of your app delegate.

### <a id="ts-arc"></a>I'm seeing "Adjust requires ARC" error

If your build failed with the error `Adjust requires ARC`, it looks like your project is not using [ARC][arc]. In that case we recommend [transitioning your project][transition] so that it does use ARC. If you don't want to use ARC, you have to enable ARC for all source files of adjust in the target's Build Phases:

Expand the `Compile Sources` group, select all adjust files and change the `Compiler Flags` to `-fobjc-arc` (Select all and press the `Return` key to change all at once).

### <a id="ts-categories"></a>I'm seeing "[UIDevice adjTrackingEnabled]: unrecognized selector sent to instance" error

This error can occur when you are adding the Adjust SDK framework to your app. The Adjust SDK contains `categories` among it's source files and for this reason, if you have chosen this SDK integration approach, you need to add `-ObjC` flags to `Other Linker Flags` in your Xcode project settings. Adding this flag will fix this error.

### <a id="ts-session-failed"></a>I'm seeing the "Session failed (Ignoring too frequent session.)" error

This error typically occurs when testing installs. Uninstalling and reinstalling the app is not enough to trigger a new install. The servers will determine that the SDK has lost its locally aggregated session data and ignore the erroneous message, given the information available on the servers about the device.

This behaviour can be cumbersome during tests, but is necessary in order to have the sandbox behaviour match production as much as possible.

You can reset the session data of the device in our servers. Check the error message in the logs:

```
Session failed (Ignoring too frequent session. Last session: YYYY-MM-DDTHH:mm:ss, this session: YYYY-MM-DDTHH:mm:ss, interval: XXs, min interval: 20m) (app_token: {yourAppToken}, adid: {adidValue})
```

<a id="forget-device">With the `{yourAppToken}` and  either `{adidValue}` or `{idfaValue}` values filled in below, open one of the following links:

```
http://app.adjust.com/forget_device?app_token={yourAppToken}&adid={adidValue}
```

```
http://app.adjust.com/forget_device?app_token={yourAppToken}&idfa={idfaValue}
```

When the device is forgotten, the link just returns `Forgot device`. If the device was already forgotten or the values were incorrect, the link returns `Device not found`.

### <a id="ts-install-tracked"></a>I'm not seeing "Install tracked" in the logs

If you want to simulate the installation scenario of your app on your test device, it is not enough if you just re-run the app from the Xcode on your test device. Re-running the app from the Xcode doesn't cause app data to be wiped out and all internal files that our SDK is keeping inside your app will still be there, so upon re-run, our SDK will see those files and think of your app was already installed (and that SDK was already launched in it) but just opened for another time rather than being opened for the first time.

In order to run the app installation scenario, you need to do following:

* Uninstall app from your device (completely remove it)
* Forget your test device from the adjust backend like explained in the issue [above](#forget-device)
* Run your app from the Xcode on the test device and you will see log message "Install tracked"

### <a id="ts-iad-sdk-click"></a>I'm seeing the "Unattributable SDK click ignored" message

You may notice this message while testing your app in `sandbox` environment. It is related to some changes Apple introduced in `iAd.framework` version 3. With this, a user can be directed to your app from a click on iAd banner and this will cause our SDK to send an `sdk_click` package to the adjust backend informing it about the content of the clicked URL. For some reason, Apple decided that if the app was opened without clicking on iAd banner, they will artificially generate an iAd banner URL click with some random values. Our SDK won't be able to distinguish if the iAd banner click was genuine or artificially generated and will send an `sdk_click` package regardless to the adjust backend. If you have your log level set to `verbose`, you will see this `sdk_click` package looking something like this:

```
[Adjust]d: Added package 1 (click)
[Adjust]v: Path:      /sdk_click
[Adjust]v: ClientSdk: ios4.10.1
[Adjust]v: Parameters:
[Adjust]v:      app_token              {YourAppToken}
[Adjust]v:      created_at             2016-04-15T14:25:51.676Z+0200
[Adjust]v:      details                {"Version3.1":{"iad-lineitem-id":"1234567890","iad-org-name":"OrgName","iad-creative-name":"CreativeName","iad-click-date":"2016-04-15T12:25:51Z","iad-campaign-id":"1234567890","iad-attribution":"true","iad-lineitem-name":"LineName","iad-creative-id":"1234567890","iad-campaign-name":"CampaignName","iad-conversion-date":"2016-04-15T12:25:51Z"}}
[Adjust]v:      environment            sandbox
[Adjust]v:      idfa                   XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
[Adjust]v:      idfv                   YYYYYYYY-YYYY-YYYY-YYYY-YYYYYYYYYYYY
[Adjust]v:      needs_response_details 1
[Adjust]v:      source                 iad3
```

If for some reason this `sdk_click` would be accepted, it would mean that a user who has opened your app by clicking on some other campaign URL or even as an organic user, will get attributed to this unexisting iAd source. This is the reason why our backend ignores it and informs you with this message:

```
[Adjust]v: Response: {"message":"Unattributable SDK click ignored."}
[Adjust]i: Unattributable SDK click ignored.
```

So, this message doesn't indicate any issue with your SDK integration but it's simply informing you that our backend has ignored this artificially created `sdk_click` which could have lead to your user being wrongly attributed/reattributed.

### <a id="ts-wrong-revenue-amount"></a>I'm seeing incorrect revenue data in the adjust dashboard

The Adjust SDK tracks what you tell it to track. If you are attaching revenue to your event, the number you write as an amount is the only amount which will reach the adjust backend and be displayed in the dashboard. Our SDK does not manipulate your amount value, nor does our backend. So, if you see wrong amount being tracked, it's because our SDK was told to track that amount.

Usually, a user's code for tracking revenue event looks something like this:

```objc
// ...

- (double)someLogicForGettingRevenueAmount {
    // This method somehow handles how user determines
    // what's the revenue value which should be tracked.

    // It is maybe making some calculations to determine it.

    // Or maybe extracting the info from In-App purchase which
    // was successfully finished.

    // Or maybe returns some predefined double value.

    double amount; // double amount = some double value

    return amount;
}

// ...

- (void)someRandomMethodInTheApp {
    double amount = [self someLogicForGettingRevenueAmount];

    ADJEvent *event = [ADJEvent eventWithEventToken:@"abc123"];
    [event setRevenue:amount currency:@"EUR"];
    [Adjust trackEvent:event];
}

```

If you are seing any value in the dashboard other than what you expected to be tracked, **please, check your logic for determining amount value**.


[dashboard]:   http://adjust.com
[adjust.com]:  http://adjust.com

[en-readme]:  README.md
[zh-readme]:  doc/chinese/README.md
[ja-readme]:  doc/japanese/README.md
[ko-readme]:  doc/korean/README.md

[sdk2sdk-mopub]:  doc/english/sdk-to-sdk/mopub.md

[arc]:         http://en.wikipedia.org/wiki/Automatic_Reference_Counting
[examples]:    http://github.com/adjust/ios_sdk/tree/master/examples
[carthage]:    https://github.com/Carthage/Carthage
[releases]:    https://github.com/adjust/ios_sdk/releases
[cocoapods]:   http://cocoapods.org
[transition]:  http://developer.apple.com/library/mac/#releasenotes/ObjectiveC/RN-TransitioningToARC/Introduction/Introduction.html

[example-tvos]:       examples/AdjustExample-tvOS
[example-iwatch]:     examples/AdjustExample-iWatch
[example-imessage]:   examples/AdjustExample-iMessage
[example-ios-objc]:   examples/AdjustExample-ObjC
[example-ios-swift]:  examples/AdjustExample-Swift

[AEPriceMatrix]:     https://github.com/adjust/AEPriceMatrix
[event-tracking]:    https://docs.adjust.com/en/event-tracking
[callbacks-guide]:   https://docs.adjust.com/en/callbacks
[universal-links]:   https://developer.apple.com/library/ios/documentation/General/Conceptual/AppSearch/UniversalLinks.html

[special-partners]:           https://docs.adjust.com/en/special-partners
[attribution-data]:           https://github.com/adjust/sdks/blob/master/doc/attribution-data.md
[ios-web-views-guide]:        doc/english/web_views.md
[currency-conversion]:        https://docs.adjust.com/en/event-tracking/#tracking-purchases-in-different-currencies
[universal-links-guide]:      https://docs.adjust.com/en/universal-links/
[adjust-universal-links]:     https://docs.adjust.com/en/universal-links/#redirecting-to-universal-links-directly
[universal-links-testing]:    https://docs.adjust.com/en/universal-links/#testing-universal-link-implementations
[reattribution-deeplinks]:    https://docs.adjust.com/en/deeplinking/#manually-appending-attribution-data-to-a-deep-link
[ios-purchase-verification]:  https://github.com/adjust/ios_purchase_sdk

[reattribution-with-deeplinks]:   https://docs.adjust.com/en/deeplinking/#manually-appending-attribution-data-to-a-deep-link

[run]:         https://raw.github.com/adjust/sdks/master/Resources/ios/run5.png
[add]:         https://raw.github.com/adjust/sdks/master/Resources/ios/add5.png
[drag]:        https://raw.github.com/adjust/sdks/master/Resources/ios/drag5.png
[delegate]:    https://raw.github.com/adjust/sdks/master/Resources/ios/delegate5.png
[framework]:   https://raw.github.com/adjust/sdks/master/Resources/ios/framework5.png

[adc-ios-team-id]:            https://raw.github.com/adjust/sdks/master/Resources/ios/adc-ios-team-id5.png
[custom-url-scheme]:          https://raw.github.com/adjust/sdks/master/Resources/ios/custom-url-scheme.png
[adc-associated-domains]:     https://raw.github.com/adjust/sdks/master/Resources/ios/adc-associated-domains5.png
[xcode-associated-domains]:   https://raw.github.com/adjust/sdks/master/Resources/ios/xcode-associated-domains5.png
[universal-links-dashboard]:  https://raw.github.com/adjust/sdks/master/Resources/ios/universal-links-dashboard5.png

[associated-domains-applinks]:      https://raw.github.com/adjust/sdks/master/Resources/ios/associated-domains-applinks.png
[universal-links-dashboard-values]: https://raw.github.com/adjust/sdks/master/Resources/ios/universal-links-dashboard-values5.png

## <a id="license"></a>License

The Adjust SDK is licensed under the MIT License.

Copyright (c) 2012-2019 Adjust GmbH, http://www.adjust.com

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
