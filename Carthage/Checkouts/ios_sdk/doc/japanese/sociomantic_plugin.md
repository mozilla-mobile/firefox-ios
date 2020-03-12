## Sociomanticプラグイン

以下のいずれかの方法でadjustとSociomanticの統合が可能です。

### CocoaPods

[CocoaPods](http://cocoapods.org/)をご利用の場合、Podfileに以下の記述を加えることができます。

```ruby
pod 'Adjust/Sociomantic'
```

### Carthage

[Carthage](https://github.com/Carthage/Carthage)をご利用の場合、Cartfileに以下の記述を加えることができます。

```ruby
github "adjust/ios_sdk" "sociomantic"
```

### ソースファイル

以下の手順でadjustとSociomanticのイベントを統合することもできます。

1. `plugin/Sociomantic`フォルダを[releases page](https://github.com/adjust/ios_sdk/releases)からダウンロードアーカイブに置いてください。

2. プロジェクトの`Adjust`フォルダに`ADJSociomantic.h`と`ADJSociomantic.m`ファイルをドラッグしてください。

3. `Choose options for adding these files`のダイアログが出たら、`Copy items if needed`にチェックを入れ、`Create groups`を選択してください。

### Sociomanticイベント

以下の手順でadjustとSociomanticを統合することができます。

1. Sociomanticイベントのメソッドを利用でき、ディクショナリのプロパティ名として使う以下の変数も使えるようになります。

    ```objc
    NSString *const SCMCategory;
    NSString *const SCMProductName;
    NSString *const SCMSalePrice;
    NSString *const SCMAmount;
    NSString *const SCMCurrency;
    NSString *const SCMProductURL;
    NSString *const SCMProductImageURL;
    NSString *const SCMBrand;
    NSString *const SCMDescription;
    NSString *const SCMTimestamp;
    NSString *const SCMValidityTimestamp;
    NSString *const SCMQuantity;
    NSString *const SCMScore;
    NSString *const SCMProductID;
    NSString *const SCMAmount;
    NSString *const SCMCurrency;
    NSString *const SCMQuantity;
    NSString *const SCMAmount;
    NSString *const SCMCurrency;
    NSString *const SCMActionConfirmed;
    NSString *const SCMActionConfirmed;
    NSString *const SCMCustomerAgeGroup;
    NSString *const SCMCustomerEducation;
    NSString *const SCMCustomerGender;
    NSString *const SCMCustomerID;
    NSString *const SCMCustomerMHash;
    NSString *const SCMCustomerSegment;
    NSString *const SCMCustomerTargeting;
    ```

2. Sociomanticのイベントを送信する前に、以下のようにパートナーIDを設定する必要があります。

    ```objc
    #import "ADJSociomantic.h"

    [ADJSociomantic injectPartnerIdIntoSociomanticEvents:@"{sociomanticPartnerId}"];
    ```

3. これでSociomanticのイベントをそれぞれ統合できるようになりました。以下に例を示します。

#### カスタマーイベント

```objc
#import "ADJSociomantic.h"

ADJEvent *event = [ADJEvent eventWithEventToken:ANY_TOKEN];
NSDictionary *customerData = @{
    SCMCustomerID: @"123456"
};

[ADJSociomantic injectCustomerDataIntoEvent:event withData:customerData];
[Adjust trackEvent:event];
```

#### View Home Page

```objc
#import "ADJSociomantic.h"

ADJEvent *event = [ADJEvent eventWithEventToken:HOMEPAGE_TOKEN];

[ADJSociomantic injectHomePageIntoEvent:event];
[Adjust trackEvent:event];
```

#### リスティング

```objc
#import "ADJSociomantic.h"

ADJEvent *event = [ADJEvent eventWithEventToken:LISTING_TOKEN];
NSArray *categories = @[@"category_1", @"category_2", @"category_3"];
NSString *date = @"1427792434";

[ADJSociomantic injectViewListingIntoEvent:event withCategories:categories];
// You also can provide a date like this
[ADJSociomantic injectViewListingIntoEvent:event withCategories:categories withDate:date];
[Adjust trackEvent:event];
```

#### プロダクト

```objc
#import "ADJSociomantic.h"

ADJEvent *event      = [ADJEvent eventWithEventToken:PRODUCT_VIEW_TOKEN];
NSDictionary *params = @{
    SCMCategory     : @[@"cat1", @"cat2"],
    SCMProductName  : @"stuff",
    SCMDescription  : @"pure awesomeness"
};

[ADJSociomantic injectViewProductIntoEvent:event productId:@"productId_4" withParameters:params];
[Adjust trackEvent:event];
```
*Product Viewに使用できるプロダクトパラメータ一覧*

<table>
<colgroup>
    <col width="8%" />
    <col width="5%" />
    <col width="21%" />
    <col width="64%" />
</colgroup>
<thead>
<tr class="header">
    <th align="left">パラメータ名</th>
    <th align="left">条件</th>
    <th align="left">説明</th>
    <th align="left">備考</th>
</tr>
</thead>
<tbody>

<tr class="odd">
    <td align="left">SCMCategory</td>
    <td align="left">必須*</td>
    <td align="left">プロダクトカテゴリ(entire category path)</td>
    <td align="left">リスティングページまたはカテゴリのトラッキングコードから提供されるカテゴリ情報は、フィードまたはプロダクトページのトラッキングコードから提供されるカテゴリ情報と一致する必要があります。</td>
</tr>
<tr class="even">
    <td align="left">SCMProductName</td>
    <td align="left">必須*</td>
    <td align="left">プロダクト名</td>
    <td align="left">記号はエンコードできませんが、UTF-8で使用できます。HTMLマークアップは使用できません。</td>
</tr>
<tr class="odd">
    <td align="left">SCMSalePrice</td>
    <td align="left">必須*</td>
    <td align="left">セール価格 (小数 e.g. 2.99)</td>
    <td align="left">小数点はドットを使ってください。カンマは使えません。</td>
</tr>
<tr class="even">
    <td align="left">SCMAmount</td>
    <td align="left">必須*</td>
    <td align="left">通常価格 (小数 e.g. 3.99)</td>
    <td align="left">小数点はドットを使ってください。カンマは使えません。</td>
</tr>
<tr class="odd">
    <td align="left">SCMCurrency</td>
    <td align="left">必須*</td>
    <td align="left">通貨コード(ISO 4217フォーマット e.g. EUR)</td>
    <td align="left">決められた通貨コードが入ります。トラッキングコードサンプルでご確認いただけます。</td>
</tr>
<tr class="even">
    <td align="left">SCMProductURL></td>
    <td align="left">必須*</td>
    <td align="left">プロダクトURL (ディープリンク)</td>
    <td align="left">有効なディープリンクを設定してください。Googleアナリティクス、Hurra、Eulerian等のクリックトラッキングパラメータを含まないディープリンクが理想的です。ディープリンクは http:// で始まるようにしてください。</td>
</tr>
<tr class="odd">
    <td align="left">SCMProductImageURL</td>
    <td align="left">必須*</td>
    <td align="left">プロダクト画像URL</td>
    <td align="left">画像サイズにご注意ください。広告中に任意でつけられる画像は最小で 200x200 px で、同じアスペクト比である必要があります。</td>
</tr>
<tr class="even">
    <td align="left">SCMBrand</td>
    <td align="left">必須*</td>
    <td align="left">プロダクトブランド</td>
    <td align="left">記号はエンコードできませんが、UTF-8で使用できます(上記SCMProductNameと同様です)。HTMLマークアップは使用できません。</td>
</tr>
<tr class="odd">
    <td align="left">SCMDescription</td>
    <td align="left">任意</td>
    <td align="left">短い商品説明</td>
    <td align="left">記号はエンコードできませんが、UTF-8で使用できます(上記SCMProductNameと同様です)。HTMLマークアップは使用できません。</td>
</tr>
<tr class="even">
    <td align="left">SCMTimestamp</td>
    <td align="left">任意</td>
    <td align="left">プロダクト公開までのタイムスタンプ(GMT)</td>
    <td align="left">訪問者が検索した日付を入力してください。NSNumberクラスでラップされたNSTimeInterval形式にしてください(例をご確認ください)。</td>
</tr>
<tr class="odd">
    <td align="left">SCMValidityTimestamp</td>
    <td align="left">任意</td>
    <td align="left">プロダクト公開までのタイムスタンプ(GMT)</td>
    <td align="left">プロダクトが利用可能になるまでの時間をUnixタイムスタンプで入力してください。常に利用できるプロダクトには 0 を入力してください。NSNumberクラスでラップされたNSTimeInterval形式にしてください(SCMTimestampと同様です)。</td>
</tr>
<tr class="even">
    <td align="left">SCMQuantity</td>
    <td align="left">任意</td>
    <td align="left">プロダクトの在庫数</td>
    <td align="left">このフィールドはSociomanticの担当者にご相談いただいた上でご使用ください。</td>
</tr>
<tr class="odd">
    <td align="left">SCMScore</td>
    <td align="left">任意</td>
    <td align="left">プロダクトのプライオリティスコア(0 から 10.0 まで)</td>
    <td align="left">このフィールドはSociomanticの担当者にご相談いただいた上でご使用ください。</td>
</tr>

</tbody>
</table>

\*フィードで設定されている場合は任意

どの設定を使うべきか不明瞭な場合は、Sociomanticのテクニカルアカウント担当にご相談ください。

#### カート

```objc
#import "ADJSociomantic.h"

ADJEvent *event = [ADJEvent eventWithEventToken:CART_TOKEN];
NSDictionary *product5 = @{
    SCMAmount    : @100,
    SCMCurrency  : @"EUR",
    SCMQuantity  : @1,
    SCMProductID : @"productId_5",
};
NSString *product6 = @"productId_6";
NSDictionary *product7 = @{
    SCMProductID : @"productId_7"
};


NSArray * productList = @[product5, product6, product7];

[ADJSociomantic injectCartIntoEvent:event cart:productList];
[Adjust trackEvent:event];
```

*Cart Viewに利用できるカートパラメータ一覧*

<table>
<colgroup>
    <col width="8%" />
    <col width="5%" />
    <col width="21%" />
    <col width="64%" />
</colgroup>
<thead>
<tr class="header">
    <th align="left">パラメータ名</th>
    <th align="left">条件</th>
    <th align="left">説明</th>
    <th align="left">備考</th>
</tr>
</thead>
<tbody>
<tr class="odd">
    <td align="left">SCMProductID</td>
    <td align="left">必須</td>
    <td align="left">プロダクトID</td>
    <td align="left">カラーやサイズなどのサブIDを除いたプロダクトIDを入力してください。</td>
</tr>
<tr class="even">
    <td align="left">SCMAmount</td>
    <td align="left">任意</td>
    <td align="left">価格(小数 e.g. 2.99)</td>
    <td align="left">小数点はドットを使ってください。カンマは使えません。数量が1より大きい場合でも、プロダクト1つあたりの価格を入力してください。</td>
</tr>
<tr class="odd">
    <td align="left">SCMCurrency</td>
    <td align="left">任意</td>
    <td align="left">通貨コード(ISO 4217フォーマット e.g. EUR)</td>
    <td align="left">決められた通貨コードが入ります。トラッキングコードサンプルでご確認いただけます。</td>
</tr>
<tr class="even">
    <td align="left">SCMQuantity</td>
    <td align="left">任意</td>
    <td align="left">選択されたプロダクトの数量</td>
    <td align="left">整数で入力してください。</td>
</tr>

</tbody>
</table>

#### 未確認のトランザクション

```objc
#import "ADJSociomantic.h"

ADJEvent *event = [ADJEvent eventWithEventToken:TRANSACTION_TOKEN];
NSString *product5 =  @"productId_5";
NSDictionary *product6 = @{
    SCMQuantity  : @3,
    SCMProductID : @"productId_6"
};
NSArray * productList = @[product5, product6];

[ADJSociomantic injectTransactionIntoEvent:event transactionId:@"123456" withProducts:productList];
[Adjust trackEvent:event];
```

もしくは、以下のようにパラメータをつけることもできます。

```objc
#import "ADJSociomantic.h"

ADJEvent *event = [ADJEvent eventWithEventToken:TRANSACTION_TOKEN];
NSString *product5 =  @"productId_5";
NSDictionary *product6 = @{
    SCMQuantity  : @3,
    SCMProductID : @"productId_6"
};
NSArray *productList = @[product5, product6];
NSDictionary *parameters = @{
    SCMQuantity: @4  // 3 times product6 and 1 product5
};

[ADJSociomantic injectTransactionIntoEvent:event transactionId:@"123456" withProducts:productList withParameters:parameters];
[Adjust trackEvent:event];
```

#### 確認済みトランザクション

```objc
#import "ADJSociomantic.h"

ADJEvent *event = [ADJEvent eventWithEventToken:TRANSACTION_TOKEN];
NSString *product5 =  @"productId_5";
NSDictionary *product6 = @{
    SCMQuantity  : @3,
    SCMProductID : @"productId_6"
};
NSArray * productList = @[product5, product6];

[ADJSociomantic injectConfirmedTransactionIntoEvent:event transactionId:@"123456" withProducts:productList];
[Adjust trackEvent:event];
```

もしくは、以下のようにパラメータをつけることもできます。

```objc
#import "ADJSociomantic.h"

ADJEvent *event = [ADJEvent eventWithEventToken:TRANSACTION_TOKEN];
NSString *product5 =  @"productId_5";
NSDictionary *product6 = @{
    SCMQuantity  : @3,
    SCMProductID : @"productId_6"
};
NSArray *productList = @[product5, product6];
NSDictionary *parameters = @{
    SCMQuantity: @4  // 3 times product6 and 1 product5
};

[ADJSociomantic injectConfirmedTransactionIntoEvent:event transactionId:@"123456" withProducts:productList withParameters:parameters];
[Adjust trackEvent:event];
```

*Transaction Viewに使用できるカートパラメータの一覧*

カートパラメータを見る

*Transaction Viewに使用できるトランザクションパラメータの一覧*

<table>
<colgroup>
    <col width="8%" />
    <col width="5%" />
    <col width="21%" />
    <col width="64%" />
</colgroup>
<thead>
<tr class="header">
    <th align="left">パラメータ名</th>
    <th align="left">必須</th>
    <th align="left">説明</th>
    <th align="left">備考</th>
</tr>
</thead>
<tbody>
<tr class="odd">
    <td align="left">SCMAmount</td>
    <td align="left">任意</td>
    <td align="left">価格(小数 e.g. 2.99)</td>
    <td align="left">小数点はドットを使ってください。カンマは使えません。数量が1より大きい場合でも、プロダクト1つあたりの価格を入力してください。</td>
</tr>
<tr class="even">
    <td align="left">SCMCurrency</td>
    <td align="left">任意</td>
    <td align="left">通貨コード(ISO 4217フォーマット e.g. EUR)</td>
    <td align="left">決められた通貨コードが入ります。トラッキングコードサンプルでご確認いただけます。</td>
</tr>
<tr class="odd">
    <td align="left">SCMQuantity</td>
    <td align="left">任意</td>
    <td align="left">選択されたプロダクトの数量</td>
    <td align="left">整数で入力してください。</td>
</tr>

</tbody>
</table>

#### リードイベント

```objc
#import "ADJSociomantic.h"

ADJEvent *event = [ADJEvent eventWithEventToken:LEAD_TOKEN];

[ADJSociomantic injectLeadIntoEvent:event leadID:@"123456789"];
[Adjust trackEvent:event];
```

確認済みリードには以下のように記述できます。

```objc
#import "ADJSociomantic.h"

ADJEvent *event = [ADJEvent eventWithEventToken:LEAD_TOKEN];

[ADJSociomantic injectLeadIntoEvent:event leadID:@"123456789" andConfirmed:YES];
[Adjust trackEvent:event];
```
