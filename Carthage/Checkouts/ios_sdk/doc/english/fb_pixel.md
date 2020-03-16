## Facebook pixel integration

[The Facebook Pixel](https://www.facebook.com/business/help/952192354843755) is a web-only analytics tool from Facebook. In the past it was impossible to use the Facebook SDK to track Pixel events in an app's webview. Since the release of [FB SDK](https://developers.facebook.com/docs/analytics) v4.34, it's now possible to do so, and use the [Hybrid Mobile App Events](https://developers.facebook.com/docs/app-events/hybrid-app-events) to convert Facebook Pixel events into Facebook App events.

It is also now possible to use the Facebook Pixel with the Adjust SDK, without integrating the FB SDK.

## Facebook integration

### Example app

There is an example app inside the [`AdjustExample-FbPixel` directory][example-fbpixel] that demonstrates how Facebook Pixel events can be tracked with usage of Adjust web view SDK.

### Facebook App ID

There is no need to integrate the FB SDK; however, you must follow a few of the same integration steps from the FB SDK in order for the Adjust SDK to integrate the Facebook Pixel.

As is described in the [FB SDK iOS SDK guide](https://developers.facebook.com/docs/ios/getting-started/#xcode) you will need to add your Facebook App ID to the app. You can follow the steps in that guide, but we've also copied them here below:

- In Xcode, right click on your project's `Info.plist` file and select Open As -> Source Code.
- Insert the following XML snippet into the body of your file just before the final `</dict>` element:

    ```xml
    <dict>
      ...
      <key>FacebookAppID</key>
      <string>{your-app-id}</string>
      ...
    </dict>
    ```

- Replace `{your-app-id}` with your app's App ID (found on the *Facebook App Dashboard*).

### Facebook Pixel configuration

Follow Facebook's guide on how to integrate the Facebook Pixel. The Javascript code should look something like this:

```js
<!-- Facebook Pixel Code -->
<script>
  !function(f,b,e,v,n,t,s)
    ...
  fbq('init', <YOUR_PIXEL_ID>);
  fbq('track', 'PageView');
</script>
...
<!-- End Facebook Pixel Code -->
```

Now, just as described in the [Hybrid Mobile App Events guide](https://developers.facebook.com/docs/app-events/hybrid-app-events) `Update Your Pixel` section, you'll need to update the Facebook Pixel code like this:

```js
fbq('init', <YOUR_PIXEL_ID>);
fbq('set', 'mobileBridge', <YOUR_PIXEL_ID>, <YOUR_FB_APP_ID>);
```

**Note**: Please pay attention that it is **very important** that you first call `'init'` and immediately afterwards `'set'` method. Facebook's script snipet they offer you to paste to your HTML web page (like shown above) contains `'track'` method for page view event right after call to `'init'` method. In order for this page view event to be properly tracked, please make sure to call `'set'` method in between!

## Adjust integration

### Augment the web view

Follow the integration guide for [iOS web view](web_views.md) apps. In the section where you load the webview bridge (see below):

```objc
- (void)viewWillAppear:(BOOL)animated {
    ...
    UIWebView *webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    // or with WKWebView:
    // WKWebView *webView = [[WKWebView alloc] initWithFrame:self.view.bounds];

    // add @property (nonatomic, strong) AdjustBridge *adjustBridge; on your interface
    self.adjustBridge = [[AdjustBridge alloc] init];
    [self.adjustBridge loadUIWebViewBridge:webView];
    // optionally you can add a web view delegate so that you can also capture its events
    // [self.adjustBridge loadUIWebViewBridge:webView webViewDelegate:(UIWebViewDelegate*)self];
    
    // or with WKWebView:
    // [self.adjustBridge loadWKWebViewBridge:webView];
    // optionally you can add a web view delegate so that you can also capture its events
    // [self.adjustBridge loadWKWebViewBridge:webView wkWebViewDelegate:(id<WKNavigationDelegate>)self];
    ...
```

No matter how you choose to load the web view into the Adjust bridge, follow that step by adding the following line:

```objc
[self.adjustBridge augmentHybridWebView];
```

### Event name configuration

The Adjust web bridge SDK translates Facebook Pixel events into Adjust events.

For this reason, it's necessary to map Facebook Pixels to specific Adjust events, or to configure a default Adjust event token ***before*** starting Adjust SDK and tracking any Facebook Pixel event, including the copy-pasted `fbq('track', 'PageView');` from the Facebook Pixel configuration.

To map Facebook Pixel events and Adjust events, call `addFbPixelMapping(fbEventNameKey, adjEventTokenValue)` in the `adjustConfig` instance before initializing the Adjust SDK. Here's an example of what that could look like:

```js
adjustConfig.addFbPixelMapping('fb_mobile_search', adjustEventTokenForSearch);
adjustConfig.addFbPixelMapping('fb_mobile_purchase', adjustEventTokenForPurchase);
```

Note that this would match when tracking the following Facebook Pixel events: `fbq('track', 'Search', ...);` and `fbq('track', 'Purchase', ...);` respectively. Unfortunately, we do not have access to the entire mapping scheme between the event names tracked in Javascript and the event names used by the FB SDK. 

To help you, here is the event name information we've found so far:

| Pixel event name | Corresponding Facebook app event name
| ---------------- | -------------------------------------
| ViewContent      | fb_mobile_content_view
| Search           | fb_mobile_search
| AddToCart        | fb_mobile_add_to_cart
| AddToWishlist    | fb_mobile_add_to_wishlist
| InitiateCheckout | fb_mobile_initiated_checkout
| AddPaymentInfo   | fb_mobile_add_payment_info
| Purchase         | fb_mobile_purchase
| CompleteRegistration | fb_mobile_complete_registration

This may not be an exhaustive list; it's also possible that Facebook adds to or updates the current listing. While testing, check the Adjust logs for warnings such as:

```
There is not a default event token configured or a mapping found for event named: 'fb_mobile_search'. It won't be tracked as an adjust event
```

There is also the option to use a default Adjust event if you do not have mapping configured. Just call `adjustConfig.setFbPixelDefaultEventToken(defaultEventToken);` before initializing the Adjust SDK.

[example-fbpixel]:  ../../examples/AdjustExample-FbPixel
