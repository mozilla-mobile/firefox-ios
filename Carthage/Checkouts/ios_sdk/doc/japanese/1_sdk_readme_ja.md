
こちらは、adjust™のiOS 用SDKです。adjust™についての詳細は
[adjust.comをご覧ください]。



### 見本アプリ

[`example` ダイレクトリー][example]の中に、[`iOS`][example-ios]と
[`tvOS`][example-tvos]用の見本アプリが格納されています。
このXcodeプロジェクトを開けば、adjust のSDK の統合方法の実例をご確認いただけます。

### 基本的な統合方法

adjust のSDK をiOS のプロジェクトに統合するための手順を説明します。
ここでは、iOS アプリケーションの開発にXcodeを使用していると想定してします。

[CocoaPods][cocoapods]を使用している場合は、
`Podfile`に次のコードを追加して、

```
pod 'Adjust', :git => 'git://github.com/adjust/ios_sdk.git', :tag => 'v4.5.0'
```

[Carthage][carthage]を利用している場合は次のコードを`Cartfile`に追加して、[ステップ 3](#step3)に進んで下さい。

```
github "adjust/ios_sdk"
```

SDKをプロジェクトにフレームワークとして追加することもできます。
[こちらのページ][releases]で２つのアーカイブがあります：

* `AdjustSdkStatic.framework.zip`
* `AdjustSdkDynamic.framework.zip`

iOS8にてAppleがdynamic frameworks（embedded frameworks)を導入しました。アプリがiOS8以上の端末用の場合は、dynamic frameworkを利用することができます。
StaticかDynamicフレームワークを選択し、プロジェクトに追加して、[ステップ３][#step3]に進んでください。

#### SDKの入手

最新バージョンのSDKを[公開ページ][releases]からダウンロードし、アーカイブを任意のダイレクトリーに
解凍してください。

#### プロジェクトへのSDKの追加

Xcodeのプロジェクトナビゲータで`Supporting Files`グループ（または他の任意のグループ）を指定し、
Finderから`Adjust`というサブダイレクトリーをXcodeの
`Supporting Files`グループへドラッグしてください。

![][drag]

`Choose options for adding these files`のダイアログでは必ず
`Copy items if needed`というチェックボックスをチェックし、`Create
groups`のラジオボタンを選択してください。

![][add]

#### <a id="step3"></a>AdSupportとiAdのフレームワークの追加

プロジェクトナビゲータで対象のプロジェクトを選択し、メインビューの左側で、
追加先のターゲットを選択してください。`Build Phases`のタブから`Link
Binary with Libraries` のグループを展開し、セクション下部の`+`ボタンをクリックしてください。
`AdSupport.framework`を選択し、`Add`ボタンをクリックします。同様の手順で
`iAd.framework`も追加してください。最後に、両方のフレームワークの`Status`を
`Optional`に変更します。

![][framework]

### アプリへのAdjustの統合

#### Importステートメント

adjustSDKをソース、もしくはPod repositoryから追加した場合は、下記のimportステートメントをご利用ください：

```
#import "Adjust.h"
```

フレームワークもしくはCarthageとしてSDKを追加した場合は、次の行を利用ください：

```
#import &lt;AdjustSdk/Adjust.h&gt;
```

はじめに、基本的なセッションのトラッキングの設定を行います。

#### 基本設定

プロジェクトナビゲータからアプリケーション デリゲートのソースファイルを開いてください。
ファイルの先頭に`import`というステートメントを追加し、次に
アプリケーション デリゲートの、`didFinishLaunching`または`didFinishLaunchingWithOptions`というメソッドに、`Adjust`への
呼び出しを次の通り追加してください。

```
#import "Adjust.h"
// ...
NSString *yourAppToken = @"{YourAppToken}";
NSString *environment = ADJEnvironmentSandbox;
ADJConfig *adjustConfig = [ADJConfig configWithAppToken:yourAppToken
                                            environment:environment];
[Adjust appDidLaunch:adjustConfig];
```

![][delegate]

`{YourAppToken}`の箇所を、対象アプリのトークンと置き換えてください。トークンは
[ダッシュボード]にて確認できます。

アプリのビルドがテスト版か製品版かにより、
`environment`に以下のいずれかの値を適宜設定してください。

```
NSString *environment = ADJEnvironmentSandbox;
NSString *environment = ADJEnvironmentProduction;
```

**重要:**アプリがテスト版の場合のみ値を`ADJEnvironmentSandbox`に設定し、
アプリの公開前に必ずこの値を
`ADJEnvironmentProduction`に変更してください。再度開発やテストを行う際は、設定を
`ADJEnvironmentSandbox`に戻してください。

adjust ではこの設定により、トラフィックが実際のものなのか、テスト機から生じたものなのかを判別しています。
この値を常に正しく設定することは非常に大切で、売上のトラッキングを行う際には
特に重要となります。

##### Adjustのログ設定

`ADJConfig`インスタンスで、以下のパラメータのいずれかを設定して`setLogLevel:`関数を呼び出せば、
テスト時に表示されるログの量を
増減させることができます。

```
[adjustConfig setLogLevel:ADJLogLevelVerbose]; // enable all logging
[adjustConfig setLogLevel:ADJLogLevelDebug];   // enable more logging
[adjustConfig setLogLevel:ADJLogLevelInfo];    // the default
[adjustConfig setLogLevel:ADJLogLevelWarn];    // disable info logging
[adjustConfig setLogLevel:ADJLogLevelError];   // disable warnings as well
[adjustConfig setLogLevel:ADJLogLevelAssert];  // disable errors as well
```

#### アプリのビルド

アプリをビルドし、実行します。ビルドに成功したら、コンソールから
SDKのログをよくお読みください。またアプリの初回起動後は、
`Install tracked`という情報をログで確認してください。

![][run]

##### トラブルシューティング

`Adjust requires ARC`というエラーによりビルドが失敗した場合は、
プロジェクトで[自動参照カウント（ARC）][arc]機能を使用していない可能性があります。この場合は、[プロジェクトをARCを使用したものに切り替える]
[transition]ことをお勧めします。ARCを使用したくない場合は、
ターゲットのBuild Phases ペイン内で、全てのadjustのソースファイルで、次の通りARCを有効にする必要があります。

`Compile Sources`グループを展開したら、全てのadjust 用ファイル(Adjust、ADJ...、...+ADJAdditions)を選択し
+、`Compiler Flags`を`-fobjc-arc`に変更してください(変更を一度に行いたい場合は、全てを選択し、
`Return`キーを押してください)。

### 追加機能

プロジェクトにadjust のSDKを統合すると、以下の
機能を利用できるようになります。

#### イベントトラッキングの設定

adjustを使用してイベントをトラッキングすることができます。例えば、あるボタンへのタップをトラッキング
したい時は、[ダッシュボード]で新しいイベントトークンを作成し、
そこに`abc123`のようなイベントトークンを関連付けてください。[
そして、タップをトラッキングするために、ボタンの`buttonDown`メソッドに次の文字列を
追加してください。

```
ADJEvent *event = [ADJEvent eventWithEventToken:@"abc123"];
[Adjust trackEvent:event];
```

この時点でボタンをタップすると、ログに`Event tracked`という文字列が確認できます。

このイベントインスタンスを使って事前に設定を行えば、更に詳細なトラッキングを行うことも可能です。


##### コールバックパラメータの追加

[[ダッシュボード]でイベント追跡用のコールバックURLを設定することが可能で、
イベントがトラッキングされる度に、そのURLへGETリクエストが送信されます。
`addCallbackParameter`トラッキング前に、イベントインスタンスで`addCallbackParameter`　を呼び出して、そのイベント用のコールバックパラメーターを設定することができます。
その後、設定されたパラメーターがコールバックURLに付け足されます。


例えば、
`http://www.adjust.com/callback`をコールバックURLとして登録し、イベントを次のようにトラッキングする場合、

```
ADJEvent *event = [ADJEvent eventWithEventToken:@"abc123"];
[event addCallbackParameter:@"key" value:@"value"];
[event addCallbackParameter:@"foo" value:@"bar"];
[Adjust trackEvent:event];
```

イベントがトラッキングされると、次のURLにリクエストが送信されます。

```
http://www.adjust.com/callback?key=value&foo=bar
```

注目すべき機能として、adjustでは`{idfa}`といった、パラメータ値として利用できる様々なプレースホルダに対応しています。
実際に生成されるコールバックでは、この
プレースホルダはデバイスの広告識別子（IDFA）で置き換えらることになります。
また、adjust ではカスタムパラメータはコールバックに付加されるだけで、
一切保存されませんのでご注意下さい。イベントにコールバックを登録していなければ、
これらのパラメータは読み込まれることすらありません。

URLコールバックの使い方については、
[コールバックについての説明][callbacks-guide]ページで、使用可能な値を網羅したリストと一緒に、[詳しく紹介しています。

##### 売上のトラッキング

広告のタップや
アプリ内購入で売上が発生する場合は、売上情報をイベントと一緒にトラッキングすることができます。
例えば、タップ1回で0.01ユーロの収入が発生する場合、次のように設定して売上イベントをトラッキングすることができます。

```
ADJEvent *event = [ADJEvent eventWithEventToken:@"abc123"];
[event setRevenue:0.01 currency:@"EUR"];
[Adjust trackEvent:event];
```

もちろん、このコードはコールバック パラメータと組み合わせることもできます。

通貨トークンを設定した場合、adjustは売上高を自動的に為替計算し、任意の通貨で表示します。詳細は[為替レートの計算][currency-conversion]ページをご覧ください。

売上とイベントトラッキングの詳細は、[イベントトラッキングについて][event-tracking]をご覧ください。

##### <a id="deduplication"></a> 売上情報の重複登録防止

オプションの取引IDを引き渡すことで、売上の重複トラッキングを防ぐこともできます。
adjust では最新の取引IDが10個記録され、重複する取引IDを含む売上イベントはスキップされます。
この機能は、アプリ内購入をトラッキングする際に特に便利です。
以下の例をご覧ください。

アプリ内購入を追跡する場合、
ソースに`paymentQueue:updatedTransaction`と記述のある箇所で、ステータスが`SKPaymentTransactionStatePurchased`に変わった場合にのみ、`finishTransaction`（取引終了）の後に、`trackEvent` が呼び出されるよう設定して下さい。
このようにして、
実際には発生していない売上がトラッキングされるのを防ぐことができます。

```
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

##### レシートの照合

アプリ内購入を追跡する場合は、トラッキングデータにレシートを添付することができます。
この場合、adjustのサーバーはAppleにレシートの照会を行い、
確認が取れなかったイベントは破棄されます。この機能を使用するには、
追跡を行う購入の取引IDをadjustに送る必要があります。取引IDは
[上述の](#deduplication)SDK側での重複防止にも使用されます。

```
NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
NSData *receipt = [NSData dataWithContentsOfURL:receiptURL];

ADJEvent *event = [ADJEvent eventWithEventToken:...];
[event setRevenue:... currency:...];
[event setReceipt:receipt transactionId:transaction.transactionIdentifier];

[Adjust trackEvent:event];
```

#### ディープリンク　リアトリビューションの設定

adjust のSDKをディープリンクに対応するよう設定して、カスタムURLからアプリが開かれた際にトラッキングを行うことができます。
adjustでは、adjust専用のパラメータだけを読み込みます。
ディープリンクを使ったリターゲッティングやリエンゲージメントキャンペーンを予定している場合、この設定は必須となります。


プロジェクトナビゲータでアプリケーション デリゲートのソースファイルを開いてください。
`openURL`メソッドを表示または追加し、以下のadjustへの呼び出しコードを追加します。

```
- (BOOL)  application:(UIApplication *)application openURL:(NSURL *)url
    sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    [Adjust appWillOpenUrl:url];

    // Your code goes here
    Bool canHandle = [self someLogic:url];
    return canHandle;
}
```

#### イベントのバッファリングの有効化

アプリでイベント トラッキングが頻繁に発生する場合、
一部のHTTPリクエストを遅らせておいて、1分ごとに一括送信した方がよいことがあります。
その場合は、`ADJConfig`インスタンスでイベント バッファリングを有効にしてください。

```
[adjustConfig setEventBufferingEnabled:YES];
```

#### アトリビューションのコールバックの実装

トラッカーがアトリビューションの変化を検出した際に通知を受け取れるよう、デリゲート コールバックを登録することができます。
アトリビューションのソースを比較しなければいけないため、
変化の発生時に通知を行うことは出来ません。最も簡単な方法で設定するには、単一の匿名リスナを作成してください。
以下の手順で行って下さい。

また、adjustの[アトリビューションデータの適切な利用に関する方針]
[attribution-data]を必ず参照してください。

1. `AppDelegate.h`を開いて、インポートと`AdjustDelegate`の宣言を次の通り追加してください。

    ```
    #import "Adjust.h"

    @interface AppDelegate : UIResponder <UIApplicationDelegate, AdjustDelegate>
    ```

2. `AppDelegate.m`を開き、以下のデリゲート コールバック関数をAppDelegateクラスの実装コードに追加します。

    ```
    - (void)adjustAttributionChanged:(ADJAttribution *)attribution {
    }
    ```

3. AppDelegateクラスに`ADJConfig` インスタンスを設定します。

    ```
    [adjustConfig setDelegate:self];
    ```

デリゲートコールバックの設定には`ADJConfig` インスタンスを使用するため、
`[Adjust appDidLaunch:adjustConfig]`関数より先に、`setDelegate`インスタンスを呼び出すようにして下さい。

このデリゲート関数は、SDKが最後のアトリビューションデータを取得した際に呼び出されます。
呼び出されたデリゲート関数内には`attribution`パラメータが含まれており、アトリビューションの種類を確認することができます。
以下に、このパラメータのプロパティを簡単にまとめました。

- `NSString trackerToken` 発生したインストールのトラッカー トークン。
- `NSString trackerName` 発生したインストールのトラッカー名。
- `NSString network` 発生したインストールのネットワーク階層のグループ名。
- `NSString campaign` 発生したインストールのキャンペーン階層のグループ名。
- `NSString adgroup` 発生したインストールの広告グループ階層のグループ名。
- `NSString creative` 発生したインストールのクリエイティブ階層のグループ名。
- `NSString clickLabel` 発生したインストールのクリック ラベル。

#### トラッキングの無効化

`setEnabled``NO`adjustSDKが行っているデバイスのアクティビティのトラッキングをすべて無効化することができます。
そのためには、`NO`パラメータをセットして`setEnabled`関数を呼び出します。この設定はセッションが進んでも
維持され、最初のセッションの後にしか有効化できません。

```
[Adjust setEnabled:NO];
```

`isEnabled`関数を呼び出せば、adjust のSDKが現在有効かどうかを確認できます。
また、`YES`パラメータをセットして`setEnabled`関数を呼び出せば、いつでもadjust のSDKを
有効化することができます。

### オフラインモード

一旦adjustサーバまでの送信を停止スルことができます。すると、すべての数値がファイルで保存されますので、たくさんのイベントを発生しないようにご注意ください。

`true`というパラメータで`setOfflineMode`を呼び出すことでオフラインモードを利用できます。

```
[Adjust setOfflineMode:YES];
```

また、`false`パラメータで`setOfflineMode`を呼び出すとオンラインになります。すると、すべてのデータが正しいタイムスタンプと一緒に弊社のサーバへ送信されます。

トラッキングの無効化と違って、こちらの設定は起動旅にリセットしますので、オフラインモードの状態でアプリを終了しても、再起動するとオンラインモードとしてアプリが起動します。

#### パートナー パラメータ

ダッシュボードでトラッキングデータを共有するよう設定したネットワーク パートナーに対し、送信されるパラメータを追加することもできます。


これは、上記のコールバック パラメータと同様の働きを持つもので、
`ADJEvent`インスタンスで`addPartnerParameter`メソッドを呼び出せば追加することができます。

```
ADJEvent *event = [ADJEvent eventWithEventToken:@"abc123"];
[event addPartnerParameter:@"key" value:@"value"];
[Adjust trackEvent:event];
```

adjust のパートナーとその統合については
[スペシャルパートナーについて][special-partners]のページをご覧ください。

[adjust.com]: https://adjust.com
[cocoapods]: http://cocoapods.org
[dashboard]: https://adjust.com
[example]: http://github.com/adjust/ios_sdk/tree/master/example
[releases]: https://github.com/adjust/ios_sdk/releases
[arc]: http://en.wikipedia.org/wiki/Automatic_Reference_Counting
[transition]: http://developer.apple.com/library/mac/#releasenotes/ObjectiveC/RN-TransitioningToARC/Introduction/Introduction.html
[drag]: /images/sdk/Resources/ios/drag4.png
[add]: /images/sdk/Resources/ios/add3.png
[framework]: /images/sdk/Resources/ios/framework4.png
[delegate]: /images/sdk/Resources/ios/delegate4.png
[run]: /images/sdk/Resources/ios/run4.png
[AEPriceMatrix]: https://github.com/adjust/AEPriceMatrix
[attribution-data]: https://github.com/adjust/sdks/blob/master/doc/attribution-data.md
[callbacks-guide]: /ja//callbacks
[event-tracking]: /ja/event-tracking
[special-partners]: https://docs.adjust.com/en/special-partners
[currency-conversion]: /ja/event-tracking/#tracking-purchases-in-different-currencies
[ダッシュボード]: https://adjust.com/apps
