## Integrate Adjust with the Batch.com SDK

To integrate Adjust with Batch.com SDK, you must send your Adjust attribution data to the Batch SDK after receiving the attribution response from our backend. Follow the steps in the [attribution callback][attribution-callback] chapter of our iOS SDK guide to implement this. To use the Batch.com SDK API, the callback method can be set as the following:

```objc
- (void)adjustAttributionChanged:(ADJAttribution *)attribution {
    // initiate Batch user editor to set new attributes
    BatchUserDataEditor *editor = [BatchUser editor];

    if (attribution.network != nil)
        [editor setAttribute:attribution.network forKey:@"adjust_network"];
    if (attribution.campaign != nil)
        [editor setAttribute:attribution.campaign forKey:@"adjust_campaign"];
    if (attribution.adgroup != nil)
        [editor setAttribute:attribution.adgroup forKey:@"adjust_adgroup"];
    if (attribution.creative != nil)
        [editor setAttribute:attribution.creative forKey:@"adjust_creative"];

    // send new attributes to Batch servers
    [editor save];
}
```

Before you implement this interface, please take care to consider the [possible conditions for usage of some of your data][attribution-data].

[attribution-data]:     https://github.com/adjust/sdks/blob/master/doc/attribution-data.md
[attribution-callback]: https://github.com/adjust/ios_sdk#attribution-callback