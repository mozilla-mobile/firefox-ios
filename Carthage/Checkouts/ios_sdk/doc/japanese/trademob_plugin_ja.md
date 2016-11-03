## Trademobプラグイン

以下のいずれかの方法でadjustとTrademobの統合が可能です。

### CocoaPods

[CocoaPods](http://cocoapods.org/)をご利用の場合、Podfileに以下の記述を加えることができます。

```ruby
pod 'Adjust/Trademob'
```

### Carthage

[Carthage](https://github.com/Carthage/Carthage)をご利用の場合、Cartfileに以下の記述を加えることができます。

```ruby
github "adjust/ios_sdk" "trademob"
```

### ソースファイル

以下の手順でadjustとTrademobを統合することもできます。

2. `plugin/Trademob`フォルダを[releases page](https://github.com/adjust/ios_sdk/releases)からダウンロードアーカイブに置いてください。

2. プロジェクトの`Adjust`フォルダに`ADJTrademob.h`と`ADJTrademob.m`ファイルをドラッグしてください。

3. `Choose options for adding these files`のダイアログが出たら、`Copy items if needed`にチェックを入れ、`Create groups`を選択してください。

このプラグインについてご質問があれば、`eugenio.warglien@trademob.com`へご相談ください。

### Trademobイベント

次の方法でTrademobのイベントを使うことができます。

#### リスティング

```objc
#import "ADJTrademob.h"

ADJEvent *event = [ADJEvent eventWithEventToken:@"{viewListingEventToken}"];

NSArray *itemIds = @[@"itemId1", @"itemId2", @"itemId3"];

NSDictionary *metadata = @{@"info1":@"value1", @"info2":@"value2"};

[ADJTrademob injectViewListingIntoEvent:event itemIds:itemIds metadata:metadata];

[Adjust trackEvent:event];
```

#### アイテム

```objc
#import "ADJTrademob.h"

ADJEvent *event = [ADJEvent eventWithEventToken:@"{viewItemEventToken}"];

NSDictionary *metadata = @{@"info1":@"value1", @"info2":@"value2"};

[ADJTrademob injectViewItemIntoEvent:event itemId:@"itemId" metadata:metadata];

[Adjust trackEvent:event];
```

#### バスケットに追加

```objc
#import "ADJTrademob.h"

ADJEvent *event = [ADJEvent eventWithEventToken:@"{addToBasketEventToken}"];

ADJTrademobItem *item1 = [[ADJTrademobItem alloc] initWithId:@"itemId1" price:120.4 quantity:1];
ADJTrademobItem *item2 = [[ADJTrademobItem alloc] initWithId:@"itemId2" price:20.1 quantity:4];

NSArray *items = @[item1, item2];

[ADJTrademob injectAddToBasketIntoEvent:event items:items metadata:nil];

[Adjust trackEvent:event];
```

#### チェックアウト

```objc
#import "ADJTrademob.h"

ADJEvent *event = [ADJEvent eventWithEventToken:@"{checkoutEventToken}"];

ADJTrademobItem *item1 = [[ADJTrademobItem alloc] initWithId:@"itemId1" price:120.4 quantity:1];
ADJTrademobItem *item2 = [[ADJTrademobItem alloc] initWithId:@"itemId2" price:20.1 quantity:4];

NSArray *items = @[item1, item2];

NSDictionary *metadata = @{@"info1":@"value1", @"info2":@"value2"};

[ADJTrademob injectCheckoutIntoEvent:event items:items metadata:metadata];

[Adjust trackEvent:event];
```
