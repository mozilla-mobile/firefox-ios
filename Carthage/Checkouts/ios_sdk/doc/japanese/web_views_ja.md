## 概要

これはWeb viewを使うiOSアプリのためのadjust.com™のiOS SDKガイドです。
adjust.com™について詳しくは[adjust.com]をご覧ください。

[WebViewJavascriptBridge][web_view_js_bridge]プラグインを使って
JavascriptからネイティブObjective-Cのコールへのブリッジ(その逆も同様です)を提供します。
このプラグインは`MITライセンス`が適用されています。

## 目次

* [基本的な統合](#basic-integration)
   * [ネイティブadjust iOS SDKの追加](#native-add)
   * [プロジェクトへのAdjustBridgeの追加](#bridge-add)
   * [アプリへのAdjustBridgeの統合](#bridge-integrate-app)
   * [Web viewへのAdjustBridgeの統合](#bridge-integrate-web)
   * [基本設定](#basic-setup)
   * [AdjustBridgeログ](#bridge-logging)
   * [アプリのビルド](#build-the-app)
* [追加機能](#additional-features)
   * [イベントトラッキング](#event-tracking)
      * [収益トラッキング](#revenue-tracking)
      * [コールバックパラメータ](#callback-parameters)
      * [パートナーパラメータ](#partner-parameters)
   * [アトリビューションコールバック](#attribution-callback)
   * [イベントとセッションのコールバック](#event-session-callbacks)
   * [イベントバッファリング](#event-buffering)
   * [トラッキングの無効化](#disable-tracking)
   * [オフラインモード](#offline-mode)
   * [バックグラウンドでのトラッキング](#background-tracking)
   * [デバイスID](#device-ids)
   * [ディープリンキング](#deeplinking)
      * [ディファート・ディープリンクのコールバック](#deferred-deeplinking-callback)
* [ライセンス](#license)

## <a id="basic-integration">基本的な統合

### <a id="native-add">ネイティブadjust iOS SDKの追加

Web viewでadjust SDKを使うには、アプリにadjustのネイティブiOS SDKを追加する必要があります。adjustのネイティブiOS SDKをインストールするには、[iOS SDK README][basic_integration]の「基本的な統合」をご参照ください。

### <a id="bridge-add">プロジェクトへのAdjustBridgeの追加

Xcodeのプロジェクトナビゲータから`Supporting Files`グループを探してください。もしくは他のグループでも構いません。Finderからそのグループに`AdjustBridge`のディレクトリをドラッグしてください。

![][bridge_drag]

`Choose options for adding these files`のダイアログが出てきたら、必ず`Copy items into destination group's folder`にチェックを入れ、上のラジオボタン`Create groups for any added folders`を選択してください。

![][bridge_add]

### <a id="bridge-integrate-app">3. アプリへのAdjustBridgeの統合

プロジェクトナビゲータからView Controllerのソースファイルを開いてください。ファイル最上部に`import`の記述を追加してください。Web Viewデリゲートの`viewDidLoad`か`viewWillAppear`のメソッドで次の`AdjustBridge`のコールを追加してください。

```objc
#import "Adjust.h"
// Or #import <AdjustSdk/Adjust.h>
// (depends on the way you have chosen to add our native iOS SDK)
// ...

- (void)viewWillAppear:(BOOL)animated {
    UIWebView *webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    // or with WKWebView:
    // WKWebView *webView = [[NSClassFromString(@"WKWebView") alloc] initWithFrame:self.view.bounds];

    AdjustBridge *adjustBridge = [[AdjustBridge alloc] init];
    [adjustBridge loadUIWebViewBridge:webView];
    // or with WKWebView:
    // [adjustBridge loadWKWebViewBridge:webView];
}

// ...
```

![][bridge_init_objc]

### <a id="bridge-integrate-web">Web viewへのAdjustBridgeの統合

Web viewでJavascriptのブリッジを使うには、`WebViewJavascriptBridge`プラグインのように設定する必要があります。
[README][wvjsb_readme]のセクション4で紹介されています。以下のJavascriptコードを追加して、adjustのiOS web bridgeを初期化してください。

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
    WVJBIframe.src = 'wvjbscheme://__BRIDGE_LOADED__';
    document.documentElement.appendChild(WVJBIframe);

    setTimeout(function() { document.documentElement.removeChild(WVJBIframe) }, 0)
}

setupWebViewJavascriptBridge(function(bridge) {
    // AdjustBridge initialisation will be added in this method.
})
```

![][bridge_init_js]

### <a id="basic-setup">Basic setup

HTMLファイル内でadjust Javascriptファイルへの参照を追加してください。

```html
<script type="text/javascript" src="adjust.js"></script>
<script type="text/javascript" src="adjust_event.js"></script>
<script type="text/javascript" src="adjust_config.js"></script>
```

Javascriptファイルへの参照を追加すると、HTMLファイル内で使えるようになり、adjust SDKを初期化することができます。


```js
setupWebViewJavascriptBridge(function(bridge) {
    // ...

    var yourAppToken = '{YourAppToken}'
    var environment = AdjustConfig.EnvironmentSandbox
    var adjustConfig = new AdjustConfig(bridge, yourAppToken, environment)

    Adjust.appDidLaunch(adjustConfig)

    // ...
)}
```

![][bridge_init_js_xcode]

`{YourAppToken}`にアプリトークンを入力してください。これはダッシュボードで確認できます。

テスト用か本番用かによって、`environment`を以下のいずれかの値に設定してください。

```js
var environment = AdjustConfig.EnvironmentSandbox
var environment = AdjustConfig.EnvironmentProduction
```

**重要** この値はどなたかがアプリをテストしている時に限り`AdjustConfig.EnvironmentSandbox`に設定する必要があります。
アプリを提出する前に、`AdjustConfig.EnvironmentProduction`になっていることを確認してください。
再び開発しテストをする時に`AdjustConfig.EnvironmentSandbox`に戻してください。

adjustはこの変数を使って実際のトラフィックとテストのトラフィックを判別しています。
この値は常に正しく設定することが重要です。収益データをトラッキングする際は特にご留意ください。

### <a id="bridge-logging">AdjustBridgeログ

`AdjustConfig`インスタンスの`setLogLevel:`に設定するパラメータを変更することによって記録するログのレベルを調節できます。
パラメータは以下の種類があります。

```objc
adjustConfig.setLogLevel(AdjustConfig.LogLevelVerbose) // すべてのログを有効にする
adjustConfig.setLogLevel(AdjustConfig.LogLevelDebug)   // より詳細なログを記録する
adjustConfig.setLogLevel(AdjustConfig.LogLevelInfo)    // デフォルト
adjustConfig.setLogLevel(AdjustConfig.LogLevelWarn)    // infoのログを無効にする
adjustConfig.setLogLevel(AdjustConfig.LogLevelError)   // warningも無効にする
adjustConfig.setLogLevel(AdjustConfig.LogLevelAssert)  // errorも無効にする
```

### <a id="build-the-app">アプリのビルド

アプリをビルドしてRunしてください。成功したら、コンソールに出力されるSDKのログをよく見てみてください。アプリが初めて立ち上がった後、infoログ`Install tracked`が出力されているはずです。

![][bridge_install_tracked]

## <a id="additional-features">追加機能

プロジェクトにadjust SDKを統合すると、次の機能を利用できるようになります。

### <a id="event-tracking">イベントトラッキング

adjustを使ってイベントトラッキングができます。ここではあるボタンのタップを毎回トラックしたい場合について説明します。
[dashboard]にてイベントトークンを作成し、そのイベントトークンは仮に`abc123`というイベントトークンと関連しているとします。
タップをトラックするため、ボタンの`onclick`メソッドに以下のような記述を追加します。

```js
var adjustEvent = new AdjustEvent('abc123')
Adjust.trackEvent(adjustEvent)
```

こうすると、ボタンがタップされた時にログに`Event tracked`と出力されるようになります。

このイベントインスタンスはトラッキング前のイベントを設定するためにも使えます。

#### <a id="revenue-tracking">収益のトラッキング

広告をタップした時やアプリ内課金をした時などにユーザーが報酬を得る仕組みであれば、そういったイベントもトラッキングできます。
1回のタップで1ユーロセントの報酬と仮定すると、報酬イベントは以下のようになります。

```js
var adjustEvent = new AdjustEvent('abc123')
adjustEvent.setRevenue(0.01, 'EUR')

Adjust.trackEvent(adjustEvent)
```

もちろんこれはコールバックパラメータと紐付けることができます。

通貨トークンを設定する場合、adjustは自動的に収益を任意の報酬に変換します。
更に詳しくは[通貨の変換][currency-conversion]をご覧ください。

収益とイベントトラッキングについては[イベントトラッキングガイド]もご参照ください。

#### <a id="callback-parameters">コールバックパラメータ

[dashboard]でイベントにコールバックURLを登録することができます。イベントがトラッキングされるたびにそのURLにGETリクエストが送信されます。
トラッキングする前にイベントで`addCallbackParameter`をコールすることによって、イベントにコールバックパラメータを追加できます。
そうして追加されたパラメータはコールバックURLに送られます。

例えば、コールバックURLに`http://www.adjust.com/callback`を登録した場合、イベントトラッキングは以下のようになります。

```js
var adjustEvent = new AdjustEvent('abc123')
adjustEvent.addCallbackParameter('key', 'value')
adjustEvent.addCallbackParameter('foo', 'bar')

Adjust.trackEvent(adjustEvent)
```

この場合、adjustはイベントをトラックし以下にリクエストを送信します。

    http://www.adjust.com/callback?key=value&foo=bar

adjustは様々なプレースホルダーをサポートしています。例えば`{idfa}`はパラメータの値として使うことができます。
コールバックではこのプレースホルダーは広告主向けの端末のIDで置き換えられることになります。
カスタムパラメータは格納しませんが、コールバックに付け加えます。
イベントにコールバックを登録していない場合は、パラメータは使用されません。

URLコールバックについて、使用可能な値の一覧など詳しくは[コールバックガイド][callbacks-guide]をご参照ください。

#### <a id="partner-parameters">パートナーパラメータ

adjustのダッシュボード上で有効化されている統合のために、ネットワークパートナーに送信するパラメータを設定することができます。

これは上記のコールバックパラメータと同様に機能しますが、
`AdjustEvent`インスタンスの`addPartnerParameter`メソッドをコールすることにより追加されます。

```js
var adjustEvent = new AdjustEvent('abc123')
adjustEvent.addPartnerParameter('key', 'value')
adjustEvent.addPartnerParameter('foo', 'bar')

Adjust.trackEvent(adjustEvent)
```

スペシャルパートナーとその統合について詳しくは[guide to special partners][special-partners]をご覧ください。

### <a id="attribution-callback">アトリビューションコールバック

アトリビューションが変更された時に通知を受け取れるよう、コールバックを登録することができます。
アトリビューションはいくつかのソースがあり得るため、変更の発生と同時に通知を受けることはできません。

[アトリビューションデータに関する方針][attribution-data]を必ずご確認ください。

コールバックメソッドは`AdjustConfig`インスタンスを使って設定されますので、`Adjust.appDidLaunch(adjustConfig)`
をコールする前に`setAttributionCallback`をコールしてください。

```js
adjustConfig.setAttributionCallback(function(attribution) {
    // In this example, we're just displaying alert with attribution content.
    alert('Tracker token = ' + attribution.trackerToken + '\n' +
          'Tracker name = ' + attribution.trackerName + '\n' +
          'Network = ' + attribution.network + '\n' +
          'Campaign = ' + attribution.campaign + '\n' +
          'Adgroup = ' + attribution.adgroup + '\n' +
          'Creative = ' + attribution.creative + '\n' +
          'Click label = ' + attribution.clickLabel)
})
```

コールバックメソッドはSDKが最終のアトリビューションデータを受け取ったときに呼び出されます。
コールバック内で`attribution`パラメータへのアクセスができます。以下にプロパティを簡単に紹介します。

- `var trackerToken` 最新インストールのトラッカートークン
- `var trackerName` 最新インストールのトラッカー名
- `var network` 最新インストールのネットワークのグループ階層
- `var campaign` 最新インストールのキャンペーンのグループ階層
- `var adgroup` 最新インストールのアドグループのグループ階層
- `var creative` 最新インストールのクリエイティブのグループ階層
- `var clickLabel` 最新インストールのクリックラベル

### <a id="event-session-callbacks">イベントとセッションのコールバック

イベントやセッションがトラッキングされた際に通知を受け取れるよう、リスナを登録することができます。
リスナには4種類あり、成功したイベント、失敗したイベント、成功したセッション、失敗したセッションをそれぞれトラッキングします。

成功したイベントへのコールバックメソッドを以下のように実装してください。

```js
adjustConfig.setEventSuccessCallback(function(eventSuccess) {
    // ...
})
```

失敗したイベントへは以下のように実装してください。

```js
adjustConfig.setEventFailureCallback(function(eventFailure) {
    // ...
})
```

同様に、成功したセッション

```js
adjustConfig.setSessionSuccessCallback(function(sessionSuccess) {
    // ...
})
```

失敗したセッション

```js
adjustConfig.setSessionFailureCallback(function(sessionFailure) {
    // ...
})
```

コールバックメソッドはSDKがサーバーにデータ送信を試みた後で呼ばれます。
コールバック内で該当のコールバックのレスポンスのデータオブジェクトにアクセスができます。
レスポンスデータのプロパティを以下に簡単に紹介します。

- `var message` サーバーからのメッセージまたはSDKのエラーログ
- `var timeStamp` サーバーからのタイムスタンプ
- `var adid` adjustから提供されるユニークデバイスID
- `var jsonResponse` サーバーからのレスポンスのJSONオブジェクト

どちらのイベントレスポンスのオブジェクトも以下を含みます。

- `var eventToken` イベントトークン。イベントがトラッキングされた場合

イベントとセッション両方の失敗した場合のオブジェクトは以下を含みます。

- `var willRetry` しばらく後に再送を試みる予定であるかどうかを示します。

### <a id="event-buffering">イベントバッファリング

イベントトラッキングを多用する場合は、HTTPリクエストを遅らせて1分毎にまとめて送信したほうがいい場合があります。
その場合は、`AdjustConfig`インスタンスでイベントバッファリングを有効にしてください。

```js
adjustConfig.setEventBufferingEnabled(true)
```

### <a id="disable-tracking">トラッキングの無効化

`setEnabled`にパラメータ`false`を渡すことで、adjust SDKが行うデバイスのアクティビティのトラッキングをすべて無効にすることができます。
**この設定はセッション間で記憶されます** 最初のセッションの後でしか有効化できません。

```js
Adjust.setEnabled(false)
```

<a id="is-enabled">adjust SDKが現在有効かどうか、`isEnabled`関数を呼び出せば確認できます。
また、`setEnabled`関数に`true`を渡せば、adjust SDKを有効にすることができます。

```js
Adjust.isEnabled(function(isEnabled) {
    if (isEnabled) {
        // SDK is enabled.    
    } else {
        // SDK is disabled.
    }
})
```

### <a id="offline-mode">オフラインモード

adjustのサーバーへの送信を一時停止し、保持されているトラッキングデータを後から送信するために
adjust SDKをオフラインモードにすることができます。
オフラインモード中はすべての情報がファイルに保存されるので、イベントをたくさん発生させすぎないようにご注意ください。

`true`パラメータで`setOfflineMode`を呼び出すとオフラインモードを有効にできます。

```js
Adjust.setOfflineMode(true)
```

反対に、`false`パラメータで`setOfflineMode`を呼び出せばオフラインモードを解除できます。
adjust SDKがオンラインモードに戻った時、保存されていた情報は正しいタイムスタンプでadjustのサーバーに送られます。

トラッキングの無効化とは異なり、この設定はセッション間で*記憶されません*。
オフラインモード時にアプリを終了しても、次に起動した時にはオンラインモードとしてアプリが起動します。

### <a id="background-tracking">バックグラウンドでのトラッキング

adjust SDKはデフォルドではアプリがバックグラウンドにある時はHTTPリクエストを停止します。
この設定は`AdjustConfig`インスタンスで変更できます。

```js
adjustConfig.setSendInBackground(true)
```

### <a id="device-ids">デバイスID

Google Analyticsなどの一部のサービスでは、レポートの重複を防ぐためにデバイスIDとクライアントIDを連携させることが求められます。

デバイスID IDFAを取得するには、`getIdfa`関数をコールしてください。

```js
Adjust.getIdfa(function(idfa) {
    // ...
});
```

### <a id="deeplinking">ディープリンキング

カスタムURLスキームからアプリを開けるよう、adjust SDKでディープリンクを設定することができます。

ディープリンクを使ったリターゲティングやリエンゲージメントを想定している場合、
ディープリンクにadjustキャンペーンの特定のパラメータを置く必要があります。
ディープリンクを使ったリターゲティングやリエンゲージメントについて詳しくは[公式資料][reattribution-deeplinks]をご覧ください。

プロジェクトナビゲータからApplication Delegateのソースファイルを開いてください。
`openURL`と`application:continueUserActivity:restorationHandler:`があればそこに、なければこれらを追加し、
`AdjustBridge`への参照を追加してください。この参照はWeb viewを表示するView Controllerにあるはずです。

```objc
#import "Adjust.h"
// Or #import <AdjustSdk/Adjust.h>
// (depends on the way you have chosen to add our native iOS SDK)
// ...

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    // This is how AdjustBridge is accessed in our example app.
    // Of course, you can choose on your own how to access it.
    [self.uiWebViewExampleController.adjustBridge sendDeeplinkToWebView:url];
    
    // Your logic whether URL should be opened or not.
    BOOL shouldOpen = [self yourLogic:url];
    
    return shouldOpen;
}

// ...

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity 
 restorationHandler:(void (^)(NSArray *restorableObjects))restorationHandler {
    if ([[userActivity activityType] isEqualToString:NSUserActivityTypeBrowsingWeb]) {
        [self.uiWebViewExampleController.adjustBridge sendDeeplinkToWebView:[userActivity webpageURL]];
    }

    // Your logic whether URL should be opened or not.
    BOOL shouldOpen = [self yourLogic:url];
    
    return shouldOpen;
}
```

両方のメソッドにこのコールを追加すると、iOS 8以下(旧カスタムURLスキームを使用しているバージョン)とiOS 9以降(`ユニバーサルリンク`を使用)の両方に対応します。

**重要** ユニバーサルリンクを有効化するために、ネイティブiOS SDK READMEより[ユニバーサルリンクガイド][ios_sdk_ulinks]をご確認ください。

ディープリンクURLをWeb viewに返送するには、`deeplink`ブリッジにメソッドを登録してください。
このメソッドは、ディープリンク情報のついたトラッカーURLをクリックした後にアプリが開かれると、adjust SDKによって呼ばれます。

```js
setupWebViewJavascriptBridge(function(bridge) {
    bridge.registerHandler('deeplink', function(data, responseCallback) {
        // In this example, we're just displaying alert with deeplink URL content.
        alert('Deeplink:\n' + data)
    })
})
```

#### <a id="deferred-deeplinking-callback">ディファート・ディープリンクのコールバック

Deferredディープリンクが開く前に通知を受けるデリゲートコールバックを登録し、adjust SDKがそれを開くかどうか決めることができます。

このコールバックは`AdjustConfig`でも設定されます。

```js
adjustConfig.setDeferredDeeplinkCallback(function(deferredDeeplink) {
    // In this example, we're just displaying alert with deferred deeplink URL content.
    alert('Deferred deeplink:\n' + deferredDeeplink)
})
```

このコールバック関数は、SDKがサーバーからディファード・ディープリンクを受け取った後、SDKがそれを開く前に呼ばれます。

`AdjustConfig`インスタンスでは他にも、adjust SDKにこのリンクを開くかどうか指示できる設定があります。
これは`setOpenDeferredDeeplink`メソッドを呼び出して設定できます。

```js
adjustConfig.setOpenDeferredDeeplink(true)
// Or if you don't want our SDK to open the link:
adjustConfig.setOpenDeferredDeeplink(false)
```

これを指定しなければ、デフォルトではadjust SDKはリンクを開こうとします。

[dashboard]:  http://adjust.com
[adjust.com]: http://adjust.com

[wvjsb_readme]:             https://github.com/marcuswestin/WebViewJavascriptBridge#usage
[ios_sdk_ulinks]:           https://github.com/adjust/ios_sdk/#universal-links
[callbacks-guide]:          https://docs.adjust.com/en/callbacks
[attribution-data]:         https://github.com/adjust/sdks/blob/master/doc/attribution-data.md
[special-partners]:         https://docs.adjust.com/en/special-partners
[basic_integration]:        https://github.com/adjust/ios_sdk/#basic-integration
[web_view_js_bridge]:       https://github.com/marcuswestin/WebViewJavascriptBridge
[currency-conversion]:      https://docs.adjust.com/en/event-tracking/#tracking-purchases-in-different-currencies
[event-tracking-guide]:     https://docs.adjust.com/en/event-tracking/#reference-tracking-purchases-and-revenues
[reattribution-deeplinks]:  https://docs.adjust.com/en/deeplinking/#manually-appending-attribution-data-to-a-deep-link

[bridge_add]:             https://raw.githubusercontent.com/adjust/sdks/master/Resources/ios/bridge/bridge_add.png
[bridge_drag]:            https://raw.githubusercontent.com/adjust/sdks/master/Resources/ios/bridge/bridge_drag.png
[bridge_init_js]:         https://raw.githubusercontent.com/adjust/sdks/master/Resources/ios/bridge/bridge_init_js.png
[bridge_init_objc]:       https://raw.githubusercontent.com/adjust/sdks/master/Resources/ios/bridge/bridge_init_objc.png
[bridge_init_js_xcode]:   https://raw.githubusercontent.com/adjust/sdks/master/Resources/ios/bridge/bridge_init_js_xcode.png
[bridge_install_tracked]: https://raw.githubusercontent.com/adjust/sdks/master/Resources/ios/bridge/bridge_install_tracked.png

## <a id="license">ライセンス

adjust SDKはMITライセンスを適用しています。

Copyright (c) 2012-2016 adjust GmbH,
http://www.adjust.com

以下に定める条件に従い、本ソフトウェアおよび関連文書のファイル（以下「ソフトウェア」）の複製を取得するすべての人に対し、
ソフトウェアを無制限に扱うことを無償で許可します。これには、ソフトウェアの複製を使用、複写、変更、結合、掲載、頒布、サブライセンス、
および/または販売する権利、およびソフトウェアを提供する相手に同じことを許可する権利も無制限に含まれます。

上記の著作権表示および本許諾表示を、ソフトウェアのすべての複製または重要な部分に記載するものとします。

ソフトウェアは「現状のまま」で、明示であるか暗黙であるかを問わず、何らの保証もなく提供されます。
ここでいう保証とは、商品性、特定の目的への適合性、および権利非侵害についての保証も含みますが、それに限定されるものではありません。 
作者または著作権者は、契約行為、不法行為、またはそれ以外であろうと、ソフトウェアに起因または関連し、
あるいはソフトウェアの使用またはその他の扱いによって生じる一切の請求、損害、その他の義務について何らの責任も負わないものとします。
