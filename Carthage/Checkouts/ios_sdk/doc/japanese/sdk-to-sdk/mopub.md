## MoPubの広告収益をAdjust SDKで計測

[Adjust iOS SDK README][ios-readme]

[MoPub iOS documentation][mopub-docs]

本機能には以下のSDKバージョンとそれ以降のバージョンが必須となります：

- **Adjust SDK v4.18.0**
- **MoPub SDK v5.7.0**

**動画リワード広告**を表示している場合: MoPub SDKの`didTrackImpressionWithAdUnitID:impressionData:`コールバックメソッドの実装内で、以下のようにAdjust SDKの`trackAdRevenue:payload:`メソッドを呼び出す必要があります。

```objc
- (void)didTrackImpressionWithAdUnitID:(NSString *)adUnitID 
                        impressionData:(MPImpressionData * _Nullable)impressionData {
    // Pass impression data JSON to Adjust SDK.
    [Adjust trackAdRevenue:ADJAdRevenueSourceMopub payload:[impressionData jsonRepresentation]];
}
```

**他の広告フォーマット**を表示している場合: MoPub SDKの`mopubAd:didTrackImpressionWithImpressionData:` コールバックメソッドの実装内で、以下のようにAdjust SDKの`trackAdRevenue:payload:` メソッドを呼び出す必要があります。

```objc
- (void)mopubAd:(id<MPMoPubAd>)ad didTrackImpressionWithImpressionData:(MPImpressionData * _Nullable)impressionData {
    // Pass impression data JSON to Adjust SDK.
    [Adjust trackAdRevenue:ADJAdRevenueSourceMopub payload:[impressionData jsonRepresentation]];                              
}
```

MoPub連携による広告収益計測についてご質問がございましたら、担当のアカウントマネージャーもしくはsupport@adjust.comまでお問い合わせください。

[mopub-docs]:        https://developers.mopub.com/publishers/android/impression-data/
[ios-readme]:    ../../japanese/README.md
