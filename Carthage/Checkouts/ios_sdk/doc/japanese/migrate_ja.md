## iOS用adjust SDKのv3.4.0からv.4.8.0への移行

### 初期設定

adjust SDKの設定方法が変わりました。初期設定はすべて新しいconfigオブジェクトで行わるようになります。
加えてadjustのprefixも`AI`から`ADJ`に変わりました。
移行の前後で`AppDelegate.m`の設定がどのように行われるか例を示します。

##### 移行前

```objc
[Adjust appDidLaunch:@"{YourAppToken}"];
[Adjust setEnvironment:AIEnvironmentSandbox];
[Adjust setLogLevel:AILogLevelInfo];
[Adjust setDelegate:self];

- (void)adjustFinishedTrackingWithResponse:(AIResponseData *)responseData {
}
```

##### 移行後

```objc
NSString *yourAppToken = @"{YourAppToken}";
NSString *environment = ADJEnvironmentSandbox;
ADJConfig *adjustConfig = [ADJConfig configWithAppToken:yourAppToken
                                            environment:environment];
[adjustConfig setLogLevel:ADJLogLevelInfo];
[adjustConfig setDelegate:self];
[Adjust appDidLaunch:adjustConfig];

- (void)adjustAttributionChanged:(ADJAttribution *)attribution {
}
```

### イベントトラッキング

トラッキングされる前に設定することのできるイベントオブジェクトも導入しました。
導入前後で設定がどのように行われるか例を示します。

##### 導入前

```objc
NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
[parameters setObject:@"value" forKey:@"key"];
[parameters setObject:@"bar" forKey:@"foo"];
[Adjust trackEvent:@"abc123" withParameters:parameters];
```

##### 導入後

```objc
ADJEvent *event = [ADJEvent eventWithEventToken:@"abc123"];
[event addCallbackParameter:@"key" value:@"value"];
[event addCallbackParameter:@"foo" value:@"bar"];
[Adjust trackEvent:event];
```

### 収益トラッキング

収益は通常のイベントとして扱えるようになりました。報酬と通過をトラッキングするよう設定するだけです。
イベントトークンなしでは収益のトラッキングはできなくなりましたので、ご注意ください。
ダッシュボードでイベントトークンを追加作成する必要がある場合があります。
任意のトランザクションIDがイベントインスタンスのプロパティとなります。

*注意* 金額のフォーマットがセント単位から通過単位に変わりました。
現在の収益トラッキングの金額は通過単位に調整されているはずです。(100で割った値になります)

##### 変更前

```objc
[Adjust trackRevenue:1.0 transactionId:transaction.transactionIdentifier forEvent:@"xyz987"];
```

##### 変更後

```objc
ADJEvent *event = [ADJEvent eventWithEventToken:@"xyz987"];
[event setRevenue:0.01 currency:@"EUR"]; // You have to include the currency
[event setTransactionId:transaction.transactionIdentifier];
[Adjust trackEvent:event];
```

## v3.0.0から移行する場合の追加手順

`trackRevenue`に、任意で使用できる`transactionId`というパラメータを追加しました。
アプリ内課金をトラッキングする場合、Appleから提供されるトランザクションIDを渡すと、重複を防ぐのに役立つでしょう。
下記のような形でご利用いただけます。

```objc
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased:
                [self finishTransaction:transaction];

                [Adjust trackRevenue:...
                       transactionId:transaction.transactionIdentifier // avoid duplicates
                            forEvent:...
                      withParameters:...];

                break;
            // more cases
        }
    }
}
```

## v2.1.x or 2.2.xから移行する場合の追加手順

メインクラスの名称を`AdjustIo`から`Adjust`に変更しました。
すべてのadjust SDKのコールを更新するには、次のステップに進んでください。

1. 旧`AdjustIo`ソースフォルダを右クリックし、`Delete`を選択、`Move to Trash`をクリックしてください。

2. Xcodeメニューから`Find → Find and Replace in Project...`を選び、検索と置換の機能に進んでください。
   検索フィールドに`AdjustIo`を、置換フィールドに`Adjust`を入れてEnterを押してください。
   置換したくないものがあれば、プレビューを押してマッチした結果から選択解除してください。
   Replaceをクリックして、`Adjust`インポートとコールを置換してください。
   
       ![][rename]

