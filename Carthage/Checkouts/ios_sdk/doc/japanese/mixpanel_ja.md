##adjustとMixpanel SDKの統合

Mixpanel APIは共通のプロパティを`super properties`としてすべてのアクティビティで送信できるよう登録できます。詳しくは[Mixpanel page][mixpanel_ios]でご確認いただけます。Mixpanelのトラッキングされるすべてのイベントとadjustを統合するには、アトリビューションデータを受け取った後に`super properties`を設定する必要があります。adjustのiOS SDKガイド[デリゲートコールバック][response_callbacks]章に従って実装してください。
Mixpanel APIを使用するための関数は以下のように設定できます。

```objc
- (void)adjustAttributionChanged:(ADJAttribution *)attribution {
    Mixpanel *mixpanel = [Mixpanel sharedInstance];

    // The adjust properties will be sent
    // with all future track calls.
    if (attribution.network != nil)
        [mixpanel registerSuperProperties:@{@"[Adjust]Network":  attribution.network}];
    if (attribution.campaign != nil)
        [mixpanel registerSuperProperties:@{@"[Adjust]Campaign": attribution.campaign}];
    if (attribution.adgroup != nil)
        [mixpanel registerSuperProperties:@{@"[Adjust]Adgroup":  attribution.adgroup}];
    if (attribution.creative != nil)
        [mixpanel registerSuperProperties:@{@"[Adjust]Creative": attribution.creative}];
}
```

このインターフェイスを実装する前に、[データの取り扱いの状態][attribution_data]についてご確認ください。

[mixpanel_ios]: https://mixpanel.com/help/reference/ios#super-properties
[attribution_data]: https://github.com/adjust/sdks/blob/master/doc/attribution-data.md
[response_callbacks]: https://github.com/adjust/ios_sdk#9-receive-delegate-callbacks
