## Facebook Pixelの統合


[Facebook Pixel](https://www.facebook.com/business/help/952192354843755) はFacebookが提供するウェブサイト専用の分析ツールです。以前は、アプリ内のweb viewでPixelイベントをトラッキングするのにFacebook SDKを利用できませんでした。[FB SDK](https://developers.facebook.com/docs/analytics) v4.34のリリース以降はトラッキングが可能になり、[Hybrid Mobile App Events](https://developers.facebook.com/docs/app-events/hybrid-app-events) を使用して、Facebook PixelイベントをFacebook アプリイベントに変換します。

また、FB SDKを統合しなくても、Adjust SDKを使用してアプリ内のweb viewでFacebook Pixelを利用できるようになりました。

## Facebookの統合

### アプリサンプル

[`example-fbpixel` ディレクトリ][example-fbpixel]にあるアプリサンプルを見ると、Adjustのweb view SDKを使用してどのようにFacebook Pixelイベントをトラッキングできるかがわかります。

### FacebookアプリID

FB SDKを統合する必要はありませんが、Adjust SDKがFacebook Pixelを統合するために、一部FB SDKと同じ統合手順に従う必要があります。

まず[FB SDK iOS SDKガイド](https://developers.facebook.com/docs/ios/getting-started/#xcode) に記載の通り、対象のFacebookアプリIDをアプリに追加する必要があります。
統合手順は上記リンクに記載がありますが、以下にも転載致します。

- Xcodeで、プロジェクトの`Info.plist`ファイルを右クリックして、[Open As] -> [Source Code]を選択します。
- 以下のXMLスニペットをファイルのボディ部の最後の`` 要素の直前に挿入します。


    ```xml
    <dict>
      ...
      <key>FacebookAppID</key>
      <string>{your-app-id}</string>
      ...
    </dict>
    ```

- `{{your-app-id}}`を対象アプリのアプリID（*Facebook App Dashboard*に表示される）に置き換えます。

### Facebook Pixelの設定

Facebook Pixelの統合方法については、Facebookのガイドに従ってください。

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

この後、[Hybrid Mobile App Eventsガイド](https://developers.facebook.com/docs/app-events/hybrid-app-events) の`Update Your Pixel`セクションに記載の通り、Facebook Pixelのコードを以下のように変更するだけです。


```js
fbq('init', <YOUR_PIXEL_ID>);
fbq('set', 'mobileBridge', <YOUR_PIXEL_ID>, <YOUR_FB_APP_ID>);
```

**注意**：はじめに`'init'`メソッドを呼び出し、その直後に`'set'`メソッドを呼び出すことが**非常に重要**です。HTMLのウェブページに貼り付ける、Facebook提供の（上記のような）スクリプトスニペットは、`'init'`メソッドの呼び出しのすぐ後にページビューイベントの`'track'`メソッドが含まれています。このページビューイベントを正しくトラッキングするために、必ずこれらの間に`'set'`メソッドを呼び出してください。

## Adjustの統合

### Web viewの拡大

[iOS web view](web_views_ja.md) アプリの統合ガイドに従ってください。こちらはWeb view bridgeをロードするセクションです。（以下を参照）


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


どのweb viewをAdjust bridgeに選択するかに関わらず、手順に従って下記のラインを追加してください。

```objc
[self.adjustBridge augmentHybridWebView];
```

### Event名の設定

Adjust web bridge SDKは、Facebook PixelイベントをAdjustイベントに変換します。

このため、Facebook Pixel設定の`fbq('track', 'PageView');`をコピーペーストで追加し、Adjust SDKを開始してFacebook Pixelイベントをトラッキングする**前**に、Facebook Pixelsを特定のAdjustイベントにマッピングするか、デフォルトのAdjustイベントトークンを設定する必要があります。

Facebook PixelイベントをAdjustイベントにマッピングするには、Adjust SDKを初期化する前に`adjustConfig`インスタンスの`addFbPixelMapping(fbEventNameKey, adjEventTokenValue)`を呼び出します。マッピングの例は以下の通りです。


```js
adjustConfig.addFbPixelMapping('fb_mobile_search', adjustEventTokenForSearch);
adjustConfig.addFbPixelMapping('fb_mobile_purchase', adjustEventTokenForPurchase);
```

注意：これは、以下のFacebook Pixelイベントをトラッキングする際の`fbq('track', 'Search', ...);`および`fbq('track', 'Purchase', ...);`にそれぞれ対応します。残念ながら、Javascriptでトラッキングされるイベント名とFB SDKで使用されるイベント名との間のすべてのマッピングスキームにはアクセスできません。

参考として、以下はAdjustがこれまで確認したイベント名の情報になります。

| Pixelイベント名 | 対応するFacebookアプリのイベント名
| ---------------- | -------------------------------------
| ViewContent      | fb_mobile_content_view
| Search           | fb_mobile_search
| AddToCart        | fb_mobile_add_to_cart
| AddToWishlist    | fb_mobile_add_to_wishlist
| InitiateCheckout | fb_mobile_initiated_checkout
| AddPaymentInfo   | fb_mobile_add_payment_info
| Purchase         | fb_mobile_purchase
| CompleteRegistration | fb_mobile_complete_registration


これは完全なリストではない可能性があります。また、Facebookが現在のリストに追加や更新を加える可能性もあります。テスト中は、Adjustログで以下のような警告を確認してください。

```
There is not a default event token configured or a mapping found for event named: 'fb_mobile_search'. It won't be tracked as an adjust event
```

```
イベント名'fb_mobile_search'について、設定されたデフォルトイベントトークンが存在しないか、マッピングが見つかりません。Adjustイベントとしてトラッキングできません。
```

また、マッピングを設定しない場合でもデフォルトのAdjustイベントの使用は可能です。Adjust SDKを初期化する前に、`adjustConfig.setFbPixelDefaultEventToken(defaultEventToken);`を呼び出してください。


[example-fbpixel]:  ../../examples/AdjustExample-FbPixel
