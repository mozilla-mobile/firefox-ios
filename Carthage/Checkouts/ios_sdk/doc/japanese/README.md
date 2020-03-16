これはネイティブadjust™iOS SDKガイドです。adjust™については[adjust.com]をご覧ください。

Web viewを使用するアプリで、JavascriptコードからAdjustのトラッキングをご利用いただくには、
[iOS Web view SDKガイド][ios-web-views-guide]をご確認ください。

Read this in other languages: [English][en-readme], [中文][zh-readme], [日本語][ja-readme], [한국어][ko-readme].

<section id='toc-section'>
</section>

### <a id="example-apps"></a>サンプルアプリ

[`iOS (Objective-C)`][example-ios-objc]と[`iOS (Swift)`][example-ios-swift]、[`tvOS`][example-tvos]、[`iMessage`][example-imessage]、[`Apple Watch`][example-iwatch]のサンプルアプリが[`examples`デイレクトリー][examples]にあります。
このXcodeプロジェクトを開けば、adjust SDKの統合方法の実例をご確認いただけます。

### <a id="basic-integration">基本的な統合方法

adjust SDKをiOSプロジェクトに連携する手順を説明します。
ここでは、iOSアプリケーションの開発にXcodeを使用していると想定しています。

#### <a id="sdk-get"></a>プロジェクトにSDKを追加する


