## Summary

This is the guide to the iOS SDK of Adjust™ for iOS apps which are using web views. You can read more about Adjust™  at [adjust.com].

It provides a bridge from Javascript to native Objective-C calls (and vice versa) by using the [WebViewJavascriptBridge][web_view_js_bridge] plugin. This plugin is also licensed under `MIT License`.

## Table of contents

* [Example app](#example-app)
* [Basic integration](#basic-integration)
   * [Add the SDK with the web bridge to your project](#sdk-add)
   * [Add iOS frameworks](#sdk-frameworks)
   * [Integrate the SDK into your app](#sdk-integrate)
   * [Integrate AdjustBridge into your app](#bridge-integrate-app)
   * [Integrate AdjustBridge into your web view](#bridge-integrate-web)
   * [Basic setup](#basic-setup)
   * [Adjust logging](#adjust-logging)
   * [Build your app](#build-the-app)
* [Additional features](#additional-features)
   * [Event tracking](#event-tracking)
      * [Revenue tracking](#revenue-tracking)
      * [Revenue deduplication](#revenue-deduplication)
      * [Callback parameters](#callback-parameters)
      * [Partner parameters](#partner-parameters)
   * [Session parameters](#session-parameters)
      * [Session callback parameters](#session-callback-parameters)
      * [Session partner parameters](#session-partner-parameters)
      * [Delay start](#delay-start)
   * [Attribution callback](#attribution-callback)
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
* [License](#license)

## <a id="example-app"></a>Example app

In the repository, you can find an example [`iOS app with web view`][example-webview]. You can use this project to see how the Adjust SDK can be integrated.

## <a id="basic-integration"></a>Basic integration

If you are migrating from the web bridge SDK v4.9.1 or previous, please follow [this migration guide](web_view_migration.md) when updating to this new version.

We will describe the steps to integrate the Adjust SDK into your iOS project. We are going to assume that you are using Xcode for your iOS development.

### <a id="sdk-add"></a>Add the SDK with the web bridge to your project

If you're using [CocoaPods][cocoapods], you can add the following line to your `Podfile` and continue from [this step](#sdk-integrate):

```ruby
pod 'Adjust/WebBridge', '~> 4.18.3'
```

---

If you're using [Carthage][carthage], you can add following line to your `Cartfile` and continue from [this step](#sdk-frameworks):

```ruby
github "adjust/ios_sdk"
```

---

You can also choose to integrate the Adjust SDK by adding it to your project as a framework. On the [releases page][releases] you can find the `AdjustSdkWebBridge.framework.zip` which contains dynamic framework.

### <a id="sdk-frameworks"></a>Add iOS frameworks

1. Select your project in the Project Navigator
2. In the left-hand side of the main view, select your target
3. In the `Build Phases` tab, expand the `Link Binary with Libraries` group
4. At the bottom of that section, select the `+` button
5. Select the `AdSupport.framework`, then the `Add` button 
6. Repeat the same steps to add the `iAd.framework`, `CoreTelephony.framework` and `WebView.framework`
7. Change the `Status` of the frameworks to `Optional`.

### <a id="sdk-integrate"></a>Integrate the SDK into your app

If you added the Adjust SDK via a Pod repository, you should use one of the following import statements in your app's source files:

```objc
#import "AdjustBridge.h"
```

---

If you added the Adjust SDK as a static/dynamic framework or via Carthage, you should use the following import statement in your app's source files:

```objc
#import <AdjustSdkWebBridge/AdjustBridge.h>
```

Next, we'll set up basic session tracking.

### <a id="bridge-integrate-app"></a>Integrate AdjustBridge into your app

In the Project Navigator open the source file your View Controller. Add the `import` statement at the top of the file. In 
the `viewDidLoad` or `viewWillAppear` method of your Web View Delegate add the following calls to `AdjustBridge`:

```objc
#import "AdjustBridge.h"
// or #import <AdjustSdkWebBridge/AdjustBridge.h>

- (void)viewWillAppear:(BOOL)animated {
    WKWebView *webView = [[WKWebView alloc] initWithFrame:self.view.bounds];

    // add @property (nonatomic, strong) AdjustBridge *adjustBridge; on your interface
    [self.adjustBridge loadWKWebViewBridge:webView];
    // optionally you can add a web view delegate so that you can also capture its events
    // [self.adjustBridge loadWKWebViewBridge:webView wkWebViewDelegate:(id<WKNavigationDelegate>)self];
}

// ...
```

You also can make use of the WebViewJavascriptBridge library we include, by using the `bridgeRegister` property of the `AdjustBridge` instance.
The register/call handler interface is similar to what WebViewJavascriptBridge does for ObjC. See [the library documentation](https://github.com/marcuswestin/WebViewJavascriptBridge#usage) for how to use it.

### <a id="bridge-integrate-web"></a>Integrate AdjustBrige into your web view

To use the Javascript bridge on your web view, it must be configured like the `WebViewJavascriptBridge` plugin [README][wvjsb_readme] is advising in section `4`. Include the following Javascript code to intialize the Adjust iOS web bridge:

```js
function setupWebViewJavascriptBridge(callback) {
    if (window.WebViewJavascriptBridge) {
        return callback(WebViewJavascriptBridge);
    }

    if (window.WVJBCallbacks) {
        return window.WVJBCallbacks.push(callback);
    }

    window.WVJBCallbacks = [callback];

    var WVJBIframe = document.createElement('iframe');
    WVJBIframe.style.display = 'none';
    WVJBIframe.src = 'https://__bridge_loaded__';
    document.documentElement.appendChild(WVJBIframe);

    setTimeout(function() { document.documentElement.removeChild(WVJBIframe) }, 0)
}
```

Take notice that the line `WVJBIframe.src = 'https://__bridge_loaded__';` was changed in version 4.11.6 from `WVJBIframe.src = 'wvjbscheme://__BRIDGE_LOADED__';` due to a change in the  `WebViewJavascriptBridge` plugin.

### <a id="basic-setup"></a>Basic setup

In the same HTML file, initialise the Adjust SDK inside the `setupWebViewJavascriptBridge` callback:

```js
setupWebViewJavascriptBridge(function(bridge) {
    // ...

    var yourAppToken = yourAppToken;
    var environment = AdjustConfig.EnvironmentSandbox;
    var adjustConfig = new AdjustConfig(yourAppToken, environment);

    Adjust.appDidLaunch(adjustConfig);

    // ...
});
```

**Note**: Initialising the Adjust SDK like this is `very important`. Otherwise, you may encounter different kinds of issues as described in our [troubleshooting section](#ts-delayed-init).

Replace `yourAppToken` with your app token. You can find this in your [dashboard].

Depending on whether you build your app for testing or for production, you must set `environment` with one of these values:

```js
var environment = AdjustConfig.EnvironmentSandbox;
var environment = AdjustConfig.EnvironmentProduction;
```

**Important:** This value should be set to `AdjustConfig.EnvironmentSandbox` if and only if you or someone else is testing your app. Make sure to set the environment to `AdjustConfig.EnvironmentProduction` just before you publish the app. Set it back to `AdjustConfig.EnvironmentSandbox` when you start developing and testing it again.

We use this environment to distinguish between real traffic and test traffic from test devices. It is very important that you keep this value meaningful at all times! This is especially important if you are tracking revenue.

### <a id="adjust-logging"></a>Adjust logging

You can increase or decrease the amount of logs that you see during testing by calling `setLogLevel:` on your `ADJConfig` instance with one of the following parameters:

```js
adjustConfig.setLogLevel(AdjustConfig.LogLevelVerbose)   // enable all logging
adjustConfig.setLogLevel(AdjustConfig.LogLevelDebug)     // enable more logging
adjustConfig.setLogLevel(AdjustConfig.LogLevelInfo)      // the default
adjustConfig.setLogLevel(AdjustConfig.LogLevelWarn)      // disable info logging
adjustConfig.setLogLevel(AdjustConfig.LogLevelError)     // disable warnings as well
adjustConfig.setLogLevel(AdjustConfig.LogLevelAssert)    // disable errors as well
adjustConfig.setLogLevel(AdjustConfig.LogLevelSuppress)  // disable all logging
```

If you don't want your app in production to display any logs coming from the Adjust SDK, then you should select `AdjustConfig.LogLevelSuppress` and in addition to that, initialise `AdjustConfig` object with another constructor where you should enable suppress log level mode with `true` in the third parameter:

```js
setupWebViewJavascriptBridge(function(bridge) {
    // ...

    var yourAppToken = yourAppToken;
    var environment = AdjustConfig.EnvironmentSandbox;
    var adjustConfig = new AdjustConfig(yourAppToken, environment, true);

    Adjust.appDidLaunch(adjustConfig);

    // ...
});
```

### <a id="build-the-app"></a>Build your app

Build and run your app. If the build succeeds, you should carefully read the SDK logs in the console. After the app launches
for the first time, you should see the info log `Install tracked`.

## <a id="additional-features"></a>Additional features

Once you integrate the Adjust SDK into your project, you can take advantage of the following features.

### <a id="event-tracking"></a>Event tracking

You can use Adjust to track events. Let's say you want to track every tap on a particular button. You would create a new  event token in your [dashboard], which has an associated event token - looking something like `abc123`. In your button's `onclick` method you would then add the following lines to track the tap:

```js
var adjustEvent = new AdjustEvent('abc123');
Adjust.trackEvent(adjustEvent);
```

When tapping the button you should now see `Event tracked` in the logs.

The event instance can be used to configure the event even more before tracking it.

### <a id="revenue-tracking"></a>Revenue tracking

If your users can generate revenue by tapping on advertisements or making in-app purchases you can track those revenues with events. Lets say a tap is worth one Euro cent. You could then track the revenue event like this:

```js
var adjustEvent = new AdjustEvent(eventToken);
adjustEvent.setRevenue(0.01, 'EUR');
Adjust.trackEvent(adjustEvent);
```

This can be combined with callback parameters of course.

When you set a currency token, Adjust will automatically convert the incoming revenues into a reporting revenue of your  choice. Read more about [currency conversion here.][currency-conversion]

You can read more about revenue and event tracking in the [event tracking guide][event-tracking-guide].

### <a id="revenue-deduplication"></a>Revenue deduplication

You can also pass in an optional transaction ID to avoid tracking duplicate revenues. The last ten transaction IDs are remembered and revenue events with duplicate transaction IDs are skipped. This is especially useful for in-app purchase tracking.

If you have access to the transaction indentifier from the web view, you can pass it to the `setTransactionId` method on the Adjust event object. That way you can avoid tracking revenue that is not actually being generated.

```js
var adjustEvent = new AdjustEvent(eventToken);
adjustEvent.setTransactionId(transactionIdentifier);
Adjust.trackEvent(adjustEvent);
```

### <a id="callback-parameters"></a>Callback parameters

You can register a callback URL for your events in your [dashboard]. We will send a GET request to that URL whenever the event gets tracked. You can add callback parameters to that event by calling `addCallbackParameter` on the event before tracking it. We will then append these parameters to your callback URL.

For example, suppose you have registered the URL `http://www.adjust.com/callback` then track an event like this:

```js
var adjustEvent = new AdjustEvent(eventToken);
adjustEvent.addCallbackParameter('key', 'value');
adjustEvent.addCallbackParameter('foo', 'bar');
Adjust.trackEvent(adjustEvent);
```

In that case we would track the event and send a request to:

    http://www.adjust.com/callback?key=value&foo=bar

It should be mentioned that we support a variety of placeholders like `{idfa}` that can be used as parameter values. In the resulting callback this placeholder would be replaced with the ID for Advertisers of the current device. Also note that we don't store any of your custom parameters, but only append them to your callbacks. If you haven't registered a callback for an event, these parameters won't even be read.

You can read more about using URL callbacks, including a full list of available values, in our [callbacks guide][callbacks-guide].

### <a id="partner-parameters"></a>Partner parameters

You can also add parameters to be transmitted to network partners, for the integrations that have been activated in your Adjust dashboard.

This works similarly to the callback parameters mentioned above, but can be added by calling the `addPartnerParameter` method on your `AdjustEvent` instance.

```js
var adjustEvent = new AdjustEvent('abc123');
adjustEvent.addPartnerParameter('key', 'value');
adjustEvent.addPartnerParameter('foo', 'bar');
Adjust.trackEvent(adjustEvent);
```

You can read more about special partners and these integrations in our [guide to special partners][special-partners].

### <a id="session-parameters"></a>Session parameters

Some parameters are saved to be sent in every event and session of the Adjust SDK. Once you have added any of these parameters, you don't need to add them every time, since they will be saved locally. If you add the same parameter twice, there will be no effect.

If you want to send session parameters with the initial install event, they must be called before the Adjust SDK launches via `Adjust.appDidLaunch()`. If you need to send them with an install, but can only obtain the needed values after launch, it's possible to [delay](#delay-start) the first launch of the Adjust SDK to allow this behavior.

### <a id="session-callback-parameters"></a>Session callback parameters

The same callback parameters that are registered for [events](#callback-parameters) can be also saved to be sent in every event or session of the Adjust SDK.

The session callback parameters have a similar interface of the event callback parameters. Instead of adding the key and it's value to an event, it's added through a call to `Adjust` method `addSessionCallbackParameter(key,value)`:

```js
Adjust.addSessionCallbackParameter('foo', 'bar');
```

The session callback parameters will be merged with the callback parameters added to an event. The callback parameters added to an event have precedence over the session callback parameters. Meaning that, when adding a callback parameter to an event with the same key to one added from the session, the value that prevails is the callback parameter added to the event.

It's possible to remove a specific session callback parameter by passing the desiring key to the method `removeSessionCallbackParameter`.

```js
Adjust.removeSessionCallbackParameter('foo');
```

If you wish to remove all key and values from the session callback parameters, you can reset it with the method `resetSessionCallbackParameters`.

```js
Adjust.resetSessionCallbackParameters();
```

### <a id="session-partner-parameters"></a>Session partner parameters

In the same way that there is [session callback parameters](#session-callback-parameters) that are sent every in event or session of the Adjust SDK, there is also session partner parameters.

These will be transmitted to network partners, for the integrations that have been activated in your Adjust [dashboard].

The session partner parameters have a similar interface to the event partner parameters. Instead of adding the key and it's value to an event, it's added through a call to `Adjust` method `addSessionPartnerParameter:value:`:

```js
Adjust.addSessionPartnerParameter('foo','bar');
```

The session partner parameters will be merged with the partner parameters added to an event. The partner parameters added to an event have precedence over the session partner parameters. Meaning that, when adding a partner parameter to an event with the same key to one added from the session, the value that prevails is the partner parameter added to the event.

It's possible to remove a specific session partner parameter by passing the desiring key to the method `removeSessionPartnerParameter`.

```js
Adjust.removeSessionPartnerParameter('foo');
```

If you wish to remove all key and values from the session partner parameters, you can reset it with the method `resetSessionPartnerParameters`.

```js
Adjust.resetSessionPartnerParameters();
```

### <a id="delay-start"></a>Delay start

Delaying the start of the Adjust SDK allows your app some time to obtain session parameters, such as unique identifiers, to be send on install.

Set the initial delay time in seconds with the method `setDelayStart` in the `AdjustConfig` instance:

```js
adjustConfig.setDelayStart(5.5);
```

In this case this will make the Adjust SDK not send the initial install session and any event created for 5.5 seconds. After this time is expired or if you call `Adjust.sendFirstPackages()` in the meanwhile, every session parameter will be added to the delayed install session and events and the Adjust SDK will resume as usual.

**The maximum delay start time of the Adjust SDK is 10 seconds**.

### <a id="attribution-callback"></a>Attribution callback

You can register a callback method to be notified of attribution changes. Due to the different sources considered for attribution, this information cannot by provided synchronously.

Please make sure to consider our [applicable attribution data policies][attribution-data].

As the callback method is configured using the `AdjustConfig` instance, you should call `setAttributionCallback` before calling `Adjust.appDidLaunch(adjustConfig)`.

```js
adjustConfig.setAttributionCallback(function(attribution) {
    // In this example, we're just displaying alert with attribution content.
    alert('Tracker token = ' + attribution.trackerToken + '\n' +
          'Tracker name = ' + attribution.trackerName + '\n' +
          'Network = ' + attribution.network + '\n' +
          'Campaign = ' + attribution.campaign + '\n' +
          'Adgroup = ' + attribution.adgroup + '\n' +
          'Creative = ' + attribution.creative + '\n' +
          'Click label = ' + attribution.clickLabel + '\n' +
          'Adid = ' + attribution.adid);
});
```

The callback method will get triggered when the SDK receives final attribution data. Within the callback you have access to the `attribution` parameter. Here is a quick summary of its properties:

- `var trackerToken` the tracker token of the current install.
- `var trackerName` the tracker name of the current install.
- `var network` the network grouping level of the current install.
- `var campaign` the campaign grouping level of the current install.
- `var adgroup` the ad group grouping level of the current install.
- `var creative` the creative grouping level of the current install.
- `var clickLabel` the click label of the current install.
- `var adid` the unique device identifier provided by attribution.

If any value is unavailable, it will not be part of the of the attribution object.

### <a id="event-session-callbacks"></a>Event and session callbacks

You can register a callback to be notified when events or sessions are tracked. There are four callbacks: one for tracking successful events, one for tracking failed events, one for tracking successful sessions and one for tracking failed sessions.

Follow these steps and implement the following callback methods to track successful events:

```js
adjustConfig.setEventSuccessCallback(function(eventSuccess) {
    // ...
});
```

The following delegate callback function to track failed events:

```js
adjustConfig.setEventFailureCallback(function(eventFailure) {
    // ...
});
```

To track successful sessions:

```js
adjustConfig.setSessionSuccessCallback(function(sessionSuccess) {
    // ...
});
```

And to track failed sessions:

```js
adjustConfig.setSessionFailureCallback(function(sessionFailure) {
    // ...
});
```

The callback methods will be called after the SDK tries to send a package to the server. Within the callback methods you have access to a response data object specifically for that callback. Here is a quick summary of the session response data properties:

- `var message` the message from the server or the error logged by the SDK.
- `var timeStamp` timestamp from the server.
- `var adid` a unique device identifier provided by Adjust.
- `var jsonResponse` the JSON object with the response from the server.

Both event response data objects contain:

- `var eventToken` the event token, if the package tracked was an event.

And both event and session failed objects also contain:

- `var willRetry` indicates there will be an attempt to resend the package at a later time.

### <a id="disable-tracking"></a>Disable tracking

You can disable the Adjust SDK from tracking any activities of the current device by calling `setEnabled` with parameter `false`. **This setting is remembered between sessions**.

```js
Adjust.setEnabled(false);
```

<a id="is-enabled">You can check if the Adjust SDK is currently enabled by calling the function `isEnabled`.

```js
Adjust.isEnabled(function(isEnabled) {
    if (isEnabled) {
        // SDK is enabled.    
    } else {
        // SDK is disabled.
    }
});
```

It is always possible to activate the Adjust SDK by invoking `setEnabled` with the enabled parameter as `true`.

### <a id="offline-mode"></a>Offline mode

You can put the Adjust SDK in offline mode to suspend transmission to our servers while retaining tracked data to be sent later. While in offline mode, all information is saved in a file, so be careful not to trigger too many events while in offline mode.

You can activate offline mode by calling `setOfflineMode` with the parameter `true`.

```js
Adjust.setOfflineMode(true);
```

Conversely, you can deactivate offline mode by calling `setOfflineMode` with `false`. When the Adjust SDK is put back in online mode, all saved information is send to our servers with the correct time information.

Unlike disabling tracking, this setting is **not remembered bettween sessions**. This means that the SDK is in online mode whenever it is started, even if the app was terminated in offline mode.

### <a id="event-buffering"></a>Event buffering

If your app makes heavy use of event tracking, you might want to delay some network requests in order to send them in one batch every minute. You can enable event buffering with your `AdjustConfig` instance:

```js
adjustConfig.setEventBufferingEnabled(true);
```

### <a id="gdpr-forget-me"></a>GDPR right to be forgotten

In accordance with article 17 of the EU's General Data Protection Regulation (GDPR), you can notify Adjust when a user has exercised their right to be forgotten. Calling the following method will instruct the Adjust SDK to communicate the user's choice to be forgotten to the Adjust backend:

```js
Adjust.gdprForgetMe();
```

Upon receiving this information, Adjust will erase the user's data and the Adjust SDK will stop tracking the user. No requests from this device will be sent to Adjust in the future.

### <a id="sdk-signature"></a> SDK signature

The Adjust SDK signature is enabled on a client-by-client basis. If you are interested in using this feature, please contact your account manager.

If the SDK signature has already been enabled on your account and you have access to App Secrets in your Adjust Dashboard, please use the method below to integrate the SDK signature into your app.

An App Secret is set by calling `setAppSecret` on your `AdjustConfig` instance:

```js
adjustConfig.setAppSecret(secretId, info1, info2, info3, info4);
```

### <a id="background-tracking"></a>Background tracking

The default behaviour of the Adjust SDK is to pause sending network requests while the app is in the background. You can change this behaviour in your `AdjustConfig` instance:

```js
adjustConfig.setSendInBackground(true);
```

If nothing is set, sending in background is **disabled by default**.

### <a id="device-ids"></a>Device IDs

The Adjust SDK offers you possibility to obtain some of the device identifiers.

### <a id="di-idfa"></a>iOS Advertising Identifier

Certain services (such as Google Analytics) require you to coordinate device and client IDs in order to prevent duplicate reporting.

To obtain the device identifier IDFA, call the function `getIdfa`:

```js
Adjust.getIdfa(function(idfa) {
    // ...
});
```

### <a id="di-adid"></a>Adjust device identifier

For each device with your app installed, Adjust backend generates unique **adjust device identifier** (**adid**). In order to obtain this identifier, you can make a call to the following method on the `Adjust` instance:

```js
var adid = Adjust.getAdid();
```

**Note**: Information about the **adid** is available after the app's installation has been tracked by the Adjust backend. From that moment on, the Adjust SDK has information about the device **adid** and you can access it with this method. So, **it is not possible** to access the **adid** before the SDK has been initialised and the installation of your app has been tracked successfully.

### <a id="user-attribution"></a>User attribution

The attribution callback will be triggered as described in the [attribution callback section](#attribution-callback), providing you with the information about any new attribution when ever it changes. In any other case, where you want to access information about your user's current attribution, you can make a call to the following method of the `Adjust` object:

```js
var attribution = Adjust.getAttribution();
```

**Note**: Information about current attribution is available after app installation has been tracked by the Adjust backend and attribution callback has been initially triggered. From that moment on, Adjust SDK has information about your user's attribution and you can access it with this method. So, **it is not possible** to access user's attribution value before the SDK has been initialised and attribution callback has been initially triggered.

### <a id="push-token"></a>Push token

Push tokens are used for Audience Builder and client callbacks, and they are required for uninstall and reinstall tracking.

To send us the push notification token, add the following call to `Adjust` in the `didRegisterForRemoteNotificationsWithDeviceToken` of your app delegate:

```objc
#import "Adjust.h"
// or #import <AdjustSdkWebBridge/Adjust.h>

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [Adjust setDeviceToken:deviceToken];
}
```

Or, if you have access to the push token from the web view, you can instead call the `setDeviceToken` method in the `Adjust` object in Javascript:

```js
Adjust.setDeviceToken(deviceToken);
```

### <a id="pre-installed-trackers"></a>Pre-installed trackers

If you want to use the Adjust SDK to recognize users that found your app pre-installed on their device, follow these steps.

1. Create a new tracker in your [dashboard].
2. Open your app delegate and add set the default tracker of your `AdjustConfig` instance:

  ```js
  adjustConfig.setDefaultTracker(trackerToken);
  ```

  Replace `trackerToken` with the tracker token you created in step 2. Please note that the dashboard displays a tracker
  URL (including `http://app.adjust.com/`). In your source code, you should specify only the six-character token and not
  the entire URL.

### <a id="deeplinking"></a>Deep linking

If you are using the Adjust tracker URL with an option to deep link into your app from the URL, there is the possibility to get info about the deep link URL and its content. Hitting the URL can happen when the user has your app already installed (standard deep linking scenario) or if they don't have the app on their device (deferred deep linking scenario). Both of these scenarios are supported by the Adjust SDK and in both cases the deep link URL will be provided to you after you app has been started after hitting the tracker URL. In order to use this feature in your app, you need to set it up properly.

### <a id="deeplinking-standard"></a>Standard deep linking scenario

If your user already has the app installed and hits the tracker URL with deep link information in it, your application will be opened and the content of the deep link will be sent to your app so that you can parse it and decide what to do next. With introduction of iOS 9, Apple has changed the way how deep linking should be handled in the app. Depending on which scenario you want to use for your app (or if you want to use them both to support wide range of devices), you need to set up your app to handle one or both of the following scenarios.

### <a id="deeplinking-setup-old"></a>Deep linking on iOS 8 and earlier

Deep linking on iOS 8 and earlier devices is being done with usage of a custom URL scheme setting. You need to pick a custom URL scheme name which your app will be in charge for opening. This scheme name will also be used in the Adjust tracker URL as part of the `deep_link` parameter. In order to set this in your app, open your `Info.plist` file and add new `URL types` row to it. In there, as `URL identifier` write you app's bundle ID and under `URL schemes` add scheme name(s) which you want your app to handle. In the example below, we have chosen that our app should handle the `adjustExample` scheme name.

![][custom-url-scheme]

After this has been set up, your app will be opened after you click the Adjust tracker URL with `deep_link` parameter which contains the scheme name which you have chosen. After app is opened, `openURL` method of your `AppDelegate` class will be triggered and the place where the content of the `deep_link` parameter from the tracker URL will be delivered. If you want to access the content of the deep link, override this method.

```objc
#import "Adjust.h"
// or #import <AdjustSdkWebBridge/Adjust.h>

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

Adjust is taking care of lots of things to do with universal links behind the scenes. But, in order to support universal links with the Adjust, you need to perform small setup for universal links in the Adjust dashboard. For more information on that should be done, please consult our official [docs][universal-links-guide].

Once you have successfully enabled the universal links feature in the dashboard, you need to do this in your app as well:

After enabling `Associated Domains` for your app in Apple Developer Portal, you need to do the same thing in your app's Xcode project. After enabling `Assciated Domains`, add the universal link which was generated for you in the Adjust dashboard in the `Domains` section by prefixing it with `applinks:` and make sure that you also remove the `http(s)` part of the universal link.

![][associated-domains-applinks]

After this has been set up, your app will be opened after you click the Adjust tracker universal link. After app is opened, `continueUserActivity` method of your `AppDelegate` class will be triggered and the place where the content of the universal link URL will be delivered. If you want to access the content of the deep link, override this method.

``` objc
#import "Adjust.h"
// or #import <AdjustSdkWebBridge/Adjust.h>

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
#import "Adjust.h"
// or #import <AdjustSdkWebBridge/Adjust.h>

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

You can register a callback to be notified before a deferred deep link is opened. You can configure the callback on the `AdjustConfig` instance:

```js
adjustConfig.setDeferredDeeplinkCallback(function(deferredDeeplink) {
    // ...
});
```
The callback function will be called after the SDK receives a deffered deep link from our server and before opening it. 

If this callback is not implemented, **the Adjust SDK will always try to open the deep link by default**.

With another setting on the `AdjustConfig` instance, you have the possibility to decide whether the Adjust SDK will open this deeplink or not. You could, for example, not allow the SDK to open the deep link at the current moment, save it, and open it yourself later. You can do this by calling the `setOpenDeferredDeeplink` method:

```js
// Default setting. The SDK will open the deeplink after the deferred deeplink callback
adjustConfig.setOpenDeferredDeeplink(true);

// Or if you don't want our SDK to open the deeplink:
adjustConfig.setOpenDeferredDeeplink(false);
```

### <a id="deeplinking-reattribution"></a>Reattribution via deep links

Adjust enables you to run re-engagement campaigns with usage of deep links. For more information on how to do that, please check our [official docs][reattribution-with-deeplinks].

If you are using this feature, in order for your user to be properly reattributed, you need to make one additional call to the Adjust SDK in your app.

Once you have received deep link content information in your app, add a call to the `appWillOpenUrl` method. By making this call, the Adjust SDK will try to find if there is any new attribution info inside of the deep link and if any, it will be sent to the Adjust backend. If your user should be reattributed due to a click on the Adjust tracker URL with deep link content in it, you will see the [attribution callback](#attribution-callback) in your app being triggered with new attribution info for this user.

The call to `appWillOpenUrl` should be done like this to support deep linking reattributions in all iOS versions:

```objc
#import "Adjust.h"
// or #import <AdjustSdkWebBridge/Adjust.h>

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
#import "Adjust.h"
// or #import <AdjustSdkWebBridge/Adjust.h>

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

If you have access to the deeplink url in the web view, you can call the `appWillOpenUrl` method from the `Adjust` object from Javascript:

```js
Adjust.appWillOpenUrl(deeplinkUrl);
```


[dashboard]:  http://adjust.com
[adjust.com]: http://adjust.com

[releases]:   https://github.com/adjust/ios_sdk/releases
[carthage]:   https://github.com/Carthage/Carthage
[cocoapods]:  http://cocoapods.org

[wvjsb_readme]:             https://github.com/marcuswestin/WebViewJavascriptBridge#usage
[ios_sdk_ulinks]:           https://github.com/adjust/ios_sdk/#universal-links
[example-webview]:          https://github.com/adjust/ios_sdk/tree/master/examples/AdjustExample-WebView
[callbacks-guide]:          https://docs.adjust.com/en/callbacks
[attribution-data]:         https://github.com/adjust/sdks/blob/master/doc/attribution-data.md
[special-partners]:         https://docs.adjust.com/en/special-partners
[basic_integration]:        https://github.com/adjust/ios_sdk/#basic-integration
[web_view_js_bridge]:       https://github.com/marcuswestin/WebViewJavascriptBridge
[currency-conversion]:      https://docs.adjust.com/en/event-tracking/#tracking-purchases-in-different-currencies
[event-tracking-guide]:     https://docs.adjust.com/en/event-tracking/#reference-tracking-purchases-and-revenues
[reattribution-deeplinks]:  https://docs.adjust.com/en/deeplinking/#manually-appending-attribution-data-to-a-deep-link

[custom-url-scheme]:            https://raw.github.com/adjust/sdks/master/Resources/ios/custom-url-scheme.png
[associated-domains-applinks]:  https://raw.github.com/adjust/sdks/master/Resources/ios/associated-domains-applinks.png

## <a id="license"></a>License

The Adjust SDK is licensed under the MIT License.

Copyright (c) 2012-2018 Adjust GmbH, http://www.adjust.com

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
