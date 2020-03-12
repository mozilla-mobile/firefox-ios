## 通过 Adjust SDK 跟踪 MoPub 广告收入

[Adjust iOS SDK 自述文件][ios-readme]

[MoPub iOS 文档][mopub-docs]

此功能最低 SDK 版本要求：

- **Adjust SDK v4.18.0**
- **MoPub SDK v5.7.0**

如果您在展示**奖励式视频广告**：在实施 MoPub SDK `didTrackImpressionWithAdUnitID:impressionData:` 回传方法时，请确保按照如下方式调用 Adjust SDK 的 `trackAdRevenue:payload:`方法：

```objc
- (void)didTrackImpressionWithAdUnitID:(NSString *)adUnitID 
                        impressionData:(MPImpressionData * _Nullable)impressionData {
    // Pass impression data JSON to Adjust SDK.
    [Adjust trackAdRevenue:ADJAdRevenueSourceMopub payload:[impressionData jsonRepresentation]];
}
```
如果您在展示**其他的广告格式**：在实施 MoPub SDK `mopubAd:didTrackImpressionWithImpressionData:` 回传方法时，请确保按照如下方式调用 Adjust SDK 的 `trackAdRevenue:payload:` 方法：

```objc
- (void)mopubAd:(id<MPMoPubAd>)ad didTrackImpressionWithImpressionData:(MPImpressionData * _Nullable)impressionData {
    // Pass impression data JSON to Adjust SDK.
    [Adjust trackAdRevenue:ADJAdRevenueSourceMopub payload:[impressionData jsonRepresentation]];                              
}
```

如果您对 MoPub 广告收入跟踪有任何疑问，请联系您的专属客户经理，或发送邮件至 support@adjust.com。

[mopub-docs]:        https://developers.mopub.com/publishers/android/impression-data/
[ios-readme]:    ../../chinese/README.md