[CocoaPods][cocoapods]を使用している場合は、`Podfile`に以下のコードを追加し、
[こちらの手順](#sdk-integrate)に進んでください。

```ruby
pod 'Adjust', '~> 4.18.3'
```

または

```ruby
pod 'Adjust', :git => 'https://github.com/adjust/ios_sdk.git', :tag => 'v4.18.3'
```

---

[Carthage][carthage]を使用している場合は、`Cartfile`に以下のコードを追加し、
[こちらの手順](#sdk-frameworks)に進んでください。

```ruby
github "adjust/ios_sdk"
```

---

adjust SDKはフレームワークとしてプロジェクトに追加することもできます。
[リリースページ][releases]に以下の3つのアーカイブがあります。

* `AdjustSdkStatic.framework.zip`
* `AdjustSdkDynamic.framework.zip`
* `AdjustSdkTv.framework.zip`
* `AdjustSdkIm.framework.zip`

iOS 8リリース以降、AppleはDynamic Frameworks (Embedded Framework)を導入しています。 
iOS 8以降の端末をターゲットにしている場合は、adjustの SDK dynamic frameworkが使用できます。 
StaticかDynamicフレームワークを選択し、プロジェクトに追加してください。

`tvOS`アプリの場合もadjust SDKの利用が可能です。
`AdjustSdkTv.framework.zip`アーカイブからadjustのtvOSフレームワークを展開してください。

同様に`iMessage`アプリの場合もadjust SDKの利用が可能です。`AdjustSdkIm.framework.zip`アーカイブからIMフレームワークを展開してください。

#### <a id="sdk-frameworks"></a>iOSフレームワークを追加する

1. プロジェクトナビゲータ上でプロジェクトを選択します。
2. メインビューの左側にある該当ターゲットを選択します。
3. `Build Phases`タブで、`Link Binary with Libraries`を開きます。
4. そのセクションの最下部にある`+`ボタンをクリックします。
5. `AdSupport.framework`を選び、`Add`をクリックします。
6. tvOSを使用していない場合は、同じ手順を繰り返して`iAd.framework`と`CoreTelephony.framework`を追加してください。
7. フレームワークの`Status`を`Optional`にしてください。

#### <a id="sdk-integrate"></a>SDKをアプリに実装する

Podリポジトリからadjust SDKを追加した場合は、次のimport statement(インポートステートメント）のいづれかを使用します。

```objc
#import "Adjust.h"
```

または

```objc
#import <Adjust/Adjust.h>
```

---

adjust SDKをStaticまたはDynamicフレームワークとして追加した場合、またはCarthageを使う場合は、以下のインポートステートメントを使用します。

```objc
#import <AdjustSdk/Adjust.h>
```

---

tvOSアプリケーションでadjust SDKを使用している場合は、以下のインポートステートメントを使用します。

```objc
#import <AdjustSdkTv/Adjust.h>
```

---

iMessageアプリケーションでadjust SDKを使用している場合は、以下のインポートステートメントを使用します。

```objc
#import <AdjustSdkIm/Adjust.h>
```


次に基本的なセッションのトラッキングを設定します。

#### <a id="basic-setup">基本設定

Project Navigator上で、アプリケーションデリゲートのソースファイルを開いてください。
ソースコードの先頭に`import`の記述を追加し、`didFinishLaunching`か`didFinishLaunchingWithOptions`のメソッド中に
下記の`Adjust`コールを追加してください。

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

**注意**: adjust SDKの初期化は、手順に沿い`確実に`行なってください。[トラブルシューティングのセクション](#ts-delayed-init)で説明しているように、さまざまな問題が発生することがあります。

`{YourAppToken}`をあなたのアプリケーショントークンに置き換えてください。これはダッシュボードで見つけることができます。

テストのためにアプリケーションをビルドするか実行のためにビルドするかによって、以下の値を選び`environment`を設定してください。

```objc
NSString *environment = ADJEnvironmentSandbox;
NSString *environment = ADJEnvironmentProduction;
```

**重要** お客様や、その他の人がアプリのテストをしている場合にのみ、この値は`ADJEnvironmentSandbox`に設定してください。
アプリを公開する直前に環境を`ADJEnvironmentProduction`に設定してください。開発とテストを再び開始する時は、`ADJEnvironmentSandbox`に戻してください。

これらの環境から、実際のトラフィックとテストデバイスのトラフィックを区別することができます。
特に収益をトラッキングする場合に重要な値となりますので、大切にしてください。

### <a id="basic-setup-imessage">iMessage固有の設定

**ソースからSDKを追加する：** adjust SDKをiMessageアプリケーションにソースから追加する場合、プリプロセッサマクロ**ADJUST_IM=1**がiMessageプロジェクトで設定されていることを確認してください。

**SDKをフレームワークとして追加する：** iMessageアプリケーションに`AdjustSdkIm.framework`を追加した後、`Build Phases`プロジェクト設定で`New Copy Files Phase`を追加します。`AdjustSdkIm.framework`を`Frameworks`フォルダにコピーする、を選択してください。

**セッショントラッキング：** セッショントラッキングをiMessageアプリで正しく機能させるためには、追加の統合ステップを1回実行してください。標準のiOSアプリでは、Adjust SDKはiOSシステム通知に自動的に登録され、いつアプリ内に入り、フォアグラウンドから離れたかを知ることができます。これはiMessageアプリの場合には該当しないため、iMessageアプリビューコントローラの`trackSubsessionStart`メソッドと`trackSubsessionEnd`メソッドへの明示的な呼び出しを追加する必要があります。 これにより、アプリがフォアグラウンドに 表示されているかどうかをSDKに認識させることができます。

`didBecomeActiveWithConversation`のメソッド中に`trackSubsessionStart`を追加します:

```objc
-(void)didBecomeActiveWithConversation:(MSConversation *)conversation {
    // Called when the extension is about to move from the inactive to active state.
    // This will happen when the extension is about to present UI.
    // Use this method to configure the extension and restore previously stored state.
     [Adjust trackSubsessionStart];
}
```

`willResignActiveWithConversation`のメソッド中に`trackSubsessionEnd`を追加します：

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

このセットを使用すると、Adjust SDKはiMessageアプリ内でセッションのトラッキングを正常に行うことができます。

**注意：** 書き込んだiOSアプリとiMessageの拡張機能は、異なるメモリ空間で動作しており、バンドル識別子も異なります。２つの場所で同じアプリトークンを使用してAdjust SDKを初期化すると、相互が認識しない2つの独立したインスタンスが生成され、ダッシュボードのデータが混在してしまうことがあります。これを避けるために、iMessageアプリ用に別のアプリをAdjustダッシュボードに作成し、別のアプリトークンを使ってSDKの初期化をその中で行ってください。


#### <a id="adjust-logging">Adjustログ

`ADJConfig`インスタンスの`setLogLevel:`に設定するパラメータを変更することによって記録するログのレベルを調節できます。
パラメータは以下の種類があります。

```objc
[adjustConfig setLogLevel:ADJLogLevelVerbose];  // すべてのログを有効にする
[adjustConfig setLogLevel:ADJLogLevelDebug];    // より詳細なログを記録する
[adjustConfig setLogLevel:ADJLogLevelInfo];     // デフォルト
[adjustConfig setLogLevel:ADJLogLevelWarn];     // infoのログを無効にする
[adjustConfig setLogLevel:ADJLogLevelError];    // warningsを無効にする
[adjustConfig setLogLevel:ADJLogLevelAssert];   // errorsも無効にする
[adjustConfig setLogLevel:ADJLogLevelSuppress]; // すべてのログを無効にする
```

本番用のアプリにadjust SDKのログを表示させたくない場合は、ログレベルを`ADJLogLevelSuppress`に設定してください。
加えて、ログレベルをsuppressに設定する部分で`ADJConfig`オブジェクトを以下のように初期化してください。

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
                                    allowSupressLogLevel:YES];

[Adjust appDidLaunch:adjustConfig];
```

#### <a id="build-the-app">アプリのビルド

アプリをビルドして実行しましょう。ビルドが成功したら、コンソールに表示されるSDKログを注視してください。
初めてアプリが実行されたあと、`Install tracked`のinfoが出力されるはずです。

![][run]

### <a id="additional-feature">追加機能

adjust SDKの実装ができたら、更に以下の機能を利用することができます。

#### <a id="event-tracking">イベントトラッキング

adjustを使ってイベントトラッキングができます。ここではあるボタンのタップを毎回トラックしたい場合について説明します。
[dashboard]にてイベントトークンを作成し、そのイベントトークンは仮に`abc123`というイベントトークンと関連しているとします。
タップをトラックするため、ボタンの`buttonDown`メソッドに以下のような記述を追加します。

```objc
ADJEvent *event = [ADJEvent eventWithEventToken:@"abc123"];
[Adjust trackEvent:event];
```

こうすると、ボタンがタップされた時にログに`Event tracked`と出力されるようになります。

このイベントインスタンスはトラッキング前のイベントを設定するためにも使えます。

##### <a id="revenue-tracking">収益のトラッキング

広告をタップした時やアプリ内課金をした時などにユーザーが報酬を得る仕組みであれば、そういったイベントもトラッキングできます。
1回のタップで1ユーロセントの報酬と仮定すると、報酬イベントは以下のようになります。

```objc
ADJEvent *event = [ADJEvent eventWithEventToken:@"abc123"];

[event setRevenue:0.01 currency:@"EUR"];

[Adjust trackEvent:event];
```

もちろんこれはコールバックパラメータと紐付けることができます。

通貨トークンを設定する場合、adjustは自動的に収益を任意の報酬に変換します。
更に詳しくは[通貨の変換][currency-conversion]をご覧ください。

収益とイベントトラッキングについては[イベントトラッキングガイド](https://docs.adjust.com/en/event-tracking/#reference-tracking-purchases-and-revenues)もご参照ください。

##### <a id="revenue-deduplication"></a>収益の重複排除

報酬を重複してトラッキングすることを防ぐために、トランザクションIDを随意で設定することができます。
最新の10のトランザクションIDが記憶され、重複したトランザクションIDの収益イベントは除外されます。
これはアプリ内課金のトラッキングに特に便利です。下記に例を挙げます。

アプリ内課金をトラッキングする際は、状態が`SKPaymentTransactionStatePurchased`に変わって初めて
`paymentQueue:updatedTransaction`中の`finishTransaction`の後で`trackEvent`をコールするようにしてください。
こうすることで、実際には生成されない報酬をトラッキングすることを防ぐことができます。

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

##### <a id="iap-verification">アプリ内課金の検証

adjustのサーバーサイドのレシート検証ツール、Purchase Verificationを使ってアプリ内で行われたアプリ内課金の妥当性を調べる際は、
iOS purchase SDKをご利用ください。詳しくは[こちら][ios-purchase-verification]

##### <a id="callback-parameters">コールバックパラメータ

[dashboard]でイベントにコールバックURLを登録することができます。イベントがトラッキングされるたびに
そのURLにGETリクエストが送信されます。トラッキングする前にイベントで`addCallbackParameter`をコールすることによって、
イベントにコールバックパラメータを追加できます。そうして追加されたパラメータはコールバックURLに送られます。

例えば、コールバックURLに`http://www.mydomain.com/callback`を登録した場合、イベントトラッキングは以下のようになります。

```objc
ADJEvent *event = [ADJEvent eventWithEventToken:@"abc123"];

[event addCallbackParameter:@"key" value:@"value"];
[event addCallbackParameter:@"foo" value:@"bar"];

[Adjust trackEvent:event];
```

この場合、adjustはこのイベントをトラッキングし以下にリクエストが送られます。

    http://www.mydomain.com/callback?key=value&foo=bar

パラメータの値として使われることのできるプレースホルダーは、`{idfa}`のような様々な形に対応しています。
得られるコールバック内で、このプレースホルダーは該当デバイスの広告主用のIDに置き換えられます。
独自に設定されたパラメータには何も格納しませんが、コールバックに追加されます。
イベントにコールバックを登録していない場合は、これらのパラメータは使われません。

URLコールバックについて詳しくは[コールバックガイド][callbacks-guide]をご覧ください。
利用可能な値のリストもこちらで参照してください。

##### <a id="partner-parameters">パートナーパラメータ

adjustのダッシュボード上で連携が有効化されているネットワークパートナーに送信するパラメータを設定することができます。

これは上記のコールバックパラメータと同様に機能しますが、
`ADJEvent`インスタンスの`addPartnerParameter`メソッドをコールすることにより追加されます。

```objc
ADJEvent *event = [ADJEvent eventWithEventToken:@"abc123"];

[event addPartnerParameter:@"key" value:@"value"];
[event addPartnerParameter:@"foo" value:@"bar"];

[Adjust trackEvent:event];
```

スペシャルパートナーとその統合について詳しくは[連携パートナーガイド][special-partners]をご覧ください。

### <a id="callback-id"></a>コールバック ID
トラッキングしたいイベントにカスタムIDを追加できます。このIDはイベントをトラッキングし、成功か失敗かの通知を受け取けとれるようコールバックを登録することができます。このIDは`ADJEvent`インスタンスの`setCallbackId`メソッドと呼ぶように設定できます：

```objc
ADJEvent *event = [ADJEvent eventWithEventToken:@"abc123"];

[event setCallbackId:@"Your-Custom-Id"];

[Adjust trackEvent:event];
```

#### <a id="session-parameters">セッションパラメータ

いくつかのパラメータは、adjust SDKのイベントごと、セッションごとに送信するために保存されます。
このいずれかのパラメータを追加すると、これらはローカル保存されるため、毎回追加する必要はありません。
同じパラメータを再度追加しても何も起こりません。

これらのセッションパラメータはadjust SDKが立ち上がる前にコールすることができるので、インストール時に送信を確認することもできます。
インストール時に送信したい場合は、adjust SDKの初回立ち上げを[遅らせる](#delay-start)ことができます。
ただし、必要なパラメータの値を得られるのは立ち上げ後となります。

##### <a id="session-callback-parameters"> セッションコールバックパラメータ

[イベント](#callback-parameters)で設定された同じコールバックパラメータを、
adjust SDKのイベントごとまたはセッションごとに送信するために保存することもできます。

セッションコールバックパラメータのインターフェイスとイベントコールバックパラメータは似ています。
イベントにキーと値を追加する代わりに、`Adjust`の`addSessionCallbackParameter:value:`メソッドへのコールで追加されます。

```objc
[Adjust addSessionCallbackParameter:@"foo" value:@"bar"];
```

セッションコールバックパラメータは、イベントに追加されたコールバックパラメータとマージされます。
イベントに追加されたコールバックパラメータは、セッションコールバックパラメータより優先されます。
イベントに追加されたコールバックパラメータがセッションから追加されたパラメータと同じキーを持っている場合、
イベントに追加されたコールバックパラメータの値が優先されます。

`removeSessionCallbackParameter`メソッドに指定のキーを渡すことで、
特定のセッションコールバックパラメータを削除することができます。

```objc
[Adjust removeSessionCallbackParameter:@"foo"];
```

セッションコールバックパラメータからすべてのキーと値を削除したい場合は、
`resetSessionCallbackParameters`メソッドを使ってリセットすることができます。

```objc
[Adjust resetSessionCallbackParameters];
```

##### <a id="session-partner-parameters">セッションパートナーパラメータ

adjust SDKのイベントごとやセッションごとに送信される[セッションコールバックパラメータ](#session-callback-parameters)があるように、
セッションパートナーパラメータも用意されています。

これらはネットワークパートナーに送信され、adjust[ダッシュボード]で有効化されている連携のために利用されます。

セッションパートナーパラメータのインターフェイスとイベントパートナーパラメータは似ています。
イベントにキーと値を追加する代わりに、`Adjust`の`addSessionPartnerParameter:value:`メソッドへのコールで追加されます。

```objc
[Adjust addSessionPartnerParameter:@"foo" value:@"bar"];
```

セッションパートナーパラメータはイベントに追加されたパートナーパラメータとマージされます。イベントに追加されたパートナーパラメータは、
セッションパートナーパラメータより優先されます。イベントに追加されたパートナーパラメータが
セッションから追加されたパラメータと同じキーを持っている場合、イベントに追加されたパートナーパラメータの値が優先されます。

`removeSessionPartnerParameter`.メソッドに指定のキーを渡すことで、
特定のセッションパートナーパラメータを削除することができます。

```objc
[Adjust removeSessionPartnerParameter:@"foo"];
```

セッションパートナーパラメータからすべてのキーと値を削除したい場合は、
`resetSessionPartnerParameters`メソッドを使ってリセットすることができます。

```objc
[Adjust resetSessionPartnerParameters];
```

##### <a id="delay-start">ディレイスタート

adjust SDKのスタートを遅らせると、ユニークIDなどのセッションパラメータを取得しインストール時に送信できるようにすることがでいます。

`ADJConfig`インスタンスの`setDelayStart`メソッドで、遅らせる時間を秒単位で設定できます。

```objc
[adjustConfig setDelayStart:5.5];
```

この場合、adjust SDKは最初のインストールセッションと生成されるイベントを初めの5.5秒間は送信しません。
この時間が過ぎるまで、もしくは`[Adjust sendFirstPackages]`がコールされるまで、
セッションパラメータはすべてディレイインストールセッションとイベントに追加され、adjust SDKは通常通り再開します。

**adjust SDKのディレイスタートは最大で10秒です。**

#### <a id="attribution-callback">アトリビューションコールバック

トラッカーのアトリビューション変化の通知を受けるために、デリゲートコールバックを登録することができます。
アトリビューションには複数のソースがあり得るため、この情報は同時に送ることができません。
次の手順に従って、アプリデリゲートでデリゲートプロトコルを実装してください。

[アトリビューションデータに関するポリシー][attribution-data]を必ずご確認ください。

1. `AppDelegate.h`を開いてインポートと`AdjustDelegate`の宣言を追加してください。

    ```objc
    @interface AppDelegate : UIResponder <UIApplicationDelegate, AdjustDelegate>
    ```

2. `AppDelegate.m`を開き、以下のデリゲートコールバック関数を追加してください。

    ```objc
    - (void)adjustAttributionChanged:(ADJAttribution *)attribution {
    }
    ```

3. `ADJConfig`インスタンスにデリゲートを設定してください。

    ```objc
    [adjustConfig setDelegate:self];
    ```

デリゲートコールバックが`ADJConfig`インスタンスを使っているため、`[Adjust appDidLaunch:adjustConfig]`をコールする前に`setDelegate`をコールする必要があります。

このデリゲート関数は、SDKが最後のアトリビューションデータを取得した時に作動します。
デリゲート関数内で`attribution`パラメータを確認することができます。このパラメータのプロパティの概要は以下の通りです。

- `NSString trackerToken` 最新アトリビューションのトラッカートークン
- `NSString trackerName` 最新アトリビューションのトラッカー名
- `NSString network` 最新アトリビューションのネットワークのグループ階層
- `NSString campaign` 最新アトリビューションのキャンペーンのグループ階層
- `NSString adgroup` 最新アトリビューションのアドグループのグループ階層
- `NSString creative` 最新アトリビューションのクリエイティブのグループ階層
- `NSString clickLabel` 最新アトリビューションのクリックラベル
- `NSString adid` adjustユニークID

### <a id="ad-revenue"></a>広告収益の計測

Adjust SDKを利用して、以下のメソッドを呼び出し広告収益情報を計測することができます。

```objc
[Adjust trackAdRevenue:source payload:payload];
```

Adjust SDKにパスするメソッドの引数は以下の通りです。

- `source` - 広告収益情報のソースを指定する`NSString`オブジェクト
- `payload` - 広告収益のJSONを格納する`NSData`オブジェクト

現在、弊社は以下の`source`パラメータの値のみ対応しています。

- `ADJAdRevenueSourceMopub` - メディエーションプラットフォームのMoPubを示します。（詳細は、[統合ガイド][sdk2sdk-mopub]を参照ください）

#### <a id="event-session-callbacks">イベントとセッションのコールバック

イベントとセッションの双方もしくはどちらかをトラッキングし、成功か失敗かの通知を受け取れるようデリゲートコールバックを登録することができます。
[アトリビューションコールバック](#attribution-callback)に使われる`AdjustDelegate`プロトコルをここでも任意で使うことができます。

成功したイベントへのデリゲートコールバック関数を以下のように実装してください。

```objc
- (void)adjustEventTrackingSucceeded:(ADJEventSuccess *)eventSuccessResponseData {
}
```

失敗したイベントへは以下のように実装してください。

```objc
- (void)adjustEventTrackingFailed:(ADJEventFailure *)eventFailureResponseData {
}
```

同様に、成功したセッション

```objc
- (void)adjustSessionTrackingSucceeded:(ADJSessionSuccess *)sessionSuccessResponseData {
}
```

失敗したセッション

```objc
- (void)adjustSessionTrackingFailed:(ADJSessionFailure *)sessionFailureResponseData {
}
```

デリゲート関数はSDKがサーバーにパッケージ送信を試みた後で呼ばれます。
デリゲートコールバック内でデリゲートコールバック用のレスポンスデータオブジェクトを確認することができます。
レスポンスデータのプロパティの概要は以下の通りです。

- `NSString message` サーバーからのメッセージまたはSDKのエラーログ
- `NSString timeStamp` サーバーからのタイムスタンプ
- `NSString adid` adjustから提供されるユニークデバイスID
- `NSDictionary jsonResponse` サーバーからのレスポンスのJSONオブジェクト

イベントのレスポンスデータは以下を含みます。

- `NSString eventToken` トラッキングされたパッケージがイベントだった場合、そのイベントトークン
- `NSString callbackid` イベントオブジェクトにカスタム設定されたコールバックID

失敗したイベントとセッションは以下を含みます。

- `BOOL willRetry` しばらく後に再送を試みる予定であるかどうかを示します。

#### <a id="disable-tracking">トラッキングの無効化

`setEnabled`にパラメータ`NO`を渡すことで、adjustSDKが行うデバイスのアクティビティのトラッキングをすべて無効にすることができます。
**この設定はセッション間で記憶されます** 最初のセッションの後でしか有効化できません。

```objc
[Adjust setEnabled:NO];
```

<a id="is-enabled">adjust SDKが現在有効かどうか、`isEnabled`関数を呼び出せば確認できます。
また、`setEnabled`関数に`YES`を渡せば、adjust SDKを有効にすることができます。

#### <a id="offline-mode">オフラインモード

adjustのサーバーへの送信を一時停止し、保持されているトラッキングデータを後から送信するために
adjust SDKをオフラインモードにすることができます。
オフラインモード中はすべての情報がファイルに保存されるので、イベントをたくさん発生させすぎないようにご注意ください。

`YES`パラメータで`setOfflineMode`を呼び出すとオフラインモードを有効にできます。

```objc
[Adjust setOfflineMode:YES];
```

反対に、`NO`パラメータで`setOfflineMode`を呼び出せばオフラインモードを解除できます。
adjust SDKがオンラインモードに戻った時、保存されていた情報は正しいタイムスタンプでadjustのサーバーに送られます。

トラッキングの無効化とは異なり、この設定はセッション間で*記憶されません*。
オフラインモード時にアプリを終了しても、次に起動した時にはオンラインモードとしてアプリが起動します。

#### <a id="event-buffering">イベントバッファリング

イベントトラッキングを酷使している場合、HTTPリクエストを遅らせて1分毎にまとめて送信したほうがいい場合があります。
その場合は、`ADJConfig`インスタンスでイベントバッファリングを有効にしてください。

```objc
[adjustConfig setEventBufferingEnabled:YES];
```

設定されていない場合、イベントバッファリングは**デフォルトで無効**になっています。

### <a id="gdpr-forget-me"></a>GDPR消去する権利（忘れられる権利）

次のメソッドを呼び出すと、EUの一般データ保護規制（GDPR）第17条に従い、ユーザーが消去する権利（忘れられる権利）を行使した際にAdjust SDKがAdjustバックエンドに情報を通知します。

```objc
[Adjust gdprForgetMe];
```

この情報を受け取ると、Adjustはユーザーのデータを消去し、Adjust SDKはユーザーの追跡を停止します。この削除された端末からのリクエストは今後、Adjustに送信されません。 

#### <a id="background-tracking">バックグラウンドでのトラッキング

adjust SDKはデフォルドではアプリがバックグラウンドにある時はHTTPリクエストを停止します。
この設定は`AdjustConfig`インスタンスで変更できます。

```objc
[adjustConfig setSendInBackground:YES];
```

設定されていない場合、バックグラウンドでの送信は**デフォルトで無効**になっています。

#### <a id="device-ids">デバイスID

Google Analyticsなどの一部のサービスでは、レポートの重複を防ぐためにデバイスIDとクライアントIDを連携させることが求められます。

デバイスID IDFAを取得するには、`idfa`関数をコールしてください。

```objc
NSString *idfa = [Adjust idfa];
```

#### <a id="push-token">Pushトークン

プッシュ通知のトークンを送信するには、アプリケーションデリゲートにて
`didRegisterForRemoteNotificationsWithDeviceToken`内の`Adjust`に以下の記述を追加してください。

```objc
- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [Adjust setDeviceToken:deviceToken];
}
```

#### <a id="pre-installed-trackers">プレインストールのトラッカー

すでにアプリをインストールしたことのあるユーザーをadjust SDKを使って識別したい場合は、次の手順で設定を行ってください。

1. [dashboard]上で新しいトラッカーを作成してください。

2. App Delegateを開き、`ADJConfig`のデフォルトトラッカーを設定してください。

    ```objc
    ADJConfig *adjustConfig = [ADJConfig configWithAppToken:yourAppToken environment:environment];
    [adjustConfig setDefaultTracker:@"{TrackerToken}"];
    [Adjust appDidLaunch:adjustConfig];
    ```

    `{TrackerToken}`にステップ2で作成したトラッカートークンを入れてください。
    ダッシュボードには`http://app.adjust.com/`を含むトラッカーURLが表示されます。
    ソースコード内にはこのURLすべてではなく、6文字のトークンを抜き出して指定してください。

3. アプリをビルドしてください。Xcodeで下記のような行が表示されるはずです。

    ```
    Default tracker: 'abc123'
    ```

#### <a id="deeplinking">ディープリンキング

URLからアプリへのディープリンクを使ったadjustトラッカーURLをご利用の場合、ディープリンクURLとその内容の情報を得られる可能性があります。
ユーザーがすでにアプリをインストールしている状態でそのURLに訪れた場合(スタンダード・ディープリンキング)と、
アプリをインストールしていないユーザーがURLを開いた場合(ディファード・ディープリンキング)が有り得ます。
どちらの場合もadjust SDKでサポートでき、ディープリンクURLはユーザーがそのURLを訪れてからアプリを開いた後で提供されます。
この機能を使う場合は、正しい設定を行ってください。

##### <a id="deeplinking-standard">スタンダード・ディープリンキング

アプリをすでにインストールしているユーザーがディープリンクデータの付加されたトラッカーURLを開いた場合、
アプリが開かれるとディープリンクの情報はアプリに送信されます。iOS 9以降において、Apple社はディープリンクの扱いを変更しています。
どちらの状況でアプリにディープリンクを使うか、もしくはあらゆる端末をカバーするために両方でディープリンクを使うかによって、
以下のいずれかまたは両方の設定を行ってください。

##### <a id="deeplinking-setup-old"> iOS 8以前でのディープリンキング

iOS 8以前の端末でのディープリンキングはカスタムURLスキームの設定によって行なわれます。アプリが開かれるためのカスタムURLスキーム名をつける必要があります。
このスキーム名はadjustトラッカーURLでも`deep_link`パラメータとして使われます。これを設定するには、`Info.plist`ファイルを開き
`URL types`の行を新たに追加してください。そこにアプリのバンドルIDを`URL identifier`として入力し、`URL schemes`の欄に該当のスキーム名を入れてください。
下記の例では、`adjustExample`というスキーム名を扱います。

![][custom-url-scheme]

これが設定されると、該当のスキーム名を含む`deep_link`パラメータを持つadjustトラッカーURLをクリックした後でアプリが開かれます。
アプリが開かれた後、`AppDelegate`クラスの`openURL`メソッドが呼ばれ、トラッカーURLの`deep_link`パラメータの内容が送信されます。
このディープリンクの内容データを利用したい場合、このメソッドを上書きしてください。

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

これで、iOS 8以前の端末へのディープリンクの設定は完了です。

##### <a id="deeplinking-setup-new"> iOS 9以前でのディープリンキング

iOS 9以降の端末へディープリンクを対応させるためには、Appleのユニバーサルリンクを有効化させる必要があります。
ユニバーサルリンクについて、それらの設定については[こちら][universal-links]をご確認ください。

adjustはユニバーサルリンクをサポートするために様々な対応をしています。
adjustでユニバーサルリンクを使うには、adjustダッシュボードでユニバーサルリンクのための設定を行ってください。
詳しくは[公式資料][universal-links-guide]をご覧ください。

ダッシュボードでの設定が完了したら、以下の作業を行ってください。

Appleディベロッパポータルでアプリの`Associated Domains`を有効化し、Xcodeプロジェクトでも同様にしてください。
`applinks:`を前につけてadjustダッシュボードの`Domains`ページで生成されたユニバーサルリンクを追加してください。
ユニバーサルリンクから`http(s)`を削除することを忘れずにご確認ください。

![][associated-domains-applinks]

この設定が完了すると、adjustのトラッカーユニバーサルリンクがクリックされた後にアプリが開かれます。
アプリが開いた後、`AppDelegate`クラスの`continueUserActivity`メソッドが呼ばれ、ユニバーサルリンクURLの内容が送信されます。
このディープリンクの内容データを利用したい場合、このメソッドを上書きしてください。

``` objc
- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity
 restorationHandler:(void (^)(NSArray *restorableObjects))restorationHandler {
    if ([[userActivity activityType] isEqualToString:NSUserActivityTypeBrowsingWeb]) {
        NSURL url = [userActivity webpageURL];

        // url object contains your universal link content
    }

    // Apply your logic to determine the return value of this method
    return YES;
    // or
    // return NO;
}
```

これで、iOS 9以降の端末へのディープリンクの設定は完了です。

従来のカスタムURLスキームのフォーマットでディープリンクを受け取るような独自のロジックを実装されている場合のために、
adjustはユニバーサルリンクを従来のディープリンクURLに変換するヘルパー関数を用意しています。
ユニバーサルリンクとカスタムURLスキームをこのメソッドに渡すと、カスタムURLスキームのディープリンクが生成されます。

``` objc
- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity
 restorationHandler:(void (^)(NSArray *restorableObjects))restorationHandler {
    if ([[userActivity activityType] isEqualToString:NSUserActivityTypeBrowsingWeb]) {
        NSURL url = [userActivity webpageURL];

        NSURL *oldStyleDeeplink = [Adjust convertUniversalLink:url scheme:@"adjustExample"];
    }

    // Apply your logic to determine the return value of this method
    return YES;
    // or
    // return NO;
}
```

##### <a id="deeplinking-deferred">ディファード・ディープリンキング

ディファード・ディープリンクが開く前に通知を受けるデリゲートコールバックを登録し、adjust SDKがそれを開くかどうか決めることができます。
[アトリビューションコールバック](#attribution-callback)や[イベントとセッションのコールバック](event-session-callbacks)に使われる
`AdjustDelegate`プロトコルをここでも使うことができます。

次のステップに進み、ディファード・ディープリンクのデリゲートコールバック関数を以下のように実装してください。

```objc
- (void)adjustDeeplinkResponse:(NSURL *)deeplink {
    // deeplink object contains information about deferred deep link content

    // Apply your logic to determine whether the adjust SDK should try to open the deep link
    return YES;
    // or
    // return NO;
}
```

コールバック関数はSDKがサーバーからDeferredディープリンクを受け取った後、それを開く前にコールされます。
コールバック関数内で、ディープリンクとSDKがディープリンクを立ち上げるかどうかのboolean値を確認できます。
例えば、ディープリンクをすぐには開かないようにした場合、それを保存し後から任意のタイミングで開くよう設定できます。

このコールバックが実装されていない場合、**adjust SDKはデフォルトで常にディープリンクを開きます**。

##### <a id="deeplinking-reattribution">ディープリンクを介したリアトリビューション

adjustはディープリンクを使ったリエンゲージメントキャンペーンをサポートしています。
詳しくは[公式資料][reattribution-with-deeplinks]をご覧ください。

この機能をご利用の場合、ユーザーが正しくリアトリビューションされるために、adjust SDKへのコールを追加してください。

アプリでディープリンクの内容データを受信したら、`appWillOpenUrl`メソッドへのコールを追加してください。
このコールによって、adjust SDKはディープリンクの中に新たなアトリビューションが存在するかを調べ、あった場合はadjustサーバーにこれを送信します。
ディープリンクのついたadjustトラッカーURLのクリックによってユーザーがリアトリビュートされる場合、
[アトリビューションコールバック](#attribution-callback)がこのユーザーの新しいアトリビューションデータで呼ばれます。

すべてのiOSバージョンにおいて、ディープリンキング・リアトリビューションをサポートするための`appWillOpenUrl`のコールは下記のようになります。

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

### <a id="troubleshooting">トラブルシューティング

#### <a id="ts-delayed-init">SDK初期化時の問題

[基本設定](#basic-setup)で説明した通り、アプリケーションデリゲートの`didFinishLaunching`か`didFinishLaunchingWithOptions`の
どちらかのメソッド内でadjust SDKを初期化することを強くお奨めします。
ここでなるべく早くadjust SDKを初期化することは非常に重要で、こうすればSDKのすべての機能を使うことができます。

この時にadjust SDKを初期化しないと、アプリ内のトラッキングにあらゆる影響が出ます。
**トラッキングを正しく行うために、adjust SDKは*必ず*初期化してください。**

以下のいずれかを行いたい場合、`SDK初期化前だと実行されません`。

* [イベントトラッキング](#event-tracking)
* [ディープリンクを介したリアトリビューション](#deeplinking-reattribution)
* [トラッキングの無効化](#disable-tracking)
* [オフラインモード](#offline-mode)

実際に初期化する前にadjust SDKのすべての機能を利用できるようにしたい場合、
アプリ内に`カスタムアクション・キューイングメカニズム`を構築するという方法があります。
adjust SDKに行わせたいすべての処理をキューに格納し、SDKが初期化された後で処理させます。

オフラインモードの状態は変わらず、トラッキングの有効/無効の状態も変わらず、
ディープリンクリアトリビューションは不可でイベントトラッキングは`排除されます`。

セッションのトラッキングもSDK初期化のタイミングに影響される可能性があります。
adjust SDKは初期化されるまでどんなセッションも回収できません。
これはトラッキングの精度に影響を与え、ダッシュボード上のDAUの数値が正しく測定されない可能性があります。

ここに例を上げます: スプラッシュ画面や初めのスクリーン以外のあるViewまたはView Controllerがロードされる時にadjust SDKをスタートするとし、
ユーザーはホームスクリーンからそこへ遷移すると仮定します。
ユーザーがアプリをダウンロードして開いた時、ホームスクリーンが表示されます。
この時、このユーザーによるインストールはトラッキングされているはずで、そのユーザーは何らかのキャンペーンから誘導されて来たのでしょう。
そのユーザーがアプリを起動した時、そのデバイスからセッションが作られ、アプリのアクティブユーザーとなります。
しかしadjust SDKはこの一連の流れを全く関知しません。adjust SDKを初期化すると設定されたスクリーンにユーザーが移動する必要があるからです。
ユーザーが何らかの理由でアプリを気に入らず、ホームスクリーンを表示した直後にアンインストールした場合、
このユーザーのアクションに関するすべての情報はadjust SDKにトラッキングされることはなく、ダッシュボードにも表示されません。

##### イベントトラッキング

イベントをトラッキングするために、トラッキングしたいイベントを内部でキューイングメカニズムに入れ、
SDKが初期化された後でトラッキングしてください。
SDKが初期化される前に作られたイベントトラッキングは、そのイベントが`除外されたり`、`永久に失われる`ことに繋がります。
そうならないために、SDKが`初期化`されて[`有効化`](#is-enabled)されてからトラッキングするようにしてください。

##### オフラインモード、トラッキングの有効化/無効化

オフラインモードはSDKの初期化の間で保持されるものではありません。なので、デフォルトでは`無効`に設定されます。
SDKの初期化前にオフラインモードを有効にしたい場合でも、最終的にSDKが初期化されるまでは`無効`のままです。

トラッキングの有効化/無効化はSDK初期化の間でも保持されます。SDK初期化の前にこの値を切り替えたい場合は、
切り替えは無視されます。初期化されると、SDKは切り替えを指示された状態(有効/無効)になります。

##### Reattribution via deep linksディープリンクを介したリアトリビューション

[上記](#deeplinking-reattribution)の通り、ディープリンク・リアトリビューションを使う際は、
旧式かユニバーサルリンクのどちらのディープリンクメカニズムかによりますが、
以下のコールをした後に`NSURL`オブジェクトが得られます。

```objc
[Adjust appWillOpenUrl:url]
```

このコールをSDK初期化の前に行った場合、アトリビュートされるべきだったURLからのディープリンクの情報は永久に失われます。
リアトリビューションを正しく行いたい場合は、この`NSURL`オブジェクトをキューにし
SDKが初期化されたら`appWillOpenUrl`メソッドが呼ばれるようにしてください。

##### セッショントラッキング

セッションのトラッキングはadjust SDKが自動で行い、アプリ開発者が制御することはできません。
セッショントラッキングを正しく行うためには、このREADMEで推奨される通りにadjust SDKを初期化することは極めて重要です。
これをしないと、セッショントラッキングやダッシュボードに表示されるDAUの数値に予測不能な影響が出る恐れがあります。
起こりうる誤りは様々で、うちいくつかを下に挙げます。

* SDKが初期化される前にユーザーがアプリを削除すると、そのインストールとセッションはトラッキングされず、ダッシュボードに記録されることもありません。
* SDKの初期化が午前0時以降だった場合にユーザーが午前0時前にアプリをダウンロードし開いた場合、
インストールとセッションは翌日のものとして記録される恐れがあります。
* SDKの初期化が午前0時以降だった場合、ある日ユーザーが全くアプリを開かず、日付が変わった直後に開いたとき、
アプリが開かれた日とは別の日のDAUに計上される恐れがあります。

これらの現象を避けるため、アプリケーションデリゲートの`didFinishLaunching`か`didFinishLaunchingWithOptions`メソッドにて
必ずadjust SDKを初期化してください。

#### <a id="ts-arc">"Adjust requires ARC"というエラーが出る

`Adjust requires ARC`というエラーが出てビルドに失敗した場合、そのプロジェクトは[ARC][arc]を使っていないと思われます。
その場合、[ARCを使うようプロジェクトを移行する][transition]ことをお奨めします。
ARCを使いたくない場合は、ターゲットのビルドの段階でadjustのすべてのソースファイルでARCを有効化する必要があります。手順は次の通りです。

`Compile Sources`を展開し、adjustのすべてのソースファイルを選択してください。
`Compiler Flags`を`-fobjc-arc`に変更してください。(すべてを選択し`Return`キーを押すとすべて一括で変えられます。)

#### <a id="ts-categories">"\[UIDevice adjTrackingEnabled\]: unrecognized selector sent to instance"というエラーが出る

このエラーはアプリにadjust SDKをフレームワークとして追加している場合に起こり得ます。
adjust SDKはソースファイル中に`categories`があり、このためこの方法でSDKの統合をした場合は
Xcodeプロジェクトの設定の`Other Linker Flags`に`-ObjC`フラグを追加する必要があります

#### <a id="ts-session-failed">"Session failed (Ignoring too frequent session.)"というエラーが出る

このエラーはインストールのテストの際に起こります。アンインストール後に再度インストールするだけでは新規インストールとして動作しません。
SDKがローカルで統計したセッションデータを失ったとサーバーは判断してエラーメッセージを無視し、
その端末に関する有効なデータのみが与えられます。

この仕様はテスト中には厄介かもしれませんが、サンドボックスと本番用の挙動をできる限り近づけるために必要です。

adjustのサーバーにある端末のセッションデータをリセットすることができます。ログにあるエラーメッセージをチェックしてください。

```
Session failed (Ignoring too frequent session. Last session: YYYY-MM-DDTHH:mm:ss, this session: YYYY-MM-DDTHH:mm:ss, interval: XXs, min interval: 20m) (app_token: {yourAppToken}, adid: {adidValue})
```

<a id="forget-device">With the `{yourAppToken}` and  either `{adidValue}` or `{idfaValue}` values filled in below, open one
of the following links:

```
http://app.adjust.com/forget_device?app_token={yourAppToken}&adid={adidValue}
```

```
http://app.adjust.com/forget_device?app_token={yourAppToken}&idfa={idfaValue}
```

端末に関する記録が消去されると、このリンクは`Forgot device`と返します。
もしその端末の記録がすでに消去されていたり、値が不正だった場合は`Device not found`が返ります。

#### <a id="ts-install-tracked">ログに"Install tracked"が出力されない

テスト端末でインストールをシミュレーションしたい場合、すでにインストールされたアプリがあるままのテスト端末で
Xcodeからアプリを再度立ち上げるだけでは不十分です。アプリを再度立ち上げ直してもアプリのデータは消去されず、
アプリ内にあるSDKのファイルはすべてそのままです。なので、再度立ち上げてもSDKはそれらのファイルを認識し、
アプリはすでにインストール済み(かつSDKはすでに起動済み)であると判断します。
初めての起動ではなく、何回めかに開かれたと判断されます。

インストールをシミュレーションする場合は次の手順で行ってください。

* 端末からアプリをアンインストールします (完全に消去してください)
* [上記](#forget-device)の方法でadjustのサーバーから端末に関する記録を消去してください
* Xcodeから端末上でアプリを立ち上げると、"Install tracked"が表示されるはずです

#### <a id="ts-iad-sdk-click">"Unattributable SDK click ignored"というメッセージが出る

`sandbox`環境でテストをしている時にこのメッセージが出ることがあり、
これはAppleが`iAd.framework`バージョン3でリリースした変更と関連しています。
ユーザーはiAdバナーをクリックすることでアプリへ誘導され、これによりSDKは`sdk_click`パッケージをadjustサーバーに送り
クリックされたURLの内容について知らせます。iAdバナーがクリックされずにアプリが開かれた場合、iAdバナーURLが人為的に作られ、
ランダムな値とともに送られるようAppleが設定しました。adjust SDKはこうした人為的なものと実際にクリックされてできたURLを判別できず、
どちらであってもadjustサーバーに`sdk_click`パッケージを送ります。もしログレベルを`verbose`に設定していれば、
以下のような`sdk_click`パッケージが表示されます。

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

何らかの理由でこの`sdk_click`が受け付けられた場合、別のキャンペーンURLをクリックすることによりアプリを開いたユーザーもしくはオーガニックユーザーが、
この存在しないiAdソースにアトリビュートされることを意味します。このため、adjustサーバーはこれを無視し、下記のメッセージを表示します。

```
[Adjust]v: Response: {"message":"Unattributable SDK click ignored."}
[Adjust]i: Unattributable SDK click ignored.
```

このメッセージはSDKの連携に問題があることを意味しているわけではありません。ユーザーが間違ってアトリビュートまたはリアトリビュートされる可能性のある
人為的に生成された`sdk_click`をadjustが無視したことを示しています。

#### <a id="ts-wrong-revenue-amount">adjustダッシュボード上で表示される収益データが間違っている

adjust SDKはトラッキングするよう設定されたものをトラッキングします。イベントに収益を付加している場合、金額として入力した数字のみがadjustサーバーに送信され
ダッシュボードに表示されます。adjust SDKおよびadjustサーバーは金額の値を操作しません。トラッキングされた値が間違っている場合は、
adjust SDKがトラッキングするよう設定された値が間違っていることになります。

通常、収益イベントをトラッキングするためのコードは次のようになります。

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

トラッキングされるべき値とは違う値がダッシュボードに表示されている場合は、**金額の値を決定するロジックの部分をご確認ください**。


[dashboard]:   http://adjust.com
[adjust.com]:  http://adjust.com

[en-readme]:    ../../README.md
[zh-readme]:    ../chinese/README.md
[ja-readme]:    ../japanese/README.md
[ko-readme]:    ../korean/README.md

[sdk2sdk-mopub]:  ../japanese/sdk-to-sdk/mopub.md

[arc]:         http://en.wikipedia.org/wiki/Automatic_Reference_Counting
[examples]:    http://github.com/adjust/ios_sdk/tree/master/examples
[carthage]:    https://github.com/Carthage/Carthage
[releases]:    https://github.com/adjust/ios_sdk/releases
[cocoapods]:   http://cocoapods.org
[transition]:  http://developer.apple.com/library/mac/#releasenotes/ObjectiveC/RN-TransitioningToARC/Introduction/Introduction.html

[example-tvos]:       ../../examples/AdjustExample-tvOS
[example-iwatch]:     ../../examples/AdjustExample-iWatch
[example-imessage]:   ../../examples/AdjustExample-iMessage
[example-ios-objc]:   ../../examples/AdjustExample-ObjC
[example-ios-swift]:  ../../examples/AdjustExample-Swift

[AEPriceMatrix]:     https://github.com/adjust/AEPriceMatrix
[event-tracking]:    https://docs.adjust.com/en/event-tracking
[callbacks-guide]:   https://docs.adjust.com/en/callbacks
[universal-links]:   https://developer.apple.com/library/ios/documentation/General/Conceptual/AppSearch/UniversalLinks.html

[special-partners]:     https://docs.adjust.com/en/special-partners
[attribution-data]:     https://github.com/adjust/sdks/blob/master/doc/attribution-data.md
[ios-web-views-guide]:  https://github.com/adjust/ios_sdk/blob/master/doc/japanese/web_views_ja.md
[currency-conversion]:  https://docs.adjust.com/en/event-tracking/#tracking-purchases-in-different-currencies

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


### <a id="license">ライセンス

adjust SDKはMITライセンスを適用しています。

Copyright (c) 2012-2019 Adjust GmbH, http://www.adjust.com

以下に定める条件に従い、本ソフトウェアおよび関連文書のファイル（以下「ソフトウェア」）の複製を取得するすべての人に対し、
ソフトウェアを無制限に扱うことを無償で許可します。これには、ソフトウェアの複製を使用、複写、変更、結合、掲載、頒布、サブライセンス、
および/または販売する権利、およびソフトウェアを提供する相手に同じことを許可する権利も無制限に含まれます。

上記の著作権表示および本許諾表示を、ソフトウェアのすべての複製または重要な部分に記載するものとします。

ソフトウェアは「現状のまま」で、明示であるか暗黙であるかを問わず、何らの保証もなく提供されます。
ここでいう保証とは、商品性、特定の目的への適合性、および権利非侵害についての保証も含みますが、それに限定されるものではありません。 
作者または著作権者は、契約行為、不法行為、またはそれ以外であろうと、ソフトウェアに起因または関連し、
あるいはソフトウェアの使用またはその他の扱いによって生じる一切の請求、損害、その他の義務について何らの責任も負わないものとします。