3. バージョン v3.4.0をダウンロードし、`Adjust`フォルダをXcodeプロジェクトナビゲータにドラッグしてください。

       ![][drag]

4. プロジェクトをビルドし、問題なく差し替えられたことを確認してください。

adjust SDK v3.4.0はデリゲートコールバックを追加しました。
詳細は[README]をご確認ください。

## v2.0.xから移行する場合の追加手順

プロジェクトナビゲータからアプリケーションデリゲートのソースファイルを開いてください。
ファイルの先頭に下記の`import`の記述を加えてください。
`didFinishLaunching`か`didFinishLaunchingWithOptions`のいずれかのメソッドに、
下記の`Adjust`のコールを追加してください。

```objc
#import "Adjust.h"
// ...
[Adjust appDidLaunch:@"{YourAppToken}"];
[Adjust setLogLevel:AILogLevelInfo];
[Adjust setEnvironment:AIEnvironmentSandbox];
```
![][delegate]

`{YourAppToken}`にアプリのトークンを入力してください。これは[dashboard]でご確認いただけます。

You can increase or decrease the amount of logs you see by calling
`setLogLevel:` with one of the following parameters:
`setLogLevel:`をコールするパラメータを変更すると、記録するログのレベルを調整できます。
パラメータには以下の種類があります。

```objc
[Adjust setLogLevel:AILogLevelVerbose]; // すべてのログを有効にする
[Adjust setLogLevel:AILogLevelDebug];   // より詳細なログを記録する
[Adjust setLogLevel:AILogLevelInfo];    // デフォルト
[Adjust setLogLevel:AILogLevelWarn];    // infoのログを無効にする
[Adjust setLogLevel:AILogLevelError];   // warningも無効にする
[Adjust setLogLevel:AILogLevelAssert];  // errorも無効にする
```

テスト用か本番用かによって、`setEnvironment:`のパラメータは以下のいずれかに設定する必要があります。

```objc
[Adjust setEnvironment:AIEnvironmentSandbox];
[Adjust setEnvironment:AIEnvironmentProduction];
```

**重要** この値はテスト中のみ`AIEnvironmentSandbox`に設定してください。
アプリを提出する前に`AIEnvironmentProduction`になっていることを必ず確認してください。
再度開発やテストをする際は`AIEnvironmentSandbox`に戻してください。

この変数は実際のトラフィックとテスト端末からのテストのトラフィックを区別するために利用されます。
正しく計測するために、この値の設定には常に注意してください。収益のトラッキングの際には特に重要です。

## v1.xから移行する場合の追加手順

1. `appDidLaunch`メソッドはアプリIDの代わりにアプリトークンを使用します。
   アプリトークンは[dashboard]でご確認いただけます。

2. iOS用adjust SDKバージョン3.4.0は[ARC][arc]を使用しています。もしまだ実装していなければ、
   プロジェクトを[ARC使用へ移行][transition]することをお薦めします。
   ARCをご利用になりたくない場合は、adjust SDKのすべてのファイルでARCを有効化する必要があります。
   詳細は[README]をご確認ください。

3. すべての`[+Adjust setLoggingEnabled:]`のコールを削除してください。
   ログはデフォルトで有効になっており、レベルは`[Adjust setLogLevel:]`メソッドで調整可能です。
   詳細は[README]をご確認ください。

4. すべての`[+Adjust userGeneratedRevenue:...]`コールを
   `[+Adjust trackRevenue:...]`に変更してください。
   一貫性を持たせるために名称を変更しました。金額パラメータの型は`double`です。
   数字から接尾の`f`を除いてください (`12.3f`は`12.3`になります)。

[README]: ../README.md
[rename]: https://raw.github.com/adjust/sdks/master/Resources/ios/rename.png
[drag]: https://raw.github.com/adjust/sdks/master/Resources/ios/drag3.png
[delegate]: https://raw.github.com/adjust/sdks/master/Resources/ios/delegate3.png
[arc]: http://en.wikipedia.org/wiki/Automatic_Reference_Counting
[transition]: http://developer.apple.com/library/mac/#releasenotes/ObjectiveC/RN-TransitioningToARC/Introduction/Introduction.html
[dashboard]: http://adjust.com
