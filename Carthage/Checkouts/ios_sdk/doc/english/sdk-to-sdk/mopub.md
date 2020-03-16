## Track MoPub ad revenue with Adjust SDK

[Adjust iOS SDK README][ios-readme]

[MoPub iOS documentation][mopub-docs]

Minimal SDK version required for this feature:

- **Adjust SDK v4.18.0**
- **MoPub SDK v5.7.0**

In case you are showing **rewarded video ads**: Inside of your MoPub SDK `didTrackImpressionWithAdUnitID:impressionData:` method implementation, make sure to invoke `trackAdRevenue:payload:` method of Adjust SDK like this:

```objc
- (void)didTrackImpressionWithAdUnitID:(NSString *)adUnitID 
                        impressionData:(MPImpressionData * _Nullable)impressionData {
    // Pass impression data JSON to Adjust SDK.
    [Adjust trackAdRevenue:ADJAdRevenueSourceMopub payload:[impressionData jsonRepresentation]];
}
```

In case you are showing **other ad formats**: Inside of your MoPub SDK `mopubAd:didTrackImpressionWithImpressionData:` method implementation, make sure to invoke `trackAdRevenue:payload:` method of Adjust SDK like this:

```objc
- (void)mopubAd:(id<MPMoPubAd>)ad didTrackImpressionWithImpressionData:(MPImpressionData * _Nullable)impressionData {
    // Pass impression data JSON to Adjust SDK.
    [Adjust trackAdRevenue:ADJAdRevenueSourceMopub payload:[impressionData jsonRepresentation]];                              
}
```

In case you have any questions about ad revenue tracking with MoPub, please contact your dedicated account manager or send an email to support@adjust.com.

[mopub-docs]:   https://developers.mopub.com/publishers/ios/impression-data/
[ios-readme]:   ../../../README.md
