## Facebook 픽셀 연동

[Facebook 픽셀](https://www.facebook.com/business/help/952192354843755)은 Facebook의 웹 전용 애널리틱스 도구입니다. 종전에는 Facebook SDK으로 앱 WebView에서 픽셀 이벤트를 추적할 수 없었으나 [Facebook SDK](https://developers.facebook.com/docs/analytics) v4.34 버전 출시와 더불어 이제 가능해졌으며, [하이브리드 모바일 앱 이벤트](https://developers.facebook.com/docs/app-events/hybrid-app-events)를 사용하여 Facebook 픽셀 이벤트를 Facebook 앱 이벤트로 전환할 수 있습니다.

또한 Facebook SDK에 연동하지 않고도 Adjust SDK로 Facebook 픽셀을 사용할 수 있습니다. 

## Facebook 연동

### 앱 예제

[`AdjustExample-FbPixel` 디렉토리][example-fbpixel]에서 Adjust WebView SDK를 사용하지 않고 Facebook 픽셀 이벤트를 추적하는 방법을 설명하는 앱 예제를 찾아볼 수 있습니다.

### Facebook App ID

Facebook SDK 연동을 하지 않아도 됩니다. 그러나 Adjust SDK가 Facebook 픽셀을 연동하도록 하기 위해서는 Facebook SDK에서와 동일한 몇 단계의 절차를 밟아야 합니다. 

[Facebook iOS SDK 지침](https://developers.facebook.com/docs/ios/getting-started/#xcode)에 설명한 대로 Facebook App ID를 앱에 추가해야 합니다. 위 지침에 설명한 단계를 그대로 따르면 되며, 이용자의 편의를 위해 아래에 그대로 복사해 놓았습니다. 

- Xcode에서 프로젝트 내 `Info.plist` 파일을 우클릭한 후 'Open As' -> 'Source Code'를 선택합니다.
- 다음 XML 라인을 파일 본문 마지막 `</dict>` 엘리먼트 바로 앞에 삽입합니다.

    ```xml
    <dict>
      ...
      <key>FacebookAppID</key>
      <string>{your-app-id}</string>
      ...
    </dict>
    ```

- `{your-app-id}`를 사용 중인 앱의 App ID로 대체합니다. (App ID는 *Facebook App 대시보드*에서 확인할 수 있습니다.)

### Facebook 픽셀 환경설정

픽셀 연동에 대한 Facebook 지침을 따르면 됩니다. 자바스크립트 코드는 다음과 같이 보일 것입니다. 

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

이제 [하이브리드 모바일 앱 이벤트 지침](https://developers.facebook.com/docs/app-events/hybrid-app-events) 내 `Update Your Pixel` 섹션에서 설명한 대로 Facebook 픽셀 코드를 다음과 같이 업데이트합니다.

```js
fbq('init', <YOUR_PIXEL_ID>);
fbq('set', 'mobileBridge', <YOUR_PIXEL_ID>, <YOUR_FB_APP_ID>);
```

**주의**: `'init'`를 먼저 호출하고 바로 그 다음에 `'set'` 메서드를 호출하는 게 **대단히 중요**함을 명심해 주십시오. (위에 나온 것처럼) Facebook에서 제공하여 사용 대상 HTML 웹 페이지에 붙이는 스크립트 라인에는, `'init'` 호출 바로 다음에 페이지 보기 이벤트에 사용하는 `'track'` 메서드가 들어 있습니다. 이 페이지 보기 이벤트를 올바로 추적하려면 그 사이에 반드시 `'set'` 메서드를 호출해야 합니다!

## Adjust 연동

### WebView 증강

[iOS WebView](web_views.md) 앱의 연동 지침을 따르면 됩니다. WebView 브릿지를 로드할 섹션은 아래를 참조하십시오.

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

WebView를 Adjust 브릿지에 로드하는 데 어떤 방법을 사용하든 상관 없이 공통적으로 아래 라인을 추가하고 해당 단계를 따르면 됩니다. 

```objc
[self.adjustBridge augmentHybridWebView];
```

### 이벤트 이름 환경설정

Adjust 웹 브릿지 SDK는 Facebook 픽셀 이벤트를 Adjust 이벤트로 전환시켜 줍니다.

따라서 Facebook 픽셀을 특정한 Adjust 이벤트에 배치(매핑, mapping)하거나, Facebook 픽셀 환경설정에서 복사해 와서 붙이는 `fbq('track', 'PageView');` 등의 Facebook 픽셀 이벤트 추적을 Adjust SDK를 사용하여 시작하기 **전에** Adjust 이벤트 토큰의 기본값을 설정해야 합니다.

Facebook 픽셀 이벤트와 Adjust 이벤트를 매핑하려면 Adjust SDK를 초기화하기 전에 `adjustConfig` 인스턴스에서 `addFbPixelMapping(fbEventNameKey, adjEventTokenValue)` 메서드를 호출합니다. 매핑이 이루어진 예는 아래와 같습니다.

```js
adjustConfig.addFbPixelMapping('fb_mobile_search', adjustEventTokenForSearch);
adjustConfig.addFbPixelMapping('fb_mobile_purchase', adjustEventTokenForPurchase);
```

위에 보이는 매핑의 예시는 Facebook 이벤트 중 `fbq('track', 'Search', ...);` 및 `fbq('track', 'Purchase', ...);`를 각각 추적하는 경우에 해당함을 유의해 주십시오. 아쉽게도 Adjust는 자바스크립트에서 추적하는 이벤트 이름과 Facebook SDK에 사용하는 이벤트 이름 전체의 매핑 구조에는 접근할 수 없습니다.

사용자에게 도움을 드리고자 Adjust가 지금까지 찾아 낸 이벤트 이름 정보를 다음과 같이 정리했습니다.

| 픽셀 이벤트 이름   | 해당하는 Facebook 앱 이벤트 이름
| ---------------- | -------------------------------------
| ViewContent      | fb_mobile_content_view
| Search           | fb_mobile_search
| AddToCart        | fb_mobile_add_to_cart
| AddToWishlist    | fb_mobile_add_to_wishlist
| InitiateCheckout | fb_mobile_initiated_checkout
| AddPaymentInfo   | fb_mobile_add_payment_info
| Purchase         | fb_mobile_purchase
| CompleteRegistration | fb_mobile_complete_registration

위 목록은 완전하지 않을 수 있으며, Facebook이 현재 목록에 새 항목을 추가하거나 목록을 업데이트할 가능성도 있습니다. 테스트하는 중에는 다음과 같은 Adjust 경고 로그를 확인하십시오.

```
There is not a default event token configured or a mapping found for event named: 'fb_mobile_search'. It won't be tracked as an adjust event
```

매핑 환경설정을 하지 않았다면 그냥 Adjust 이벤트 기본값을 사용할 수도 있습니다. Adjust SDK를 초기화하기 전에 `adjustConfig.setFbPixelDefaultEventToken(defaultEventToken);` 메서드를 호출하기만 하면 됩니다.

[example-fbpixel]:  ../../examples/AdjustExample-FbPixel
